<%
  li = ( opt(:context) ? ( opt(:context)[:lineIndent] or '') : '' )
  indentL2Opts= { :context => { :lineIndent => "#{li}#{' '*4}"}}
%>
<%= li %>{
<%= li %>  "Intervention" : "<%= pv( 'Intervention' ) %>",
<%= li %>  "Effectiveness" : "<%= pv( 'Intervention.Effectiveness' ) %>",
<%= li %>  "Nature of Intervention" : "<%= pv( 'Intervention.Nature Of Intervention' ) %>",
<%= li %>  "Total" : "<%= pv( 'Intervention.Overall Score' ) %>"
<%= li %>}