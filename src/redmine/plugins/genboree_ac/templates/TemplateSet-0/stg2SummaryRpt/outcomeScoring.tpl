<%
  opt(:outcomeVal, pv('Outcome'))
  opt(:outcomeSev, ( e?('Outcome.Severity') ? pv('Outcome.Severity') : opt(:noContentMsg) ) )
  opt(:outcomeLik, ( e?('Outcome.Likelihood') ? pv('Outcome.Likelihood') : opt(:noContentMsg) ) )

  # Accumulate all footnotes
  footnotes = opt(:footnotes)
  # This outcome footnotes
  #outcomeFootnotes = []
  outcomeSevNote = outcomeLikNote = nil
  if( e?('Outcome.Severity.Notes') )
    footnote = pvh('Outcome.Severity.Notes')
    footnotes << footnote
    #outcomeFootnotes << footnote
    outcomeSevNote =  footnotes.size
  end
  if( e?('Outcome.Likelihood.Notes') )
    footnote = pvh('Outcome.Likelihood.Notes')
    footnotes << footnote
    #outcomeFootnotes << footnote
    outcomeLikNote = footnotes.size
  end
%>
<%# Because of table layour here, we need to pass the OUTCOME-level footnotes (if any) from Severity & Likelihood to template that renders O/I row %>
<%= render_each( 'Outcome.Interventions', :oiScores, '', { :footnotes => footnotes, :outcomeSevNote => outcomeSevNote, :outcomeLikNote => outcomeLikNote } ) %>
