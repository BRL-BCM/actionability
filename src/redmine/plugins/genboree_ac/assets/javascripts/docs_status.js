// JS functions used on the Docs status page.

function displayErrorModal(resp){
  var respObj ;
  var statusCode ;
  var statusMsg ;
  // Redmine thin is down/being restarted. We do not have the 'nice' response object with error code and msg
  if(resp.statusText == "Bad Gateway"){
    statusCode = "502" ;
    statusMsg = "No response from the application server. It is possible that the server is down or is being restarted. Please try again in a few seconds." ;
  }
  else{
    respObj = JSON.parse(resp.responseText) ;
    statusCode = ( (respObj.status && respObj.status.statusCode) ? respObj.status.statusCode : "Unknown" ) ;
    statusMsg = ( (respObj.status && respObj.status.msg) ? respObj.status.msg : "Unknown" ) ;
  }
  $("#errorModal .error-code .value").text(statusCode) ;
  $("#errorModal .error-msg .value").text(statusMsg) ;
  $("#errorModal").modal("show") ;
}

function showMoreDocs(){
  var targetURL = kbMount+"/projects/"+projectId+'/genboree_ac/ui/docsStatus?' ;
  skip += showLimit ;
  $.ajax(targetURL, {
    method: 'GET',
    data: {
      skip: skip,
      partialOnly: "true",
      showStatus: showStatus,
      matchOrderByStr: matchOrderByStr
    },
    beforeSend: function(){
      $(".total-docs-count-hidden-container").remove() ;
      $('#spinningModal').modal('show') ;
    },
    success : function(data){
      $('#spinningModal').modal('hide') ;
      $(".show-more-btn-container").before(data) ;
      skip += showLimit ;
      if(skip >= totalDocs){
        $(".show-more-btn-container").addClass("hide") ;
      }
      // Its possible that a newly added record that was added recently was retrieved. Remove it
      if(Object.keys(newlyAdded).length > 0){
        var rows = $(".row.value-row") ;
        for(var ii=0; ii<rows.length; ii++){
          var row = rows[ii] ;
          var docId = row.getAttribute("data-doc-id") ;
          if(!row.className.match(/new/) && newlyAdded[docId]){
            $(row).remove() ;
            delete newlyAdded[docId] ;
          }
        }
      }
      // Update the 'showing' text
      updateShowingDocsText() ;
      $(".total-docs-count-hidden-container").remove() ;
      $('[data-toggle="tooltip"]').tooltip();
    },
    error: function(data){
      $('#spinningModal').modal('hide') ;
      displayErrorModal(data) ;
    }
  }) ;
}

function showDocsWithStatus(status){
  if(status != showStatus) {
    var aEls = $(".filter.dropdown-menu").find("a span") ;
    for(var ii=0; ii<aEls.length; ii++){
      var aEl = aEls[ii] ;
      if(aEl.getAttribute("data-status") == status){
        $(aEl).addClass("glyphicon glyphicon-ok") ;
      }
      else{
        $(aEl).removeClass("glyphicon glyphicon-ok") ;
      }
    }
    var targetURL = kbMount+"/projects/"+projectId+'/genboree_ac/ui/docsStatus?' ;
    // Filter has been changed. Set skip to 0
    skip = 0 ;
    $.ajax(targetURL, {
      method: 'GET',
      data: {
        skip: 0,
        partialOnly: true,
        showStatus: status,
        matchOrderByStr: matchOrderByStr,
        queryTerm: queryTerm
      },
      beforeSend: function(){
        $(".total-docs-count-hidden-container").remove() ;
        $('#spinningModal').modal('show') ;
      },
      success : function(data){
        $('#spinningModal').modal('hide') ;
        $(".row.value-row").remove() ;
        $(".show-more-btn-container").before(data) ;
        skip = 0 ;
        newlyAdded = {} ;
        // No 'show More' with query term
        if(queryTerm === "") {
          var elWithDocsCount = $(".total-docs-count-hidden-container")[0] ;
          totalDocs = parseInt(elWithDocsCount.getAttribute("data-total-docs-count")) ;
          if(totalDocs <= showLimit){
            $(".show-more-btn-container").addClass("hide") ;
          }
          else{
            $(".show-more-btn-container").removeClass("hide") ;
          }
        }
        else{
          totalDocs = $(".row.value-row").length ;
        }
        updateShowingDocsText() ;
        $(".total-docs-count-hidden-container").remove() ;
        showStatus = status ;
        $('[data-toggle="tooltip"]').tooltip();
      },
      error: function(data){
        $('#spinningModal').modal('hide') ;
        displayErrorModal(data) ;
      }
    }) ;
  }
  else{
    return false ;
  }
}

