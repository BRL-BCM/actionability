<%
  # $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "In :allContentsAndRefs template. Have:\n    :contentSubProp => #{opt(:contentSubProp).inspect}\n    :noContentMsg => #{opt(:noContentMsg).inspect}\n    rt() prop is => #{rt().inspect}\n    num( rt() ) is => #{num( rt() ).inspect}")
  refsPath = "#{rt()}.References"
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
  %>
  <%# There are some content paragraphs. Render each. %>
  <%= render_each( rt(), :contentAndRefs ) %>
  <%# Render empty contentAndRefs rows to handle minContentLines %>
  <%
    contentLines = ( len / 115 ).to_i
    numBlankLines = ( opt(:minContentLines).to_i - contentLines - 1 )
    if( numBlankLines > 0 )
      numBlankLines.times { |ii|
  %>
        <div class="contentAndRefs row">
          <div class="narrative text-left col-xs-11">&nbsp;</div>
        </div>
  <%
      }
    end
  %>
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
