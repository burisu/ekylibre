//= require selector
//= require calcul

(function(E, C, $) {
  'use strict';
  // Change budget coeff on computation method change
  $(document).on("change keyup", ".budget .computation-method", function(event){
    console.log('change on computation-method');
    const select = $(this);
    const budget = select.closest(".budget");
    const form = budget.closest("form");
    const coeff = E.coefficientValue(form, select.val());
    // Set coeff
    budget.find(".budget-coeff").numericalValue(coeff);
    // Find total
    const quantityValue = budget.find(".budget-amount").numericalValue() / budget.find(".budget-unit-amount").numericalValue();
    // Adjust quantity to maintain global total
    const quantity = budget.find(".budget-quantity");
    if (quantityValue > 0) {
      let round = 3;
      if (quantity.data("calculate-round") != null) { round = quantity.data("calculate-round"); }
      quantity.numericalValue((quantityValue / coeff).toFixed(round));
    }
    // Trigger event on quantity only
    quantity.trigger("change");
    return true;
  });

  // Change budget coeff on supports  quantity change
  $(document).on("change", "#supports-quantity", function(event){
    const form = $(this).closest("form");
    form.find(".computation-method").each(function() {
      const select = $(this);
      const coeff = E.coefficientValue(form, select.val());
      return C.changeNumericalValue(select.closest(".budget").find(".budget-coeff"), coeff);
    });
    return true;
  });

  // Referesh totals after delete support
  $(document).on("cocoon:after-remove", ".budget", function(event){
    console.log("Delete support");
    const form = $(this).closest("form");
    form.find(".computation-method").each(function() {
      const select = $(this);
      const coeff = E.coefficientValue(form, select.val());
      return C.changeNumericalValue(select.closest(".budget").find(".budget-coeff"), coeff);
    });
    return true;
  });

    // Referesh totals after delete support
  $(document).on("cocoon:before-remove", ".budget-items", (event, prevRow) => prevRow.next('.frequencies').remove());

  // Refresh totals after insert
  $(document).on("cocoon:after-insert", ".budgets", function(event){
    $(this).find(".budget select.computation-method").each(function() {
      const select = $(this);
      return select.trigger("change");
    }); 
    return true;
  }); 

  // Show working unit dependent stuff
  $(document).behave("load change", "#supports-quantity", function(event){
    const quantity = $(this).numericalValue();
    const form = $(this).closest("form");
    if (quantity > 0) {
      form.addClass("with-some-supports");
    } else {
      form.removeClass("with-some-supports");
      $('.required-support').hide();
    }
    return true;
  });

  // Referesh totals after delete support
  $(document).on("cocoon:after-insert", ".budget-items", function(event){
    $(event.currentTarget).find('.budget-amount').each(function() {
      return $(this).html(C.toBudgetCurrency($(this).numericalValue()));
    });
    if ($('#supports-quantity').numericalValue() <= 0) {
      return $('.required-support').hide();
    }
  });

  E.coefficientValue = function(form, name) {
    let coeff = 1;
    if (name === "per_production_support") {
      coeff = form.find("#supports .support.nested-fields").length;
    } else if (name === "per_working_unit") {
      coeff = form.find("#supports-quantity").numericalValue();
    }
    return coeff;
  };

  // Set the quantity for a support keepping the choosen ratio on quantity
  // in order to maintain global amount
  E.updateSupportQuantity = function(support, newRefValue, newRefUnit) {
    const ref   = support.find(".support-current-quantity");
    const input = support.find(".support-quantity");
    const oldRefValue = ref.numericalValue();
    let k = 1;
    if (oldRefValue !== 0) { k = newRefValue / oldRefValue; }
    ref.numericalValue(newRefValue);
    let round = 3;
    if (input.data("calculate-round") != null) { round = input.data("calculate-round"); }
    let inputValue = input.numericalValue();
    if ((inputValue === "") || (inputValue === 0)) {
      inputValue = parseFloat(newRefValue);
    } else {
      inputValue *= k;
    }
    input.numericalValue(inputValue.toFixed(round));
    support.find(".support-unit").html(newRefUnit);
    return true;
  };

  // Changes budget quantities with new coeff
  E.changeBudgetQuantities = function(form, coeff) {
    form.find(".budgets .budget").each(function() {
      const budget = $(this);
      const method = budget.find(".budget-computation-method").val();
      const quantity = budget.find(".budget-quantity");
      if (method === "per_working_unit") {
        const qty = quantity.numericalValue();
        let round = 3;
        if (quantity.data("calculate-round") != null) { round = quantity.data("calculate-round"); }
        quantity.numericalValue((qty * coeff).toFixed(round));
        return quantity.trigger("change");
      }
    });
    return true;
  };

  E.updateAllProductUnrollURL = function(form) {
    form.find("#supports .support .production_supports_storage input[data-selector]").each(function() {
      return E.updateProductUnrollURL($(this));
    });
    return true;
  };

  E.updateProductUnrollURL = function(support) {
    let url = "/backend/products/unroll?scope[supportables]=true";
    const form = support.closest("form");
    // Adds variant filter
    const variant_id = form.find('#production_support_variant_id').first().selector('value');
    if (variant_id != null) {
      url += `&scope[of_variant]=${variant_id}`;
    }
    // Adds exception of the group
    const exclusions = [];
    form.find("#supports .support .production_supports_storage input[data-selector]").each(function() {
      if ((this !== support.get(0)) && $(this).prop("widgetInitialized")) {
        const value = $(this).selector('value');
        if (value != null) { return exclusions.push(value); }
      }
    });
    for (var exclusion of Array.from(exclusions)) {
      url += `&exclude[]=${exclusion}`;
    }
    support.selector();
    support.selector('url', url);
    support.selector('check');
    return true;
  };


  $(document).on('change', '.v-budget-frequency', function(e) {
    const dic = {per_month: 12, per_day: 365};
    const corrected = dic[$(this).find(':selected').val()];
    const val = typeof corrected === 'undefined' ? 1 : corrected;
    return $(this).closest('.noHover').prev().find('.budget-frequency').text(val);
  });

  $(document).on('keyup', '.v-budget-repetition', function(e) {
    return $(this).closest('.noHover').prev().find('.budget-repetition').text($(this).val());
  });

  // Show working unit dependent stuff
  $(document).on("selector:change", "#supports .support .production_supports_storage input[data-selector]", function(event){
    return E.updateAllProductUnrollURL($(this).closest('form'));
  });

  // Show working unit dependent stuff
  $(document).on("cocoon:after-insert", "#supports", function(event){
    return E.updateAllProductUnrollURL($(this).closest('form'));
  });

  E.onDomReady(function() {
    $('.budget-amount').each(function() {
      return $(this).html(C.toBudgetCurrency($(this).numericalValue()));
    });
    $('.activity_budget_revenues_main_output .checkbox input').each(function() {
      return $(this).trigger('main_output:set');
    });
    $('.activity_budget_revenues_use_transfer_price .checkbox input').each(function() {
      if ($(this).is(':checked')) {
        $(this).closest('.transfered-activity').find('.transfered-to-activity').show();
      }
      return E.changeTransferPriceDisplay($(this), $(this).is(':checked'));
    });
    return $('.budget-locked').each(function() {
      if ($(this).val() === 'true') {
        $(this).closest('.budget').addClass('budget-item-locked');
        return $(this).closest('.budget').next('.frequencies').addClass('budget-item-locked');
      }
    });
  });

  $(document).behave("change", ".activity_budget_revenues_main_output .checkbox input", function(event){
    return $(this).trigger('main_output:set');
  });

  $(document).behave("change", ".budget-total .amount", event => $('.activity_budget_revenues_use_transfer_price .checkbox input').each(function() {
    return E.updateTransferPrice($(this));
  }));

  $(document).behave("change", ".activity_budget_revenues_use_transfer_price .checkbox input", function(event){
    if ($(this).is(':checked')) {
      E.changeTransferPriceDisplay($(this), true);
      return $(this).closest('.transfered-activity').find('.transfered-to-activity').show();
    } else {
      E.changeTransferPriceDisplay($(this), false);
      return $(this).closest('.transfered-activity').find('.transfered-to-activity').hide();
    }
  });

  $(document).behave("main_output:set", ".activity_budget_revenues_main_output .checkbox input", function(event) {
    if ($(this).is(':checked')) {
      if ($(".activity_budget_revenues_main_output .checkbox input:checked").length > 1) {
        $('.activity_budget_revenues_main_output .checkbox input').prop('checked', false).trigger('change');
        $(this).prop('checked', true);
      }
      $(this).closest('.frequencies').find('.transfer-price').show();
      $(this).closest('.frequencies').next('.transfered-activity').find('.use-transfer-price').show();
      return $(this).closest('.frequencies').find('.activity_budget_revenues_use_transfer_price .checkbox input').trigger('change');
    } else {
      $(this).closest('.frequencies').next('.transfered-activity').find('.activity_budget_revenues_use_transfer_price .checkbox input').prop('checked', false).trigger('change');
      $(this).closest('.frequencies').next('.transfered-activity').find('.use-transfer-price').hide();
      return $(this).closest('.frequencies').find('.transfer-price').hide();
    }
  });

  E.updateTransferPrice = function(element) {
    const frequencies = element.closest('.transfered-activity').prev('.frequencies');
    const budget = frequencies.prev('.budget');
    const non_taken_revenue = budget.find('.revenue-amount').data('trueValue');
    const mapped_expenses = $.map($('.expense-amount'), (val, i) => $(val).data('trueValue'));
    let expenses_sum = 0;
    $.each(mapped_expenses, function() {
      return expenses_sum += parseFloat(this);
    });
    const mapped_revenues = $.map($(".revenue-amount"), (val, i) => $(val).data('trueValue'));
    let revenues_sum = -(non_taken_revenue);
    $.each(mapped_revenues, function() {
      return revenues_sum += parseFloat(this);
    });
    const quantity = parseFloat(budget.find('.budget-quantity').val());
    const coefficient = $('.budget-coeff').val() ? $('.budget-coeff').val() : 1;
    let transfer_price = ((expenses_sum - revenues_sum)/(coefficient * quantity));
    transfer_price = $.isNumeric(transfer_price) ? transfer_price : 0.00;
    frequencies.find('.transfer-price-box').html(C.toBudgetCurrency(transfer_price));
    frequencies.find('.v-transfer-price').attr('value', transfer_price);
    if (element.is(':checked')) {
      budget.find('.activity_budget_revenues_unit_amount span input').attr('value',transfer_price).prop('value',transfer_price);
    }
    return transfer_price;
  };

  E.changeTransferPriceDisplay = function(element, state) {
    const transfer_price = E.updateTransferPrice(element.closest('.transfered-activity').find('.use-transfer-price'));
    const price = element.closest('.transfered-activity').prev('.frequencies').prev('.budget').find('.activity_budget_revenues_unit_amount span input');
    if (state) {
      price.attr('value', transfer_price).val(transfer_price);
      return price.prop("readonly", true).css('background', 'lightgray');
    } else {
      return price.prop("readonly",false).css('background', 'none');
    }
  };

  // Show working unit dependent stuff
  $(document).behave("load selector:set", "#production_support_variant_id", function(event){
    const variant = $(this);
    const id = variant.selector('value');
    const form = variant.closest('form');
    if (/^\d+$/.test(id)) {
      form.addClass("with-supports");
      E.updateAllProductUnrollURL(form);
    } else {
      form.removeClass("with-supports");
    }
    return true;
  });

  // Force calculation of final values to ensure that all numbers are clear
  return $(document).behave("load", "#revenues-amount, #expenses-amount", function() {
    return $(this).each(function() {
      return $(this).trigger('change');});
});

})(ekylibre, calcul, jQuery);
