<%
  # @todo Make 'iri' using request protocol and host, and path to "real" doc API JSON content
  iri = 'XXXX'
  # @todo Make title from Syndrome and Genes.Gene
  #$stderr.puts "STARTING docSummaryBase"
  opt(:context, {}) unless( opt(:context) )
  context = opt(:context)
  indentL1Opts = { :context => { :lineIndent => ( ' ' * 4 ) } }
  # Build the various links to this page using page url.
  requestUrl = context[:requestUrl]
  # - build iri
  releaseKbRsrcPath = context[:releaseKbRsrcPath].to_s.chomp('/')
  docColl = context[:actionabilityColl]
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "requestUrl: #{requestUrl.inspect} ; releaseKbRsrcPath: #{releaseKbRsrcPath.inspect} ; docColl: #{docColl.inspect} ; root prop: #{rt().inspect} ; doc ID: #{pv(rt()).inspect}")
  docId = pv( rt() )
  requestUri = URI.parse(requestUrl)
  iri = "http://__GENBOREE_actionabilityFQDN__#{releaseKbRsrcPath}/coll/#{docColl}/doc/#{docId}"
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "iri: #{iri.inspect}")
  # - build url for stg2 doc
  releaseRptBase = context[:releaseRptBase].to_s.chomp('/')
  stg2Url = "http://__GENBOREE_actionabilityFQDN__#{releaseRptBase}/ui/stg2SummaryRpt?doc=#{docId}"
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "stg2Url: #{stg2Url.inspect}")
%>

{
<%= subRender( rt() , :docSummaryStatic ) %>
  "iri" : "<%= iri %>",
  "curationVersion" : "<%= pv( 'ActionabilityDocID.Release' ) %>",
  "title" : "<%= pv( ' ActionabilityDocID.Syndrome') %> - <%= render_each( 'ActionabilityDocID.Genes', %q^<!%= pv('Gene') %!>^, ', ' ) %>",
  "statusFlag" : "<%= pv( 'ActionabilityDocID.Status') %>",
  "dateISO8601" : "<%= ( Time.parse( pv( 'ActionabilityDocID.Release.Date' ) ) rescue Time.at(0) ).iso8601 %>",
  "scoreDetails" : "<%= stg2Url %>",
  "genes" : [
    <%= render_each( 'ActionabilityDocID.Genes', :docSummaryGene, ",\n", ( @__opts.deep_merge( indentL1Opts ) ) ) %>
  ],
  "conditions" : [
    <%= render_each( 'ActionabilityDocID.Syndrome.OmimIDs', :docSummaryOmim, ",\n", ( @__opts.deep_merge( indentL1Opts ) ) ) %>
  ],
  "scores" : [
    <%= render_each( 'ActionabilityDocID.Score.Final Scores.Outcomes', :docSummaryScoresOutcome, ",\n", ( @__opts.deep_merge( indentL1Opts ) ) ) %>
  ]
}

<%
  #$stderr.puts "  DONE docSummaryBase"
%>
