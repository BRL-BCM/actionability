<%
  li = ( opt(:context) ? ( opt(:context)[:lineIndent] or '') : '' )
  indentL2Opts= { :context => { :lineIndent => "#{li}#{' '*4}"}}
%>
<%= li %>{
<%= li %>  "Outcome" : "<%= pv( 'Outcome' ) %> ",
<%= li %>  "Severity" : "<%= pv( 'Outcome.Severity' ) %>",
<%= li %>  "Likelihood" : "<%= pv( 'Outcome.Likelihood' ) %>",
<%= li %>  "Interventions" : [
<%= li %>    <%= render_each( 'Outcome.Interventions', :docSummaryScoresInterventions, ",", @__opts.deep_merge( indentL2Opts ) ) %>
<%= li %>  ]
<%= li %>}
