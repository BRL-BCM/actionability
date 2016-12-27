<%
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "In :allContentsAndRefs template. Have:\n    :contentSubProp => #{opt(:contentSubProp).inspect}\n    :noContentMsg => #{opt(:noContentMsg).inspect}\n    rt() prop is => #{rt().inspect}\n    num( rt() ) is => #{num( rt() ).inspect}")
%>
<%# Are there any content paragraphs ? %>
<% if( num( rt() ) > 0) %>
  <%
    items = items( rt() )
    len = 0
    items.each { |item|
      itemDoc = BRL::Genboree::KB::KbDoc.new(item)
      content = itemDoc.getPropVal( "#{itemDoc.getRootProp()}.#{opt(:contentSubProp)}" )
      len += content.size
      content = itemDoc.getPropVal( "#{itemDoc.getRootProp()}.Tier" )
      len += 7 if(content =~ /\S/)
    }
    if(len < (opt(:minContentLines) * 115))
      opt(:minContentLines, 2)
    else
      opt(:minContentLines, 1)
    end
  %>
  <%# There are some content paragraphs. Render each. %>
  <%= render_each( rt(), :contentAndRefs ) %>
<% else %>
  <%# There are no content paragraphs. Render empty content "row" %>
  <div class="contentAndRefs row">
    <%# Content column %>
    <div class="narrative text-left col-xs-11">
      <span class="missing paragraph">
        <%= (opt(:noContentMsg) or '&nbsp;') %>
      </span>
      <% if( (opt(:noContentMsg)).size < 115 ) %>
        <% (opt(:minContentLines) - 1).times { |ii| %>
          <br>&nbsp;
        <% } %>
      <% end %>
    </div>
    <%# Refs column %>
    <div class="refs text-left col-xs-1">&nbsp;</div>
  </div>
<% end %>
