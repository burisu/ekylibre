(function(E, $) {
  'use strict';

  $(document).on('change', "*[data-sensor-vendor]", function() {
    const $el = $(this);
    const $target = $($(this).data('sensor-target'));
    const $url = $(this).data('sensor-url');

    if ($el.val() != null) {
      return $.ajax({
        url: $url,
        data: {vendor_euid: $el.val()},
        success(data, status, request) {
          $target.html("");
          $.each(data, function(i, model) {
            let option;
            return option = $("<option></option>")
            .val(model[1])
            .html(model[0])
            .appendTo($target);
          });

          $target.prop('disabled', false);

          return $target.trigger("change");
        },
        error() {
          return console.error("No model found");
        }
      });
    }
  });


  $(document).on('change', "*[data-sensor-model]", function() {
    const $el = $(this);
    const $parent = $($(this).data('sensor-parent'));
    const $url = $(this).data('sensor-url');

    if ($parent.val() && $el.val()) {
      return $.ajax({
        url: $url,
        data: {vendor_euid: $parent.val(), model_euid: $el.val(), id: $el.data('sensor-id')},
        success(data, status, request) {
          return true;
        }
      });
    }
  });

  return $(document).ready(() => $('*[data-sensor-vendor]').trigger('change'));

})(ekylibre, jQuery);
