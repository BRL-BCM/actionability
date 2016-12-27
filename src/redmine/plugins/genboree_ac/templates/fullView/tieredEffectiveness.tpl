<%
  rootProp = @__producer.kbDoc.getRootProp() # used for several sections like Patient Management, Surveillance, etc.
  varBase = "@#{rootProp.variableize}" # thus we'll get the instance variable by name (yay reflection)
  contentLabel = rootProp.split(/\s+/).first
  contentLabel = {
    "Patient" => "Management",
    "Family" => "Management",
    "Surveillance" => "Surveillance",
    "Circumstance" => "Circumstance"
  }[contentLabel]
  outcomes = @__producer.kbDoc.getPropItems("#{rootProp}.Outcomes")
%>
<div class="tiered content">
  <div class="value keytext itemLabel"><%= instance_variable_get("#{varBase}Key_text") %></div>
  <div class="value keytext">
    <% if(instance_variable_get("#{varBase}Recommendation_text")) %>
      <span class="value text"><%= instance_variable_get("#{varBase}Recommendation_text") %></span>
    <% end %>
    <% if(instance_variable_get("#{varBase}Tier")) %>
      <span class="tier">(<span class="name">Tier:</span> <span class="value tier"><%= instance_variable_get("#{varBase}Tier") %></span>)</span>
    <% end %>
    <% if(@__kbDoc.getPropItems("#{rootProp}.References")) %>
      <span class="refs inline sup">
        [<%= @__producer.render_each(
          "#{rootProp}.References",
          %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
          ', ' ) %>]
      </span>
    <% end %>
  </div>
  <div class="attrs">
    <% if(outcomes and outcomes.size > 0) %>
      <div class="attr"><span class="name">Outcomes:</span>
        <ul class="values list"><%= @__producer.render_each( "#{rootProp}.Outcomes", :outcomeNameListItem) %></ul>
      </div>
    <% end %>
  </div>
</div>
