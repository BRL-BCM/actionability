<!-- Top heading  -->
<div class="container-fluid">
  <h4 class="rptTitle col-xs-12 text-center">
    <strong>Stage II: Summary Report</strong>
    <span class="rptSubTitle small col-xs-12 text-center">
      <strong>Incidental Findings in Adults</strong>
    </span>
    <span class="rptSubTitle small col-xs-12 text-center">
      <strong>Non-diagnostic, excludes newborn screening & prenatal testing/screening</strong>
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
  </div>
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
        opt(:noContentMsg, 'No penetrance information has been provided.')
        opt(:minContentLines, 3)
      %>
      <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Penetrances', :allContentsAndRefs) %>
      <%
        opt(:contentSubProp, 'Notes')
        opt(:noContentMsg, 'No relative risk information has been provided.')
        opt(:minContentLines, 2)
      %>
      <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Relative Risk', :specificContentAndRefs) %>
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
        opt(:contentSubProp, 'Notes')
        opt(:noContentMsg, 'No expressivity information has been provided.')
        opt(:minContentLines, 1)
      %>
      <%= subRender('ActionabilityDocID.Stage 2.Threat Materialization Chances.Expressivity Notes', :specificContentAndRefs) %>
    </div>
  </div>

  <!-- SECTION: Nature of Intervention -->
  <!-- Section Header row -->
  <div class="colHeader lvl3 row">
    <div class="sectionName h4 text-left col-xs-12">4. Nature of Intervention</div>
  </div>
  <!-- Nature of Intervention row -->
  <div class="data even row">
    <div class="topic text-center col-xs-2">
      <span class="paragraph">Burden and/or Risk</span>
    </div>
    <!-- Row for content paragraph column + related reference column -->
    <div class="allContentsAndRefs col-xs-10">
      <%
        opt(:contentSubProp, 'Key Text')
        opt(:noContentMsg, 'No burden or risk information has been provided.')
        opt(:minContentLines, 1)
      %>
      <%= subRender('ActionabilityDocID.Stage 2.Acceptability of Intervention.Nature of Intervention', :specificContentAndRefs) %>
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
      <span class="paragraph">Chance to Escape Clinical Detection in Adults</span>
    </div>
    <!-- Row for content paragraph column + related reference column -->
    <div class="allContentsAndRefs col-xs-10">
      <%
        opt(:contentSubProp, 'Key Text')
        opt(:noContentMsg, 'No information about escaping detection has been provided.')
        opt(:minContentLines, 3)
      %>
      <%= subRender('ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection', :specificContentAndRefs) %>
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
  %>
  <%= render_each( 'ActionabilityDocID.Score.Final Scores.Outcomes', :outcomeScoring ) %>
</div>
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