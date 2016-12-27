<%
  xx = self.extend(GenboreeAcUiFullViewHelper)
  #$stderr.puts "    - #{@searchstring.inspect} (#{@searchstringNumberofhits.inspect} on #{@searchstringDate.inspect})"
  source = @__opts[:context][:source]
  haveSearchStr = (@searchstring and @searchstring.to_s =~ /\S/)
  if(haveSearchStr)
    if( e?('SearchString.searchURL') )
      url = pv('SearchString.searchURL')
    elsif( source )
      url = fillUrlTemplateForSource( source, { :searchString => @searchstring } )
    else
      url = nil
    end
  else
    url = nil
  end
%>
<tr>
  <td class="search-label">
    <span><%= pv('SearchString.Label') %></span>
  </td>
  <td class="search value"><%= @searchstring %>
    <% if(url) %>
      <a target="_blank" class="externalLink sup fa fa-external-link" href="<%= url %>"></a>
    <% end %>
  </td>
  <td class="hits value"><%= @searchstringNumberofhits %></td>
  <td class="date value"><%= @searchstringDate %></td>
</tr>
