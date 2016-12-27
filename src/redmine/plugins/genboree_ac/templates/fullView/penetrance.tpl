<% outcomes = @__producer.kbDoc.getPropItems("Penetrance.Outcomes") %>
<div class="tiered">
  <div class="title"><span class="itemLabel">Penetrance:</span> <span class="value"><%= @penetranceKey_text %></span></div>
  <% if(@penetranceNotes) %>
      <span class="value text"><%= @penetranceNotes %></span>
  <% end %>
  <% if(@penetranceTier) %>
      <span class="tier">(<span class="name">Tier:</span> <span class="value tier"><%= @penetranceTier %></span>)</span>
  <% end %>
  <% if(@__kbDoc.getPropItems("Penetrance.References") or !@__opts[:trim]) %>
    <span class="refs inline sup">
      [<%= @__producer.render_each(
             "Penetrance.References",
             %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
             ', ' ) %>]
    </span>
  <% end %>
  <div class="attrs">
    <% if(outcomes and outcomes.size > 0) %>
      <div class="attr"><span class="name">Outcomes:</span>
        <ul class="values list"><%= @__producer.render_each(
          "Penetrance.Outcomes",
          %q^<li><!%= @outcome %!></li>^ ) %>
        </ul>
      </div>
    <% end %>
  </div>
</div>
