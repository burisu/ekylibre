(function(E, $) {
  'use strict';

  // Toggle annotation widget
  $(document).on("click", "a[data-annotate]", function(event) {
    const link = $(this);
    let scope = $("html");
    if (link.data("use-closest")) {
      scope = link.closest(link.data("use-closest"));
    }
    link.hide();
    const annotation = scope.find(link.data('annotate'));
    annotation.show();
    autosize(annotation.find("textarea").focus());
    return false;
  });


  // Manage fields filling in sales/purchases
  $(document).on("selector:change", "*[data-variant-of-deal-item]", function(_event, _value, is_initialization) {
    return E.trade.updateValues($(this), is_initialization);
  });


  E.trade = {

    updateValues($element, is_initialization) {
      const options = $element.data("variant-of-deal-item");
      const variant_id = $element.selector('value');
      const reg = new RegExp("\\bRECORD_ID\\b", "g");
      const form = $element.closest('form');
      const params = {};
      // TODO So so bad
      form.find('#sale_client_id, #purchase_supplier_id, #sale_address_id, #purchase_address_id').each(function() {
        const selector = $(this);
        const value = selector.selector('value');
        if (value != null) { return params[selector.attr('id')] = value; }
      });
      const $conditioningSelector = $element.closest($element.data('parent')).find($element.data('filter-unroll'));
      if (($conditioningSelector[0] !== $conditioningSelector.context) && !is_initialization) {
        $conditioningSelector.closest('.selector').find('.selector-value').attr('value', '');
        $conditioningSelector.val('');
      }
      if ($conditioningSelector.length) {
        const conditioningId = $conditioningSelector.first().selector('value');
        if (conditioningId) { params['conditioning_id'] = conditioningId; }
      }
      params['reference_date'] = form.find('[data-deal-reference-date]').val();

      if (variant_id != null) {
        const item = $element.closest("*[data-trade-item]");
        return $.ajax({
          url: options.url.replace(reg, variant_id),
          data: params,
          dataType: "json",
          success(data, status, request) {
            // Update fields
            let select, tax_ids, unit;
            if (data.name) {
              item.find(options.label_field || ".label").val(data.name);
            }

            if (data.depreciable) {
              item.find('.fixed-asset').show();
              const preexistingAsset = item.find(".sale_items_preexisting_asset input[type='checkbox']").prop('checked');
              if (preexistingAsset) { item.find('#new_asset').hide(); }
            } else {
              item.find('.fixed-asset').hide();
            }

            if (data.subscription != null) {
              if (data.subscription.nature_name != null) {
                item.find('.subscription_nature_name').html(data.subscription.nature_name);
              }
              if (data.subscription.started_on != null) {
                item.find('.subscription_started_on').val(data.subscription.started_on);
              }
              if (data.subscription.stopped_on != null) {
                item.find('.subscription_stopped_on').val(data.subscription.stopped_on);
              }
              if (data.subscription.address_id != null) {
                select = item.find('.subscription_address_id').first();
                select.selector('value', data.subscription.address_id);
              }
              item.find('.subscription').show();
            } else {
              item.find('.subscription').hide();
              select = item.find('.subscription_address_id').first();
              select.selector('clear');
              item.find('.subscription_started_on').val('');
              item.find('.subscription_stopped_on').val('');
            }

            const tradeType = item.data('tradeItem');
            const $taxSelector = item.find("*[data-trade-component='tax']");
            if (['purchase', 'sale'].includes(tradeType)) {
              tax_ids =  data.tax_ids[tradeType];
            }
            if (tax_ids != null) {
              E.trade._handleTaxSelectorOptions($taxSelector, tax_ids);
            }

            if (!is_initialization && (unit = data.unit)) {
              if (unit.name) {
                item.find(options.unit_name_tag || ".unit-name").html(data.name);
              }
              if (unit.conditioning_id) {
                const conditioning_selector_element = item.find("[id$='conditioning_unit_id']");
                if (!conditioning_selector_element.val()) {
                  const conditioning_selector = conditioning_selector_element.data('ui-selector');
                  conditioning_selector.value(unit.conditioning_id, true);
                }
              }
              let input = item.find(options.unit_pretax_amount_field || "*[data-trade-component='unit_pretax_amount']");
              if (unit.pretax_amount != null) {
                input.val(unit.pretax_amount);
                input.trigger('unit-value:change');
              } else if (input.val() === "") {
                input.val(0);
              }

              input = item.find(options.unit_amount_field || "*[data-trade-component='unit_amount']");
              if (unit.amount != null) {
                input.val(unit.amount);
              } else if (input.val() === "") {
                input.val(0);
              }

              // Compute totals
              E.trade.updateUnitPretaxAmount(item);
              E.toggleValidateButton(item, false);

              if (tax_ids != null) {
                E.trade._handleTaxSelectorValue($taxSelector, tax_ids);
              }
            }

            // Compute totals
            if (['change', 'readystatechange'].includes(event.type)) {
              return E.trade.updateUnitPretaxAmount(item);
            }
          },

          error(request, status, error) {
            return console.log(`Error while retrieving price and tax fields content: ${error}`);
          }
        });
      } else {
        return console.warn("Cannot get variant ID");
      }
    },

    _handleTaxSelectorValue($taxSelector, tax_ids) {
      if (tax_ids.length > 0) {
        return $taxSelector.val(tax_ids[0]);
      }
    },

    _handleTaxSelectorOptions($taxSelector, tax_ids) {
      if (tax_ids.length > 1) {
        return $taxSelector.children('option').toArray().map(function(option) {
          $(option).show();
          if (!tax_ids.includes(parseInt(option.value))) {
            return $(option).hide();
          }
        });
      }
    },

    round(value, digits) {
      const magnitude = Math.pow(10, digits);
      // console.log value, magnitude, value * magnitude, Math.round(value * magnitude), (Math.round(value * magnitude) / magnitude), (Math.round(value * magnitude) / magnitude).toFixed(digits)
      return (Math.round(value * magnitude) / magnitude).toFixed(digits);
    },

    // Compute other amounts from unit pretax amount
    updateUnitPretaxAmount(item) {
      const values = E.trade.itemValues(item);
      const updates = {};
      // Compute pretax_amount
      updates.pretax_amount = (values.unit_pretax_amount * values.quantity * (100.0 - values.reduction_percentage)) / 100.0;
      // Compute amount
      updates.amount = E.trade.round(updates.pretax_amount * values.tax, 2);
      // Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2);
      return E.trade.itemValues(item, updates);
    },

    // Compute other amounts from pretax amount
    updatePretaxAmount(item) {
      const values = E.trade.itemValues(item);
      const updates = {};
      // Compute unit_pretax_amount
      updates.unit_pretax_amount = E.trade.round(values.pretax_amount / ((values.quantity * (100.0 - values.reduction_percentage)) / 100.0), 2);
      // Compute amount
      updates.amount = E.trade.round(values.pretax_amount * values.tax, 2);
      return E.trade.itemValues(item, updates);
    },

    // Compute other amounts from amount
    updateAmount(item) {
      const values = E.trade.itemValues(item);
      const updates = {};
      // Compute pretax_amount
      updates.pretax_amount = values.amount / values.tax;
      // Compute unit_pretax_amount
      updates.unit_pretax_amount = E.trade.round(updates.pretax_amount / ((values.quantity * (100.0 - values.reduction_percentage)) / 100.0), 2);
      // Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2);
      return E.trade.itemValues(item, updates);
    },

    // Compute other amounts from amount
    updateCreditedQuantity(item) {
      const values = E.trade.itemValues(item);
      const updates = {};
      // Compute pretax_amount
      updates.pretax_amount = (-1 * values.unit_pretax_amount * values.credited_quantity * (100.0 - values.reduction_percentage)) / 100.0;
      // Compute unit_pretax_amount
      updates.amount = E.trade.round(updates.pretax_amount * values.tax, 2);
      // Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2);
      return E.trade.itemValues(item, updates);
    },

    // Compute other amounts from pretax amount
    updateCreditedPretaxAmount(item) {
      const values = E.trade.itemValues(item);
      const updates = {};
      // Compute credited quantity
      updates.unit_pretax_amount = -(E.trade.round(values.pretax_amount / ((values.credited_quantity * (100.0 - values.reduction_percentage)) / 100.0), 2));
      // Compute amount
      updates.amount = E.trade.round(values.pretax_amount * values.tax, 2);
      return E.trade.itemValues(item, updates);
    },

    // Compute other amounts from unit pretax amount
    updateCreditedAmount(item) {
      const values = E.trade.itemValues(item);
      const updates = {};
      // Compute pretax_amount
      updates.pretax_amount = values.amount / values.tax;
      // Compute credited quantity
      updates.unit_pretax_amount = -(E.trade.round(values.pretax_amount / ((values.credited_quantity * (100.0 - values.reduction_percentage)) / 100.0), 2));
      // Compute amount
      // Round pretax amount
      updates.pretax_amount = E.trade.round(updates.pretax_amount, 2);
      return E.trade.itemValues(item, updates);
    },

    find(item, name) {
      return item.find(`*[data-trade-component='${name}']`);
    },

    itemValues(item, updates = null) {
      if (updates === null) {
        const values = {
          unit_pretax_amount: E.trade.find(item, "unit_pretax_amount").numericalValue(),
          quantity: E.trade.find(item, "quantity").numericalValue(),
          credited_quantity: E.trade.find(item, "credited_quantity").numericalValue(),
          reduction_percentage: E.trade.find(item, "reduction_percentage").numericalValue(),
          tax: E.trade.find(item, "tax").numericalValue(),
          pretax_amount: E.trade.find(item, "pretax_amount").numericalValue(),
          amount: E.trade.find(item, "amount").numericalValue()
        };
        return values;
      } else {
        return (() => {
          const result = [];
          for (var key in updates) {
            var value = updates[key];
            result.push(E.trade.find(item, key).numericalValue(value));
          }
          return result;
        })();
      }
    }
  };

  E.purchasing = {

    // Compute what have to be computed
    compute(item, changedComponent) {
      const component = changedComponent.data("trade-component");
      switch (component) {
        case 'unit_pretax_amount': case 'quantity': case 'reduction_percentage': case 'tax':
          return E.trade.updateUnitPretaxAmount(item);
        case 'pretax_amount':
          return E.trade.updatePretaxAmount(item);
        case 'amount': case 'conditionning': case 'conditionning_quantity':
          if (item.closest('tbody').is('[data-trade-type="quick_affair"]')) { return E.trade.updateAmount(item); } // Change THIS
          break;
        default:
          return console.error(`Unknown component: ${component}`);
      }
    }
  };

  // Computes changes on items
  $(document).on("keyup change", "form *[data-trade-item='purchase'] *[data-trade-component]", function(event) {
    const component = $(this);
    return E.purchasing.compute(component.closest("*[data-trade-item]"), component);
  });

  E.selling = {

    // Compute what have to be computed
    compute(item, changedComponent) {
      let component = changedComponent.data("trade-component");
      if (!['unit_pretax_amount', 'pretax_amount', 'amount'].includes(component)) {
        component = changedComponent.closest('*[data-trade-item]').find('*[data-compute-from-updater]').val();
      }
      switch (component) {
        case 'unit_pretax_amount':
          return E.trade.updateUnitPretaxAmount(item);
        case 'pretax_amount':
          return E.trade.updatePretaxAmount(item);
        case 'amount':
          return E.trade.updateAmount(item);
        default:
          return console.error(`Unknown component: ${component}`);
      }
    }
  };

  // Computes changes on items
  $(document).on("keyup change", "form *[data-trade-item='sale'] *[data-trade-component]", function(event) {
    const component = $(this);
    return E.selling.compute(component.closest("*[data-trade-item]"), component);
  });


  $(document).on("change", "*[data-compute-from]", e => $(e.currentTarget).closest('*[data-trade-item]').find('*[data-compute-from-updater]').val($(e.currentTarget).data('compute-from')));


  // Sale crediting workflow
  E.crediting = {
    // Compute what have to be computed
    compute(item, changedComponent) {
      const component = changedComponent.data("trade-component");
      switch (component) {
        case 'credited_quantity':
          return E.trade.updateCreditedQuantity(item);
        case 'pretax_amount':
          return E.trade.updateCreditedPretaxAmount(item);
        case 'amount':
          return E.trade.updateCreditedAmount(item);
        default:
          return console.error(`Unknown component: ${component}`);
      }
    }
  };

  // Computes changes on items
  $(document).on("keyup change", "form *[data-trade-item='crediting'] *[data-trade-component]", function(event) {
    const component = $(this);
    return E.crediting.compute(component.closest("*[data-trade-item]"), component);
  });

})(ekylibre, jQuery);
