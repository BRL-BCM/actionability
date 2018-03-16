<%
  # Dig out the "context" info that was passed in (generally Controller instance variables
  # relevant to proper template rendering BEYOND the KbDoc itself.)
  context = opt(:context)
  viewingHeadAcDoc = context[:viewingHeadVersion]
  verOrRelLabel = context[:verOrRelLabel]
  gbac_label_release = context[:gbac_label_release]
  isAcReleaseTrack = context[:isAcReleaseTrack]
  releaseKbBaseUrl = context[:releaseKbBaseUrl]

  # Build link to release history
  if( isAcReleaseTrack or releaseKbBaseUrl.blank? or pv('ActionabilityDocID.Release').blank? )
    releaseHistoryLink = ''
  else
    releaseKbBaseUrl= releaseKbBaseUrl.to_s.strip
    releaseKbBaseUrl.chomp!('/')
    releaseHistoryLink = "#{releaseKbBaseUrl}/ui/docVersions?doc=#{pv('ActionabilityDocID')}"
  end

  # Build the various links to this page using page url.
  # * We won't do this via Rails' params variable because may have some other things spiked in.
  requestUrl = context[:requestUrl]
  requestUri = URI.parse(requestUrl)
  requestParams = CGI.parse( requestUri.query )
  linkUris = {}
  linkParams = {}
  [ :permalink, :current ].each { |linkType|
    linkUris[linkType] = URI.parse( 'ui/stg1RuleOutRpt' )
    linkParams[linkType] = requestParams.deep_clone
  }
  # Build permalink to the viewed version. Ensure version is set to viewed one or head, even if not present in url.
  linkParams[:permalink]['version'] = context[:viewAcDocVersion]
  linkUris[:permalink].query = Rack::Utils.build_query( linkParams[:permalink] )
  # Build link to current/head/most-recent. Basically strip off the version param.
  linkParams[:current].delete('version')
  linkUris[:current].query = Rack::Utils.build_query( linkParams[:current] )
%>
<!-- Top heading  -->
<div class="container-fluid">
  <h4 class="rptTitle col-xs-12 text-center">
    <strong>Stage I: Rule-Out Dashboard</strong>
    <span class="rptSubTitle small col-xs-12 text-center">
      <strong>Secondary Findings in Adults</strong>
    </span>
    <span class="links col col-xs-12 small text-center">
      <a class="permalink link" href="<%= linkUris[:permalink].to_s %>"><span class="fa fa-link"></span>Permalink</a>
      <% unless( viewingHeadAcDoc ) %>
        <a class="current <%= verOrRelLabel %> link" href="<%= linkUris[:current].to_s %>"><span class="fa fa-link"></span>Current <%= (isAcReleaseTrack ? verOrRelLabel.capitalize : 'Content') %></a>
      <% end %>
      <a class="<%= verOrRelLabel.pluralize %> link" href="ui/docVersions?doc=<%= pv('ActionabilityDocID') %>"><span class="fa fa-history"></span><%= verOrRelLabel.capitalize %> History</a>
      <% unless( isAcReleaseTrack or releaseKbBaseUrl.blank? or pv('ActionabilityDocID.Release').blank? ) %>
        <a class="<%= gbac_label_release %> link" href="<%= releaseHistoryLink %>"><span class="fa fa-history"></span>Public <%= gbac_label_release.capitalize %> History</a>
      <% end %>
    </span>
  </h4>
</div>


