<%# For use when can't inline. For example, when doing all References within item list docs %>
<% if( num("#{rt()}.References") > 0) %>
  <%= render_each(
    "#{rt()}.References",
    %q^<span class="ref link" data-ac-ref-id="ref_%<!%= pv('Reference') %!>%"><a href="javascript:;" onclick="document.location.hash='ref_%<!%= pv('Reference') %!>%'"><!%= pv('Reference') %!></a></span>^,
    ',' ) %>,
<% end %>