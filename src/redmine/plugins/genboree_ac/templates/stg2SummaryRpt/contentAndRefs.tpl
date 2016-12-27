<%#
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "In :contentAndRefs template. Have:\n    :contentSubProp => #{opt(:contentSubProp).inspect}\n    :noContentMsg => #{opt(:noContentMsg).inspect}\n    rt() prop is => #{rt().inspect}\n    num( rt().References ) is => #{num( "#{rt()}.References").inspect}")
%>
<%
  tierPath = "#{rt()}.Tier"
  notesPath = "#{rt()}.Notes"
  refsPath = "#{rt()}.References"
  contentPath = "#{rt()}.#{opt(:contentSubProp)}"
  contentPath = '' if(contentPath == notesPath)
  #contentLabel = "#{opt(:contentSubPropLabel)} " if( opt(:contentSubPropLabel).to_s =~ /\S/ )
  numBlankLines = opt(:minContentLines) - 1
%>
<%# Each content paragraph + reference is a "row". %>
<% if( e?(contentPath) or e?(notesPath) ) %>
  <div class="contentAndRefs row">
    <%# Content column %>
    <div class="<%= pn(rt(), :idSafe=>true) %> narrative text-left col-xs-11">
      <%# $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "Text content:\n\n#{pv(contentPath).inspect}\n\n") %>
      <span class="paragraph"><%# = contentLabel %><%= pv(contentPath) %>
        <% if( e?(notesPath) ) %>
          <div class="pgap">&nbsp;</div>
          <%= pv(notesPath) %>
      <% end %>
        <%# IFF the root prop has a Tier subprop, display it or message if missing, else no Tier subprop in model so skip %>
        <% if( propDef(tierPath) ) %>
          <% if( e?(tierPath) and pv(tierPath) !~ /Not provided/i ) %>
            <span class="tierText">(Tier <%= pv(tierPath) %>)</span>
          <% end %>
        <% end %>
      </span>
      <% if( ( pv(contentPath).to_s.size + pv(notesPath).to_s.size + (propDef(tierPath) ? 7 : 0) ) < 115 ) %>
        <% numBlankLines.times { |ii| %>
          <br>&nbsp;
        <% } %>
      <% end %>
    </div>
    <%# Refs column %>
    <div class="refs text-left col-xs-1">
      <span class="paragraph">
        <% if( propDef(refsPath) and num(refsPath) > 0) %>
            (<%= render_each(
                   refsPath,
                   %q^<span><a href="#ref_%<!%= pv('Reference') %!>%">ref_displ_%<!%= pv('Reference') %!>%</a></span>^,
                   ',' )
            %>)
        <% else %>
          &nbsp;
        <% end %>
      </span>
    </div>
  </div>
<% end %>
