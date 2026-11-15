(function(E, $) {
  'use strict';

  const updateStockAfterPurchase = ($form, newstock) => {
    return $form.find(".merchandise-stock-after-purchase .stock-value").text(newstock.toFixed(2));
  };

  const onTotalQuantityChanged = $input => {
    let newStock;
    const $form = $input.closest('.nested-item-form');
    const coefficient = $form.find('[data-coefficient]').data('coefficient');
    const newQuantity = $input.val();
    const currentstock = getCurrentStock($form);
    if (!coefficient || (newQuantity.length === 0)) {
      newStock = currentstock;
    } else {
      newStock = currentstock + (parseFloat(newQuantity) * coefficient);
    }
    return updateStockAfterPurchase($form, newStock);
  };

  var getCurrentStock = $form => {
    return parseFloat($form.find('.merchandise-current-stock .stock-value').text());
  };

  const getVariantStock = variantId => {
    let p2;
    const p = $.getJSON(`/backend/product_nature_variants/${variantId}/detail`);
    return p2 = p.then(data => {
      return {
        stock: data.default_unit_stock,
        unit: data.default_unit_name
      };
  });
  };

  const onvariantChanged = $variantSelector => {
    let updateQuantity;
    const $form = $variantSelector.closest('.nested-item-form');

    const variantId = $variantSelector.selector('value');
    getVariantStock(variantId).then(data => {
      $form.find(".merchandise-current-stock .stock-value").text(data.stock);
      $form.find(".stock-unit").text(data.unit);
      return updateQuantity($form);
    });

    return updateQuantity = $form => {
      const $quantity = $form.find('.order-quantity, .invoice-quantity');

      if (($quantity.val() === "0") || ($quantity.val() === "")) {
        $quantity.val(1);
      }
      return $quantity.trigger('change');
    };
  };


  $(document).on('keyup change', '.nested-fields .form-field .purchase_order_items_conditioning_quantity .order-quantity', function(event) {
    return onTotalQuantityChanged($(this));
  });

  $(document).on('selector:change', '.order-variant.selector-search', function(event) {
    return onvariantChanged($(this));
  });

  $(document).on('selector:change', '.invoice-variant.selector-search', function(event) {
    return onvariantChanged($(this));
  });

  $.each(['purchase_order', 'purchase_invoice'], function(i, purchase_att) {

    $(document).on('input unit-value:change', `.${purchase_att}_items_unit_pretax_amount > .controls > .input-append > input`, function() {
      const unit_amount = ($(this).val() / $(this).data().coeff).toFixed(2);
      return $(this.closest('tr')).find(`.${purchase_att}_items_base_unit_amount > .controls > .input-append > input`).val(unit_amount);
    });

    return $(document).on('selector:change', `.${purchase_att}_items_conditioning_unit > .controls > .selector > .selector-value`, function() {
      const that = this;
      return $.ajax('/backend/sales/conditioning_ratio', {
        type: 'get',
        dataType: 'json',
        data: { 'id': this.value
      },
        success(data) {
          const table = $(that).closest('tr');
          let coeff = 1;
          if (data.coeff && (data.coeff !== 1)) {
            ({
              coeff
            } = data);
            $(table).find('.unitary-quantity').show();
          }
          $(table).find(`.${purchase_att}_items_unit_pretax_amount > .controls > .input-append > input`).data('coeff', coeff);
          const amount_input = $(table).find(`.${purchase_att}_items_unit_pretax_amount > .controls > .input-append > input`);
          const unit_amount = (amount_input.val() / amount_input.data().coeff).toFixed(2);
          return $(table).find(`.${purchase_att}_items_base_unit_amount > .controls > .input-append > input`).val(unit_amount);
        }
      }
      );
    });
  });

  return E.Purchases = {
    compute_amount() {
      const $pretaxAmounts = $('.nested-fields .pre-tax-invoice-total-controls input');
      const pretaxAmount = $pretaxAmounts.toArray().reduce(((acc, e) => acc + parseFloat(e.value)), 0).toFixed(2);
      const $preTaxTotal = $('.total-except-tax .total-value');
      $preTaxTotal.text(pretaxAmount);

      const $taxAmounts = $('.nested-fields .invoice-total-controls input');
      const taxAmount = $taxAmounts.toArray().reduce(((acc, e) => acc + parseFloat(e.value)), 0).toFixed(2);
      const $taxTotal = $('.purchase-total .total-value');
      $taxTotal.text(taxAmount);

      const $vatTotal = $('.vat-total .total-value');
      return $vatTotal.text((taxAmount - pretaxAmount).toFixed(2));
    }
  };

})(ekylibre, jQuery);