<!-- Report Table  -->
<div id="stage1Table" class="rptTable container-fluid">
  <!-- HEADER ROW -->
  <div class="colHeader lvl1 row">
    <!-- BEGIN: Left 'Column' Header -->
    <div id="stage1LeftCol" class="col-md-6 col-sm-12">
      <!-- Column head -->
      <div class="row">
        <div class="attr text-right col-xs-4">
          <span class="name">GENE/GENE PANEL:</span>
        </div>
        <div class="values text-left col-xs-8">
          <%= render_each(
            'ActionabilityDocID.Genes',
            %q^<span class="value"><!%= pv('Gene') %!></span>^,
            ', ' ) %>
        </div>
      </div>
      <% if( ( pv( 'ActionabilityDocID.Status' ) != 'In Preparation' ) ) %>
        <div class="row">
          <div class="attr text-right col-xs-4">
            <span class="name">HGNC IDs:</span>
          </div>
          <div class="values text-left col-xs-8">
            <%= render_each(
            'ActionabilityDocID.Genes',
            %q^<span class="value"><!%= pv('Gene.HGNCId') %!></span>^,
            ', ' ) %>
          </div>
        </div>
      <% end %>
    </div>
    <!-- BEGIN: Right 'Column' Header -->
    <div id="stage1RightCol" class="col-md-6 col-sm-12">
      <!-- Column head -->
      <div class="row">
        <div class="attr text-right col-xs-4">
          <span class="name">DISORDER:</span>
        </div>
        <div class="values text-left col-xs-8">
          <%= pv('ActionabilityDocID.Syndrome') %>
        </div>
      </div>
      <% if( ( pv( 'ActionabilityDocID.Status' ) != 'In Preparation' ) ) %>
        <div class="row">
          <div class="attr text-right col-xs-4">
            <span class="name">OMIM IDs:</span>
          </div>
          <div class="values text-left col-xs-8">
            <%= render_each(
              'ActionabilityDocID.Syndrome.OmimIDs',
              %q^<span class="value"><!%= pv('OmimID') %!></span>^,
              ', ' ) %>
          </div>
        </div>
      <% end %>
    </div>
  </div>
  <!-- END: header row -->

  <% if( ( pv( 'ActionabilityDocID.Status' ) != 'In Preparation' ) ) %>
    <!-- BEGIN: Body -->
    <div class="rptTable row">
      <!-- BEGIN: Left 'Column' Body -->
      <div class="colBody col-md-6 col-sm-12">
        <!-- actionability -->
        <div class="sectionHdr text-center h3 col-xs-12">
          <strong>ACTIONABILITY</strong>
        </div>
        <!-- actionability - questions -->
        <!-- actionability - question - practice guideline? -->
        <%
          ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Practice Guideline').to_s.strip.downcase
          q1IsYes = isYes = case ans
            when 'yes'
              :yes
            when 'no'
              :no
            else
              :none
            end
        %>
        <div id="q1" class="question col-xs-12">
          1. Is there a qualifying resource, such as a practice guideline or systematic review, for the genetic condition?
        </div>
        <!-- Yes/No -->
        <div class="yes-no text-left col-xs-12">
          <div class="row">
            <div class="yes col-xs-4"> <i class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></i> YES</div>
            <div class="no col-xs-8"> <i class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></i> NO</div>
          </div>
        </div>

        <!-- actionability - questions - ways result is actionable -->
        <div id="q2" class="question col-xs-12">
          2. Does the practice guideline or systematic review indicate that the result is actionable in one or more of the following ways?
        </div>
        <div class="yes-no text-left col-xs-12">
          <!-- question column title -->
          <div class="qnaListHeaders row">
            <div class="yes minor col-xs-1">YES</div>
            <div class="no minor col-xs-11">NO</div>
          </div>

          <!-- actionability - question - patient management? -->
          <%
            ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable.Patient Management').to_s.strip.downcase
            isYes = case ans
              when 'yes'
                :yes
              when 'no'
                :no
              else
                :none
            end
          %>
          <div class="qnaList row">
            <div class="yes minor col-xs-1"> <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> </div>
            <div class="no minor col-xs-11">
              <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>Patient Management</span>
            </div>
          </div>

          <!-- actionability - question - surveillance or screening? -->
          <%
            ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable.Surveillance or Screening').to_s.strip.downcase
            isYes = case ans
              when 'yes'
                :yes
              when 'no'
                :no
              else
                :none
            end
          %>
          <div class="qnaList row">
            <div class="yes minor col-xs-1"> <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> </div>
            <div class="no minor col-xs-11">
              <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>Surveillance or Screening</span>
            </div>
          </div>

          <!-- actionability - question - family management? -->
          <%
            ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable.Family Management').to_s.strip.downcase
            isYes = case ans
              when 'yes'
                :yes
              when 'no'
                :no
              else
                :none
            end
          %>
          <div class="qnaList row">
            <div class="yes minor col-xs-1"> <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> </div>
            <div class="no minor col-xs-11">
              <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>Family Management</span>
            </div>
          </div>

          <!-- actionability - question - circumstances to avoid? -->
          <%
            ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable.Circumstances to Avoid').to_s.strip.downcase
            isYes = case ans
              when 'yes'
                :yes
              when 'no'
                :no
              else
                :none
            end
          %>
          <div class="qnaList row">
            <div class="yes minor col-xs-1"><span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> </div>
            <div class="no minor col-xs-11">
              <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>Circumstances to Avoid</span>
            </div>
          </div>

          <!-- actionability - question - yes for 1 or more above? -->
          <%
            ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable.Yes for 1 or more above').to_s.strip.downcase
            q2IsYes = isYes = case ans
              when 'yes'
                :yes
              when 'no'
                :no
              else
                :none
            end
          %>
          <div class="qnaList row">
            <div class="yes col-xs-7">
              <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>YES (&gt;= 1 above)</span>
            </div>
            <div class="no col-xs-5">
              <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>NO (STOP)</span>
            </div>
          </div>
        </div>

        <!-- actionability - question - actionable in undiagnosed? -->
        <%
          ans =pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable in undiagnosed').to_s.strip.downcase
          q3IsYes = isYes = case ans
            when 'yes'
              :yes
            when 'no'
              :no
            else
              :none
          end
        %>
        <div id="q3" class="question col-xs-12">
          3. Is the result actionable in an undiagnosed adult with the genetic condition?
        </div>
        <!-- Yes/No -->
        <div class="yes-no text-left col-xs-12">
          <div class="row">
            <div class="yes col-xs-4"> <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> YES</div>
            <div class="no col-xs-8"> <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span> NO (STOP)</div>
          </div>
        </div>
      </div>
      <!-- END: Left Column -->

      <!-- BEGIN: Right 'Column' Body -->
      <div class="rightCol colBody col-md-6 col-sm-12">
        <!-- penetrance -->
        <div class="sectionHdr text-center h3 col-xs-12">
          <strong>PENETRANCE</strong>
        </div>
        <!-- penetrance - questions -->
        <!-- penetrance - question - moderate variant? -->
        <%
          ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Penetrance.Moderate Penetrance Variant').to_s.strip.downcase
          q4IsYes = isYes = case ans
            when 'yes'
              :yes
            when 'no'
              :no
            when 'unknown'
              :unknown
            else
              :none
          end
          isUnk = (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Penetrance.Moderate Penetrance Variant').to_s.strip.downcase == 'unknown')
        %>
        <div id="q4" class="question col-xs-12">
          4. Is there at least one known pathogenic variant with at least moderate penetrance (&ge;40%) or moderate relative risk (&ge;2) in any population?
        </div>
        <!-- Yes/No -->
        <div class="yes-no text-left col-xs-12">
          <div class="row">
            <div class="yes col-xs-3"> <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> YES</div>
            <div class="no col-xs-3"> <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span> NO</div>
            <div class="other col-xs-6"> <span class="fa fa<%= '-check' if(isYes == :unknown) %>-square-o fa-lg" aria-hidden="true"></span> UNKNOWN</div>
          </div>
        </div>

        <!-- significance -->
        <div class="sectionHdr pushDown1 col-xs-12 text-center h3">
          <strong>SIGNIFICANCE/BURDEN OF DISEASE</strong>
        </div>
        <!-- significance - questions -->
        <!-- significance - question - important? -->
        <%
          ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Significance of Disease.Important Health Problem').to_s.strip.downcase
          q5IsYes = isYes = case ans
            when 'yes'
              :yes
            when 'no'
              :no
            else
              :none
          end
        %>
        <div id="q5" class="question col-xs-12">
          5. Is this condition an important health problem?
        </div>
        <!-- Yes/No -->
        <div class="yes-no text-left col-xs-12">
          <div class="row">
            <div class="yes col-xs-4"> <span class="fa fa<%= '-check' if(isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span> YES</div>
            <div class="no col-xs-8"> <span class="fa fa<%= '-check' if(isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span> NO</div>
          </div>
        </div>

        <!-- survey result - questions -->
        <!-- survey result - question - q2-5 all yes? -->
        <%
          q6IsYes = isYes = [ q2IsYes, q3IsYes, q4IsYes, q5IsYes ].all? { |xx| xx == :yes }
        %>
        <div id="q6" class="question col-xs-12">
          6. Are Actionability (Q2-3), Penetrance (Q4), and Significance (Q5) all &quot;YES&quot;?
        </div>
        <!-- Yes/No -->
        <div class="yes-no text-left col-xs-12">
          <div class="row">
            <div class="yes col-xs-12">
              <span class="fa fa<%= '-check' if(isYes) %>-square-o fa-lg" aria-hidden="true"></span>
              <span class="withInstruction">YES <span class="important instruction">(Proceed to Stage - II)</span></span>
            </div>
          </div>
          <div class="row">
            <div class="no col-xs-12">
              <span class="fa fa<%= '-check' unless(isYes) %>-square-o fa-lg" aria-hidden="true"></span>
              <span class="withInstruction"> NO <span class="important instruction">(Consult Actionability Working Group)</span></span>
            </div>
          </div>
          <!-- survey result - question - exception made?
          <!-- (cannot actually make exception if already q6 is YES...but doc may have exception boxes checked, so we look for that too when setting class) -->
          <%
            ans = pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Need for making exception.Exception Made').to_s.strip.downcase
            isYes = case ans
              when 'yes'
                :yes
              when 'no'
                :no
              else
                :none
            end
          %>
          <div class="row">
            <div class="yes instruction minor col-xs-11 col-xs-offset-1">
              <span class="fa fa<%= '-check' if(!q6IsYes and isYes == :yes) %>-square-o fa-lg" aria-hidden="true"></span>
              <span>Exception granted, proceed to Stage II</span>
            </div>
          </div>
          <div class="row">
            <div class="yes instruction minor col-xs-11 col-xs-offset-1">
              <span class="fa fa<%= '-check' if(!q6IsYes and isYes == :no) %>-square-o fa-lg" aria-hidden="true"></span>
              <span> Exception not granted, STOP </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  <% else %>
    <%# Based on status values and business logic, we should not try to display the report for this doc %>
    <%
      noticeHtml = (
        'The \'Stage 1 Rule-Out Dashboard\' is not available because ' +
        ( viewingHeadAcDoc ? 'currently,<br>this gene-disease pair is' : ( (requestParams[:version].to_s =~ /\S/) ? "at version '#{requestParams[:version]}',<br>this gene-disease pair was" : 'at this version,<br>this gene-disease pair was' ) ) +
          ' <u>in preparation</u> and undergoing curation.'
      )
    %>
    <div class="rptTable row">
      <!-- BEGIN: Left 'Column' Body -->
      <div class="colBody col-sm-12">
        <!-- actionability -->
        <div class="notice-title text-center h3 col-xs-12">
          <strong>NOTICE</strong>
        </div>
        <div id="q1" class="notice-text text-center col-xs-12">
          <%= noticeHtml %>
        </div>
      </div>
    </div>
  <% end %>
</div>
