(function(E, $) {
  'use strict';

  // Add class on removed item
  $(document).on("cocoon:before-remove", "*", function(event, item){
    if (item.hasClass("nested-fields")) { item.removeClass("nested-fields").addClass("removed-nested-fields"); }
    return true;
  });

  // Manage minimum/maximum
  $(document).behave('load cocoon:after-remove cocoon:after-insert', "[data-association-insertion-minimum]", function(event){
    const item = $(this);
    const minimum = item.data('association-insertion-minimum');
    const removers = item.find('> .nested-fields .nested-remove');
    if (item.find('.nested-fields').length <= minimum) {
      removers.hide();
    } else {
      removers.show();
    }
    return true;
  });

  // Manage minimum/maximum
  return $(document).behave('load cocoon:after-remove cocoon:after-insert', "[data-association-insertion-maximum]", function(event){
    const item = $(this);
    const maximum = item.data('association-insertion-maximum');
    const inserter = item.find('> .links');
    if (item.children('.nested-fields').length >= maximum) {
      inserter.hide();
    } else {
      inserter.show();
    }
    return true;
});

})(ekylibre, jQuery);
