(function(E, $) {
  'use strict';

  const appendLightsToInput = function($input) {
    const htmlString = "<span class='lights'><span class='go'></span><span class='caution'></span><span class='stop'></span></span><span class='lights-message'></span>";
    return $input.closest($input.data('lights')).append(htmlString);
  };

  $(document).ready(() => $('[data-lights]').each(function() {
    return appendLightsToInput($(this));
  }));

  return $(document).on("cocoon:after-insert", ".nested-inputs", (e, $newRow) => $newRow.find('[data-lights]').each(function() {
    return appendLightsToInput($(this));}));

})(ekylibre, jQuery);
