<span class="lvl1 title"><%= @actionabilitydocidSyndrome %> <span class="status">(Status: <%= @actionabilitydocidStatus %>)</span></span>
  <div class="section">
    <div class="keytext"><span><%= @actionabilitydocidSyndromeOverview %></span></div>
    <div class="attrs">
      <div class="attr"><span class="name">Aliases:</span> <%= @__producer.render_each(
        "ActionabilityDocID.Syndrome.Acronyms",
        %q^<span class="value"><!%= @acronym %!></span>^,
        ', ') %>
      </div>
      <div class="attr"><span class="name">OMIM:</span> <span class="omim list"><%= @__producer.render_each(
        "ActionabilityDocID.Syndrome.OmimIDs",
        %q^<span class="value"><a target="__blank" href="http://www.omim.org/entry/<!%= @omimid %!>"><!%= @omimid %!></a></span>^,
        ', ' ) %>
      </div>
      <div class="attr"><span class="name">Orphanet:</span> <span class="orphanet list"><%= @__producer.render_each(
        "ActionabilityDocID.Syndrome.OrphanetIDs",
        %q^<span class="value"><a target="__blank" href="http://www.orpha.net/consor/cgi-bin/OC_Exp.php?Expert=<!%= @orphanetid %!>"><!%= @orphanetid %!></a></span>^,
        ', ' ) %>
      </div>
    </div>

    <!-- GENES -->
    <span id="genes" class="lvl3 title">Genes: <span><%= @__producer.render_each(
      "ActionabilityDocID.Genes",
      %q^<span><a target="__blank" href="http://www.omim.org/entry/<!%= @geneGeneomim %!>"><!%= @gene %!></a></span>^,
      ', ' ) %>
    </span></span>
  </div>

<!-- LITERATURE SEARCH SUMMARY -->
<span id="litSearch" class="lvl2 title">Literature Search Summary: <span class="status">(Status: <%= @actionabilitydocidLiteraturesearchStatus %>)</span></span>
  <div class="section">
    <table class="litSources">
      <tr class="header">
        <td class="search">Search</td>
        <td class="hits"># Hits</td>
        <td class="date">Date</td>
      </tr>
      <%= @__producer.render_each( "ActionabilityDocID.LiteratureSearch.Sources", :litSource) %>
    </table>
  </div>

<!-- STAGE 1 -->
<span id="stage1" class="lvl2 title stage1">Stage 1 - Rule-Out Board: <span class="status">(Status: <%= @actionabilitydocidStage_1Status %>)</span></span>
  <div class="section stage1">

    <!-- STAGE 1 - Actionability -->
    <span class="lvl3 title">Actionability</span>
      <div class="qna"><span class="question">1. Is there a practice guideline for systematic review for the genetic condition?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityPractice_guideline %></span></div>
      <div class="qna"><span class="question">2. Does the practice guideline or systematic review indicate that the result is actionable in one or more of the following ways?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityResult_actionableYes_for_1_or_more_above %></span></div>
        <div class="depth2">
          <div class="qna"><span class="question">Patient management?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityResult_actionablePatient_management %></span></div>
          <div class="qna"><span class="question">Surveillance or screening?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityResult_actionableSurveillance_or_screening %></span></div>
          <div class="qna"><span class="question">Family management?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityResult_actionableFamily_management %></span></div>
          <div class="qna"><span class="question">Circumstances to avoid?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityResult_actionableCircumstances_to_avoid %></span></div>
        </div>
      <div class="qna"><span class="question">3. Is the result actionable in an undiagnosed adult with the genetic condition?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1ActionabilityResult_actionable_in_undiagnosed %></span></div>

    <!-- STAGE 1 - Penetrance -->
    <span class="lvl3 title">Penetrance</span>
      <div class="qna"><span class="question">4. Is there at least one known pathogenic variant with at least moderate penetrance (>=40%) or moderate relative risk (>=2) in any population?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1PenetranceModerate_penetrance_variant %></span></div>

    <!-- STAGE 1 - Significance/Burden of Disease -->
    <span class="lvl3 title">Significance/Burden of Disease</span>
      <div class="qna"><span class="question">5. Is this condition an important health problem?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1Significance_of_diseaseImportant_health_problem %></span></div>

    <!-- STAGE 1 - Exception (special) -->
    <span class="lvl3 title">Exception</span>
      <div class="qna"><span class="question">Is there a need to make an exception?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1Need_for_making_exception %></span></div>
      <div class="qna"><span class="question">Has an exception been made?</span> <span class="answer yesno"><%= @actionabilitydocidStage_1Need_for_making_exceptionException_made %></span></div>
      <div class="qna"><span class="question">Why was an exception made?</span> <span class="answer"><%= @actionabilitydocidStage_1Need_for_making_exceptionException_madeNote_why_exception_made %></span></div>
  </div>

