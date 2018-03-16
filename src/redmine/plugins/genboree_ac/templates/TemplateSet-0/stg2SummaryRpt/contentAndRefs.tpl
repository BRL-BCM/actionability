<%#
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "In :contentAndRefs template. Have:\n    :contentSubProp => #{opt(:contentSubProp).inspect}\n    :noContentMsg => #{opt(:noContentMsg).inspect}\n    rt() prop is => #{rt().inspect}\n    num( rt().References ) is => #{num( "#{rt()}.References").inspect}")
%>
<%
  tierPath = "#{rt()}.Tier"
  notesPath = "#{rt()}.Notes"
  refsPath = "#{rt()}.References"
  contentPath = "#{rt()}.#{opt(:contentSubProp)}"
  additionalStmtsPath = "#{rt()}.#{opt(:additionalStmtsSubProp)}"
  contentPath = nil if(contentPath == notesPath)
  #$stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "contentPath: #{contentPath.inspect}  ; e?(contentPath): #{e?(contentPath).inspect rescue 'N/A'} ; rt(): #{rt().inspect rescue 'N/A'}")
  #contentLabel = "#{opt(:contentSubPropLabel)} " if( opt(:contentSubPropLabel).to_s =~ /\S/ )
  numBlankLines = opt(:minContentLines) - 1
  itemIdxCls = ( opt(:itemIdx) ? "itemIdx_#{opt(:itemIdx)}" : '' )
%>

<div class="<%= itemIdxCls %> contentAndRefs row">
  <%# Content column %>
  <div class="<%= pn(rt(), :idSafe=>true) %> narrative text-left col-xs-11">
    <%# Each content paragraph + reference is a "row". %>

    <% if( (contentPath and e?(contentPath)) or e?(notesPath) ) %>
      <%# $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "Text content:\n\n#{pv(contentPath).inspect}\n\n") %>
      <span class="paragraph"><%# = contentLabel %><%= pv(contentPath) if(contentPath) %>
        <% if( e?(notesPath) ) %>
            <% if( contentPath and pv(contentPath) =~ /\S/ ) %>
                <div class="pgap">&nbsp;</div>
            <% end %>
          <%= pv(notesPath) %>
        <% end %>
        <%# IFF the root prop has a Tier subprop, display it or message if missing, else no Tier subprop in model so skip %>
        <% if( propDef(tierPath) ) %>
            <% if( e?(tierPath) and pv(tierPath) !~ /Not provided/i ) %>
              <span class="tierText">(Tier <%= pv(tierPath) %>)</span>
            <% end %>
        <% end %>
      </span>
    <% else %>
      <%# Have neither content nor notes to display, so render empty content message %>
      <span class="missing paragraph">
        <%= opt(:noContentMsg) or '&nbsp;' %>
      </span>
      <% if( (opt(:noContentMsg)).size < 115 ) %>
        <% (opt(:minContentLines) - 1).times { |ii| %>
          <br>&nbsp;
        <% } %>
      <% end %>
    <% end %>
  </div>

  <%# NEW: No matter whether there is content or not, render Refs column with any refs user added %>
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

<%# IFF there are additional statements, render them too as rows %>
<%# $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "root prop: #{rt().inspect} ; num additional stmts: #{num(additionalStmtsPath).inspect}") %>
<% if( num(additionalStmtsPath) > 0 ) %>
  <%= render_each(additionalStmtsPath, :additionalStmts ) %>
<% end %>