function sortDocs(orderBy){
  var sortDirection = 'asc' ; // Hard coded for now. 
  if(orderBy != matchOrderByStr){
    var aEls = $(".order-by.dropdown-menu").find("a span") ;
    for(var ii=0; ii<aEls.length; ii++){
      var aEl = aEls[ii] ;
      if(aEl.getAttribute("data-order-by") == orderBy){
        $(aEl).addClass("glyphicon glyphicon-ok") ;
      }
      else{
        $(aEl).removeClass("glyphicon glyphicon-ok") ;
      }
    }
    var targetURL = kbMount+"/projects/"+projectId+'/genboree_ac/ui/docsStatus?' ;
    // Filter has been changed. Set skip to 0
    skip = 0 ;
    $.ajax(targetURL, {
      method: 'GET',
      data: {
        skip: 0,
        partialOnly: true,
        showStatus: showStatus,
        matchOrderByStr: orderBy,
        queryTerm: queryTerm
      },
      beforeSend: function(){
        $(".total-docs-count-hidden-container").remove() ;
        $('#spinningModal').modal('show') ;
      },
      success : function(data){
        $('#spinningModal').modal('hide') ;
        $(".row.value-row").remove() ;
        $(".show-more-btn-container").before(data) ;
        skip = 0 ;
        newlyAdded = {} ;
        // No 'show More' with query term
        if(queryTerm === "") {
          if(totalDocs <= showLimit){
            $(".show-more-btn-container").addClass("hide") ;
          }
          else{
            $(".show-more-btn-container").removeClass("hide") ;
          }
          updateShowingDocsText() ;
        }
        $(".total-docs-count-hidden-container").remove() ;
        matchOrderByStr = orderBy ;
        $('[data-toggle="tooltip"]').tooltip();
        var sortIndicatorEls = $(".sort-indicator") ;
        for(var ii=0; ii<sortIndicatorEls.length; ii++){
          var sel = sortIndicatorEls[ii] ;
          if(sel.getAttribute("data-sort-type") == matchOrderByStr){
            if(sortDirection == 'asc'){
              if(sel.className.match(/glyphicon-triangle-top/)){
                $(sel).removeClass("hide") ;
              }
              else{
                $(sel).addClass("hide") ;
              }
            }
            else{
              if(sel.className.match(/glyphicon-triangle-bottom/)){
                $(sel).removeClass("hide") ;
              }
              else{
                $(sel).addClass("hide") ;
              }
            }
          }
          else{
            $(sel).addClass("hide") ;
          }
        }
      },
      error: function(data){
        $('#spinningModal').modal('hide') ;
        displayErrorModal(data) ;
      }
    }) ;
  }
  else{
    return false ;
  }
}

function searchByTerm(){
  var term = $("#searchByTermInput").val() ;
  if(term !== ""){
    var targetURL = kbMount+"/projects/"+projectId+'/genboree_ac/ui/docsStatus?' ;
    skip = 0 ;
    $.ajax(targetURL, {
      method: 'GET',
      data: {
        skip: 0,
        partialOnly: true,
        showStatus: showStatus,
        matchOrderByStr: matchOrderByStr,
        queryTerm: term
      },
      beforeSend: function(){
        $(".total-docs-count-hidden-container").remove() ;
        $('#spinningModal').modal('show') ;
      },
      success : function(data){
        $('#spinningModal').modal('hide') ;
        newlyAdded = {} ;
        $(".row.value-row").remove() ;
        $(".show-more-btn-container").before(data) ;
        $(".show-more-btn-container").addClass("hide") ;
        totalDocs = $(".row.value-row").length ;
        updateShowingDocsText() ;
        $(".total-docs-count-hidden-container").remove() ;
        queryTerm = term ;
        $('[data-toggle="tooltip"]').tooltip();
      },
      error: function(data){
        $('#spinningModal').modal('hide') ;
        displayErrorModal(data) ;
      }
    }) ;
  }
  else{
    return false ;
  }
}