<!-- STAGE 2 -->
<span id="stage2" class="lvl2 title stage2">Stage 2 - Summary Report <span class="status">(Status: <%= @actionabilitydocidStage_2Status %>)</span></span>
  <div class="section stage2">

    <!-- STAGE 2 - Outcomes / Interventions Summary -->
    <span class="lvl3 title">Outcomes &amp; Interventions Summary</span>
      <div class="table ois">
        <div class="header row">
          <div class="cell outcome">Outcome</div>
          <div class="cell intervention">Intervention</div>
        </div>
        <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Outcomes", :outcome) %>
      </div>

    <!-- STAGE 2 - Nature of the Threat -->
    <span class="lvl3 title">Nature of the Threat</span>
      <div class="subSection">
        <!-- STAGE 2 - Nature of the Threat - Prevalence -->
        <span class="lvl4 title">Prevalence of the genetic disorder: <span class="value"> <%= @actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderKey_text %></span></span>
          <div class="value keytext"><%= @actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderNotes %></div>
          <div class="attrs">
            <div class="attr"><span class="name">Source of Population:</span> <span class="value line"><%= @actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderAdditional_fieldsSource_of_population %></span></div>
            <div class="attr"><span class="name">References:</span>
              <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder.References", :refAnchor, ', ' ) %>
            </div>
          </div>

        <!-- STAGE 2 - Nature of the Threat - Clinical Features -->
        <span class="lvl4 title">Clinical Features</span>
          <div class="value keytext"><%= @actionabilitydocidStage_2Nature_of_the_threatClinical_featuresKey_text %></div>
          <div class="attrs">
            <div class="attr"><span class="name">References:</span>
              <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Nature of the Threat.Clinical Features.References", :refAnchor, ', ' ) %>
            </div>
          </div>

        <!-- STAGE 2 - Nature of the Threat - Natural History -->
        <span class="lvl4 title">Natural History</span>
          <div class="value keytext"><%= @actionabilitydocidStage_2Nature_of_the_threatNatural_historyKey_text %></div>
          <div class="attrs">
            <div class="attr"><span class="name">References:</span>
              <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Nature of the Threat.Natural History.References", :refAnchor, ', ' ) %>
            </div>
          </div>
      </div>

    <!-- STAGE 2 - Effectiveness of Intervention -->
    <span class="lvl3 title">Effectiveness of Intervention</span>
      <div class="subSection">

        <!-- STAGE 2 - Effectiveness of Intervention - Patient Management -->
        <span class="lvl4 title">Patient Management</span>
          <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Effectiveness of Intervention.Patient Managements", :tieredEffectiveness) %>

        <!-- STAGE 2 - Effectiveness of Intervention - Surveillance -->
        <span class="lvl4 title">Surveillance</span>
          <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Effectiveness of Intervention.Surveillances", :tieredEffectiveness) %>

        <!-- STAGE 2 - Effectiveness of Intervention - Family Management -->
        <span class="lvl4 title">Family Management</span>
          <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Effectiveness of Intervention.Family Managements", :tieredEffectiveness) %>

        <!-- STAGE 2 - Effectiveness of Intervention - Circumstance to Avoid -->
        <span class="lvl4 title">Circumstance to Avoid</span>
          <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Effectiveness of Intervention.Circumstances to Avoid", :tieredEffectiveness) %>

      </div>

    <!-- STAGE 2 - Threat Materialization -->
    <span class="lvl3 title">Threat Materialization</span>
      <div class="subSection">
        <!-- STAGE 2 - Threat Materialization - Mode of Inheritance -->
        <span class="lvl4 title">Mode of Inheritance: <span class="value"><%= @actionabilitydocidStage_2Threat_materialization_chancesMode_of_inheritanceKey_text %></span></span>

        <!-- STAGE 2 - Threat Materialization - Prevalence of Genetic Mutations -->
        <span class="lvl4 title">Prevalence of Genetic Mutations: <span class="value"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationKey_text %></span></span>
          <div class="attr"><span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationTier %></span></div>
          <div class="attr"><span class="name">Source of Population for this Prevalence:</span> <span class="value line"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationAdditional_fieldsSource_of_population_for_this_prevalence %></span></div>
          <div class="attr"><span class="name">Notes:</span> <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationNotes %></span></div> <div class="attr"><span class="name">Outcomes:</span>
            <% gmOutcomes = @__producer.kbDoc.getPropItems("ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Outcomes") %>
            <% if(gmOutcomes and gmOutcomes.size > 0)  %>
              <ul class="outcomes">
                <%= @__producer.render_each(
                  "ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Outcomes",
                  %q^<li><!%= @outcome %!></li>^ ) %>
              </ul>
            <% end %>
          </div>
          <div class="attr"><span class="name">References:</span>
            <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.References", :refAnchor, ', ' ) %>
          </div>

        <!-- STAGE 2 - Threat Materialization - Penetrance -->
        <span class="lvl4 title">Penetrance</span>
          <div class="subSection">
            <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Threat Materialization Chances.Penetrances", :penetrance ) %>
          </div>

        <!-- STAGE 2 - Threat Materialization - Relative Risk -->
        <span class="lvl4 title">Relative Risk: <span class="value"> <%= @actionabilitydocidStage_2Threat_materialization_chancesRelative_riskKey_text %></span></span>
          <div class="attr"><span class="name">Notes:</span> <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesRelative_riskNotes %></span></div>
          <div class="attr"><span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationTier %></span></div>
          <div class="attr"><span class="name">References:</span>
            <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Threat Materialization Chances.Relative Risk.References", :refAnchor, ', ' ) %>
          </div>

        <!-- STAGE 2 - Threat Materialization - Expressivity -->
        <h4 class="lvl4 title">Expressivity</h4>
          <div><span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesKey_text %></span></div>
          <div class="attr"><span class="name">Notes:</span> <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesNotes %></span></div>
          <div class="attr"><span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesTier %></span></div>
          <div class="attr"><span class="name">References:</span>
            <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Threat Materialization Chances.Expressivity Notes.References", :refAnchor, ', ' ) %>
          </div>
      </div>

    <!-- STAGE 2 - Nature of Intervention -->
    <span class="lvl3 title">Nature of Intervention</span>
      <div><span class="value text"><%= @actionabilitydocidStage_2Acceptability_of_interventionNature_of_interventionKey_text %></span></div>
      <div class="attr"><span class="name">Notes:</span> <span class="value text"><%= @actionabilitydocidStage_2Acceptability_of_interventionNature_of_interventionNotes %></span></div>
      <div class="attr"><span class="name">References:</span>
        <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Acceptability of Intervention.Nature of Intervention.References", :refAnchor, ', ' ) %>
      </div>

    <!-- STAGE 2 - Nature of Intervention -->
    <span class="lvl3 title">Chance to Escape Clinical Detection</span>
      <div><span><%= @actionabilitydocidStage_2Condition_escape_detectionChance_to_escape_clinical_detectionKey_text %></span></div>
      <div class="attr"><span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Condition_escape_detectionChance_to_escape_clinical_detectionTier %></span></div>
      <div class="attr"><span class="name">Notes:</span> <span class="value text"><%= @actionabilitydocidStage_2Condition_escape_detectionChance_to_escape_clincial_detectionNotes %></span></div>
      <div class="attr"><span class="name">References:</span>
        <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.References", :refAnchor, ', ' ) %>
      </div>
  </div>

