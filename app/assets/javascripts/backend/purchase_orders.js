(function(E, $) {
  'use strict';

  return $(document).ready(function() {
    $(document).on('click', '.btn[data-validate="item-form"]', function(event) {
      let totalAmountExcludingTaxes = 0;
      let totalVatRate = 0;
      let totalAmountIncludingTaxes = 0;

      $('.nested-fields.purchase-order-items .item-display').map((index, item) => {
        const amountExcludingTaxes = $(item).find('.total-column label.amount-excluding-taxes').text();
        const vatRate = $(item).find('.total-column label.vat-rate').text().split("%")[0];

        totalAmountExcludingTaxes += parseFloat(amountExcludingTaxes);
        totalAmountIncludingTaxes += parseInt(amountExcludingTaxes * (1 + (parseFloat(vatRate) / 100)));

        const calculVatRate = parseFloat((parseFloat(amountExcludingTaxes) * parseFloat(vatRate)) / 100).toFixed(2);
        totalVatRate += parseFloat(calculVatRate);

        const selectedVatValue = $(item).parent().find('.nested-item-form select.vat-total option:selected').val();
        return $(item).find('.vat-rate').attr('data-selected-value', selectedVatValue);
      });

      $('.order-totals .total-except-tax .total-value').text(totalAmountExcludingTaxes);
      $('.order-totals .vat-total .total-value').text(totalVatRate);
      return $('.order-totals .order-total .total-value').text(totalAmountIncludingTaxes);
    });

    $('#new_purchase_order').on('iceberg:validated', E.Purchases.compute_amount);
    $('.edit_purchase_order').on('iceberg:validated', E.Purchases.compute_amount);
    $('#new_purchase_order').on('cocoon:after-remove', E.Purchases.compute_amount);
    $('.edit_purchase_order').on('cocoon:after-remove', E.Purchases.compute_amount);

    $(document).on('click', '.nested-fields .edit-item[data-edit="item-form"]', function(event) {
      const vatSelectedValue = $(event.target).closest('.nested-fields').find('.item-display .vat-rate').attr('data-selected-value');
      if (vatSelectedValue !== undefined) { return $(event.target).closest('.nested-fields').find('.nested-item-form:visible .vat-total').val(vatSelectedValue).trigger('change'); }
    });

    return $(document).on('selector:change', 'input#purchase_invoice_supplier_id', function() {
      const supplier_id = $(this).parent().find('.selector-value').val();
      return $.ajax({
        url: `/backend/entities/${supplier_id}.json`,
        success(data,status, request) {
          return $(document).find('#purchase_invoice_payment_delay').val(data.supplier_payment_delay);
        }});
  });});

})(ekylibre, jQuery);
