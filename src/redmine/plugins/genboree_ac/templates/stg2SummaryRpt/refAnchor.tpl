<%# For use when can't inline. For example, when doing all References within item list docs %>
<% if( num("#{rt()}.References") > 0) %>
  <%= render_each(
    "#{rt()}.References",
    %q^<span><a href="#ref<!%= pv('Reference') %!>"><!%= pv('Reference') %!></a></span>^,
    ',' ) %>,
<% end %>