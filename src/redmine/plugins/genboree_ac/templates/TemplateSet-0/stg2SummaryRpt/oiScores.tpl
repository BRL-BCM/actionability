<%
  # Save any footnotes seen
  footnotes = opt(:footnotes)
%>

<div class="data row">
  <div class="oiPair scrData text-left col-xs-4">
    <%= "#{opt(:outcomeVal)} / #{pv('Intervention')}" %>
  </div>
  <div class="severity scrData text-left col-xs-1">
    <%= opt(:outcomeSev) %>
    <% if( opt(:outcomeSevNote) ) %>
      <span class="footnote inline">
        <%= opt(:outcomeSevNote) %>
      </span>
    <% end %>
  </div>
  <div class="likelihood scrData text-left col-xs-2">
    <%= opt(:outcomeLik) %>
    <% if( opt(:outcomeLikNote) ) %>
      <span class="footnote inline">
        <%= opt(:outcomeLikNote) %>
      </span>
    <% end %>
  </div>
  <div class="severity scrData text-left col-xs-2">
    <%= ( e?('Intervention.Effectiveness') ? pv('Intervention.Effectiveness') : opt(:noContentMsg) ) %>
    <% if( e?('Intervention.Effectiveness.Notes') ) %>
    <%   footnote = pvh('Intervention.Effectiveness.Notes') %>
    <%   footnotes << footnote %>
        <span class="footnote inline"><%= footnotes.size %></span>
    <% end %>
  </div>
  <div class="noi scrData text-left col-xs-2">
    <%= ( e?('Intervention.Nature Of Intervention') ? pv('Intervention.Nature Of Intervention') : opt(:noContentMsg) ) %>
    <% if( e?('Intervention.Nature Of Intervention.Notes') ) %>
      <%   footnote = pvh('Intervention.Nature Of Intervention.Notes') %>
      <%   footnotes << footnote %>
      <span class="footnote inline"><%= footnotes.size %></span>
    <% end %>
  </div>
  <div class="totalScore scrData text-left col-xs-1">
    <%= ( e?('Intervention.Overall Score') ? pv('Intervention.Overall Score') : opt(:noContentMsg) ) %>
    <% if( e?('Intervention.Overall Score.Notes') ) %>
      <%   footnote = pvh('Intervention.Overall Score.Notes') %>
      <%   footnotes << footnote %>
      <span class="footnote inline"><%= footnotes.size %></span>
    <% end %>
  </div>
</div>
