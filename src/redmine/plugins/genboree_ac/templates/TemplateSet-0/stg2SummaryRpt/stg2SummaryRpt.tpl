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
    # Just need this report "file name" part of URL. If we use that plus query params, it will be correct in links due to relative uri
    linkUris[linkType] = URI.parse( 'ui/stg2SummaryRpt' )
    linkParams[linkType] = requestParams.deep_clone
  }

  # Build permalink to the viewed version. Ensure version is set to viewed one or head, even if not present in url.
  linkParams[:permalink]['version'] = context[:viewAcDocVersion]
  linkUris[:permalink].query = Rack::Utils.build_query( linkParams[:permalink] )
  # Build link to current/head/most-recent. Basically strip off the version param.
  linkParams[:current].delete('version')
  linkUris[:current].query = Rack::Utils.build_query( linkParams[:current] )
  # Build matching link to Stage 1 report
  linkUris[:matchingStage1Rpt] = linkUris[:permalink].dup
  linkUris[:matchingStage1Rpt].path.sub!(/stg2SummaryRpt/, 'stg1RuleOutRpt')
%>
<!-- Top heading  -->
<div class="container-fluid">
  <h4 class="rptTitle col-xs-12 text-center">
    <strong>Stage II: Summary Report</strong>
    <span class="rptSubTitle small col-xs-12 text-center">
      <strong>Secondary Findings in Adults</strong>
    </span>
    <span class="rptSubTitle small col-xs-12 text-center">
      <strong>Non-diagnostic, excludes newborn screening & prenatal testing/screening</strong>
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
<div id="stage2Table" class="rptTable container-fluid">
  <!-- TOP HEADER ROW -->
  <div class="colHeader lvl1 row">
    <div class="attr text-left col-xs-6">
      <span class="name">GENE/GENE PANEL:</span>
      <span class="values">
        <%= render_each(
          'ActionabilityDocID.Genes',
          %q^<span class="value"><!%= pv('Gene') %!></span>^,
          ', ' ) %>
      </span>
    </div>
    <div class="attr text-right col-xs-6">
      <span class="name">Condition:</span>
      <span class="values">
        <%= pv('ActionabilityDocID.Syndrome') %>
      </span>
    </div>
    <% if( any_matching?( 'ActionabilityDocID.Genes.Gene.SyndromeOMIMs.OMIM' ) ) %>
      <div class="gene-syndromes attr text-left col col-xs-12">
        <span class="name">GENE<span class="large parsed-entity">&hArr;</span>DISEASE PAIRS:</span>
        <span class="values">
          <%= render_each(
            'ActionabilityDocID.Genes',
            %Q^<!% opt(:gene, pv("Gene")) %!>\n<!% opt(:geneOmim, pv("Gene.GeneOMIM")) %!>\n<!%= render_each( "Gene.SyndromeOMIMs", :geneSyndrome ) %!>^
          ) %>
        </span>
      </div>
    <% end %>
  </div>

  <%
    $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "status: #{ pv( 'ActionabilityDocID.Status' ).inspect} ; stage 1 status: #{pv( 'ActionabilityDocID.Stage 1.Final Stage1 Report.Status' ).inspect}")
  %>

  <%# We can display the report if the doc is not still "In Preparation" and if Stage 1 didn't Fail %>
  <% if(  ( pv( 'ActionabilityDocID.Status' ) != 'In Preparation' ) and
          ( pv( 'ActionabilityDocID.Stage 1.Final Stage1 Report.Status' ) != 'Failed' ) ) %>
    <% $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "---REGULAR REPORT GEN---") %>
    <!-- COLUMN HEADER ROW -->
    <div class="colHeader lvl2 row">
      <div class="colName topic text-center col-xs-2">Topic</div>
      <div class="col-xs-10">
        <div class="row">
          <div class="colName narrative text-left col-xs-11">Narrative Description of Evidence</div>
          <div class="colName refs text-center col-xs-1">Ref</div>
        </div>
      </div>
    </div>

    <!-- SECTION: NATURE OF THREAT -->
    <!-- Section Header row -->
    <div class="colHeader lvl3 row">
      <div class="sectionName h4 text-left col-xs-12">1. What is the nature of the threat to health for an individual carrying a deleterious allele?</div>
    </div>
    <!-- Nature of Threat - Prevalence row -->
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Prevalence of the Genetic Disorder</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Notes')
          opt(:additionalStmtsSubProp, 'Additional Statements')
          opt(:noContentMsg, 'No prevalence of the genetic disorder information has been provided.')
          opt(:minContentLines, 2)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder', :specificContentAndRefs) %>
      </div>
    </div>
    <!-- Nature of Thread - Significance -->
    <div class="data odd row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">
          Clinical Features<br>
          <small class="subTopic">(Signs / symptoms)</small>
        </span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Key Text')
          opt(:additionalStmtsSubProp, 'Additional Statements')
          opt(:noContentMsg, 'No clinical features have been provided.')
          opt(:minContentLines, 2)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Nature of the Threat.Clinical Features', :specificContentAndRefs) %>
      </div>
    </div>
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">
          Natural History<br>
          <small class="subTopic">(Important subgroups & survival / recovery)</small>
        </span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Key Text')
          opt(:additionalStmtsSubProp, 'Additional Statements')
          opt(:noContentMsg, 'No natural history been provided.')
          opt(:minContentLines, 3)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Nature of the Threat.Natural History', :specificContentAndRefs) %>
      </div>
    </div>

    <!-- SECTION: Effectiveness -->
    <!-- Section Header row -->
    <div class="colHeader lvl3 row">
      <div class="sectionName h4 text-left col-xs-12">
        2. How effective are interventions for preventing harm?<br>
        <small class="sectionSubName">Information on the effectiveness of the recommendations below was not provided unless otherwise stated.</small>
      </div>
    </div>

    <!-- Effectiveness - Patient Management row -->
    <div class="data even row">
      <!-- Row header -->
      <div class="topic text-center col-xs-2">
        <span class="paragraph">
          Patient Management
        </span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Recommendation Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No patient management recommendations have been provided.')
          opt(:minContentLines, 1)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Effectiveness of Intervention.Patient Managements', :allContentsAndRefs) %>
      </div>
    </div>

    <!-- Effectiveness - Surveillance row -->
    <div class="data odd row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Surveillance</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Recommendation Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No surveillance recommendations have been provided.')
          opt(:minContentLines, 1)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Effectiveness of Intervention.Surveillances', :allContentsAndRefs) %>
      </div>
    </div>

    <!-- Effectiveness - Family  Management row -->
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Family Management</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Recommendation Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No family management recommendations have been provided.')
          opt(:minContentLines, 1)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Effectiveness of Intervention.Family Managements', :allContentsAndRefs) %>
      </div>
    </div>

    <!-- Effectiveness - Circumstances row -->
    <div class="data odd row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Circumstances to Avoid</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Recommendation Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No circumstances-to-avoid recommendations have been provided.')
          opt(:minContentLines, 1)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Effectiveness of Intervention.Circumstances to Avoid', :allContentsAndRefs) %>
      </div>
    </div>

    <!-- SECTION: Materialization -->
    <!-- Section Header row -->
    <div class="colHeader lvl3 row">
      <div class="sectionName h4 text-left col-xs-12">3. What is the chance that this threat will materialize?</div>
    </div>

    <!-- Materialization - Mode of Inheritance row -->
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Mode of Inheritance</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Key Text')
          opt(:additionalStmtsSubProp, nil)
          opt(:noContentMsg, 'No expressivity information has been provided.')
          opt(:minContentLines, 1)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Mode of Inheritance', :specificContentAndRefs) %>
      </div>
    </div>

    <!-- Materialization - Prevalence of Genetic Mutations row -->
    <div class="data odd row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Prevalence of Genetic Mutations</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Notes')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No genetic mutation prevalence information has been provided.')
          opt(:minContentLines, 2)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation', :specificContentAndRefs) %>
      </div>
    </div>

    <!-- Materialization - Penetrance or Relative Risk row -->
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">
          Penetrance<br>OR<br>Relative Risk<br>
          <small class="subTopic">(Include any high risk racial or ethnic subgroups)</small>
        </span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Notes')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'Information on the prevalence of mutations was not available.')
          opt(:minContentLines, 3)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Penetrances', :allContentsAndRefs) %>
        <%
          opt(:contentSubProp, 'Notes')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'Information on relative risk was not available.')
          opt(:minContentLines, 2)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Relative Risks', :allContentsAndRefs) %>
      </div>
    </div>

    <!-- Materialization - Expressivity row -->
    <div class="data odd row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Expressivity</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Key Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'Information on variable expressivity was not available.')
          opt(:minContentLines, 1)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Expressivity Notes', :allContentsAndRefs) %>
      </div>
    </div>

    <!-- SECTION: Nature of Intervention -->
    <!-- Section Header row -->
    <div class="colHeader lvl3 row">
      <div class="sectionName h4 text-left col-xs-12">4. What is the Nature of the Intervention?</div>
    </div>
    <!-- Nature of Intervention row -->
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Nature of Intervention</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Key Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No nature of intervention information has been provided.')
          opt(:minContentLines, 1)
        %>
        <%# = subRender('ActionabilityDocID.Stage 2.Acceptability of Intervention.Nature of Intervention', :specificContentAndRefs) %>

        <%= subRender('ActionabilityDocID.Stage 2.Acceptability of Intervention.Natures of Intervention', :allContentsAndRefs) %>

      </div>
    </div>

    <!-- SECTION: Escape Detection -->
    <!-- Section Header row -->
    <div class="colHeader lvl3 row">
      <div class="sectionName h4 text-left col-xs-12">5. Would the underlying risk or condition escape detection prior to harm in the settting of recommended care?</div>
    </div>
    <!-- Nature of Intervention row -->
    <div class="data even row">
      <div class="topic text-center col-xs-2">
        <span class="paragraph">Chance to Escape Clinical Detection</span>
      </div>
      <!-- Row for content paragraph column + related reference column -->
      <div class="allContentsAndRefs col-xs-10">
        <%
          opt(:contentSubProp, 'Key Text')
          opt(:additionalStmtsSubProp, 'Additional Tiered Statements')
          opt(:noContentMsg, 'No information about escaping detection has been provided.')
          opt(:minContentLines, 3)
        %>
        <%= subRender('ActionabilityDocID.Stage 2.Condition Escape Detection.Chances to Escape Clinical Detection', :allContentsAndRefs) %>
      </div>
    </div>
  </div>

  <br>&nbsp;<br>

  <%# Scoring Table %>
  <div id="scoringTable" class="rptTable scrTable container-fluid">
    <%# TABLE TITLE %>
    <div class="colHeader lvl3 row">
      <div class="sectionName h4 text-left col-xs-12">Final Consensus Scores</div>
    </div>
    <!-- COLUMN HEADER ROW -->
    <div class="colHeader lvl2 row">
      <div class="colName oiPair text-left col-xs-4">Outcome / Intervention Pair</div>
      <div class="colName severity text-left col-xs-1">Severity</div>
      <div class="colName likelihood text-left col-xs-2">Likelihood</div>
      <div class="colName effectiveness text-left col-xs-2">Effectiveness</div>
      <div class="colName noi text-left col-xs-2">Nature of the<br>Intervention</div>
      <div class="colName totalScore text-left col-xs-1">Total<br>Score</div>
    </div>
    <%# Row for each the O/I pairs + scores %>
    <%
      opt(:noContentMsg, 'N/A')
      footnotes = []
    %>
    <%= render_each( 'ActionabilityDocID.Score.Final Scores.Outcomes', :outcomeScoring, '', { :footnotes => footnotes } ) %>
  </div>
  <%# Render footnotes collected as visited each O/I %>
  <% if( footnotes and footnotes.size > 0 ) %>
      <div class="footnotes">
  <%
        footnotes.each_index { |ii| footnote = footnotes[ii]
  %>
          <div class="footnote-entry">
            <span class="num"><%= ii + 1 %>.</span>
            <span class="text"><%= footnote %></span>
          </div>
  <%    } %>
      </div>
  <% end %>
  To see the scoring key, please go to: <a class="external" href="https://clinicalgenome.org/working-groups/actionability/projects-initiatives/actionability-evidence-based-summaries/">https://clinicalgenome.org/working-groups/actionability/projects-initiatives/actionability-evidence-based-summaries/</a>

  <!-- TIER LEGEND -->
  <div class="tierInfo nobreak row">
    <div class="col-xs-12">
      <strong>Description of sources of evidence:</strong>
    </div>
    <div class="tierDefs col-xs-12">
      <div class="tierDef">
        <strong>Tier 1:</strong> Evidence from a systematic review, or a meta-analysis or clinical practice guideline clearly based on a systematic review.
      </div>
      <div class="tierDef">
        <strong>Tier 2:</strong> Evidence from clinical practice guidelines or broad-based expert consensus with non-systematic evidence review.
      </div>
      <div class="tierDef">
        <strong>Tier 3:</strong> Evidence from another source with non-systematic review of evidence with primary literature cited.
      </div>
      <div class="tierDef">
        <strong>Tier 4:</strong> Evidence from another source with non-systematic review of evidence with no citations to primary data sources.
      </div>
      <div class="tierDef">
        <strong>Tier 5:</strong> Evidence from a non-systematically identified source.
      </div>
    </div>
  </div>

  <!-- LIT SEARCH DATE INFO -->
  <%=  subRender( 'ActionabilityDocID.LiteratureSearch', :litSearchDates ) %>
