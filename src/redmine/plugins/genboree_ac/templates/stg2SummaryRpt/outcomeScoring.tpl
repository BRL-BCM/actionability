<%
  opt(:outcomeVal, pv('Outcome'))
  opt(:outcomeSev, ( e?('Outcome.Severity') ? pv('Outcome.Severity') : opt(:noContentMsg) ) )
  opt(:outcomeLik, ( e?('Outcome.Likelihood') ? pv('Outcome.Likelihood') : opt(:noContentMsg) ) )
%>
<%= render_each( 'Outcome.Interventions', :oiScores ) %>
