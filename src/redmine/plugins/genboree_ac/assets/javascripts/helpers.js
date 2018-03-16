function logout()
{
  var result = $.post(
    kbMount+"/logout",
    {
      "authenticity_token"  : csrf_token,
      _method: 'post',
    },
    function(respData, status, xhr) {
      location.href = kbMount ;
    }
  ).fail(function(respData, status, xhr) {
    location.href = kbMount ;
  }) ;
}


function reopenAcDoc(){
  var state = $('input[name="updateReleasedDocStatus"]').bootstrapSwitch('state') ;
  answer = ( state ? 'true' : 'false' ) ;
  var reqConfig = {
    method: "POST",
    success: function(response, opts) {
      $('#spinningModal').modal('hide') ;
      location.reload() ;
    },
    failure: function(response, opts) {
      $('#spinningModal').modal('hide') ;
      displayGenericAjaxCallbackErr(response) ;
    },
    url: kbMount+"/projects/"+projectId+'/genboree_ac/data/doc/reopen?'
  } ;
  reqConfig['params'] = {
    "authenticity_token"  : csrf_token,
    "docIdentifier"       : docIdentifier,
    "updateReleasedDoc"    : answer
  } ;
  $('#spinningModal').modal('show') ;
  Ext.Ajax.request( reqConfig );   
}