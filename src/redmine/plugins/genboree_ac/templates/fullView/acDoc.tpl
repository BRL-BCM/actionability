<span class="lvl1 title"><%= @actionabilitydocidSyndrome %> <span class="status">(Status: <%= @actionabilitydocidStatus %>)</span></span>
  <div class="section">
    <% if(@actionabilitydocidSyndromeOverview or !@__opts[:trim]) %>
      <div class="keytext"><span><%= @actionabilitydocidSyndromeOverview %></span></div>
    <% end %>
    <div class="attrs">
      <% if(@actionabilitydocidSyndromeAcronyms or !@__opts[:trim]) %>
        <div class="attr"><span class="name">Aliases:</span>
          <% if(num('ActionabilityDocID.Syndrome.Acronyms') > 0) %>
            <%= @__producer.render_each(
                  'ActionabilityDocID.Syndrome.Acronyms',
                  %q^<span class="value"><!%= @acronym %!></span>^,
                  '; ') %>
          <% else %>
            [None provided]
          <% end %>
        </div>
      <% end %>
      <% if(@actionabilitydocidSyndromeOmimids or !@__opts[:trim] ) %>
        <div class="attr"><span class="name">OMIM:</span> <span class="omim list"><%= @__producer.render_each(
          "ActionabilityDocID.Syndrome.OmimIDs",
          %q^<span class="value"><a target="__blank" href="http://www.omim.org/entry/<!%= @omimid %!>"><!%= @omimid %!></a></span>^,
          ', ' ) %></span>
        </div>
      <% end %>
      <% if(@actionabilitydocidSyndromeOrphanetids or !@__opts[:trim]) %>
        <div class="attr"><span class="name">Orphanet:</span> <span class="orphanet list"><%= @__producer.render_each(
          "ActionabilityDocID.Syndrome.OrphanetIDs",
          %q^<span class="value"><a target="__blank" href="http://www.orpha.net/consor/cgi-bin/OC_Exp.php?Expert=<!%= @orphanetid %!>"><!%= @orphanetid %!></a></span>^,
          ', ' ) %></span>
        </div>
      <% end %>
    </div>

    <!-- GENES -->
    <span id="genes" class="lvl3 title">Genes: <span><%= @__producer.render_each(
      "ActionabilityDocID.Genes",
      %q^<span><a target="__blank" href="http://www.omim.org/entry/<!%= @geneGeneomim %!>"><!%= @gene %!></a></span>^,
      ', ' ) %>
    </span></span>
  </div>

