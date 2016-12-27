<%
  require 'time'

  if(@referenceCategory == 'PMID')
    #matchIdx = ( @referencePmidCitation =~ /^([^,]+(?:,[^,]+)*)\.\s+(.+)\.\s+([^\.]+)\.\s+(\S+)(?:\s+[^;]+)?;([^:\.]+)(?:\s*:\s*([^\.]+))?/ )
    matchIdx = ( @referencePmidCitation =~ /^([^,]+(?:,[^,]+)*)\.\s+(.+)\.\s+([^\.]+)\.\s+([^\s;\.]+)(?:(\s+[^;]+)?;([^:\.]+)(?:\s*:\s*([^\.]+))?)?/ )
    if(matchIdx)
      #$stderr.puts "    1st - #{$~.captures.inspect}\n\n"
      authors, title, journal, year, date, volIssue, pages = $~.captures
    elsif(matchIdx = ( @referencePmidCitation =~ /^([^,]+(?:,[^,]+)*)\.\s+(.+)\.\s+([^\.]+)\.\s+(\S+)\s+([^;]+)/ ) )
      #$stderr.puts "    2nd - #{$~.captures.inspect}\n\n"
      authors, title, journal, year, date, volIssue, pages = $~.captures
    elsif(matchIdx = ( @referencePmidCitation =~ /^(.+)\.\s+([^\.]+)\.\s+([^\s;\.]+)(?:(?:\s+[^;]+)?;([^:\.]+)(?:\s*:\s*([^\.]+))?)?/ ) )
      #$stderr.puts "    3rd - #{$~.captures.inspect}\n\n"
      title, journal, year, date, volIssue, pages = $~.captures
    else
      #$stderr.puts "    NONE!"
      matchIdx = nil
    end

    if(matchIdx)
%>
      <div id="ref_%<%= @reference %>%" class="ref section pmid <%= @reference %> row">
        <span class="refNum text-right col-xs-1">
          <span class="idx"><%= @__opts[:count] %>.</span>
        </span>
        <span class="citation col-xs-11">
          <% if(authors) then %><span class="authors"><%= authors %></span>.<% end %>
          <span class="title"><%= title.capitalize %>.</span>
          <span class="journal"><%= journal %></span>.
          <% if(year) then %> <span class="year">(<span class="value"><%= year %></span>)</span><% end %>
          <% if(volIssue) then %> <span class="volIssue"><span class="value"><%= volIssue %></span>:</span><% end %>
          <% if(pages) then %> <span class="pages"><%= pages %></span>. <% end %>
          <a class="link fa fa-external-link" target="_blank" href="http://www.ncbi.nlm.nih.gov/pubmed/?term=<%= @referencePmid %>"></a>
        </span>
      </div>
