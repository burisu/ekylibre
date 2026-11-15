(function($) {
  'use strict';
  $.display = value => console.log(value);

  $.load = function() {
    $("*[data-slider]").each(function() {
      const {
        length
      } = $(this).data("slider").crumbs;
      return $(this).slider({
        min: 0,
        max: length - 1,
        values: $(this).data("slider").cursors,
        slide(event, ui) {
          return $.display(ui.value);
        }
      });
    });
  };

  // events
  $(document).ready($.load);
  return true;
})(jQuery);
