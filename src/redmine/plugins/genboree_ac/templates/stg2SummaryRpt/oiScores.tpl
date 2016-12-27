<div class="data row">
  <div class="oiPair scrData text-left col-xs-4"><%= "#{opt(:outcomeVal)} / #{pv('Intervention')}" %></div>
  <div class="severity scrData text-left col-xs-1"><%= opt(:outcomeSev) %></div>
  <div class="likelihood scrData text-left col-xs-2"><%= opt(:outcomeLik) %></div>
  <div class="severity scrData text-left col-xs-2"><%= ( e?('Intervention.Effectiveness') ? pv('Intervention.Effectiveness') : opt(:noContentMsg) ) %></div>
  <div class="noi scrData text-left col-xs-2"><%= ( e?('Intervention.Nature Of Intervention') ? pv('Intervention.Nature Of Intervention') : opt(:noContentMsg) ) %></div>
  <div class="totalScore scrData text-left col-xs-1"><%= ( e?('Intervention.Overall Score') ? pv('Intervention.Overall Score') : opt(:noContentMsg) ) %></div>
</div>
