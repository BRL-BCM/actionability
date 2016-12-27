<%
  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "LIT_SOURCE: #{@source.inspect}")
  # Need to ensure we're passing forward some key info when rendering search string:
  @__opts[:context] = {} unless(@__opts[:context])
  @__opts[:context][:source] = @source
%>
<tr class="subHeader"><td class="hdr" colspan="4"><%= @source %></td></tr>
<%= @__producer.render_each( "Source.SearchStrings", :sourceSearch ) %>
