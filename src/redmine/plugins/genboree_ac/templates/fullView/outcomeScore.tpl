  <div class="outcome row">
    <div class="outcome col text-left col-xs-2">
      <%= pv('Outcome') %>
    </div>
    <div class="interventions col col-xs-10">
      <%# Outcome scores row first %>
      <div class="intervention wrapper row">
        <div class="intervention col text-left col-xs-3">&nbsp;</div>
        <div class="severity col text-center col-xs-2"><%= pv('Outcome.Severity') %></div>
        <div class="likelihood col text-center col-xs-2"><%= pv('Outcome.Likelihood') %></div>
        <div class="effectiveness col text-center col-xs-2">&nbsp;</div>
        <div class="noi col text-center col-xs-2">&nbsp;</div>
        <div class="overall col text-center col-xs-1">&nbsp;</div>
      </div>
      <%# Now rows for each intervention %>
      <%= @__producer.render_each( "Outcome.Interventions", :interventionScore ) %>
    </div>
  </div>