function updateShowingDocsText(){
  var showingRecs = $(".row.value-row").length ;
  var text = "Showing "+showingRecs+" of "+totalDocs+" topics" ;
  $(".docs-count-text span").text(text) ;
}

function resetIfEmpty(){
  var term = $("#searchByTermInput").val() ;
  if(term === "" && queryTerm !== ""){
    var targetURL = kbMount+"/projects/"+projectId+'/genboree_ac/ui/docsStatus?' ;
    skip = 0 ;
    $.ajax(targetURL, {
      method: 'GET',
      data: {
        skip: 0,
        partialOnly: true,
        showStatus: showStatus,
        matchOrderByStr: matchOrderByStr,
        queryTerm: ""
      },
      beforeSend: function(){
        $(".total-docs-count-hidden-container").remove() ;
        $('#spinningModal').modal('show') ;
      },
      success : function(data){
        $('#spinningModal').modal('hide') ;
        $(".row.value-row").remove() ;
        $(".show-more-btn-container").before(data) ;
        skip = 0 ;
        var elWithDocsCount = $(".total-docs-count-hidden-container")[0] ;
        totalDocs = parseInt(elWithDocsCount.getAttribute("data-total-docs-count")) ;
        if(totalDocs <= showLimit){
          $(".show-more-btn-container").addClass("hide") ;
        }
        else{
          $(".show-more-btn-container").removeClass("hide") ;
        }
        updateShowingDocsText() ;
        $(".total-docs-count-hidden-container").remove() ;
        queryTerm = "" ;
        $('[data-toggle="tooltip"]').tooltip();
      },
      error: function(data){
        $('#spinningModal').modal('hide') ;
        displayErrorModal(data) ;
      }
    }) ;
  }
  else{
    return true ;
  }
}

// Get all docs that match the entered syndrome/disease and make sure they all have DIFFERENT genes associated with them
function validateCreateNewForm(){
  $.ajax(kbMount+'/projects/'+projectId+'/genboree_ac/data/docs/actionDocs', {
    method: 'GET',
    data: {
      "matchProp"           : "ActionabilityDocID.Syndrome",
      "matchValues"          : $("#syndromeInput").val(),
      "matchMode"           : 'exact'
    },
    beforeSend: function(){
      $('#spinningModal').modal('show') ;
    },
    success : function(data){
      
      var docs = JSON.parse(data)['data'] ;
      if(docs.length > 0){
        var enteredGenes = $("#genesInput").tagsinput("items") ;
        var ii ;
        var lookup = {} ;
        for(ii=0; ii<enteredGenes.length; ii++){
          lookup[enteredGenes[ii].toUpperCase()] = true ;
        }
        var geneSyndromeComboExists = false ;
        var existingGene ;
        for(ii=0; ii<docs.length; ii++){
          var geneList = docs[ii].ActionabilityDocID.properties.Genes.items ;
          for(var jj=0; jj<geneList.length; jj++){
            var gene = geneList[jj].Gene.value ;
            if(lookup[gene]){
              geneSyndromeComboExists = true ;
              existingGene = gene ;
              break ;
            }
          }
        }
        if(geneSyndromeComboExists){
          $('#spinningModal').modal('hide') ;
          $(".submit-failed.alert").removeClass("hide") ;
          $(".submit-failed-error-msg").remove() ;
          if($(".submit-failed.alert").length === 0) {
            var markup = getDismissableAlertForFailedSubmit() ;
            $(".form-group.submit-btn-container").before(markup) ;
          }
          $(".submit-failed.alert").append("<span class=\"submit-failed-error-msg\"><strong>ERROR:</strong> A document with the gene: "+existingGene+" already exists for the syndrome you have entered. Creating duplicate Gene-Disease pairs is not allowed.</span>") ;
        }
        else{
          submitCreateNewForm() ;
        }
      }
      else{
        submitCreateNewForm() ;
      }
    },
    error: function(data){
      $('#spinningModal').modal('hide') ;
      console.log("Failed request to get docs with the entered syndrome.") ;
      displayErrorModal(data) ;
    }
  }) ;
}

