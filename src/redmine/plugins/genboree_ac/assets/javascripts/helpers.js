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
