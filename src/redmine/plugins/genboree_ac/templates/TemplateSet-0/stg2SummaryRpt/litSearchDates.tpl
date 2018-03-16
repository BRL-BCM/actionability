<%
  sources = items( 'LiteratureSearch.Sources' )
  if(sources and !sources.empty?)
    minDate = maxDate = nil
    sources.each { |source|
      sourceDoc = BRL::Genboree::KB::KbDoc.new( source )
      searchStrs = sourceDoc.getPropItems( 'Source.SearchStrings' )
      if(searchStrs and !searchStrs.empty?)
        searchStrs.each { |searchStr|
          searchStrDoc = BRL::Genboree::KB::KbDoc.new( searchStr )
          dateStr = searchStrDoc.getPropVal( 'SearchString.Date' )
          if(dateStr and !dateStr.empty?)
            dateAsTime = Time.parse(dateStr) rescue nil
            if(dateAsTime)
              if(minDate.nil? or minDate > dateAsTime)
                minDate = dateAsTime
              end
              if(maxDate.nil? or maxDate < dateAsTime)
                maxDate = dateAsTime
              end
            end
          end
        }
      end
    }
%>
        <div class="lit search date">
          <span class="title">Date of Search:</span>
          <span class="value"><%= minDate.strftime('%m.%d.%Y') %><%= " (updated #{maxDate.strftime('%m.%d.%Y')})" if(minDate < maxDate) %></span>
        </div>
<%
  end
%>
