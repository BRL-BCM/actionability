require 'json'
require 'escape_utils'
require 'uri_template'

# Helper module for Actionability related apps

module GenboreeAcHelper
      
  module LitSearchHelper
    
    LIT_SEARCH_SOURCE_HASH = {
      "OMIM" => {
        'displayText'       => "entry title",
        'hitsText'          => "Number of guidelines identified in entry",
        'siteUrl'           => 'http://omim.org/',
        'searchUriTemplate' => 'http://omim.org/search?index=entry&sort=score+desc%2C+prefix_sort+desc&start=1&limit=10&search={searchString}'
       },
      "GeneReview" => {
        "displayText"       => "entry title",
        'hitsText'          => "Number of guidelines identified in entry",
        'siteUrl'           => 'http://www.ncbi.nlm.nih.gov/books/NBK1116/',
        'searchUriTemplate' => 'http://www.ncbi.nlm.nih.gov/books/NBK1116/?term={searchString}'
      },
      "Orphanet" => {
        "displayText"       => "entry title",
        'hitsText'          => "Number of guidelines identified in entry",
        'siteUrl'           => 'http://www.orpha.net/consor/cgi-bin/index.php',
        'searchUriTemplate' => 'http://www.orpha.net/consor/cgi-bin/Disease_Search_Simple.php?lng=EN&diseaseGroup={searchString}'
      },
      "Clinical Utility Gene Card" => {
        "displayText"       => "search term",
        'hitsText'          => "Number of guidelines identified in entry",
        'siteUrl'           => 'http://www.nature.com/ejhg/archive/categ_genecard_012015.html',
        'searchUriTemplate' => 'http://www.nature.com/search?journal=ejhg&q={searchString}&q_match=all&sp-a=sp1001702d&sp-m=0&sp-p-1=phrase&sp-sfvl-field=subject%7Cujournal&sp-x-1=ujournal&submit=go'
      },
      "HuGE" => {
        "displayText"       => "search term",
        'hitsText'          => "Number of hits",
        'siteUrl'           => 'https://phgkb.cdc.gov/HuGENavigator/startPagePubLit.do',
        'searchUriTemplate' => 'https://phgkb.cdc.gov/HuGENavigator/searchSummary.do?firstQuery={searchString}&action=search&Mysubmit=Search'
      },
      "National Guideline Clearinghouse" => {
        "displayText"       => "search term",
        'hitsText'          => "Number of hits",
        'siteUrl'           => 'http://www.guideline.gov/',
        'searchUriTemplate' => 'http://www.guideline.gov/search/search.aspx?term={searchString}'
      },
      "PUBMED" => {
        "displayText"       => "search term",
        'hitsText'          => "Number of hits",
        'siteUrl'           => 'http://ncbi.nlm.nih.gov/pubmed/',
        'searchUriTemplate' => "http://www.ncbi.nlm.nih.gov/pubmed/?term={searchString}"
      },
      "MedGen" => {
        "displayText"       => "search term",
        'hitsText'          => "Number of hits",
        'siteUrl'           => 'http://www.ncbi.nlm.nih.gov/medgen/',
        'searchUriTemplate' => 'http://www.ncbi.nlm.nih.gov/medgen/?term={searchString}'
      },
      "Other" => {
        "displayText" => "search term",
        'hitsText'          => "Number of hits",
        'siteUrl'     => nil
      }
    }
    
    def getLitSearchSourceHash()
      return LIT_SEARCH_SOURCE_HASH
    end
    
    def getLitSearchSourceHashJSON()
      return JSON.generate(LIT_SEARCH_SOURCE_HASH)      
    end

    def searchConfBySource(source)
      return LIT_SEARCH_SOURCE_HASH[source.to_s]
    end

    def fillUrlTemplateForSource(source, params={})
      retVal = nil
      conf = searchConfBySource(source)
      if(conf and conf['searchUriTemplate'].is_a?(String) and params.is_a?(Hash))
        begin
          uriTemplate = URITemplate.new(conf['searchUriTemplate'])
          retVal = uriTemplate.expand(params)
        rescue => err
          $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Error trying to compose full url.\n  Error Class: #{err.class}\n  Error Message: #{err.message}\n  Error Trace:\n#{err.backtrace.join("\n")}")
        end
      end
      return retVal
    end
  end
end