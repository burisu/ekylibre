(function(E, $) {
  'use strict';
  const PURCHASE_PROCESS_FORM = '#new_reception, #new_purchase_invoice, .edit_reception, .edit_purchase_invoice';

  // Initialization of helpers for reconciliation badges
  $(() => {
    E.reconciliation.incident_badge = new StateBadgeSet('#incident-badge');
    E.reconciliation.badges = new StateBadgeSet('#reconciliation-badges');
    return E.reconciliation.state = new StateSet('.reconciliable-form', "reconciliable-form");
  });

  // Change reconciliation badges state
  const set_reconciliation_state = is_reconciled => {
    if (is_reconciled) {
      E.reconciliation.badges.setState('reconcile');
      return E.reconciliation.state.setState('reconcile');
    } else {
      E.reconciliation.badges.setState('to-reconcile');
      return E.reconciliation.state.setState('to-reconcile');
    }
  };

  // Change incident badge state
  const set_incident_state = is_incident => {
    if (is_incident) {
      return E.reconciliation.incident_badge.setState('incident');
    } else {
      return E.reconciliation.incident_badge.setState(null);
    }
  };

  // Update nested items styles based on their compliance state (incident)
  const handle_form_item_non_compliant = ($nested_fields, $input) => {
    if (!$input) { $input = $nested_fields.find('.reception-item-non-compliant'); }
    if ($input.is(':checked')) {
      return $nested_fields.addClass('reception-form__nested-fields--invalid');
    } else {
      return $nested_fields.removeClass('reception-form__nested-fields--invalid');
    }
  };

  // Handles non-compliance for late delivery checkbox in receptions
  $(document).on('change', '#reception_late_delivery', function() {
    const $container = $(this).closest('.reception-form');
    if ($(this).is(':checked')) {
      $container.addClass('reception-form--late');
    } else {
      $container.removeClass('reception-form--late');
    }
    return refresh_state();
  });

  // Handle non-compliance 'local' update for nested items
  $(document).on('change', '.reception-item-non-compliant', function() { return handle_form_item_non_compliant($(this).closest('tbody.nested-fields'), $(this)); });

  // Updates state for badges (reconciliation and incident)
  var refresh_state = () => {
    set_reconciliation_state(!!$('.nested-fields .nested-item-form[data-item-id]').length);
    return set_incident_state(!!$(".reception-form--late, .reception-form__nested-fields--invalid").length);
  };

  // Disable selector (unroll) component for variant in a nested-item-form for reconciliated items
  const prevent_unroll_edition_for_reconciliated_items = (e, data) => {
    let target;
    if (data) { target = data; }
    if (!target) { ({
      target
    } = e); }
    if (!$(target).is('tbody')) { target = $(target).closest('tbody'); }

    if ($(target).find('.nested-item-form[data-item-id]').length) {
      return E.reconciliation.disableSelectorInput($(target).find('input[id*="variant"]'));
    }
  };

  $(document).on('cocoon:after-insert', PURCHASE_PROCESS_FORM, prevent_unroll_edition_for_reconciliated_items);
  $(document).on('cocoon:after-remove', PURCHASE_PROCESS_FORM, refresh_state);

  // Update incident status (badge) after nested item form validation
  $(document).on('iceberg:cancelled iceberg:validated', (event, data) => {
    handle_form_item_non_compliant(data.line);
    return refresh_state();
  });

  //#############################
  //    Reconciliation modal    #
  //#############################
  // Open modal on button click
  $(document).on('click', '#showReconciliationModal', event => {
    const $form = $(event.target).closest('form');
    return open_reconciliation_modal($form);
  });

  // Validate modal
  const handle_modal_validation = modal => {
    return modal.getContent().find('.valid-modal').on('click', function(event) {
      const displayedItemIds = $('.nested-fields .nested-item-form[data-item-id]').map(function() { return $(this).attr('data-item-id'); }).toArray();
      E.reconciliation.createLinesWithSelectedItems(modal.getContent(), displayedItemIds, event);
      E.reconciliation.removeLineWithUnselectedItems(modal.getContent(), displayedItemIds, event);

      refresh_state();
      return modal.close();
    });
  };

  const purchase_invoice_modal_options = () => {
    const url = "/backend/purchase_process/reconciliation/receptions_to_reconciliate";
    const data = {supplier: $('input[name="purchase_invoice[supplier_id]"]').val()};
    const $form = $('.edit_purchase_invoice');
    if ($form.length) {
      const action = $form.attr('action');
      data['purchase_invoice'] = action.substr(action.lastIndexOf('/') + 1);
    }
    return {url, data};
  };

  const reception_modal_options = () => {
    const url = "/backend/purchase_process/reconciliation/purchase_orders_to_reconciliate";
    const data = {supplier: $('input[name="reception[sender_id]"]').val()};
    const $form = $('.edit_reception');
    if ($form.length) {
      const action = $form.attr('action');
      data['reception'] = action.substr(action.lastIndexOf('/') + 1);
    }
    return {url, data};
  };

  const isPurchaseInvoiceForm = $form => {
    return $form.closest('.simple_form').is('.new_purchase_invoice, .edit_purchase_invoice');
  };

  const isReceptionForm = $form => {
    return $form.closest('.simple_form').is('.new_reception, .edit_reception');
  };

  // Returns a promise that resolves to the content for the modal to be opened
  const content_for_reconciliation_modal = $form => {
    let options = {};
    if (isPurchaseInvoiceForm($form)) {
      options = purchase_invoice_modal_options();
    } else if (isReceptionForm($form)) {
      options = reception_modal_options();
    } else { return Promise.reject("Modal type cannot be guessed!"); }
    return E.ajax.html(options);
  };

  // Opens the reconciliation modal
  var open_reconciliation_modal = $form => {
    const prom = E.modal.open('#purchase_process_reconciliation', content_for_reconciliation_modal($form));
    prom.then(modal => {
      const content = modal.getContent().get(0);
      const root = content.querySelector('.purchase-orders');
      // Attacher un ecouteur evenement sur les checkbox des items
      E.delegateListener(root, 'click', ".item-checkbox", e => {
        const commandContainer = e.target.closest('.model');
        syncState(commandContainer, $form);
      });

      // Handle automated selection of multiple checkbox
      E.delegateListener(root, 'click', '.model-checkbox', e => {
        const {
          checked
        } = e.target;
        const commandContainer = e.target.closest('.model');
        setAllChildrenTo(commandContainer, checked, $form);
      });

      let displayedItemIds = Array.from(document.querySelectorAll('.nested-fields .nested-item-form[data-item-id]'));
      displayedItemIds = displayedItemIds.map(item => item.dataset.itemId);

      displayedItemIds.forEach(id => {
        const checkbox = content.querySelector(`.item input[type='checkbox'][data-id='${id}']`);
        const commandContainer = checkbox.closest('.model');
        if (checkbox) {
          checkbox.checked = true;
          return syncState(commandContainer, $form);
        }
      });
    });

    return prom.then(modal => {
      return handle_modal_validation(modal);
    });
  };

  //#### TOOLS
  // Only used for purchase invoice reconciliation with receptions
  // Manually set variant on unroll selector in order to bypass 'selector:change' trigger
  // Manually trigger 'cocoon:after-insert' in order to have correct event binding on item buttons
  $(document).behave('load', '*[data-lazy-loading-variant-id]', function() {
    $(this).selector('value', this.data('lazyLoadingVariantId'));
    const inserted = $(this).closest('.purchase-invoice-items');
    const reconciliationIdInput = inserted.find('#purchase_invoice_items_attributes_RECORD_ID_parcels_purchase_invoice_items');
    if (reconciliationIdInput.length > 0) {
      $(this).closest('table.list').trigger('cocoon:after-insert', [inserted]);
    }
    return inserted.find('.invoice-variant').on('selector:set', function() {
      // Automatically calculate invoice total field value
      inserted.find('.pre-tax-invoice-total').trigger('change');
      return inserted.find('.invoice-total').trigger('change');
    });
  });

  // Checks the parent checkbox if all children are checked. Uncheck it if not.
  // If all checked, set 'close command to true, else to false'
  // Also hide/display the close command radio
  var syncState = (commandContainer, $form) => {
    const itemCheckboxes = Array.from(commandContainer.querySelectorAll('.item-checkbox'));
    const allItemsCheckboxesChecked = itemCheckboxes.map(cb => cb.checked).reduce(((acc, e) => acc && e), true);
    commandContainer.querySelector('.model-checkbox').checked = allItemsCheckboxesChecked;
    computeTotals();

    if (isReceptionForm($form)) {
      setCloseCommand(commandContainer, allItemsCheckboxesChecked);

      const closePurchaseOrderBlock = commandContainer.querySelector('.close-purchase-order');
      if (itemCheckboxes.map(cb => cb.checked).includes(true)) {
        return closePurchaseOrderBlock.classList.remove('hidden');
      } else {
        return closePurchaseOrderBlock.classList.add('hidden');
      }
    }
  };

  // Sets the value of the radiobutton to `value`
  var setCloseCommand = (commandContainer, value) => {
    const closePurchaseOrderBlock = commandContainer.querySelector('.close-purchase-order');
    return closePurchaseOrderBlock.querySelector(`input[type='radio'][value=${value}`).checked = true;
  };

  // Sets all children checkboxes to 'value' and sync state
  var setAllChildrenTo = (commandContainer, value, $form) => {
    commandContainer.querySelectorAll('.item-checkbox').forEach(item => { return item.checked = value; });
    return syncState(commandContainer, $form);
  };

  var computeTotals = () => {
    const $itemsChecked = $('.item-checkbox:checked');
    let totalQuantity = '';
    let totalAmount = '';

    if (!!$itemsChecked.length) {
      const variantIds = $itemsChecked.map(function() { return $(this).siblings('.variant').data('id'); });
      const uniqVariant = _.uniq(variantIds).length === 1;

      if (uniqVariant) { totalQuantity = _.sum($itemsChecked.map(function() { return parseFloat($(this).siblings('.quantity-to-fill').text()) || 0; })).toFixed(2); }
      totalAmount = _.sum($itemsChecked.map(function() { return parseFloat($(this).siblings('.total-except-taxes').text()) || 0; })).toFixed(2);
    }

    $('.modal-footer .total-quantity').html(totalQuantity);
    return $('.modal-footer .total-amount').html(totalAmount);
  };

  E.reconciliation = {
    disableSelectorInput($selectorInput) {
      $selectorInput.prop('disabled', true);
      return $selectorInput.siblings(':last').addClass('disabled');
    },

    reconciliateItems(modalContent) {
      const checkedItemId = modalContent.find('.item-checkbox:checked').attr('data-id');
      const itemFieldId = $('.item-checkbox:checked').attr('data-item-field-id');

      if ($('#is-purchase-orders').val() === "false") {
        return $(`#${itemFieldId}`).val(JSON.stringify([checkedItemId]));
      } else {
        return $(`#${itemFieldId}`).val(checkedItemId);
      }
    },

    createLinesWithSelectedItems(modal, displayedItemIds, event) {
      const itemsCheckboxes = $(modal).find('.item-checkbox:checked');

      return itemsCheckboxes.each(function(index, itemCheckbox) {
        const isPurchaseOrderModal = $(itemCheckbox).closest('.modal-content').find('#is-purchase-orders').val();

        if (!displayedItemIds.includes($(itemCheckbox).attr('data-id'))) {
          E.reconciliation._createNewItemLine(itemCheckbox);

          if ((index === 0) && (isPurchaseOrderModal === "false")) {
            const responsibleId = $(itemCheckbox).closest('.item').attr('data-responsible-id');
            $('#purchase_invoice_responsible_id').first().selector('value', responsibleId);
          }

          E.reconciliation._fillNewLineForm(itemCheckbox, isPurchaseOrderModal);
        }

        if (isPurchaseOrderModal === "true") {
          const $itemCb = $(itemCheckbox);
          const purchaseOrderItemId = $itemCb.data('id');
          const $formContainer = $(`table.list .nested-fields .nested-item-form[data-item-id='${purchaseOrderItemId}']`);
          return purchaseOrderToCloseUpdate($itemCb, $formContainer);
        }
      });
    },

    removeLineWithUnselectedItems(modal, displayedItemIds, event) {
      for (var id of Array.from(displayedItemIds)) {
        var $checkbox = $(modal).find(`.item-checkbox[data-id=${id}]`);
        if ($checkbox.length && !$checkbox.prop('checked')) {
          var $container = $(`.nested-fields .nested-item-form[data-item-id='${id}']`).closest('tbody');
          if ($container.length) {
            $container.find('a.remove-item').click();
          }
        }
      }
    },

    _createNewItemLine(itemCheckbox) {
      const variantType = $(itemCheckbox).closest('.item').attr('data-variant-type');

      const $buttonToClick = (() => { switch (variantType) {
        case 'service': return $('.row-footer .add-service');
        case 'cost': return $('.row-footer .add-fees');
        default:
          return $('.row-footer .add-merchandise');
      } })();

      return $buttonToClick.find('.add_fields').trigger('click');
    },

    _fillNewLineForm(itemCheckbox, isPurchaseOrderModal) {
      const lastLineForm = $('table.list .nested-fields .nested-item-form:last:visible');
      const checkboxLine = $(itemCheckbox).closest('.item');
      const itemId = $(itemCheckbox).attr('data-id');
      const itemQuantity = $(checkboxLine).find('.item-value.quantity-to-fill').text();
      const equipmentId = $(checkboxLine).attr('data-equipment-id');
      const teamId = $(checkboxLine).attr('data-team-id');
      const projectBudgetId = $(checkboxLine).attr('data-project-budget-id');
      const activityBudgetId = $(checkboxLine).attr('data-activity-budget-id');
      const itemConditioningId = $(checkboxLine).attr('data-conditioning-unit-id');
      const itemAnnotation = $(checkboxLine).attr('data-annotation');
      const itemCompliantState = $(checkboxLine).attr('data-non-compliant');

      $(lastLineForm).attr('data-item-id', itemId);
      $(lastLineForm).attr('data-non-compliant', itemCompliantState);

      if (isPurchaseOrderModal === "true") {
        E.reconciliation._fillPurchaseOrderItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemConditioningId, itemAnnotation);
      } else {
        E.reconciliation._fillReceptionItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemConditioningId, itemAnnotation);
      }

      $(lastLineForm).find('input[data-remember="equipment"]').first().selector('value', equipmentId);
      $(lastLineForm).find('input[data-remember="team"]').first().selector('value', teamId);
      $(lastLineForm).find('input[data-remember="project_budget"]').first().selector('value', projectBudgetId);
      $(lastLineForm).find('input[data-remember="activity_budget"]').first().selector('value', activityBudgetId);
      $(lastLineForm).find('.no-reconciliate-item-state').addClass('hidden');
      $(lastLineForm).find('.reconciliate-item-state').removeClass('hidden');
      const $line = $(lastLineForm).parent('.nested-fields');
      return $line.data('_iceberg').bindSelectorsInitialization(() => $line.data('_iceberg').setCocoonFormSubmitable());
    },

    // Creates a line BASED on a ReceptionItem
    _fillReceptionItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemConditioningId, itemAnnotation) {
      const variantId = $(checkboxLine).find('.variant').attr('data-id');
      const teamId = $(checkboxLine).attr('data-team-id');
      const activityBudgetId = $(checkboxLine).attr('data-activity-budget-id');
      const itemUnitCost = $(checkboxLine).find('.item-value.unit-cost').text();
      const itemTotalAmount = $(checkboxLine).find('.item-value.total-except-taxes').text();
      let itemReductionPercentage = $(checkboxLine).attr('data-reduction-percentage');
      const itemTaxId = $(checkboxLine).attr('data-tax-id');
      const itemSupplierReference = $(checkboxLine).attr('data-supplier-ref');

      if ((itemReductionPercentage === "") || (itemReductionPercentage === undefined)) {
        itemReductionPercentage = 0;
      }

      const itemCompliantState = $(checkboxLine).attr('data-non-compliant');
      $(lastLineForm).attr('data-item-id', itemId);
      $(lastLineForm).attr('data-non-compliant', itemCompliantState);

      const receptionItemAlreadyPresent = ($('.purchase-item-attribute').filter(function() { return ($(this).val() === JSON.stringify([itemId])); })).length;

      if (!receptionItemAlreadyPresent) { $(lastLineForm).find('.purchase-item-attribute').val(JSON.stringify([itemId])); }
      $(lastLineForm).find('.form-field .invoice-quantity').val(itemQuantity);
      $(lastLineForm).find('.form-field .invoice-unit-amount').val(itemUnitCost);
      $(lastLineForm).find('.form-field .invoice-discount-percentage').val(itemReductionPercentage);
      $(lastLineForm).find('.form-field .pre-tax-invoice-total').val(itemTotalAmount);
      const $variantSelector = $(lastLineForm).find('.form-field .invoice-variant').first();
      $variantSelector.selector('value', variantId, (function() { E.reconciliation.disableSelectorInput($variantSelector);return $(lastLineForm).find('.form-field .invoice-quantity').trigger('change'); }));
      const $conditioningSelector = $(lastLineForm).find('.invoice-conditioning').first();
      $conditioningSelector.selector('value', itemConditioningId, (function() { E.reconciliation.disableSelectorInput($conditioningSelector);return $conditioningSelector.trigger('selector:change'); }));
      $(lastLineForm).find('.form-field .purchase_invoice_items_activity_budget .selector-search').first().selector('value', activityBudgetId);
      $(lastLineForm).find('.form-field .purchase_invoice_items_team .selector-search').first().selector('value', teamId);
      $(lastLineForm).find('.annotation-logo .annotation-field').trigger('click');
      $(lastLineForm).find('.annotation-section .annotation').val(itemAnnotation);

      $(lastLineForm).find('.form-field .supplier-ref-value').text(itemSupplierReference);
      $(lastLineForm).find('.form-field .supplier-ref-block').removeClass('hidden');

      const invoiceVatField = $(lastLineForm).find('.form-field .vat-total');

      if (itemTaxId) {
        $(invoiceVatField).val(itemTaxId).change();
      } else {
        const firstVatValue = $(lastLineForm).find('.form-field .vat-total option:first').val();
        $(invoiceVatField).val(firstVatValue).change();
      }

      return setTimeout((() => $('.form-field .invoice-total').trigger('change')), 1000);
    },

    // Creates a line BASED on a PurchaseOrder
    _fillPurchaseOrderItem(lastLineForm, checkboxLine, itemId, itemQuantity, itemConditioningId, itemAnnotation) {
      const variantId = $(checkboxLine).find('.variant').attr('data-id');
      const variantType = $(checkboxLine).attr('data-variant-type');

      $(lastLineForm).find('.purchase-item-attribute').val(itemId);

      const $conditioningSelector = $(lastLineForm).find('.reception-conditionning').first();
      const $variantSelector = $(lastLineForm).find('.item-block-role .parcel-item-variant').first();

      $conditioningSelector.selector('value', itemConditioningId, (function() { E.reconciliation.disableSelectorInput($conditioningSelector);return $conditioningSelector.trigger('selector:change'); }));
      $variantSelector.selector('value', variantId, (function() { E.reconciliation.disableSelectorInput($variantSelector);$(lastLineForm).find('.form-field .invoice-quantity').trigger('change');return $variantSelector.trigger('selector:change', [null, null, { stayDisabled: true }]); }));
      $(lastLineForm).find('.hidden.purchase-item-attribute').val(itemId);
      $(lastLineForm).find('.annotation-logo .annotation-field').trigger('click');
      $(lastLineForm).find('.annotation-section .annotation').val(itemAnnotation);

      if ((variantType === "service") || (variantType === "cost")) {
        $(lastLineForm).find('.reception-quantity').val(itemQuantity);
        return $(lastLineForm).find('.buttons button[data-validate="item-form"]').removeAttr('disabled');
      } else {
        return $(lastLineForm).find('.nested-fields.storing-fields:first .storing-quantifier .storing-quantity').val(itemQuantity);
      }
    }
  };

  // Given checkbox and formContainer, this method sets the purchase-order-to-close-id property to the purchase order id on the given reception item's form fields
  //    if the purchase order of the selected element is marked for closure when saving the reception
  //
  // @param [jQuery<HTMLElement>] checkbox %li containing a checkbox for an item to maybereconcile
  // @param [jQuery<HTMLElement>] formContainer form line containing information about a reception item
  var purchaseOrderToCloseUpdate = function($checkbox, $formContainer) {
    const $purchaseOrderLine = $checkbox.closest('.model');
    const modelId = $purchaseOrderLine.find('.model-checkbox').attr('data-id');
    const $closePurchaseOrderBlock = $purchaseOrderLine.find('.close-purchase-order');
    if ($closePurchaseOrderBlock.find('input[type="radio"][value="true"]').is(':checked')) {
      return $formContainer.find('.purchase-order-to-close-id').val(modelId);
    }
  };

  E.onElementDetected('new_reception', form => {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('purchase_order_ids')) {
      return open_reconciliation_modal($(form));
    }
  });

  return E.onElementDetected('new_purchase_invoice', form => {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('reception_ids')) {
      return open_reconciliation_modal($(form));
    }
});


})(ekylibre, jQuery);
