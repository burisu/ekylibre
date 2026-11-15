(function(E, $) {
  'use strict';

  $(document).behave("load click", "form label input[name='loan[repayment_period]']:checked", function() {
    const input = $(this);
    const form = input.closest('form');
    form.find(".add-on.period").html(input.closest('label').text());
    if (form.prop("lastRepaymentPeriod") != null) {
      const period = form.prop("lastRepaymentPeriod");
      if (period !== input.val()) {
        form.find("input[name='loan[repayment_duration]'], input[name='loan[shift_duration]']").each(function() {
          const duration = $(this);
          let x = duration.val();

          if (period === "month") {
            if (input.val() === "year") { x /= 12; }
            if (input.val() === "semester") { x /= 6; }
            if (input.val() === "trimester") { x /= 3; }
          }

          if (period === "year") {
            if (input.val() === "month") { x *= 12; }
            if (input.val() === "semester") { x *= 2; }
            if (input.val() === "trimester") { x *= 4; }
          }

          if (period === "semester") {
            if (input.val() === "month") { x *= 6; }
            if (input.val() === "year") { x /= 2; }
            if (input.val() === "trimester") { x *= 2; }
          }

          if (period === "trimester") {
            if (input.val() === "month") { x *= 3; }
            if (input.val() === "year") { x /= 4; }
            if (input.val() === "semester") { x /= 2; }
          }

          return duration.val(x.toFixed(0));
        });
      }
    }
    return form.prop("lastRepaymentPeriod", input.val());
  });

})(ekylibre, jQuery);
