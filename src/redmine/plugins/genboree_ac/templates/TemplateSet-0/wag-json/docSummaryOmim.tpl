<%
  omimId = pv( 'OmimID' )
  li = ( opt(:context) ? ( opt(:context)[:lineIndent] or '') : '' )
%>
<%= li %>{
<%= li %>  "ontology" : "OMIM",
<%= li %>  "curie" : "OMIM:<%= omimId %>",
<%= li %>  "uri" : "OMIM<%= omimId %>",
<%= li %>  "iri" : "http://purl.obolibrary.org/obo/OMIM_<%= omimId %>"
<%= li %>}