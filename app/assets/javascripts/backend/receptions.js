(function(E, $) {
  'use strict';

  $(document).ready(function() {
    $('table.list').on('cocoon:after-insert', function(event, $insertedItem) {
      $('*[data-iceberg]').on("iceberg:inserted", function() {
        const that = $(this);
        return $(this).find('*[data-association]').each(function(i, cocoonBtn) {
          const node = $(cocoonBtn).data('association-insertion-node');
          const storageContainer = $(node).parent();
          return storageContainer.on('cocoon:after-insert cocoon:after-remove', function() {
            E.toggleValidateButton(that);
            return E.setStorageUnitName(that);
          });
        });
      });

      if ($insertedItem && $insertedItem.hasClass('storing-fields')) {
        const unitName = $insertedItem.closest('.item-block__storing').find('.storage-unit-name').first().text();
        return $insertedItem.find('.storage-unit-name').text(unitName);
      }
    });

    return $('.new_reception, .edit_reception').on('change', '#reception_reconciliation_state', function(event) {
      const checked = $(event.target).is(':checked');

      if (checked) {
        return $(event.target).val('accepted');
      } else {
        return $(event.target).val('to_reconciliate');
      }
    });
  });

  const updateTotalStockAfterReception = ($form, newStock, currentStock) => {
    const $totalQuantityAfterReception = $form.find(".merchandise-total-stock-after-reception .stock-value");
    const stockReceived = (newStock - currentStock).toFixed(2);
    $totalQuantityAfterReception.data('interpolate-data-attribute', stockReceived);
    $totalQuantityAfterReception.attr('data-interpolate-data-attribute', stockReceived);
    return $totalQuantityAfterReception.text(newStock.toFixed(2));
  };

  const computeTotalQuantity = $form => {
    const reducer = (acc, val) => acc + parseFloat(val);

    return $form.find('.storing-fields')
      .map(function() { return ($(this).find('.storing-quantity').val() || 0) * ($(this).find('[data-coefficient]').data('coefficient') || 0); })
      .toArray()
      .reduce(reducer, .0);
  };

  const onQuantityChanged = $input => {
    const $form = $input.closest('.nested-item-form');
    const $storageForm = $input.closest('.nested-fields');
    const $storage = $($storageForm.find(".parcel-item-storage.selector-search").get(0));
    const coefficient = $form.find('[data-coefficient]').data('coefficient');
    if (coefficient && $storage.selector('value')) {
      updateAfterReceptionQuantity($storage.closest('.nested-fields'));
      return recomputeTotalQuantity($form);
    }
  };

  var recomputeTotalQuantity = $form => {
    const totalQuantity = computeTotalQuantity($form);
    return onTotalQuantityChanged($form, totalQuantity);
  };

  var onTotalQuantityChanged = ($form, totalQuantity) => {
    let newStock;
    const currentStock = getCurrentStock($form);
    if (totalQuantity.length === 0) {
      newStock = currentStock;
    } else {
      newStock = currentStock + parseFloat(totalQuantity);
    }
    return updateTotalStockAfterReception($form, newStock, currentStock);
  };

  var getCurrentStock = $form => {
    return parseFloat($form.find('.merchandise-total-current-stock .stock-value').text());
  };

  const getVariantStock = variantId => {
    return $.getJSON(`/backend/product_nature_variants/${variantId}/detail`)
      .then(data => {
        return {
          stock: data.default_unit_stock,
          unit: data.default_unit_name,
          unitId: data.default_unit_id,
          isEquipment: data.is_equipment
        };
    });
  };

  const getStorageStock = (variantId, storageId) => {
    return $.getJSON(`/backend/product_nature_variants/${variantId}/storage_detail`, {storage_id: storageId})
      .then(data => {
        return {
          stock: data.quantity,
          unit: data.unit,
          name: data.name
        };
    });
  };

  var updateAfterReceptionQuantity = $storage => {
    const storingQuantity = $storage.find('.storing-quantity').val() || 0;
    const currentStock = $storage.find('.merchandise-current-stock .stock-value').text();
    const coefficient = $storage.find('[data-coefficient]').data('coefficient');
    const stockAfterReception = parseFloat(storingQuantity * coefficient) + parseFloat(currentStock);
    return $storage.find('.merchandise-stock-after-reception .stock-value').text(stockAfterReception.toFixed(2));
  };

  const onStorageChanged = $storageSelector => {
    const $form = $storageSelector.closest('.nested-item-form');
    const $storage = $storageSelector.closest('.nested-fields');

    const storageId = $storageSelector.selector('value');
    const variantId = $($form.find(".parcel-item-variant.selector-search").get(0)).selector('value');

    if (variantId && storageId) {
      return getStorageStock(variantId, storageId).then(data => {
        $storage.find(".merchandise-current-stock .stock-value").text(parseFloat(data.stock).toFixed(2));
        $storage.find(".stock-unit").text(data.unit);
        $storageSelector.data('storage-name', data.name);
        $storageSelector.attr('data-storage-name', data.name);
        updateAfterReceptionQuantity($storage);
        return recomputeTotalQuantity($form);
      });
    }
  };

  const onvariantChanged = $variantSelector => {
    const $form = $variantSelector.closest('.nested-item-form');
    const $conditioningSelector = $form.find('.reception-conditionning').first();
    const variantId = $variantSelector.selector('value');
    return getVariantStock(variantId).then(data => {
      if (data.isEquipment) {
        $conditioningSelector.selector('value', data.unitId, (function() { E.reconciliation.disableSelectorInput($conditioningSelector);return $conditioningSelector.trigger('selector:change'); }));
      }
      updateQuantities($form);
      $form.find(".stock-unit").text(data.unit);
      $form.find(".merchandise-total-current-stock .stock-value").text(parseFloat(data.stock).toFixed(2));
      $form.find('.storing-quantity').trigger('change');
      return $form.find('input.parcel-item-storage').trigger('selector:change');
    });
  };

  const onStorageAdded = $storageLine => {
    $storageLine.closest('.nested-item-form').find('[data-filter-unroll]').trigger('selector:change');
    const $input = $storageLine.find('.storing-quantity');
    return updateQuantity($input);
  };

  var updateQuantity = $input => {
    if (($input.val() === "0") || ($input.val() === "")) {
      $input.val(1);
    }
    return $input.trigger('change');
  };

  var updateQuantities = $form => {
    return $form.find('.storing-quantity').each(function() { return updateQuantity($(this)); });
  };

  $(document).on('selector:change', '.reception_sender .controls .selector, .purchase_invoice_supplier .controls .selector', event => $('#showReconciliationModal').removeClass('disabled'));

  $(document).on('keyup change', '.nested-fields .item-form__role .storing-quantifier .storing-quantity', function(event) {
    return onQuantityChanged($(this));
  });

  $(document).on('selector:change', '.parcel-item-variant.selector-search', function(event) {
    return onvariantChanged($(this));
  });

  $(document).on('selector:change', '.parcel-item-storage.selector-search', function(event) {
    return onStorageChanged($(this));
  });

  $(document).on('cocoon:after-insert', '.storing-row', (event, $insertedRow) => onStorageAdded($insertedRow));

  return $(document).on('cocoon:after-remove', '.storing-row', function(event) {
    return recomputeTotalQuantity($(this).closest('.nested-item-form'));
});

})(ekylibre, jQuery);
