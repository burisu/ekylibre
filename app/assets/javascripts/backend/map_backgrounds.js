// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

(function($) {
  "use strict";
  $(document).on('click', '[data-enable-url]', function() {
    return $.ajax({
      url: $(this).data('enable-url'),
      method: 'POST',
      dataType: 'json',
      success: data => {
        $(this).toggleClass('active');
        $(this).find('.map-layer-by-default').toggleClass('hide');

        if (data.new_default != null) {
          $(this).find('.map-layer-by-default.active').removeClass('active');
          return $('.map-layers-viewport').find(`[data-id=${data.new_default}]`).find('.map-layer-by-default').addClass('active');
        }
      }

    });
  });

  $(document).on('ajax:success', ".map-layer-by-default", function() {
    $('.map-layer-by-default.active').removeClass('active');
    return $(this).toggleClass('active');
  });

  $(document).on('ajax:success', ".map-layer-delete a", function() {
    return $(this).closest('.map-layer-container').remove();
  });


})(jQuery);