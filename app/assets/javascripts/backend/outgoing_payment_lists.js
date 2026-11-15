(function(E, $, C) {
  'use strict';

  $(document).on("change", "*[data-outgoing-payment-purchase-affair-selector]", function(e) {

    const $el = $(e.currentTarget);
    const $parent = $el.closest('[data-outgoing-payment-purchase-affair]');
    const $target = $parent.find('[data-outgoing-payment-purchase-affair-selection]');
    const amount = $parent.find('[data-outgoing-payment-purchase-affair-amount]').data('outgoing-payment-purchase-affair-amount');

    if ($el.prop('checked')) {
      $target.val($parent.data('outgoing-payment-purchase-affair'));
      $el.data('outgoing-payment-selected-amount', amount);
    } else {
      $target.val('');
      $el.data('outgoing-payment-selected-amount', 0);
    }

    if ($parent.find('[data-outgoing-payment-purchase-affair-selector]:checked').length > 0) {
      $parent.parents('table').find('.warning#unbalanced-entity').show();
    } else {
      $parent.parents('table').find('.warning#unbalanced-entity').hide();
    }

    // recalculate items for current third
    const $third = $el.closest('[data-outgoing-payment-third]');
    const $affairs = $third.find('[data-outgoing-payment-selected-amount]');
    const $total = $third.find('[data-outgoing-payment-total]');
    $total.removeClass('error');

    let total = 0.0;
    $affairs.each(function() {
      return total += parseFloat($(this).data('outgoing-payment-selected-amount'));
    });

    $total.text(C.toCurrency(total.toFixed(2)));

    if (total < 0) {
      return $total.addClass('error');
    }
  });


  $(document).on("click", "[data-outgoing-payment-third] thead ", function(e) {
    $(e.currentTarget).siblings('tbody').toggle();
    return false;
  });

})(ekylibre, jQuery, calcul);
