(function(){

  // the minimum version of jQuery we want
  var v = "1.3.2";

  // check prior inclusion and version
  if (window.jQuery === undefined || window.jQuery.fn.jquery < v) {
    var done = false;
    var script = document.createElement("script");
    script.src = "http://ajax.googleapis.com/ajax/libs/jquery/" + v + "/jquery.min.js";
    script.onload = script.onreadystatechange = function(){
      if (!done && (!this.readyState || this.readyState == "loaded" || this.readyState == "complete")) {
        done = true;
        initMyBookmarklet();
      }
    };
    document.getElementsByTagName("head")[0].appendChild(script);
  } else {
    initMyBookmarklet();
  }

  function initMyBookmarklet() {
    (window.myBookmarklet = function() {
      window.open("http://google.com", "ll-bookmarklet-form", 'width=800,height=400,scrollbars=yes');
//      $("body").append("\
//      <div id='ll-post-form'>\
//        <div id='ll-loading' style=''>\
//          <p>Loading...</p>\
//        </div>\
//        <iframe src='http://localhost:3000/pages/about' onload=\"$('#ll-post-form iframe').slideDown(500);\">Enable iFrames.</iframe>\
//        <style type='text/css'>\
//          #ll-loading { display: none; position: fixed; width: 100%; height: 100%; top: 0; left: 0; background-color: rgba(255,255,255,.25); cursor: pointer; z-index: 900; }\
//          #ll-loading p { color: black; font: normal normal bold 20px/20px Helvetica, sans-serif; position: absolute; top: 50%; left: 50%; width: 10em; margin: -10px auto 0 -5em; text-align: center; }\
//          #ll-post-form iframe { display: none; position: fixed; top: 10%; left: 10%; width: 500px; height: 400px; z-index: 999; border: 10px solid rgba(0,0,0,.5); margin: -5px 0 0 -5px; }\
//        </style>\
//      </div>");
//      $("#ll-loading").fadeIn(750);
    })();
  }

})();