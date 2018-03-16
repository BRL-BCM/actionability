<%#
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "In :specificContentAndRefs template. Have:\n    :contentSubProp => #{opt(:contentSubProp).inspect}\n    :noContentMsg => #{opt(:noContentMsg).inspect}\n    rt() prop is => #{rt().inspect}\n    e?( rt() ) is => #{e?( "#{rt()}.#{opt(:contentSubProp)}").inspect}")
%>
<%
  # @todo REMOVE THIS FILE - should not be needed anymore, contentAndRefs.tpl handles what it did (but check calling code carefully)
  contentPath = "#{rt()}.#{opt(:contentSubProp)}"
  notesPath = "#{rt()}.Notes"
  refsPath = "#{rt()}.References"
  #$stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "contentPath: #{contentPath.inspect}  ; e?(contentPath): #{e?(contentPath).inspect rescue 'N/A'} ; rt(): #{rt().inspect rescue 'N/A'}")
  len = ( pv(contentPath).size + pv(notesPath).size )
%>
<%# Are there any content paragraphs ? %>
<% if( e?(contentPath) or e?(notesPath) ) %>
  <%# There are some content paragraphs. Render each. %>
  <%= subRender( rt(), :contentAndRefs ) %>
  <%# Render empty contentAndRefs rows to handle minContentLines %>
  <%
    contentLines = ( len / 115 ).to_i
    numBlankLines = ( opt(:minContentLines).to_i - contentLines -1 )
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
    <%# OLD (forced to no-refs): div class="refs text-left col-xs-1">&nbsp;</div> %>
    <%# NEW (try to render refs despite no content) %>
    <div class="refs text-left col-xs-1">
      <span class="paragraph">
        <% if( propDef(refsPath) and num(refsPath) > 0) %>
            <%= render_each(
                  refsPath,
                  %q^<span class="ref link" data-ac-ref-id="ref_%<!%= pv('Reference') %!>%"><a href="javascript:;" onclick="document.location.hash='ref_%<!%= pv('Reference') %!>%'">ref_displ_%<!%= pv('Reference') %!>%</a></span>^,
                  '')
            %>
        <% else %>
          &nbsp;
        <% end %>
      </span>
    </div>
  </div>
<% end %>
