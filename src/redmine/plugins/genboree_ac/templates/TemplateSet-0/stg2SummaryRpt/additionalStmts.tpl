<%
  content = tier = nil
  estStmtsSize = opt(:additionalStmtsSize) or 0
  refsPath = "#{rt()}.References"
%>
<%# Is this an Additional Statements item or an Additional Tiered Statements item? %>
<% if( e?('NoteID') ) %>
  <%# This is an Addtional Statements item %>
  <% content = pv('NoteID.Note') %>
<% elsif( e?('RecommendationID') ) %>
  <%# This is an Addtional Tiered Statements item %>
  <% content = pv('RecommendationID.Recommendation') %>
  <% tier = pv('RecommendationID.Tier') %>
<% else %>
  <%# ERROR, unexpected kind of item %>
  <% $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Unexpected item doc given to :additionalStmts template:\n\n#{JSON.pretty_generate(@__kbDoc) rescue "<Can't render @__kbDoc as JSON!>"}\n\n") %>
<% end %>

<%# $stderr.debugPuts(__FILE__, __method__, 'DEBUG TEMPLATE', "Text content:\n\n#{content.inspect}\n\n") %>
<% if( content.to_s =~ /\S/ or ( tier and tier.to_s !~ /Not provided/i ) ) %>
  <%# Begin stmt row and add content %>
  <div class="addtional contentAndRefs row">
    <%# Content column %>
    <div class="<%= pn(rt(), :idSafe=>true) %> narrative addtional text-left col-xs-11">
      <% if( content.to_s =~ /\S/ ) %> <%# else skip %>
        <span class="paragraph"><%= content %>
          <%# Add tier if available %>
          <% if( tier and tier.to_s !~ /Not provided/i ) %>
              <span class="tierText">(Tier <%= tier %>)</span>
          <% end %>
        </span>
      <% end %>
    </div>
    <%# Refs column %>
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
