(function(E, $) {
  "use strict";

  // Check or uncheck accesses recursively if needed
  $.fn.checkAccesses = function() {
    $(this).each(function() {
      const element = $(this);
      if (element.hasClass("active")) {
        element.find("input").prop("checked", true);
        if (element.data("need-accesses")) {
          return $.each(element.data("need-accesses").split(' '), (index, value) => $(`*[data-access=${value}]`).addClass("active").checkAccesses());
        }
      } else {
        element.find("input").prop("checked", false);
        if (element.data("access")) {
          return $(`*[data-need-accesses~=${element.data('access')}]`).removeClass("active").checkAccesses();
        }
      }
    });
    return $(this);
  };

  // Check accesses on click/change events
  $(document).on("click change", "*[data-access]", function() {
    $(this).toggleClass("active").checkAccesses();
    return false;
  });

  // Through a "role" selector, it can refresh totally on access check
  return $(document).on("selector:change", "*[data-selector][data-refresh-access-control-list]", function(_event, _selectedElement, was_initializing) {
    if (was_initializing) {
      return;
    }
    const element = $(this);
    $.ajax(element.data("refresh-access-control-list").replace(/ID/g, element.selector("value")), {
      dataType: "json",
      success(data, status, response) {
        $("*[data-access]").removeClass("active");
        // console.log data.rights
        for (var resource in data.rights) {
          var actions = data.rights[resource];
          for (var action of Array.from(actions)) {
            $(`*[data-access='${action}-${resource}']`).addClass("active");
          }
        }
        return $("*[data-access]").checkAccesses();
      },
      error: E.ajaxErrorHandler
    }
    );

    return true;
});

})(ekylibre, jQuery);
