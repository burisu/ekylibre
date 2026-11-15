(function(E, $) {
  'use strict';

  return $(document).ready(() => $(document).on('selector:change input', '#inventory_achieved_at, .inventory_financial_year .selector-value, .inventory_product_nature_category .selector-value', event => {
    const achieved_at = $('#inventory_achieved_at').val();
    const financial_year_id = $('.inventory_financial_year .selector-value')[0].value;
    const nature_category_id = $('.inventory_product_nature_category .selector-value')[0].value;
    let url = nature_category_id ? `/backend/inventories/new?product_nature_category_id=${nature_category_id}` : "/backend/inventories/new?product_nature_category=all";
    url += financial_year_id ? `&financial_year_id=${financial_year_id}` : '';
    url += achieved_at ? `&achieved_at=${achieved_at}` : '';
    return $('.validate-inventory-category').attr('href', url);
}));

})(ekylibre, jQuery);