<% else %><%# Either doc is "In Preparation" or released with Stage 1 status of Failed. %>

    <% $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "---ALT REPORT GEN---") %>
  <%# Based on status values and business logic, e should not try to display the report for this doc %>
  <% if( pv('ActionabilityDocID.Status') == 'In Preparation') %>
    <%
      noticeHtml = (
        'The \'Stage 2 Summary Report\' is not available because ' +
        ( viewingHeadAcDoc ? 'currently,<br>this gene-disease pair is' : ( (requestParams[:version].to_s =~ /\S/) ? "at version '#{requestParams[:version]}',<br>this gene-disease pair was" : 'at this version,<br>this gene-disease pair was' ) ) +
        ' <u>in preparation</u> and undergoing curation.'
      )
    %>
  <% else %><%# must no be in prep but must have stage 1 Failed status %>
    <%
      noticeHtml = (
        'The \'Stage 2 Summary Report\' is not available because ' +
        ( viewingHeadAcDoc ? 'as of the most recent update,' : ( (requestParams[:version].to_s =~ /\S/) ? "in version '#{requestParams[:version]}'" : 'at this version,' ) ) +
        "<br>this gene-disease pair <u>did not pass</u> the <a href=\"#{linkUris[:matchingStage1Rpt].to_s}\">Stage 1 Rule-Out survey</a>."
      )
    %>
  <% end %>
  <div class="row">
    <div class="colBody col-sm-12">
      <div class="notice-title text-center h3 col-xs-12">
        <strong>NOTICE</strong>
      </div>
      <div id="q1" class="notice-text text-center col-xs-12">
        <%= noticeHtml %>
      </div>
    </div>
  </div>
<% end %>
