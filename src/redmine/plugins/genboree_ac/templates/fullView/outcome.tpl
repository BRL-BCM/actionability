<div class="row data outcome">
  <div class="cell outcome"><%= @outcome %></div>
  <div class="cell">
    <%= @__producer.render_each(
      "Outcome.Interventions",
      %q^<div class="row data intervention"><div class="cell intervention"><!%= @intervention %!></div></div>^ ) %>
  </div>
</div>

