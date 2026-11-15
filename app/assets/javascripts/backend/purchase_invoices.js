(function(E, $) {
  'use strict';

  $(document).ready(function() {
    const reconciliation_badges = new StateBadgeSet('#reconciliation-badges');

    $('.nested-fields.purchase-invoice-items').each(function(index, purchase_invoice) {
      const hiddenFieldToChange = $(purchase_invoice).find('input[name="purchase_invoice[items_attributes][RECORD_ID][parcels_purchase_invoice_items]"]');
      $(hiddenFieldToChange).attr('name', `purchase_invoice[items_attributes][${ index }][parcels_purchase_invoice_items]`);
      return $(hiddenFieldToChange).attr('id', `purchase_invoice_items_attributes_${ index }_parcels_purchase_invoice_items`);
    });

    $(document).on('click', '.btn[data-validate="item-form"]', function(event) {
      let totalAmountExcludingTaxes = 0;
      let totalVatRate = 0;
      let totalAmountIncludingTaxes = 0;

      $('.nested-fields.purchase-invoice-items .item-display').map((index, item) => {
        const amountExcludingTaxes = $(item).find('.pretax-amount-column label.amount-excluding-taxes').text();
        const vatRate = $(item).find('.total-column label.vat-rate').text().split("%")[0];
        const amountIncludingTaxes = $(item).find('.total-column label.amount-including-taxes').text();

        if ((amountExcludingTaxes === "??????") || (amountIncludingTaxes === "??????") || (vatRate === "??????")) {
          return;
        }

        totalAmountExcludingTaxes += parseFloat(amountExcludingTaxes);
        totalAmountIncludingTaxes += parseFloat(amountIncludingTaxes);

        const calculVatRate = (parseFloat(amountExcludingTaxes) * parseFloat(vatRate)) / 100;
        totalVatRate += calculVatRate;

        const selectedVatValue = $(item).parent().find('.nested-item-form select.vat-total option:selected').val();
        return $(item).find('.vat-rate').attr('data-selected-value', selectedVatValue);
      });

      $('.invoice-totals .total-except-tax .total-value').text(parseFloat(totalAmountExcludingTaxes).toFixed(2));
      $('.invoice-totals .vat-total .total-value').text(parseFloat(totalVatRate).toFixed(2));
      $('.invoice-totals .invoice-total .total-value').text(parseFloat(totalAmountIncludingTaxes).toFixed(2));

      const targettedElement = $(event.target);
      const fieldAssetFields = targettedElement.closest('.merchandise').find('.fixed-asset-fields');

      const fixedAssetCheckbox = fieldAssetFields.find('.purchase_invoice_items_fixed input[type="checkbox"]');
      const preexistingCheckbox = fieldAssetFields.find('.purchase_invoice_items_preexisting_asset input[type="checkbox"]');
      const depreciableProductField = fieldAssetFields.find('.purchase_invoice_items_depreciable_product .selector-value');
      const fixedAssetField = fieldAssetFields.find('.purchase_invoice_items_fixed_asset .selector-value');
      const stoppedOnField = fieldAssetFields.find('.purchase_invoice_items_fixed_asset_stopped_on input');

      fixedAssetCheckbox.prop('checked', false);
      fixedAssetCheckbox.trigger('change');

      preexistingCheckbox.prop('checked', false);
      preexistingCheckbox.trigger('change');

      depreciableProductField.val('');
      fixedAssetField.val('');
      return stoppedOnField.val('');
    });

    $('#new_purchase_invoice').on('iceberg:validated', E.Purchases.compute_amount);
    $('.edit_purchase_invoice').on('iceberg:validated', E.Purchases.compute_amount);
    $('#new_purchase_invoice').on('cocoon:after-remove', E.Purchases.compute_amount);
    $('.edit_purchase_invoice').on('cocoon:after-remove', E.Purchases.compute_amount);

    $('#new_purchase_invoice table.list, .edit_purchase_invoice table.list').on('cocoon:after-insert', function(event, insertedItem) {
          if (typeof insertedItem !== 'undefined') {
            let new_id = insertedItem.html().match(new RegExp('\\[(\\d+)\\]'))[1]; //HACK: Get id from inputs
            new_id = new_id || new Date().getTime();

            insertedItem.attr('id', `new_reception_${new_id}`);

            $(insertedItem).find('input, select').each(function() {
              const oldId = $(this).attr('id');
              if (!!oldId) {
                const elementNewId = oldId.replace(/[0-9]+/, new_id);
                $(this).attr('id', elementNewId);
              }

              const oldName = $(this).attr('name');
              if (!!oldName) {
                const elementNewName = oldName.replace(/[0-9]+/, new_id);
                return $(this).attr('name', elementNewName);
              }
            });

            const element = $(insertedItem).find('#purchase_invoice_items_attributes_RECORD_ID_parcels_purchase_invoice_items');
            const newName = element.attr('name').replace('RECORD_ID', new_id);
            const newId = element.attr('id').replace('RECORD_ID', new_id);

            $(element).attr('id', newId);
            return $(element).attr('name', newName);
          }
    });

    $(document).on('change', '.nested-item-form .fixed-asset-fields .purchase_invoice_items_fixed input[type="checkbox"]', function(event) {
      const targettedElement = $(event.target);
      return E.PurchaseInvoices.displayAssetsBlock(targettedElement);
    });

    $(document).on('change', '.nested-item-form .fixed-asset-fields .purchase_invoice_items_preexisting_asset input[type="checkbox"]', function(event) {
      const targettedElement = $(event.target);
      return E.PurchaseInvoices.manageExistingAssetDisplay(targettedElement);
    });

    $(document).on('click', '.change-reconciliation-state-block input[type="checkbox"]', function(event) {
      const checkbox = $(event.target);
      return E.PurchaseInvoicesShow.changeEventReconciliationStateBlock(checkbox);
    });

    return E.PurchaseInvoicesShow = {
      changeEventReconciliationStateBlock(checkbox) {
        const reconciliationTitle = $('.reconciliation-title');
        const purchase_invoice_id = window.location.pathname.split('/').pop();
        const isReconcile = $(reconciliationTitle).attr('data-reconcile') === 'true';
        let url = `/backend/purchases/reconciliation_states/${ purchase_invoice_id }`;

        if (checkbox.is(':checked')) {
          url += '/put_accepted_state';
        } else {
          if (isReconcile) { url += '/put_reconcile_state'; }
          if (!isReconcile) { url += '/put_to_reconcile_state'; }
        }

        return $.get(url).then(() => {
          if (checkbox.is(':checked')) {
            return reconciliation_badges.setState('accepted');
          } else {
            return reconciliation_badges.setState('to-reconcile');
          }
        });
      }
    };
  });

  E.PurchaseInvoices = {
    displayAssetsBlock(fixedCheckbox) {
      const fixedAssetFields = fixedCheckbox.closest('.fixed-asset-fields');
      const assetBlock = $(fixedAssetFields).find('.assets');

      if (fixedCheckbox.is(':checked')) {
        return assetBlock.css('display', 'block');
      } else {
        return assetBlock.css('display', 'none');
      }
    },


    manageExistingAssetDisplay(preexistingCheckbox) {
      const assetsFields = preexistingCheckbox.closest('.assets');
      const existingAssetBlock = $(assetsFields).find('.existing_asset');
      const newAssetBlock = $(assetsFields).find('.new_asset');

      if (preexistingCheckbox.is(':checked')) {
        existingAssetBlock.css('display', 'block');
        return newAssetBlock.css('display', 'none');
      } else {
        existingAssetBlock.css('display', 'none');
        return newAssetBlock.css('display', 'block');
      }
    }
  };
  
  const urlParams = function() {
    const queryString = window.location.search;
    return new URLSearchParams(queryString);
  };

  const undisabledInputOnNewPurchaseInvoiceItem = function() {
    if (urlParams().get('mode') === 'prefilled') {
      document.querySelectorAll('input[data-selector-id=\'purchase_item_variant_id\']').forEach(function(currentValue) {
        if (currentValue['value'] === '') {
          currentValue.disabled = false;
        }
      });
    }
  };

  return $(document).on('cocoon:after-insert', '#new_purchase_invoice', function(e) {
    undisabledInputOnNewPurchaseInvoiceItem();
    
});

})(ekylibre, jQuery);
