var Ext = Ext || {}; // Ext namespace won't be defined yet...

// This function is called by the Microloader after it has performed basic
// device detection. The results are provided in the "tags" object. You can
// use these tags here or even add custom tags. These can be used by platform
// filters in your manifest or by platformConfig expressions in your app.
//
Ext.beforeLoad = function (tags) {
    var s = location.search,  // the query string (ex "?foo=1&bar")
        profile;

    // For testing look for "?classic" or "?modern" in the URL to override
    // device detection default.
    //
    if (s.match(/\bclassic\b/)) {
        profile = 'classic';
    }
    else if (s.match(/\bmodern\b/)) {
        profile = 'modern';
    }
    else {
        profile = tags.desktop ? 'classic' : 'modern';
        //profile = tags.phone ? 'modern' : 'classic';
    }

    // Set the correct manifest based on the app being loaded
    if (this.manifest.match(/entry/)) {
        Ext.manifest = '../sencha/sencha-apps/entry/app' ;
    }
    else if (this.manifest.match(/curation/)) {
        Ext.manifest = '../sencha/sencha-apps/curation/app' ;
    }
    else if (this.manifest.match(/fullview/)) {
        Ext.manifest = '../sencha/sencha-apps/fullview/app' ;
    }
    // This function is called once the manifest is available but before
    // any data is pulled from it.
    //
    return function (manifest) {
        //peek at / modify the manifest object
        //debugger ;
    };
};