function submitCreateNewForm(){
  $(".submit-failed.alert").addClass("hide") ;
  var acDoc = createAcTemplateDoc() ;
  var params = {} ;
  params[csrf_param] = csrf_token ;
  params.acdoc = JSON.stringify(acDoc) ;
  params.getOtherParams = true ;
  $.ajax({
    type: "POST",
    data: params,
    url: kbMount+'/projects/'+projectId+'/genboree_ac/data/doc/actionDocSave',
    success: function(data){
      $(".docs-count-text-container").removeClass("hide") ;
      $(".versions-panel.panel.panel-info").removeClass("hide") ;
      $(".well-lg.no-docs").addClass("hide") ;
      $('#spinningModal').modal('hide') ;
      $("#createNewModal").modal("hide") ;
      var resp = JSON.parse(data)['data'] ;
      $("#createNewSuccessModal").modal("show") ;
      $("#createNewSuccessModal .modal-body .doc-id").text(resp.ActionabilityDocID.value) ;
      $(".curation-link-btn")[0].href = kbMount+'/projects/'+projectId+'/genboree_ac/ui/curation?doc='+resp.ActionabilityDocID.value ;
      addNewRecToGrid(resp) ;
      newlyAdded[resp.ActionabilityDocID.value] = true ;
      $('[data-toggle="tooltip"]').tooltip();
    },
    error: function(data){
      $("#createNewModal").modal("hide") ;
      displayErrorModal(data) ;
    }
  });
  console.log(acDoc) ;
  console.log("Form submitted") ;
}

function addNewRecToGrid(apiRespObj) {
  var docId = apiRespObj.ActionabilityDocID.value ;
  var genItems = apiRespObj.ActionabilityDocID.properties.Genes.items ;
  var genes = [] ;
  var ii ;
  for(ii=0; ii<genItems.length; ii++) {
    genes.push(genItems[ii]['Gene']['value']) ;
  }
  var gridColSizes = JSON.parse(gridColSizesJSON) ;
  var gridCols = ['syndrome', 'genes', 'lastEdited', 'status'] ;
  var lastEdited = apiRespObj.editedon ;
  var lastEditedEls = lastEdited.split(" ") ;
  var timeEl = lastEditedEls.pop() ;
  var col2Val = {
    'syndrome': apiRespObj.ActionabilityDocID.properties.Syndrome.value,
    'genes': genes,
    'lastEdited': lastEditedEls.join(" "),
    'status': apiRespObj.ActionabilityDocID.properties['Status'].value
  } ;
  genes = genes.sort().join(", ") ;
  var markup = "<div class=\"row value-row new\">" ;
  for(ii=0; ii<gridCols.length; ii++){
    
    var col = gridCols[ii] ;
    markup += ( "<div class=\"col-xs-12 "+gridColSizes.md[col]+" col text-center " );
    if(col != "lastEdited"){
      markup += col ;
    }
    else{
      markup += " last-edited" ;
    }
    markup += "\">" ;
    if(col != "status"){
      if(col == 'syndrome'){
        markup += ( '<span class="label label-success">' + 'New!' + '</span> ' );
      }
      if(col == 'lastEdited'){
        markup += '<span class="value" data-toggle="tooltip" data-html="true" title="<b>Date:</b> '+col2Val[col]+'<br/><b>Time:</b>'+timeEl+'" >'+col2Val[col]+'</span>' ;
      }
      else{
        markup += col2Val[col] ;  
      }
    }
    else{
      markup += "<div class=\"row\">" ;
      markup += '<div class="col-xs-12 col-md-8 ">' ;
      markup += ( "<span class=\"label label-info\">"+col2Val[col]+"</span>" ) ;
      markup += "</div>" ;
      markup += getActionLinksCol(docId, gridColSizes) ;
      markup += "</div>" ;
    }
    markup += "</div>" ;
  }
  
  markup += "</div>" ;
  $(".row.header").after(markup) ;
  var showing = $(".row.value-row").length ;
  totalDocs = ( parseInt(totalDocs) + 1 ) ;
  $(".docs-count-text span").text("Showing "+showing+" of "+totalDocs+" topics") ;
  window.scrollTo(0, 0) ;
}

