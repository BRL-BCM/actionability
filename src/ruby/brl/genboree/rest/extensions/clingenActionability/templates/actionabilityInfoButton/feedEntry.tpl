<%
  require 'cgi'
  entryTitle = pv( 'ActionabilityDocID.Syndrome' ) + ' - '
  entryTitle += render_each(
      'ActionabilityDocID.Genes',
      %q^<!%= pv( 'Gene' ) %!>^,
      ',',
      { :supressNewlineAfterItem => true })
%>

  <entry xml:lang="en">
    <title type="text"><%= entryTitle %></title>
    <link href="ui/fullview?doc=<%= pv( 'ActionabilityDocID' ) %>" rel="alternate" type="html" hreflang="en" title="<%= entryTitle %>"/>
    <id><%= pv('ActionabilityDocID') %></id>
    <updated><%= opt(:docModTimes)[pv(rt())].utc.iso8601 %></updated>
    <summary type="html"><%= CGI.escapeHTML( subRender( 'ActionabilityDocID', :entrySummary ).strip ) %></summary>
    <category scheme="mainSearchCriteria.v.c" term="<%= opt( :feedCategoryTermC ) %>"/>
    <category scheme="mainSearchCriteria.v.cs" term="<%= opt( :feedCategoryTermCS ) %>"/>
  </entry>