<%  else %>
      <%# Broken, but best effort render if we can %>
      <%
        if( e?('Reference.PMID.Citation') )
          citation = pv('Reference.PMID.Citation')
          pubDate = pv('Reference.PMID.Publication Date')
          if( pubDate.to_s =~ /\S/ and citation !~ /#{pubDate}/)
            citation << " <span class=\"year\">(<span class=\"value\">#{pubDate}</span>)</span>"
          end
      %>
        <div id="ref_%<%= @reference %>%" class="ref section pmid broken <%= @reference %> row">
          <span class="refNum text-right col-xs-1">
            <span class="idx"><%= @__opts[:count] %>.</span>
          </span>
          <% $stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>>>>>>>> BROKEN PubMed DOC:\n\n#{JSON.pretty_generate(@__kbDoc)}\n\n") %>
          <span class="citation broken col-xs-11">
            <%= citation %>
            <a class="link fa fa-external-link" target="_blank" href="http://www.ncbi.nlm.nih.gov/pubmed/?term=<%= @referencePmid %>"></a>
          </span>
        </div>
      <% end %>
<%  end %>
<% elsif(@referenceCategory == 'OMIM') %>
    <%
      if( e?('Reference.OMIM.Date Updated') )
        dateUpdated = Time.parse( pv('Reference.OMIM.Date Updated') ) rescue nil
        if(dateUpdated)
          dateUpdated = dateUpdated.strftime('%Y %b %d') rescue nil
        end
      else
        dateUpdated = nil
      end
    %>
    <div id="ref_%<%= @reference %>%" class="ref section omim <%= @reference %> row">
      <span class="refNum text-right col-xs-1">
        <span class="idx"><%= @__opts[:count] %>.</span>
      </span>
      <span class="citation col-xs-11">
        <span class="journal">Online Medelian Inheritance in Man, OMIM<span class="sup">&reg;</span>.</span> <span class="static">Johns Hopkins University, Baltimore, MD. MIM:</span>
          <span class="articleId"><a target="_blank" href="http://www.omim.org/entry/<%= pv('Reference.OMIM') %>"><%= pv('Reference.OMIM') %></a><%= dateUpdated ? ':' : '.' %></span>
        <% if( dateUpdated ) then %><%= dateUpdated %>. <% end %>
          World Wide Web URL: <a href="http://omim.org">http://omim.org</a>.
        <a class="link fa fa-external-link" target="_blank" href="http://www.omim.org/entry/<%= pv('Reference.OMIM') %>"></a>
      </span>
    </div>
<% elsif(@referenceCategory == 'GeneReview') %>
    <%
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>>>>>>>> GENE REVIEW DOC:\n\n#{JSON.pretty_generate(@__kbDoc)}\n\n")
      haveRevDate = e?('Reference.GeneReview.Revision Date')
      if( e?('Reference.GeneReview.Book Editors') )
        haveBookEds = true
        edsVal = pv('Reference.GeneReview.Book Editors')
        edsVal =~ /((?:[^,]+,\s*){0,2})([^,]+)/
        md = $~
        someEds, lastAppearingEd = $1.to_s.strip, $2.to_s.strip
        edsStr = (someEds =~ /\S/ ? "#{someEds} #{lastAppearingEd}" : lastAppearingEd)
        edsStr << ', et al.' if(md.post_match.to_s =~ /\S/)
      end
      availFromUrl = "http://www.ncbi.nlm.nih.gov/books/#{pv('Reference.GeneReview')}"
    %>
    <div id="ref_%<%= @reference %>%" class="ref section geneReview <%= @reference %> row">
      <span class="refNum text-right col-xs-1">
        <span class="idx"><%= @__opts[:count] %>.</span>
      </span>
      <span class="citation col-xs-11">
        <% if( e?('Reference.GeneReview.Authors') ) then %> <span class="authors"> <span class="value"><%= pv('Reference.GeneReview.Authors')%></span>.</span> <% end %>
        <% if( e?('Reference.GeneReview.Title') ) then %> <span class="title"><%= pv('Reference.GeneReview.Title').capitalize %></span>. <% end %>
        <% if( e?('Reference.GeneReview.Contribution Date') ) then %> <span class="date"><%= Time.parse( pv('Reference.GeneReview.Contribution Date') ).strftime('%Y %b %d') %></span><%= '.' unless(haveRevDate) %> <% end %>
        <% if( e?('Reference.GeneReview.Revision Date') ) then %> <span class="date">[Updated <%= Time.parse( pv('Reference.GeneReview.Revision Date') ).strftime('%Y %b %d') %></span>]. <% end %>
        <% if( haveBookEds ) then %> In: <%= edsStr %>, editors. <% end %>
        <span class="journal">GeneReviews<span class="sup">&reg;</span></span><span class="static"> [Internet]. Seattle (WA): University of Washington, Seattle; 1993-<%= Time.now.year %>.</span>
        Available from: <a target="_blank" href="<%= availFromUrl %>"><%= availFromUrl %></a>
        <a class="link fa fa-external-link" target="_blank" href="<%= availFromUrl %>"></a>
      </span>
    </div>
<% elsif( pv('Reference.Category') == 'Orphanet' ) %>
    <div id="ref_%<%= @reference %>%" class="ref section orphanet <%= @reference %> row">
      <span class="refNum text-right col-xs-1">
        <span class="idx"><%= @__opts[:count] %>.</span>
      </span>
      <span class="citation col-xs-11">
        <% if( e?('Reference.Orphanet.Name') ) then %> <span class="title"><%= pv('Reference.Orphanet.Name') %></span>. <% end %>
        <span class="journal">Orphanet encyclopedia</span><%= ',' if(e?('Reference.Orphanet.Url-Page')) %>
        <!-- [missing] span class="date">{Date last edited etc} span -->
        <% if( e?('Reference.Orphanet.Url-Page') ) %>
          <a target="_blank" href="<%= pv('Reference.Orphanet.Url-Page') %>"><%= pv('Reference.Orphanet.Url-Page') %></a>
          <a class="link fa fa-external-link" target="_blank" href="<%= pv('Reference.Orphanet.Url-Page') %>"></a>
        <% end %>
      </span>
    </div>
<% else %>
    <div id="ref_%<%= @reference %>%" class="ref section other <%= @reference %> row">
      <span class="refNum text-right col-xs-1">
        <span class="idx"><%= @__opts[:count] %>.</span>
      </span>
      <span class="citation col-xs-11">
        <% if( e?('Reference.Other Reference.Authors') ) then %> <span class="authors"><span class="value"><%= pv('Reference.Other Reference.Authors') %></span></span>. <% end %>
        <% if( e?('Reference.Other Reference.Article Title') ) then %> <span class="title"><%= pv('Reference.Other Reference.Article Title').capitalize %></span>. <% end %>
        <% if( e?('Reference.Other Reference.Journal Title') ) then %> <span class="journal"><%= pv('Reference.Other Reference.Journal Title').capitalize %></span>. <% end %>
        <% if( e?('Reference.Other Reference.Publisher') ) then %> Publisher: <span class="publisher"><%= pv('Reference.Other Reference.Publisher')%>. </span> <% end %>
         <% if( e?('Reference.Other Reference.Year') ) then %> <span class="year">(<span class="value"><%= pv('Reference.Other Reference.Year') %></span>)</span> <% end %>
        <% if( e?('Reference.Other Reference.Date Accessed') ) then %> Accessed: <span class="value"><%= pv('Reference.Other Reference.Date Accessed') %></span>. <% end %>
        <% if( e?('Reference.Other Reference.External Link') ) %>
            Website: <a target="_blank" href="<%= pv('Reference.Other Reference.External Link') %>"><%= pv('Reference.Other Reference.External Link') %></a>
            <a class="link fa fa-external-link" target="_blank" href="<%= pv('Reference.Other Reference.External Link') %>"></a>
        <% end %>
      </span>
    </div>
<% end %>