<!-- SCORING -->
<span id="scoring" class="lvl2 title scoring">Scoring of Outcome Intervention Pairs <span class="status">(Status: <%= @actionabilitydocidScoreStatus %>)</span></span>
  <div class="section scoring">

    <div class="table headers scores">
      <div class="row header">
        <div class="cell outcome">Outcome</div>
        <div class="cell">
          <div class="table intervention">
            <div class="row intervention">
              <div class="cell intervention">Intervention</div>
              <div class="cell severity">Severity</div>
              <div class="cell likelihood">Likelihood</div>
              <div class="cell effectiveness">Effectiveness</div>
              <div class="cell noi">NOI</div>
              <div class="cell overall">Overall</div>
            </div>
          </div>
        </div>
      </div>
      <%= @__producer.render_each( "ActionabilityDocID.Score.Final Scores.Outcomes", :outcomeScore) %>
    </div>
      <div class="attr"><span class="name">Date:</span> <span class="value line"><%= @actionabilitydocidScoreFinal_scoresMetadataDate %></span></div>
      <div class="attr"><span class="name">Format:</span> <span class="value line"><%= @actionabilitydocidScoreFinal_scoresMetadataMedia %></span></div>
      <div class="attr"><span class="name">Scorers Present:</span> <%#= @__producer.render_each(
        "ActionabilityDocID.Score.Final Scores.Metadata.Scorers Present",
        %q^<span><!%= @scorer %!></span>^ ) %>
      </div>
  </div>

<!-- References -->
<span id="references" class="lvl2 title">References</span>
  <div class="section">

    <%# RENDER_EACH( :mediumRef, :__allRefs ) %>
  </div>
