(((E, $) => $(document).on('click', '.notify-accountant-action', function(event) {
  event.preventDefault();
  const exchange_id = $(event.target).parents('tr').data('id');
  const url = `/backend/financial-year-exchanges/${exchange_id}/notify_accountant_modal`;
  return E.Dialog.open(url);
})))(ekylibre, jQuery);
