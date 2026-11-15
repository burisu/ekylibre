//= require 'bootstrap/tooltip'
//= require 'bootstrap/popover'

(function($) {
  "use strict";

  $(document).on("mouseover", "*[data-simple-calendar] a.previous-month, *[data-simple-calendar] a.next-month", function() {
    const link = $(this);
    const calendar = link.closest("*[data-simple-calendar]");
    link.attr("data-remote", "true")
      .attr("data-method", "get")
      .attr("data-update", "#" + calendar.attr("id"))
      .attr("data-update-mode", "closest");
  });


  $(document).behave("load", "*[data-content]", function() {
    $(this).popover({
      trigger: "hover",
      placement: "bottom",
      container: "#wrap",
      html: true
    });
  });

  $(document).behave("load", "*[data-toggle='popover']", function() {
    $(this).popover({
      trigger: "click",
      placement: "bottom",
      container: "#wrap",
      content: $($(this).attr("href")).html(),
      html: true
    });
    return false;
  });

})(jQuery);
