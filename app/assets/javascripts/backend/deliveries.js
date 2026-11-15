(function(E, $) {
  'use strict';

  $(document).behave("load click", "form label input[name='shipment[delivery_mode]']", function() {
    const input = $(this);
    if (input.is(':checked')) {
      const form = input.closest('form');
      form.find("input[name='shipment[delivery_mode]']").each(function() {
        return $(`#delivery-mode-${$(this).val()}`).hide();
      });
      return $(`#delivery-mode-${input.val()}`).show();
    }
  });

  $(document).behave("load click", "form label input[name='delivery[mode]']", function() {
    const input = $(this);
    if (input.is(':checked')) {
      const form = input.closest('form');
      form.find("input[name='delivery[mode]']").each(function() {
        return $(`#${$(this).val()}`).hide();
      });
      return $(`#${input.val()}`).show();
    }
  });

  // Manage fields filling in sales/purchases
  $(document).on("selector:set", "*[data-product-of-delivery-item]", function(e, wasInitializing) {
    let element = $(this);
    const options = element.data("product-of-delivery-item");
    const product_id = element.selector('value');
    const reg = new RegExp("\\bRECORD_ID\\b", "g");
    let scope = options['scope'];
    if (product_id != null) {
      const item = element.closest(".delivery-item");
      return $.ajax({
        url: options.url.replace(reg, product_id),
        // get params from field sale_nature_id, planned_at from options
        data: {sale_nature_id: options.sale_nature_id, planned_at: options.planned_at},
        dataType: "json",
        success(data, status, request) {
          const unit = item.find(".item-population-unit-name");
          if (data.conditioning_unit_name) {
            unit.show();
            unit.html(data.conditioning_unit_name);
            item.attr('data-conditioning-unit-name', data.conditioning_unit_name);
          } else if (data.unit_name) {
            unit.html(data.unit_name);
            item.attr('data-unit-name', data.unit_name);
          } else {
            unit.html('#');
          }
          if (!wasInitializing) { set_default_sale_price(item, data.default_sale_price); }
          if (data.variant) {
            item.find(".item-variant-name").html(data.variant.name);
          }
          const pop = item.find(".item-population");
          const total = item.find(".item-population-total");
          const prefilled = element.closest('tr').find('.prefilled-conditioning');
          if ((prefilled.length > 0) && data.conditioning_coefficient) {
            const prefilled_val = (prefilled.data("conditioningQuantity") * prefilled.data("conditioningCoefficient")) / data.conditioning_coefficient;
            total.html(data.population);
            pop.val(prefilled_val);
          } else if (data.population) {
            total.html(data.population);
          } else {
            total.html('&ndash;');
            pop.attr('placeholder', '0');
          }
          pop.attr('min', 0);
          pop.attr('max', data.population);
          if (data.population_counting === 'unitary') {
            pop.attr('disabled', 'disabled');
          } else {
            pop.removeAttr('disabled');
          }

          if (data.population_counting === 'integer') {
            pop.attr('step', 1);
          } else if (data.population_counting === 'decimal') {
            pop.removeAttr('step');
          }

          return item.find('*[data-when-item]').each(function() {
            if (typeof data[$(this).data('when-item')] !== "undefined") {
              if ((typeof $(this).data('when-scope') === "undefined") || ($(this).data('when-scope') === scope)) {
                if (typeof $(this).data("when-set-value") !== "undefined") {
                  if ($(this).data("when-set-value") === "RECORD_VALUE") {
                    let newVal = data[$(this).data("when-item")];
                    if (typeof newVal === "string") { newVal = newVal.toLowerCase(); }

                    if ($(this).is(":ui-selector")) {
                      $(this).selector("value", newVal);
                    } else if (this._flatpickr != null) {
                      this._flatpickr.setDate(newVal);
                    } else if ($(this).is("select")) {
                      $(this).val(newVal).change();
                    } else if ($(this).is("input")) {
                      $(this).val(newVal);
                    } else {
                      $(this).html(newVal);
                    }

                    $(this).trigger('change');

                    if (typeof newVal === "string") {
                      element = $(this);
                      element.is(":ui-mapeditor");
                      try {
                        const value = $.parseJSON(newVal);

                        if (((value.geometries != null) && (value.geometries.length > 0)) || ((value.coordinates != null) && (value.coordinates.length > 0))) {
                          element.mapeditor("show", value);
                          element.mapeditor("edit", value);
                          try {
                            element.mapeditor("view", "edit");
                          } catch (error) {}
                        }

                      } catch (error1) {}
                    }

                    if (!$(this).is('select')) {
                      $(this).val(newVal);
                    }
                  } else {
                    $(this).val($(this).data("when-set-value"));
                  }
                }

                if (typeof $(this).data("when-prop-value") !== "undefined") {
                  $(this).prop($(this).data("when-prop-value"), true);
                }

                if (typeof $(this).data("when-display-value") !== "undefined") {
                  if ($(this).data("when-display-value") === true) {
                    $(this).show();
                  } else {
                    $(this).hide();
                  }
                  $(this).trigger('visibility:change');
                }
              }

              if (typeof $(this).data("when-filter-value") !== "undefined") {
                const key_filter = Object.keys($(this).data('when-filter-value'))[0];
                scope = `scope[${key_filter}]=${data[$(this).data("when-item")]}`;
                let selector_url = $(this).data('selector');
                if (selector_url.indexOf(scope) < 0) {
                  if (selector_url.indexOf('?') < 0) { selector_url += '?'; } else { selector_url += '&'; }
                  selector_url += scope;
                }
                return $(this).attr('data-selector', selector_url);
              }

            } else {
              if ((typeof $(this).data('when-scope') === "undefined") || ($(this).data('when-scope') === scope)) {
                if (typeof $(this).data("when-prop-value") !== "undefined") {
                  $(this).prop($(this).data("when-prop-value"), false);
                }
              }

              if (typeof $(this).data("when-display-value") !== "undefined") {
                if ((typeof $(this).data('when-scope') === "undefined") || ($(this).data('when-scope') === scope)) {
                  if ($(this).data("when-display-value") === true) {
                    $(this).hide();
                  } else {
                    $(this).show();
                  }
                  return $(this).trigger('visibility:change');
                }
              }
            }
          });
        },


          // shape = item.find(options.population_field or ".item-shape")
          // if data.shape
          //   shape.show()
          // else
          //   shape.hide()

        error(request, status, error) {
          return console.log(`Error while retrieving price and tax fields content: ${error}`);
        }
      });
    } else {
      return console.warn("Cannot get product ID");
    }
  });

  var set_default_sale_price = function(item, default_price) {
    if (default_price) {
      return item.find(".item-unit-pretax-sale-amount").val(default_price);
    } else {
      return item.find(".item-unit-pretax-sale-amount").val(0.00);
    }
  };

  // Computes changes on items
  $(document).on("click", ".item-parted", function(event) {
    const parted = $(this);
    const item = parted.closest('.delivery-item');
    const quantifier = item.find('.item-quantifier');
    if (quantifier) {
      if (parted.is(':checked')) {
        return quantifier.removeClass('hidden');
      } else {
        return quantifier.addClass('hidden');
      }
    }
  });


})(ekylibre, jQuery);
