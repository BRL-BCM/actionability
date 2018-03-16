function showMore(){
  var targetURL = kbMount+"/projects/"+projectId+'/genboree_ac/ui/docVersions?' ;
  $.ajax(targetURL, {
    method: 'GET',
    data: {
      skip: skip+showLimit,
      doc: docId,
      totalVers: totalVers
    },
    beforeSend: function(){
      $(".show-more-btn-container").remove() ;
      $('#spinningModal').modal('show') ;
    },
    success : function(data){
      $('#spinningModal').modal('hide') ;
      $(".versions-panel").append(data) ;
      skip += showLimit ;
    }
  }) ;
}