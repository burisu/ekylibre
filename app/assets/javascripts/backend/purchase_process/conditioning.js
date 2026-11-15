(function(E, $) {
  'use strict';

  const addConditioningData = function($selector) {
    const filterId = $selector.selector('value');
    const variantId = $selector.closest('.nested-item-form').find($selector.data('variant-selector')).first().selector('value');
    if (!filterId || !variantId) { return; }

    const url = $selector.data('conditioning-data-url');
    const $quantity = $selector.closest('.storing-calculation').find("[data-trade-component='quantity']");
    return $.getJSON(url, {filter_id: filterId, variant_id: variantId}, function(data) {
      $selector.data('coefficient', data.coefficient);
      $selector.attr('data-coefficient', data.coefficient);
      $selector.data('interpolate-data-attribute', data.unit_name);
      $selector.attr('data-interpolate-data-attribute', data.unit_name);
      return $quantity.trigger('change');
    });
  };


  $(document).on('selector:change', '[data-conditioning-data-url]', function(e) {
    return addConditioningData($(this));
  });

  return $(document).on('selector:change', '[data-variant-selector]', function(e, _a, is_initialization, options) {
    if (options == null) { options = {}; }
    if (!options.manuallyTriggered) { return E.trade.updateValues($(this).closest('.nested-fields').find($(this).data('variant-selector')).first(), is_initialization); }
});

})(ekylibre, jQuery);
