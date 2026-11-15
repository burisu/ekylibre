(function(E, $) {
  'use strict';


  // Set scope for purchase
  return $(document).on("selector:change", "*[data-delivery-purchase]", function(event){
    const select = $(this);
    const form = select.closest("form");
    const entity_id = select.selector('value');
    const purchase = form.find('#incoming_parcel_purchase_id').first();
    let url = "/backend/purchases/unroll?working=true";
    const purchase_id = purchase.selector('value');
    if (purchase_id) {
      url += `&scope[current_or_self]=${purchase_id}`;
    } else {
      url += "&scope[current]=true";
    }
    if (entity_id) {
      url += `&scope[of_supplier]=${entity_id}`;
    }
    purchase.attr("data-selector", url);
    return purchase.data("selector", url);
});

})(ekylibre, jQuery);
