<%#
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "In :specificContentAndRefs template. Have:\n    :contentSubProp => #{opt(:contentSubProp).inspect}\n    :noContentMsg => #{opt(:noContentMsg).inspect}\n    rt() prop is => #{rt().inspect}\n    e?( rt() ) is => #{e?( "#{rt()}.#{opt(:contentSubProp)}").inspect}")
%>
<%
  contentPath = "#{rt()}.#{opt(:contentSubProp)}"
  notesPath = "#{rt()}.Notes"
  #$stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "contentPath: #{contentPath.inspect}  ; e?(contentPath): #{e?(contentPath).inspect}")
%>
<%# Are there any content paragraphs ? %>
<% if( e?(contentPath) or e?(notesPath) ) %>
  <%# There are some content paragraphs. Render each. %>
  <%= subRender( rt(), :contentAndRefs ) %>
<% else %>
  <%# There are no content paragraphs. Render empty content "row" %>
  <div class="contentAndRefs row">
    <%# Content column %>
    <div class="<%= pn(rt(), :idSafe=>true) %> narrative text-left col-xs-11">
      <span class="missing paragraph">
        <%= opt(:noContentMsg) or '&nbsp;' %>
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
