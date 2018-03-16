
// Add name=value parameter to url
// * Will replace existing NVP
// * Will escape the *value*
// * Deals with existing empty parameter
function addUrlNVP(url, name, value) {
  var re = new RegExp("\\b(" + name + "=[^&]*)", "gi");

  function add(sep) {
    url += ( sep + name + "=" + encodeURIComponent(value) ) ;
  }

  function change() {
    url = url.replace(re, "gi") ;
    add("") ;
  }

  if( url.indexOf("?") === -1 ) {
    add("?");
  }
  else {
    if( re.test(url) ) {
      change();
    }
    else {
      add("&");
    }
  }
}
