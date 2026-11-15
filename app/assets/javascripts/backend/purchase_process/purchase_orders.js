(function(E, $) {
  'use strict';

  const listControlledBtn = {
    toggleNewInvoiceButton() {
      const $btn = $('#generate-invoice-btn button').length ? $('#generate-invoice-btn button') : $('#generate-invoice-btn a');
      const linksUrls = $('#generate-invoice-btn a').map(function() { return { element: $(this), url: $(this).prop('href') }; });
      return this._bindInputs('reception', 'sender', $btn, linksUrls);
    },

    toggleNewReceptionButton() {
      const $btn = $('#generate-parcel-btn');
      const linksUrls = [{ element: $btn, url: $btn.prop('href') }];
      return this._bindInputs('purchase_order', 'supplier', $btn, linksUrls);
    },

    _bindInputs(model, third, $btn, linksUrls) {
      return $(document).on('change', 'input[data-list-selector]', () => {
        const $selectedItems = this._getSelectedItems();
        const selectedItemsIds = this._getSelectedItemsIds($selectedItems);
        const $reconciledItems = this._getReconciledItems($selectedItems);
        const $closedItems = this._getItemsByState($selectedItems, 'closed');
        const $draftItems = this._getItemsByState($selectedItems, 'draft');
        const sameThird = this._checkThirdUniqueness($selectedItems, third);
        this._setBtnUrl(selectedItemsIds, $btn, model, linksUrls);
        return this._setDisabledProp(model, $btn, $selectedItems, $reconciledItems, $closedItems, $draftItems, sameThird);
      });
    },

    _getSelectedItems() {
      return $('input[data-list-selector]:checked').filter(function() {
        return /\d/.test($(this).data('list-selector'));
      });
    },

    _getSelectedItemsIds($selectedItems) {
      return $selectedItems.map(function() {
        return $(this).data('list-selector');}).toArray();
    },

    _getReconciledItems($selectedItems) {
      return $selectedItems.filter(function() {
        return $(this).closest('tr').data('reconciliation-state') === 'reconcile';
      });
    },

    _getItemsByState($selectedItems, state) {
      return $selectedItems.filter(function() {
        return $(this).closest('tr').data('state') === state;
      });
    },

    _checkThirdUniqueness($selectedItems, third) {
      const selectedItemsThirdIds = $selectedItems.map(function() {
                                return $(this).closest('tr').data(`${third}Id`);}).toArray();

      return _.uniq(_.compact(selectedItemsThirdIds)).length === 1;
    },

    _setBtnUrl(selectedItemsIds, $btn, model, linksUrls) {
      const urlSeparator = (() => {
        if (model === 'purchase_order') {
        return '?';
      } else if (model === 'reception') {
        return '&';
      }
      })();

      return Array.from(linksUrls).map((linkUrl) =>
        selectedItemsIds.length > 0 ?
          $(linkUrl.element).prop('href', `${linkUrl.url}${urlSeparator}mode=prefilled&${model}_ids=${selectedItemsIds}`)
        :
          $(linkUrl.element).prop('href', linkUrl.url));
    },

    _setDisabledProp(model, $btn, $selectedItems, $reconciledItems, $closedItems, $draftItems, sameThird) {
      const disabled = (() => {
        if (model === 'reception') {
        return !$selectedItems.length || !sameThird || $draftItems.length;
      } else if (model === 'purchase_order') {
        return !$selectedItems.length || $reconciledItems.length || !sameThird || $closedItems.length;
      }
      })();

      return $btn.toggleClass('disabled', !!disabled);
    }
  };

  return $(document).ready(function() {
    if ($('#purchase_orders-list, #unreceived_purchase_orders-list').length > 0) { listControlledBtn.toggleNewReceptionButton(); }
    if ($('#receptions-list').length > 0) { return listControlledBtn.toggleNewInvoiceButton(); }});

})(ekylibre, jQuery);
