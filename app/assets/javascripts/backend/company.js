(function(E, $) {
  'use strict';

  const getAccountNumberDigits = () => parseInt($('#preferences_account_number_digits_value').val());

  return $(document).ready(function() {
    if (!$('.company-edit-form').length) { return; }
    const accountNumberDigitsInitial = getAccountNumberDigits();
    return $('.company-edit-form input[type="submit"]').click(function(event) {
      const confirmMessage = $('.company-edit-form').data('confirm-account-digits');
      if ((getAccountNumberDigits() !== accountNumberDigitsInitial) && !confirm(confirmMessage)) {
        event.preventDefault();
        return false;
      }});});

})(ekylibre, jQuery);
