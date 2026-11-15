(function(E, $) {
  'use strict';

  $(document).on("keyup change", "form *[data-trade-item='purchase'] *[data-trade-component]", function(event) {
    const component = $(this);
    const item = component.closest("*[data-trade-item]");
    const component_name = component.data('trade-component');
    if ((component_name === 'conditionning') || (component_name === 'conditionning_quantity')) {
      const conditionning = E.trade.find(item, 'conditionning');
      const conditionning_quantity = E.trade.find(item, 'conditionning_quantity');
      const quantity = E.trade.find(item,  'quantity');
      const quantity_value = parseFloat(conditionning.val() || 0) * parseFloat(conditionning_quantity.val() || 0);
      quantity.val(quantity_value);
      quantity.trigger('change');
      E.trade.updateUnitPretaxAmount(item);
      return E.toggleValidateButton(item);
    }
  });

  $(document).on("keyup change", "*[data-trade-component]", function(event) {
    const component = $(this);
    const item = component.closest('.storing-fields');
    const component_name = component.data('trade-component');

    if ((component_name === 'conditionning') || ((component_name === 'conditionning_quantity') && (item.length > 0))) {
      const conditionning = item.find('.conditionning');
      const conditionning_quantity = item.find('.conditionning-quantity');
      const quantity = item.find('.storing-quantity');
      const quantity_value = parseFloat(conditionning.val() || 0) * parseFloat(conditionning_quantity.val() || 0);
      quantity.val(quantity_value);
      quantity.trigger('change');
      E.toggleValidateButton(item.closest('.incoming-parcel-item'));
    }

    if (component_name === 'conditionning') {
      const val = item.find('.conditionning').val();
      return item.closest('#add-storing').find('.conditionning').each(function() {
        $(this).val(val);
        return $(this).closest('.storing-fields').find('.conditionning-quantity').trigger('change');
      });
    }
  });

  const fields = {
    _stripDecimals(digitString, wantedDecimals) {
      if (digitString.includes('.')) {
        const amountWithDigits = digitString.split('.');
        const amount = amountWithDigits[0];
        const digits = amountWithDigits[1];
        if (digits.length > wantedDecimals) {
          let newDigitString;
          const digitsKept = digits.substring(0, wantedDecimals);
          const amountDisplayed = amount + '.' + digitsKept;
          return newDigitString = parseFloat(amountDisplayed);
        }
      }
    },

    changeDecimalNumber(element, wantedDecimals) {
      const newValue = this._stripDecimals(element.value, wantedDecimals);
      if (newValue) { return element.value = newValue; }
    }
  };

  // Prevent having more than 2 decimals on amount fields
  $(document).on("keyup", "[data-trade-component=amount], [data-trade-component=pretax_amount]", function() {
    return fields.changeDecimalNumber(this, 2);
  });

  // Allow unit pretax amount to have 4 decimals because database stores only 4
  $(document).on("keyup", "[data-trade-component=unit_pretax_amount]", function() {
    return fields.changeDecimalNumber(this, 4);
  });

  return $(document).ready(() => $('table.list').on('cocoon:after-insert', () => $('*[data-iceberg]').on("iceberg:inserted", function(element) {
    const val = $(this).find('.conditionning').val();
    return $(this).find('.conditionning').val(val);
})));

})(ekylibre, jQuery);