<!-- STAGE 1 -->
<span id="stage1" class="lvl2 title stage1">Stage 1 - Rule-Out Board: <span class="status">(Status: <%= e?('ActionabilityDocId.Stage 1.Final Stage 1 Report.Status') ? @actionabilitydocidStage_1Final_stage1_reportStatus : '[Not Set]' %>)</span></span>
  <div class="section stage1">

    <!-- STAGE 1 - Actionability -->
    <span class="lvl3 title">Actionability</span>
      <% q1IsYes = (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Practice Guideline').to_s.strip.downcase == 'yes') %>
      <div class="qna"><span class="question">1. Is there a practice guideline for systematic review for the genetic condition?</span>
        <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityPractice_guideline.to_s.downcase %>">
          <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityPractice_guideline || '[Unknown]' %>
        </span>
      </div>
      <% q2IsYes = (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable.Yes for 1 or more above').to_s.strip.downcase == 'yes') %>
      <div class="qna"><span class="question">2. Does the practice guideline or systematic review indicate that the result is actionable in one or more of the following ways?</span>
        <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableYes_for_1_or_more_above.to_s.downcase %>">
          <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableYes_for_1_or_more_above || '[Unknown]' %>
        </span>
      </div>
        <div class="depth2">
          <div class="qna"><span class="question">Patient management?</span>
            <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionablePatient_management.to_s.downcase %>">
              <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionablePatient_management || '[Unknown]' %>
            </span>
          </div>
          <div class="qna"><span class="question">Surveillance or screening?</span>
            <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableSurveillance_or_screening.to_s.downcase %>">
              <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableSurveillance_or_screening || '[Unknown]' %>
            </span>
          </div>
          <div class="qna"><span class="question">Family management?</span>
            <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableFamily_management.to_s.downcase %>">
              <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableFamily_management || '[Unknown]' %>
            </span>
          </div>
          <div class="qna"><span class="question">Circumstances to avoid?</span>
            <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableCircumstances_to_avoid.to_s.downcase %> ">
              <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionableCircumstances_to_avoid || '[Unknown]' %>
            </span>
          </div>
        </div>
      <% q3IsYes = (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Actionability.Result Actionable in undiagnosed').to_s.strip.downcase == 'yes') %>
      <div class="qna"><span class="question">3. Is the result actionable in an undiagnosed adult with the genetic condition?</span>
        <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionable_in_undiagnosed.to_s.downcase %>">
          <%= @actionabilitydocidStage_1Final_stage1_reportActionabilityResult_actionable_in_undiagnosed || '[Unknown]' %>
        </span>
      </div>

    <!-- STAGE 1 - Penetrance -->
    <span class="lvl3 title">Penetrance</span>
      <% q4IsYes = (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Penetrance.Moderate Penetrance Variant').to_s.strip.downcase == 'yes') %>
      <div class="qna"><span class="question">4. Is there at least one known pathogenic variant with at least moderate penetrance (>=40%) or moderate relative risk (>=2) in any population?</span>
        <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportPenetranceModerate_penetrance_variant.to_s.downcase %>">
          <%= @actionabilitydocidStage_1Final_stage1_reportPenetranceModerate_penetrance_variant || '[Unknown]' %>
        </span>
      </div>

    <!-- STAGE 1 - Significance/Burden of Disease -->
    <span class="lvl3 title">Significance/Burden of Disease</span>
      <% q5IsYes = (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Significance of Disease.Important Health Problem').to_s.strip.downcase == 'yes') %>
      <div class="qna"><span class="question">5. Is this condition an important health problem?</span>
        <span class="answer yesno <%= @actionabilitydocidStage_1Final_stage1_reportSignificance_of_diseaseImportant_health_problem.to_s.downcase %>">
          <%= @actionabilitydocidStage_1Final_stage1_reportSignificance_of_diseaseImportant_health_problem || '[Unknown]' %>
        </span>
      </div>

    <!-- STAGE 1 - Exception (special) -->
    <% q6IsYes = isYes = (q2IsYes and q3IsYes and q4IsYes and q5IsYes) %>
    <span class="lvl3 title">Exception</span>
      <div class="qna"><span class="question">6. Are Actionability (Q2-3), Penetrance (Q4), and Significance (Q5) all &quot;YES&quot;?</span>
        <span class="answer yesno <%= q6IsYes ? 'yes' : 'no' %>"> <%= q6IsYes ? 'Yes' : 'No' %></span>
      </div>
      <% if( (pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Need for making exception.Exception Made').to_s.strip.downcase == 'yes') ) %>
        <div class="depth2">
          <div class="qna"><span class="question">Exception granted?</span>
            <span class="answer yesno yes">
              Yes
            </span>
          </div>
          <% if( e?('ActionabilityDocID.Stage 1.Final Stage1 Report.Need for making exception.Exception Made.Note why exception made') ) %>
            <div class="qna"><span class="question">Why was an exception made?</span>
              <span class="answer">
                <%= pv('ActionabilityDocID.Stage 1.Final Stage1 Report.Need for making exception.Exception Made.Note why exception made') %>
              </span>
            </div>
          <% end %>
        </div>
      <% end %>

    <!-- STAGE 1 - Final Stage1 Report Nodes -->
    <% if(@actionabilitydocidStage_1Final_stage1_reportNotes or !@__opts[:trim]) %>
      <span class="lvl3 title">Notes:</span>
        <div class="value text"><%= @actionabilitydocidStage_1Final_stage1_reportNotes %></div>
    <% end %>

  </div>

<!-- STAGE 2 -->
<span id="stage2" class="lvl2 title stage2">Stage 2 - Summary Report <span class="status">(Status: <%= @actionabilitydocidStage_2Status %>)</span></span>
  <div class="section stage2">

    <!-- STAGE 2 - Outcomes / Interventions Summary -->
    <% if(@__kbDoc.getPropItems('ActionabilityDocID.Stage 2.Outcomes') or !@__opts[:trim]) %>
      <span class="lvl3 title">Outcomes &amp; Interventions Summary</span>
        <div class="table ois">
          <div class="header row">
            <div class="cell outcome">Outcome</div>
            <div class="cell intervention">Intervention</div>
          </div>
          <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Outcomes", :outcome) %>
        </div>
    <% end %>

    <!-- STAGE 2 - Nature of the Threat -->
    <% if(@__kbDoc.getPropValueObj("ActionabilityDocID.Stage 2.Nature of the Threat")) %>
      <span class="lvl3 title">Nature of the Threat</span>
        <div class="subSection">
          <!-- STAGE 2 - Nature of the Threat - Prevalence -->
          <span class="lvl4 title">Prevalence of the Genetic Disorder: <span class="value"> <%= @actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderKey_text %></span></span>
          <% if(@actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderNotes) %>
            <span class="value keytext"><%= @actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderNotes %></span>
          <% end %>
          <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder.References") or !@__opts[:trim]) %>
            <span class="refs inline sup">
              [<%= @__producer.render_each(
                  "ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder.References",
                  %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                  ', ' ) %>]
            </span>
          <% end %>
          <div class="attrs">
            <% if(@actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderAdditional_fieldsSource_of_population) %>
              <div class="attr"><span class="name">Source Population:</span> <span class="value line"><%= @actionabilitydocidStage_2Nature_of_the_threatPrevalence_of_the_genetic_disorderAdditional_fieldsSource_of_population %></span></div>
            <% end %>
          </div>

          <!-- STAGE 2 - Nature of the Threat - Clinical Features -->
          <span class="lvl4 title">Clinical Features</span>
            <div class="value keytext">
              <%= pv('ActionabilityDocID.Stage 2.Nature of the Threat.Clinical Features.Key Text') %>
              <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Nature of the Threat.Clinical Features.References") or !@__opts[:trim]) %>
                <span class="refs inline sup">
                  [<%= @__producer.render_each(
                        "ActionabilityDocID.Stage 2.Nature of the Threat.Clinical Features.References",
                        %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                        ', ' ) %>]
                </span>
              <% end %>
            </div>
  
          <!-- STAGE 2 - Nature of the Threat - Natural History -->
          <span class="lvl4 title">Natural History</span>
            <div class="value keytext">
              <%= @actionabilitydocidStage_2Nature_of_the_threatNatural_historyKey_text %>
                <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Nature of the Threat.Natural History.References") or !@__opts[:trim]) %>
                  <span class="refs inline sup">
                    [<%= @__producer.render_each(
                          "ActionabilityDocID.Stage 2.Nature of the Threat.Natural History.References",
                          %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                          ', ' ) %>]
                  </span>
                <% end %>
            </div>
        </div>
    <% end %>

    <!-- STAGE 2 - Effectiveness of Intervention -->
    <% if(@__kbDoc.getPropValueObj("ActionabilityDocID.Stage 2.Effectiveness of Intervention")) %>
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
    <% end %>

    <!-- STAGE 2 - Threat Materialization -->
    <% if(@__kbDoc.getPropValueObj("ActionabilityDocID.Stage 2.Threat Materialization Chances")) %>
      <span class="lvl3 title">Threat Materialization</span>
        <div class="subSection">
          <!-- STAGE 2 - Threat Materialization - Mode of Inheritance -->
          <span class="lvl4 title">Mode of Inheritance: <span class="value"><%= @actionabilitydocidStage_2Threat_materialization_chancesMode_of_inheritanceKey_text %></span></span>
        </div>

          <!-- STAGE 2 - Threat Materialization - Prevalence of Genetic Mutations -->
        <div class="subSection">
          <span class="lvl4 title">Prevalence of Genetic Mutations: <span class="value"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationKey_text %></span></span>
          <% if(@actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationNotes) %>
              <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationNotes %></span>
          <% end %>
          <% if(@actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationTier) %>
              <span class="tier">(<span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationTier %></span>)</span>
          <% end %>
          <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.References") or !@__opts[:trim]) %>
              <span class="refs inline sup">
                [<%= @__producer.render_each(
                      "ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.References",
                        %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                        ', ' ) %>]
              </span>
          <% end %>
          <div class="attrs">
            <% if(@actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationAdditional_fieldsSource_of_population_for_this_prevalence) %>
              <div class="attr">
                <span class="name">Source Population:</span>
                <span class="value line"><%= @actionabilitydocidStage_2Threat_materialization_chancesPrevalence_of_the_genetic_mutationAdditional_fieldsSource_of_population_for_this_prevalence %></span>
              </div>
            <% end %>
             <% if(@__producer.kbDoc.getPropItems('ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Outcomes') or !@__opts[:trim]) %>
               <div class="attr"><span class="name">Outcomes:</span>
                   <ul class="outcomes">
                     <%= @__producer.render_each(
                           'ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Outcomes',
                           %q^<li><!%= @outcome %!></li>^ ) %>
                   </ul>
               </div>
             <% end %>
          </div>
        </div>
  
        <!-- STAGE 2 - Threat Materialization - Penetrance -->
        <span class="lvl4 title">Penetrance</span>
          <div class="subSection">
            <%= @__producer.render_each( "ActionabilityDocID.Stage 2.Threat Materialization Chances.Penetrances", :penetrance ) %>
          </div>
  
          <!-- STAGE 2 - Threat Materialization - Relative Risk -->
          <span class="lvl4 title">Relative Risk: <span class="value"> <%= @actionabilitydocidStage_2Threat_materialization_chancesRelative_riskKey_text %></span></span>
          <% if(@actionabilitydocidStage_2Threat_materialization_chancesRelative_riskNotes) %>
              <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesRelative_riskNotes %></span>
          <% end %>
          <% if(@actionabilitydocidStage_2Threat_materialization_chancesRelative_riskTier) %>
              <span class="tier">(<span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Threat_materialization_chancesRelative_riskTier %></span>)</span>
          <% end %>
          <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Threat Materialization Chances.Relative Risk.References") or !@__opts[:trim]) %>
              <span class="refs inline sup">
                [<%= @__producer.render_each(
                      "ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.References",
                        %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                        ', ' ) %>]
              </span>
          <% end %>

          <!-- STAGE 2 - Threat Materialization - Expressivity -->
          <span class="lvl4 title">Expressivity: </span> <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesKey_text %></span>
          <% if(@actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesNotes) %>
            <span class="value text"><%= @actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesNotes %></span>
          <% end %>
          <% if(@actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesTier) %>
            <span class="tier">(<span class="name">Tier:</span> <span class="value tier"><%= @actionabilitydocidStage_2Threat_materialization_chancesExpressivity_notesTier %></span>)</span>
          <% end %>
          <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Threat Materialization Chances.Expressivity Notes.References") or !@__opts[:trim]) %>
            <span class="refs inline sup">
              [<%= @__producer.render_each(
                    "ActionabilityDocID.Stage 2.Threat Materialization Chances.Expressivity Notes.References",
                    %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                    ', ' ) %>]
            </span>
          <% end %>
    <% end %>

    <!-- STAGE 2 - Acceptablility of Intervention -->
    <% if(@__kbDoc.getPropValueObj("ActionabilityDocID.Stage 2.Acceptability of Intervention")) %>
      <span class="lvl3 title">Nature of Intervention:</span> <span class="value text"><%= @actionabilitydocidStage_2Acceptability_of_interventionNature_of_interventionKey_text %></span>
        <% if(@actionabilitydocidStage_2Acceptability_of_interventionNature_of_interventionNotes) %>
          <span class="value text"><%= @actionabilitydocidStage_2Acceptability_of_interventionNature_of_interventionNotes %></span>
        <% end %>
        <% if(@__kbDoc.getPropItems('ActionabilityDocID.Stage 2.Acceptability of Intervention.Nature of Intervention.References') or !@__opts[:trim]) %>
            <span class="refs inline sup">
              [<%= @__producer.render_each(
                    'ActionabilityDocID.Stage 2.Acceptability of Intervention.Nature of Intervention.References',
                    %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                    ', ' ) %>]
            </span>
        <% end %>
    <% end %>

    <!-- STAGE 2 - Condition Escape Detection -->
    <% if(@__kbDoc.getPropValueObj("ActionabilityDocID.Stage 2.Condition Escape Detection")) %>
      <span class="lvl3 title">Chance to Escape Clinical Detection: </span><span class="value text"><%= pv('ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.Key Text') %></span>
        <% if( e?('ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.Notes') or !@__opts[:trim]) %>
          <span class="value text"><%= pv('ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.Notes') %></span>
        <% end %>
        <% if( e?('ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.Tier') ) %>
           <span class="tier">(<span class="name">Tier:</span> <span class="value tier"><%= pv('ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.Tier') %></span>)</span>
        <% end %>
        <% if(@__kbDoc.getPropItems("ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.References") or !@__opts[:trim]) %>
            <span class="refs inline sup">
              [<%= @__producer.render_each(
                  "ActionabilityDocID.Stage 2.Condition Escape Detection.Chance to Escape Clinical Detection.References",
                  %q^<span class="refNum"><a href="#ref_%<!%= @reference %!>%">ref_displ_%<!%= @reference %!>%</a></span>^,
                  ', ' ) %>]
            </span>
        <% end %>
    <% end %>
  </div>

<!-- SCORING -->
<span id="scoring" class="lvl2 title scoring">Scoring of Outcome Intervention Pairs <span class="status">(Status: <%= @actionabilitydocidScoreStatus %>)</span></span>
  <% if(@__kbDoc.getPropValueObj("ActionabilityDocID.Score.Final Scores")) %>
  <div class="section scoring">

    <div class="scores container-fluid">
      <div class="row header">
        <div class="outcome col text-left col-xs-2">Outcome</div>
        <div class="interventions col col-xs-10">
          <div class="intervention wrapper row">
            <div class="intervention col text-left col-xs-3">Intervention</div>
            <div id="severityScoring" class="severity col text-center col-xs-2"><a class="poTrigger" role="button" tabindex="0">Severity <span class="fa fa-question-circle-o"></span></a></div>
            <div id="likelihoodScoring" class="likelihood col text-center col-xs-2"><a class="poTrigger" role="button" tabindex="0">Likelihood <span class="fa fa-question-circle-o"></span></a></div>
            <div id="effectivenessScoring" class="effectiveness col text-center col-xs-2"><a class="poTrigger" role="button" tabindex="0">Effectiveness <span class="fa fa-question-circle-o"></span></a></div>
            <div id="noiScoring" class="noi col text-center col-xs-2"><a class="poTrigger" role="button" tabindex="0">NOI <span class="fa fa-question-circle-o"></span></a></div>
            <div id="overallScoring" class="overall col text-center col-xs-1"><a class="poTrigger" role="button" tabindex="0">Overall <span class="fa fa-question-circle-o"></span></a></div>
          </div>
        </div>
      </div>
      <%= @__producer.render_each('ActionabilityDocID.Score.Final Scores.Outcomes', :outcomeScore) %>
    </div>

      <% if(@actionabilitydocidScoreFinal_scoresMetadataDate or !@__opts[:trim]) %>
        <div class="attr"><span class="name">Date:</span> <span class="value line"><%= @actionabilitydocidScoreFinal_scoresMetadataDate %></span></div>
      <% end %>
      <% if(@actionabilitydocidScoreFinal_scoresMetadataMedia or !@__opts[:trim]) %>
        <div class="attr"><span class="name">Format:</span> <span class="value line"><%= @actionabilitydocidScoreFinal_scoresMetadataMedia %></span></div>
      <% end %>
      <% if(@__opts[:detailed] == :full) %>
        <div class="attr"><span class="name">Scorers Present:</span>
        <% if(@__kbDoc.getPropItems("ActionabilityDocID.Score.Final Scores.Metadata.Scorers Present") or !@__opts[:trim]) %>
          <%= @__producer.render_each(
            "ActionabilityDocID.Score.Final Scores.Metadata.Scorers Present",
            %q^<span><!%= @scorer %!></span>^,
            ', ') %>
        <% else %>
          <span class="missing">(Missing/Unknown)</span>
        <% end %>
        </div>
      <% end %>
    </div>
  <% else %>
    <div class="section"><span class="missing">(Final scoring not yet completed)</span></div>
  <% end %>


<!-- LITERATURE SEARCH SUMMARY -->
<%# if(@__opts[:detailed] == :full) %>
<span id="litSearch" class="lvl2 title">Literature Search Summary: <span class="status">(Status: <%= @actionabilitydocidLiteraturesearchStatus || '[Unknown]'%>)</span></span>
<% if( @__kbDoc.getPropItems("ActionabilityDocID.LiteratureSearch.Sources") or !@__opts[:trim]) %>
  <div class="section litSearch">
    <table class="litSources">
      <tr class="header">
        <td class="search-label">Label</td>
        <td class="search">Search</td>
        <td class="hits"># Hits</td>
        <td class="date">Date</td>
      </tr>
      <%= @__producer.render_each( "ActionabilityDocID.LiteratureSearch.Sources", :litSource) %>
    </table>
  </div>
<% else %>
  <div class="section"><span class="missing">(Missing/None)</span></div>
<% end %>
<%# end %>