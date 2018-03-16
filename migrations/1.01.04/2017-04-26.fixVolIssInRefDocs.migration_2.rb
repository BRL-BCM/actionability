#!/usr/bin/env ruby
require 'brl/sites/pubmed'
require 'brl/genboree/rest/apiCaller'
require 'brl/genboree/kb/kbDoc'
require "genboreeTools"

unless( ARGV.size == 1)
  $stderr.puts "\n\nUSAGE: 2017-04-26.fixVolIssInRefDocs.migration.rb {outputFile}\n\n"
  # 2017-04-26.fixVolIssInRefDocs.migration.rb 10.15.55.128 aa1 kb2 reference_model_v1.1 ./jref.examination.out
  exit 134
end

grp  = 'actionability'
kb   = 'actionability_release'
coll = 'reference_model'
outfile = ARGV[0]
# ApiCaller to get PMID-based docs
docApiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?connect=false&format=json&detailed=true&matchProp=Reference.Category&matchValues=PMID&matchMode=exact")
# ApiCaller to put repaired values for Citation and Journal Ref properties
propApiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{docId}/prop/{prop}?connect=false&format=json_pretty&detailed=true")

unkPmids = []
failedDocs = []
totCnt = 0
okCnt = 0
updatedCnt = 0
failedCnt = 0
fixedCnt = 0
hr = docApiCaller.get( :grp => grp, :kb => kb, :coll => coll  )
if( docApiCaller.succeeded? )
  summOutFile = File.open( outfile, 'w+')
  summOutFile.puts "# STATUS\tDOC ID\tPMID\tVOL\tISS\tCURR J-REF\tNEW J-REF"
  docApiCaller.parseRespBody ;
  $stderr.debugPuts(__FILE__, __method__, 'STAUTS', "Found #{docApiCaller.apiDataObj.size} PMID-based reference documents.")
  docApiCaller.apiDataObj.each { |rdoc|
    rKbDoc = BRL::Genboree::KB::KbDoc.new( rdoc )
    docId = rKbDoc.getRootPropVal()
    pmid = rKbDoc.getPropVal( 'Reference.PMID' )
    cit = rKbDoc.getPropVal( 'Reference.PMID.Citation' )
    vol = rKbDoc.getPropVal( 'Reference.PMID.Volume' ) #=> "6"
    iss = rKbDoc.getPropVal( 'Reference.PMID.Issue' ) #=> "9"
    jref = rKbDoc.getPropVal( 'Reference.PMID.Journal Ref' ) #=> "Heart Rhythm. 2009 Sep;9(6):1335-41"
    if( pmid.to_s =~ /\S/ )
      # Get new Journal Ref and Citation no matter what (will also fix some other poor string production glitches)
      pubmed = BRL::Sites::Pubmed.new( pmid )
      if( pubmed and pubmed.requestSuccess )
        newJref = pubmed.journalStr rescue nil
        newCit = pubmed.citationStr rescue nil
        if( newJref.to_s =~ /\S/ and newCit.to_s =~ /\S/ )
          # Now push out replacement Citation and Journal Ref content to the Reference kb doc
          # - Journal Ref property
          valueObj = { 'value' => newJref }
          payload = { 'data' => valueObj }
          hr = propApiCaller.put( { :grp => grp, :kb => kb, :coll => coll, :docId => docId, :prop => 'Reference.PMID.Journal Ref' }, payload.to_json )
          if( propApiCaller.succeeded? )
            # - Citation property
            valueObj = { 'value' => newCit }
            payload = { 'data' => valueObj }
            hr = propApiCaller.put( { :grp => grp, :kb => kb, :coll => coll, :docId => docId, :prop => 'Reference.PMID.Citation' }, payload.to_json )
            if( propApiCaller.succeeded? )
              okCnt += 1
              summOutFile.puts "OK - UPDATED\t#{docId}\t#{pmid}\t#{vol}\t#{iss}\t#{jref}\t#{newJref}"
            else
              summOutFile.puts "FAILED - UPDATE Citation\t#{docId}\t#{pmid}\t#{vol}\t#{iss}\t#{jref}\t#{newJref}"
              failedCnt += 1
              failedDocs << docId
            end
          else
            summOutFile.puts "FAILED - UPDATE Journal Ref\t#{docId}\t#{pmid}\t#{vol}\t#{iss}\t#{jref}\t#{newJref}"
            failedCnt += 1
            failedDocs << docId
          end
        else
          summOutFile.puts "BUG IN MAKING STR\t#{docId}\t#{pmid}\t#{vol}\t#{iss}\t#{jref}\t#{newJref}"
        end
      else
        unkPmids << [ pmid, docId ]
        summOutFile.puts "UNKNOWN PMID\t#{docId}\t#{pmid}\t#{vol}\t#{iss}\t#{jref}\t"
      end
    else
      summOutFile.puts "BAD PMID\t#{docId}\t#{pmid}\t#{vol}\t#{iss}\t#{jref}\t"
    end

    totCnt += 1
  }
  $stderr.puts ''
  summOutFile.close
else
  $stderr.debugPuts(__FILE__, __method__, 'ERROR', "ApiCaller#get failed. Response class: #{hr.inspect} ; response payload:\n\n#{docApiCaller.respBody rescue '<<NONE>>'}")
end

if( !unkPmids.empty? )
  $stderr.debugPuts(__FILE__, __method__, 'STATUS', "The following PMIDs not valid at NCBI Pubmed were skipped:\n#{unkPmids.reduce('') { |ss, xx| ss << "#{xx[0]} (Reference Doc Id #{xx[1]})\n" ; ss } }\n\n")
end
if( !failedDocs.empty? )
  $stderr.debugPuts(__FILE__, __method__, 'STATUS', "Updating the content for these Reference documents failed (see the .log output file and stderr):\n#{failedDocs.reduce('') { |ss, xx| ss << "#{xx}\n" ; ss } }\n\n")
end
$stderr.debugPuts(__FILE__, __method__, 'STATUS', "<<DONE>> - updated #{okCnt} PMID Reference docs out of #{totCnt} PMID Reference docs found.")
exit 0
