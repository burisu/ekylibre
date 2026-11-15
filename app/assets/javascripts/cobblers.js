//= require jquery-ui/widgets/sortable

(function(E, $) {
  "use strict";

  E.cobblers = {
    save(widget) {
      const list = [];
      widget.find("> .cobbles-body > .cobble").each(function() {
        return list.push($(this).attr("id"));
      });
      console.log(list);
      return $.ajax({
        url: widget.data("cobbles"),
        type: 'patch',
        data: {
          order: list
        }
      });
    }
  };

  $(document).ready(function() {
    return $("*[data-cobbles]").sortable({
      handle: ".cobble-title",
      tolerance: "pointer",
      placeholder: "cobble cobble-placeholder",
      items: ".cobble",
      containment: "parent",
      update() {
        $(window).trigger('resize');
        return E.cobblers.save($(this));
      }
    });
  });
  return true;
})(ekylibre, jQuery);