function getActionLinksCol(docId, gridColSizes){
  var markup = "<div class=\"col-xs-12 col-md-4 \">" ;
  markup += "<span>" ;
  markup += '<a href="ui/stg1RuleOutRpt?doc='+docId+'" data-trigger="hover" data-toggle="tooltip" title="View Stage1 report" class="report-link"><i class="fa fa-list-ul"></i></a>' ;
  markup += '<a href="ui/stg2SummaryRpt?doc='+docId+'" data-trigger="hover" data-toggle="tooltip" title="View Stage2 report" class="report-link"><i class="fa fa-file-text"></i></a>' ;
  markup += '<a href="ui/docVersions?doc='+docId+'" data-trigger="hover" data-toggle="tooltip" title="View all edit versions of this document" class="report-link"><i class="fa fa fa-history"></i></a>' ;
  markup += '<a href="'+kbMount+'/projects/'+projectId+'/genboree_ac/ui/curation?doc='+docId+'" data-trigger="hover" data-toggle="tooltip" title="Go to the curation interface" class="report-link"><i class="glyphicon glyphicon-edit"></i></a>' ;
  markup += "</span>" ;
  markup += "</div>" ;
  return markup ;
  
}

function createAcTemplateDoc() {
  var actionDocObj = {} ;
  actionDocObj.ActionabilityDocID = {} ;
  actionDocObj.ActionabilityDocID.value = "" ;
  actionDocObj.ActionabilityDocID.properties = {} ;
  actionDocObj.ActionabilityDocID.properties.Genes = {"items": [] } ;
  actionDocObj.ActionabilityDocID.properties["Status"] = {"value": "Entered"} ;
  actionDocObj.ActionabilityDocID.properties["Syndrome"] = {"value": $("#syndromeInput").val() } ;
  actionDocObj.ActionabilityDocID.properties.Syndrome.properties = {} ;
  actionDocObj.ActionabilityDocID.properties.Syndrome.properties.OmimIDs  = {"items": [] } ;
  actionDocObj.ActionabilityDocID.properties.Syndrome.properties.OrphanetIDs  = {"items": [] } ;
  var omims = $("#omimInput").tagsinput("items") ;
  for(var oo=0; oo<omims.length; oo++) {
    actionDocObj.ActionabilityDocID.properties.Syndrome.properties.OmimIDs.items.push({"OmimID": {"value" : omims[oo]}});
  }
  var orphanets = $("#orphanetInput").tagsinput("items") ;
  for(var or=0; or<orphanets.length; or++) {
    actionDocObj.ActionabilityDocID.properties.Syndrome.properties.OrphanetIDs.items.push({"OrphanetID": {"value" : orphanets[or]}});
  }

  actionDocObj.ActionabilityDocID.properties["Score"] = {"properties": {"Status" : {"value" : "Incomplete"}}} ;
  var genes = $("#genesInput").tagsinput("items") ;
  for(var gg=0; gg<genes.length; gg++) {
    actionDocObj.ActionabilityDocID.properties.Genes.items.push({"Gene": {"value" : genes[gg].toUpperCase(), "properties" : {"HGNCId" : {"value" : ""}, "GeneOMIM":{"value": ""}}}});
  } 

  actionDocObj.ActionabilityDocID.properties["Stage 1"]  = getStage1Obj() ;
  actionDocObj.ActionabilityDocID.properties["Stage 2"]  = getStage2Obj() ;
  console.log(actionDocObj) ;
  return actionDocObj ;
}

function getStage2Obj() {
  var stage2Obj = {} ;
  stage2Obj.properties = {
    "Condition Escape Detection": {
      "properties": {
      },
      "value": null
    },
    "Effectiveness of Intervention": {
      "properties": {
      },
      "value": null
    },
    "Status": {
      "value": "Incomplete"
    },
    "Threat Materialization Chances": {
      "properties": {
      },
      "value": null
    },
    "Nature of the Threat": {
      "properties": {
      },
      "value": null
    }
  } ;
  stage2Obj.value = null ;
  return stage2Obj ;
}

function getStage1Obj() {
  var stage1Obj = {} ;
  stage1Obj.properties = {} ;
  stage1Obj.value = null ;
  return stage1Obj ;
}


function getDismissableAlertForFailedSubmit(){
  return '<div class="alert alert-danger  submit-failed alert-dismissible" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button></div>' ;
}
