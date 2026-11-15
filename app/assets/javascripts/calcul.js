(function($, C) {

  // Format number to be read properly
  C.formatNumber = function(value, decimal, separator, thousand) {
    let deci = Math.round(Math.pow(10, decimal) * (Math.abs(value) - Math.floor(Math.abs(value))));
    let val = Math.floor(Math.abs(value));
    if ((decimal === 0) || (deci === Math.pow(10, decimal))) {
      val = Math.floor(Math.abs(value));
      deci = 0;
    }
    let valFormat = val + '';
    const nb = valFormat.length;
    let i = 1;
    while (i < 4) {
      if (val >= Math.pow(10, (3 * i))) {
        valFormat = valFormat.substring(0, nb - (3 * i)) + thousand + valFormat.substring(nb - (3 * i));
      }
      i++;
    }
    if (decimal > 0) {
      let decim = '';
      let j = 0;
      while (j < (decimal - deci.toString().length)) {
        decim += '0';
        j++;
      }
      deci = decim + deci.toString();
      valFormat = valFormat + separator + deci;
    }
    if (parseFloat(value) < 0) {
      valFormat = '-' + valFormat;
    }
    return valFormat;
  };

  // Format number simply
  C.formatNumber2 = function(value, precision, separator, thousand) {
    if (isNaN(value)) {
      return 'NaN';
    }
    let coeff = 1;
    if (value < 0) {
      coeff = -1;
    }
    const splitted = Math.abs(value).toString().split(/\./g);
    // alert(splitted.length);
    const integers = splitted[0].replace(/^0+[1-9]+/g, '');
    let decimals = (splitted[1] || '').replace(/0+$/g, '');
    if (decimals.length > precision) {
      decimals = decimals.substring(0, precision);
    }
    while (decimals.length < precision) {
      decimals = decimals + '0';
    }
    let formatted = integers;
    if (!/^\s*$/.test(decimals)) {
      formatted = formatted + separator + decimals;
    }
    if (coeff < 0) {
      formatted = "-" + formatted;
    }
    return formatted;
  };

  // Display a number with money presentation
  C.toCurrency = value => C.formatNumber2(value, 2, '.', '');

  C.toBudgetCurrency = function(value) {
    let res;
    if (Math.abs(value) > 100) {
      res = parseInt(value);
      return res.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    } else {
      return res = C.formatNumber2(value, 2, '.', '');
    }
  };

  // Auto-calculation
  C.autoCalculate = function() {
    $("*[data-use][data-auto-calculate]").each(function(){
      return C.calculate.call($(this), false);
    });
  };

  // Test change on value and trigger change event if value is really different
  C.changeNumericalValue = function(element, result, force) {
    if (force == null) { force = false; }
    if ((element.numericalValue() !== result) || force) {
      element.numericalValue(result);
      element.trigger("change");
    }
    return element;
  };

  // Adds a plugin to jQuery to work with numerical values.
  $.fn.numericalValue = function(newValue) {
    const element = $(this.get(0));
    if (isNaN(newValue) || (newValue === undefined) || (newValue === null)) {
      // Get
      let value = element.extractNumericalValue();
      let coeff = 1;
      if (/^\s*\-/.test(value)) { coeff = -1; }
      const commas = value.split(/\,/g);
      const points = value.split(/\./g);
      if ((commas.length === 2) && (points.length !== 2)) { // Metric notation
        value = value.replace(/\./g, "").replace(/\,/g, ".");
      } else if ((commas.length === 2) && (points.length === 2) && (commas[0].length > points[0].length)) {
        value = value.replace(/\./g, "").replace(/\,/g, ".");
      } else {
        value = value.replace(/\,/g, "");
      }
      value = parseFloat(value.replace(/[^0-9\.]*/g, ""));
      if (isNaN(value)) { return 0; }
      value *= coeff;
      return value;
    } else {
      // Set
      if (element.is("input")) {
        element.val(C.toCurrency(newValue));
      } else if (element.data("format") === 'budget') {
        element.html(C.toBudgetCurrency(newValue));
        element.data('trueValue', newValue);
      } else {
        element.html(C.toCurrency(newValue));
      }
      return element;
    }
  };


  // Adds a plugin to jQuery to work with numerical values.
  $.fn.extractNumericalValue = function() {
    const element = $(this);
    let value = undefined;
    if (element.is("select[data-value]")) {
      value = element.find("option:selected").attr(`data-${element.data('value')}`);
    } else if (element.is("select")) {
      value = element.find("option:selected").attr("value");
    } else if (element.is("input")) {
      value = element.val();
    } else {
      value = element.html();
    }
    if (value === undefined) { value = "0.0"; }
    return value;
  };

  $.fn.isCalculationResult = function() {
    const element = $(this);
    let neverUsed = true;
    $("*[data-calculate][data-use]").each(function() {
      return $($(this).data("use")).each(function() {
        if (this === element) { return neverUsed = false; }
      });
    });
    return neverUsed;
  };

  // Calculate result base on markup
  C.calculate = function(force){
    if (force == null) { force = false; }
    const element = $(this);
    let result = null;
    let use = element.data("use");
    if (use != null) {
      const closest = element.data("use-closest");
      if ((closest === null) || (closest === undefined)) {
        use = $(use);
      } else {
        use = element.closest(closest).find(use);
      }
      const calculation = element.data("calculate");
      if ((calculation === "multiplication") || (calculation === "mul")) {
        result = 1;
        use.each(function() {
          return result = result * C.calculate.call(this);
        });
      } else { // Sum by default
        result = 0;
        use.each(function() {
          return result = result + C.calculate.call(this);
        });
      }
      if (element.data("divide-by")) {
        result = result / C.calculate.call($(element.data("divide-by")));
      }

      const round = parseInt(element.data("calculate-round"));
      if (!isNaN(round)) {
        result = parseFloat(result.toFixed(round));
      }
    } else {
      return element.numericalValue();
    }

    C.changeNumericalValue(element, result, force);

    return result;
  };

  // Compute the sum of the elements
  $.fn.sum = function() {
    let result = 0;
    this.each(function() {
      return result = result + $(this).numericalValue();
    });
    return result;
  };

  const computeValidity = function(element, selector, difference) {
    if (difference == null) { difference = false; }
    let value = null;
    let equality = true;
    $(selector).each(function() {
      if (value == null) { value = $(this).numericalValue(); }
      if (value !== $(this).numericalValue()) { return equality = false; }
    });
    equality = equality !== difference;
    if (element.hasClass("valid") && !equality) {
      element.removeClass("valid");
      element.addClass("invalid");
      return element.trigger("change");
    } else if (element.hasClass("invalid") && equality) {
      element.removeClass("invalid");
      element.addClass("valid");
      return element.trigger("change");
    } else if (equality) {
      return element.addClass("valid");
    } else {
      return element.addClass("invalid");
    }
  };

  // Use element to compute a calculation
  $(document).behave("load", "*[data-use]", function() {
    const element = $(this);
    if (element.isCalculationResult()) {
      element.attr("data-auto-calculate", "true");
    } else {
      element.removeAttr("data-auto-calculate");
    }
  });

  $(document).behave("load", "*[data-balance]", function() {
    const element = $(this);
    const operands = $(this).data("balance").split('\\-').join('@DASH@').split(/\s\-\s/g).slice(0, 2).map(elem => elem.split('@DASH@').join('-'));
    const round = parseInt(element.data("calculate-round"));
    $(document).on("change", operands.join(", "), function() {
      const plus = $(operands[0]).sum();
      const minus = $(operands[1]).sum();
      let result = 0;
      if (plus > minus) {
        result = plus - minus;
      }
      if (!isNaN(round)) {
        result = parseFloat(result.toFixed(round));
      }
      return element.numericalValue(result);
    });
  });

  $(document).behave("load", "*[data-difference]", function() {
    const element = $(this);
    const round = parseInt(element.data("calculate-round"));
    const operands = $(this).data("difference").split('\\-').join('@DASH@').split(/\s+\-\s+/g).slice(0, 2).map(elem => elem.split('@DASH@').join('-'));
    $(document).on("change", operands.join(", "), function() {
      let result = $(operands[0]).sum() - $(operands[1]).sum();
      if (!isNaN(round)) {
        result = parseFloat(result.toFixed(round));
      }
      return C.changeNumericalValue(element, result);
    });
  });

  $(document).behave("load keyup change", "*[data-less-than-or-equal-to]", function() {
    const element = $(this);
    const maximum = parseFloat(element.data("less-than-or-equal-to"));
    if (element.numericalValue() > maximum) {
      element.removeClass("valid");
      element.addClass("invalid");
    } else {
      element.removeClass("invalid");
      element.addClass("valid");
    }
  });

  $(document).behave("load keyup change", "*[data-check-positive]", function() {
    const element = $(this);
    const value = element.find(element.data("check-positive")).numericalValue();
    if (value < 0) {
      element.removeClass("valid");
      element.addClass("invalid");
    } else if (value > 0) {
      element.removeClass("invalid");
      element.addClass("valid");
    } else {
      element.removeClass("invalid");
      element.removeClass("valid");
    }
  });

  $(document).behave("load", "*[data-valid-if-equality-between]", function() {
    const element = $(this);
    const selector = element.data("valid-if-equality-between");
    $(document).behave("load keyup change", selector, () => computeValidity(element, selector));
    $(document).on("visibility:change", function(event, hiddenOrShown) {
      const isParent = $(selector).toArray().some(triggerElement => $.contains(hiddenOrShown, triggerElement));
      if (isParent) { computeValidity(element, selector); }
    });
  });

  $(document).behave("load", "*[data-valid-if-difference-between]", function() {
    const element = $(this);
    const selector = element.data("valid-if-difference-between");
    $(document).behave("load keyup change", selector, () => computeValidity(element, selector, true));
    $(document).on("visibility:change", function(event, hiddenOrShown) {
      const isParent = $(selector).toArray().some(triggerElement => $.contains(hiddenOrShown, triggerElement));
      if (isParent) { computeValidity(element, selector, true); }
    });
  });

  $(document).on("change", "*[data-valid-if-equality-between]", function() {
    const element = $(this);
    if (element.hasClass("valid") && (element.data("submit-if-valid") === true)) {
      const form = element.closest("form");
      if (form) { form.submit(); }
    }
  });


  C.autoCalculate();

  window.setInterval(C.autoCalculate, 300);


})(jQuery, calcul);
