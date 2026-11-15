(function($) {
  "use strict";

  return $(document).on("click", "*[data-grid]", function() {
    const element = this;
    console.log("Request fullscreen");
    console.log(element);
    if (element.requestFullscreen) {
      return element.requestFullscreen();
    } else if (element.requestFullScreen) {
      return element.requestFullScreen();
    } else if (element.msRequestFullscreen != null) {
      return element.msRequestFullscreen();
    } else if (element.mozRequestFullScreen != null) {
      return element.mozRequestFullScreen();
    } else if (element.webkitRequestFullscreen != null) {
      return element.webkitRequestFullscreen();
    } else {
      return console.warn("Cannot request fullscreen");
    }
});

})(jQuery);

