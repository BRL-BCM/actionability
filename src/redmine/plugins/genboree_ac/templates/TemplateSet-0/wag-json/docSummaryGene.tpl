<%
  hgncId = pv( 'Gene.HGNCId' )
  wagGeneUri = hgncId.sub(/:/, '')
  li = ( opt(:context) ? ( opt(:context)[:lineIndent] or '') : '' )
%>
<%= li %>{
<%= li %>  "symbol" : "<%= pv( 'Gene' ) %>",
<%= li %>  "ontology" : "HGNC",
<%= li %>  "curie" : "<%= hgncId %>",
<%= li %>  "uri" : "<%= wagGeneUri %>"
<%= li %>}