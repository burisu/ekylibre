(function($) {

  // This method scope css selection inside a form or the value of data-scoper attribute
  $.fn.extend({
    formScope() {
      const reference = $(this);
      return reference.closest(reference.data("closest") || reference.data("scoper") || "form");
    }
  });

  $.fn.extend({
    formScopedSelect(selection) {
      const reference = $(this);
      if (reference.length === 1) {
        const scoper = reference.formScope();
        if (scoper.size() > 0) {
          return scoper.find(selection);
        } else {
          return $(selection);
        }
      } else {
        return console.log("You must call formScopedSelect on '1 element' object, not like: ", reference);
      }
    }
  });


})(jQuery);
