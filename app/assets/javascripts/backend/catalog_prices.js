// allows price and tax auto filling in sales view

(function($) {
  'use strict';

  $(document).on('change', '#catalog_item_all_taxes_included', function() {
    const $amount = $("#catalog_item_amount");
    const $container = $(this).closest('.catalog-items-form');
    if ($(this).is(':checked')) {
      return $container.addClass('catalog-items-form--all-taxes');
    } else {
      return $container.removeClass('catalog-items-form--all-taxes');
    }
  });

  // Manage fields filling in sales
  $(document).on("selector:change", "*[data-priced-item]", function() {
    // Get json info on priced item
    const element = $(this);
    const options = element.data("priced-item");
    const price_id = element.selector('value');
    const reg = new RegExp("\\bPRICE_ID\\b", "g");
    if (price_id != null) {
      return $.ajax(options.url.replace(reg, price_id), {
        dataType: "json",
        success(data, status, request) {
          // Update fields
          const row = element.closest(options.scope || "body");
          row.find(options.amount || ".amount").val(data.amount);
          if (data.reference_tax_id != null) {
            return row.find(options.tax || ".tax").val(data.reference_tax_id);
          }
        },
        error(request, status, error) {
          return console.log(`Error while retrieving price and tax fields content: ${error}`);
        }
      }
      );
    }
  });

  // Manage fields filling in purchases
  $(document).on("click selector:change emulated:change", "*[data-priced-variant]", function() {
    // Get json info on priced variant
    const element = $(this);
    const options = element.data("priced-variant");
    const variant_id = element.selector('value');
    const supplier_id = $("*[data-parameter-name='supplier_id']").val();
    const reg = new RegExp("\\bVARIANT_ID\\b", "g");
    if (variant_id != null) {
      return $.ajax(options.url.replace(reg, variant_id), {
        dataType: "json",
        data: {supplier_id: `${supplier_id}`},
        success(data, status, request) {
          // Update fields
          const row = element.closest(options.scope || "body");
          row.find(options.amount || ".amount").val(data.pretax_amount);
          if (data.tax_id != null) {
            return row.find(options.tax || ".tax").val(data.tax_id);
          }
        },
        error(request, status, error) {
          return console.log(`Error while retrieving price and tax fields content: ${error}`);
        }
      }
      );
    }
  });

  // trigger to update fields when changing supplier
  $(document).on("selector:change", "*[data-parameter-name='supplier_id']", () => $("*[data-priced-variant]").trigger("emulated:change"));

})(jQuery);
