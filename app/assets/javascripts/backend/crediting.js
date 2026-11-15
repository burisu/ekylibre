// allows price and tax auto filling in sales view

(function(E, $) {
  'use strict';

  E.crediting = {
    // CSS class for reference fields
    referenceClass: "special",

    methods: {
      computeManual(item, changedComponent) {
        return console.log(`Compute Manual method from ${changedComponent}`);
      },
        // Do nothing for now

      computeTaxQuantity(item, changedComponent) {
        console.log(`Compute Tax-Quantity method from ${changedComponent}`);
        if (changedComponent === "amount") {
          E.crediting.ops.mmmi(item);
          return E.crediting.ops.mmmg(item);
        } else if (changedComponent === "pretax_amount") {
          E.crediting.ops.mmmj(item);
          return E.crediting.ops.mmmh(item);
        } else if (changedComponent === "quantity") {
          E.crediting.ops.mmmh(item);
          return E.crediting.ops.mmmg(item);
        } else {
          return console.error(`Cannot compute anything for ${changedComponent}`);
        }
      },

      computeQuantityTax(item, changedComponent) {
        console.log(`Compute Quantity-Tax method from ${changedComponent}`);
        if (changedComponent === "amount") {
          E.crediting.ops.mmma(item);
          return E.crediting.ops.mmmj(item);
        } else if (changedComponent === "pretax_amount") {
          E.crediting.ops.mmmd(item);
          return E.crediting.ops.mmmj(item);
        } else if (changedComponent === "quantity") {
          E.crediting.ops.mmmg(item);
          return E.crediting.ops.mmmd(item);
        } else {
          return console.error(`Cannot compute anything for ${changedComponent}`);
        }
      },

      computeAdaptive(item, changedComponent) {
        let adaptativeMethod = item.prop("adaptativeMethod");
        if (adaptativeMethod === "tax_quantity") {
          E.crediting.methods.computeTaxQuantity(item, changedComponent);
        } else if (adaptativeMethod === "quantity_tax") {
          E.crediting.methods.computeQuantityTax(item, changedComponent);
        }
        // Evaluate if re-computation is needed
        const amount = E.crediting.find("unit_pretax_amount", item);
        const tax = E.crediting.find("tax", item);
        const taxPercentage = Math.round2((100.0 * tax.numericalValue()) - 100.0, 0.000001);
        const count = Math.decimalCount(taxPercentage);
        if (amount.numericalValue() >= Math.pow(10, count)) {
          if (adaptativeMethod !== "tax_quantity") {
            adaptativeMethod = "tax_quantity";
            E.crediting.methods.computeTaxQuantity(item, changedComponent);
          }
        } else {
          if (adaptativeMethod !== "quantity_tax") {
            adaptativeMethod = "quantity_tax";
            E.crediting.methods.computeQuantityTax(item, changedComponent);
          }
        }
        return item.prop("adaptativeMethod", adaptativeMethod);
      }
    },

    ops: {
      mmma(item) {
        return E.crediting.divide(item, "pretax_amount", "amount", "tax");
      },
      mmmd(item) {
        return E.crediting.multiply(item, "amount", "pretax_amount", "tax");
      },
      mmmg(item) {
        return E.crediting.multiply(item, "pretax_amount", "unit_pretax_amount", "quantity");
      },
      mmmh(item) {
        return E.crediting.multiply(item, "amount", "unit_amount", "quantity");
      },
      mmmi(item) {
        return E.crediting.divide(item, "quantity", "amount", "unit_amount");
      },
      mmmj(item) {
        return E.crediting.divide(item, "quantity", "pretax_amount", "unit_pretax_amount");
      }
    },

    find(name, item) {
      return item.find(`*[data-crediting-component='${name}']`);
    },

    divide(item, recipient, numerator, denominator) {
      const r = E.crediting.find(recipient, item);
      const n = E.crediting.find(numerator, item);
      const d = E.crediting.find(denominator, item);
      const value = n.numericalValue() / d.numericalValue();
      return r.val(value.toFixed(2));
    },

    multiply(item, recipient, operand, coefficient) {
      const r = E.crediting.find(recipient, item);
      const o = E.crediting.find(operand, item);
      const c = E.crediting.find(coefficient, item);
      const value = o.numericalValue() * c.numericalValue();
      return r.val(value.toFixed(2));
    },

    setReferenceValue(item, referenceValue, componentType = null) {
      if (componentType == null) {
        componentType = referenceValue.val();
      }
      if ((componentType === "quantity") || (componentType === "pretax_amount") || (componentType === "amount")) {
        // Register reference value
        referenceValue.val(componentType);
        // Set class for reference field
        item.find(`*[data-crediting-component].${E.crediting.referenceClass}`).removeClass(E.crediting.referenceClass);
        return item.find(`*[data-crediting-component='${componentType}']`).addClass(E.crediting.referenceClass);
      }
    },

    compute(item, component = null) {
      let method;
      const form = item.closest("form");
      let changedComponent = null;
      const referenceValue = item.find("*[data-crediting-component='reference_value']");

      if (component) {
        const componentType = component.data("crediting-component");
        E.crediting.setReferenceValue(item, referenceValue, componentType);
      }

      // Computes values
      const creditingMethod = form.find("*[data-crediting-method]");
      if (creditingMethod.is("input[type='radio']")) {
        method = form.find("*[data-crediting-method]:checked").val();
      } else {
        method = creditingMethod.val();
      }

      // Get reference value
      changedComponent = referenceValue.val();

      // Apply method
      if (method === "quantity_tax") {
        return E.crediting.methods.computeQuantityTax(item, changedComponent);
      } else if (method === "tax_quantity") {
        return E.crediting.methods.computeTaxQuantity(item, changedComponent);
      } else if (method === "adaptative") {
        return E.crediting.methods.computeAdaptive(item, changedComponent);
      } else if (method === "manual") {
        return E.crediting.methods.computeManual(item, changedComponent);
      } else {
        return console.error(`Cannot compute anything with ${method} method`);
      }
    }
  };

  // Computes changes on items
  $(document).behave("load", "form *[data-crediting-item] *[data-crediting-component='reference_value']", function() {
    return E.crediting.setReferenceValue($(this).closest("*[data-crediting-item]"), $(this));
  });

  // Computes changes on items
  $(document).on("keyup change", "form *[data-crediting-item] *[data-crediting-component]", function() {
    return E.crediting.compute($(this).closest("*[data-crediting-item]"), $(this));
  });

  // Computes changes on items
  $(document).on("change", "form *[data-crediting-method]", function() {
    return $(this).closest("form").find("*[data-crediting-item]").each(function() {
      return E.crediting.compute($(this));
    });
  });

  // Computes changes on items
  $(document).on("keyup keydown", "form input[data-force-sign='-']", function() {
    return $(this).each(function() {
      const input = $(this);
      if (!input.val().match(/^\-/)) {
        return input.val(`-${input.val()}`);
      }
    });
  });

})(ekylibre, jQuery);
