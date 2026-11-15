(function($, E) {
  "use strict";

  E.checkFinancialYearCurrency = function() {
    const change_item = $(this).closest('*[data-change-url]');
    const date = $(this).val();
    console.log(date);
    if (!/^\d\d\d\d\-\d\d\-\d\d$/.test(date)) { return; }
    $.ajax({
      url: change_item.data('change-url'),
      data: {
        on: date
      },
      dataType: "json",
      success(data, status, request) {
        let change;
        if (data.from !== data.to) {
          change = 'true';
        } else {
          change = 'false';
        }
        change_item.attr('data-with-change', change);
        change_item.find('#journal_entry_real_currency_rate').val(data.exchange_rate);
        const label = change_item.find('label[data-change-label]');
        label.html(label.data('change-label').replace(/\{\{FROM\}\}/, data.from).replace(/\{\{TO\}\}/, data.to));
        return change_item.find('.financial-year-currency').html(data.to);
      }
    });
    return $.checkDate($(this));
  };

  $(document).on('change keyup', '#journal-entry-form #journal_entry_printed_on', E.checkFinancialYearCurrency);

  return $(document).ready(function() {
    const calculate_sum = function(column) {
      let sum = 0;
      $("td."+column+"-without-error-correction").each(function(index, elem) {
        const numval = parseFloat($(elem).html());
        if ((typeof(numval) === "number") && !isNaN(numval)) {
          return sum += numval;
        }
      });
      return sum;
    };

    const withoutError = function(correctedTD) {
      let column = correctedTD.className.split(" ").filter(element => (element === "credit") || (element === "debit"));
      column = column[0];
      return $(correctedTD).next("td."+column+"-without-error-correction").html();
    };

    const resetCorrectedValues = () => ['debit', 'credit'].forEach(column => $("td."+column).each(function(index, input) {
      const valueWithoutError = withoutError(input);
      return $(input).html(valueWithoutError);
    }));

    const errorRepartition =  function(column, sum, error_sum) {
      const precision = parseFloat($("#entry-"+column+".decimal").data("calculate-round"));

      error_sum =  Math.abs(Math.round(error_sum * Math.pow(10, precision)));
      let left = error_sum;

      return $("."+column).each(function(index, item) {
          let itemval = withoutError(item);
          itemval = parseFloat(itemval) * Math.pow(10, precision);
          let toCorrect = (itemval / (sum * Math.pow(10, precision))) * error_sum;

          if ((typeof(itemval) === "number") && !isNaN(itemval)) {
            toCorrect = (itemval / (sum * Math.pow(10, precision))) * error_sum;
            toCorrect = Math.ceil(Math.min(left, toCorrect));
            $(item).html(Math.round(itemval + toCorrect) / Math.pow(10, precision));
            return left -= toCorrect;
          }
      });
    };

    const evening = function() {
      resetCorrectedValues();

      if ($("#total").hasClass("valid")) {
        const debit = calculate_sum("debit");
        const credit = calculate_sum("credit");

        if (debit !== credit) {

          // entry-debit[data-calculate-round] should be equal
          //   to entry-credit[data-calculate-round]

          const error_sum = (debit - credit);

          if (error_sum !== 0) {
            if (error_sum > 0) {
              return errorRepartition("credit", credit, error_sum);
            } else {
              return errorRepartition("debit", debit, error_sum);
            }
          }
        }
      }
    };

    const convert = function(item, column) {
      const field = $(item).closest("tr").next("tr").find("td."+column);
      const precision = field.data("calculate-round");
      let new_val = parseFloat($("#journal_entry_real_currency_rate").val()) * parseFloat($(item).val());
      new_val = Math.round(new_val * Math.pow(10, precision)) / Math.pow(10, precision);
      field.html(new_val);
      return field.next("td."+column+"-without-error-correction").html(new_val);
    };

    const convertAll = () => ['debit', 'credit'].forEach(column => $(".real-"+column).each((index, item) => convert(item, column)));

    const toggleAutocompletion = () => $.ajax({
      url:  '/backend/journal_entries/toggle-autocompletion',
      type: 'patch',
      data: {
        autocompletion: $('#preference_entry_autocompletion').is(":checked")
      },
      error() {
        return $('#preference_entry_autocompletion').attr('checked', !$('#preference_entry_autocompletion').is(":checked"));
      }
    });

    $(document).behave("change", "#preference_entry_autocompletion", () => toggleAutocompletion());

    if ($("#subtotal").length > 0) {
      ['debit', 'credit'].forEach(column => $(document).behave("change keyup paste", '.real-'+column,  function() {
        convert(this, column);
        return evening();
      }));

      $(document).behave("change keyup paste", "#journal_entry_real_currency_rate", function() {
        convertAll();
        return evening();
      });

      const observer = new MutationObserver(mutations => mutations.forEach(function(mutation) {
        if (mutation.addedNodes.length > 0) {
          convertAll();
          return evening();
        }
      }));

      observer.observe(document.getElementById("items-table"), {childList: true});

      // to avoid autocalculate messing up our first error calculation.
      return setTimeout(evening, 500);
    }});

})(jQuery, ekylibre);
