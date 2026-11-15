//= require jquery.blank
//= require jquery-ui/widgets/sortable

(function($) {
  "use strict";
  $(document).ready(() => // Initialize cells loading asynchronously their contents
  $("*[data-async-content]").each(function(index) {
    const element = $(this);
    let async_div = element.closest("*[data-beehive-cell]");
    if (!async_div.length) {
      async_div = element;
    }
    async_div.addClass("loading");
    element.html("<i class='cell-indicator'></i>");
    return $.ajax({
      url: element.data("async-content"),
      dataType: "html",
      success(data, status, request) {
        async_div.removeClass("loading");
        if ($.isBlank(data)) {
          async_div.addClass("blank");
          element.append($(`<p class='cell-message'>${element.data('async-content-empty-message')}</p>`));
          return element.trigger('cell:empty');
        } else {
          element.html(data);
          element.trigger('cell:load');
          return $(window).trigger('resize');
        }
      },
      error(request, status, error) {
        console.error(`Error while retrieving ${element.data('async-content')} cell content: ${status} ${error}`);
        async_div.removeClass("loading");
        async_div.addClass("errored");
        element.append($(`<p class='cell-message'>${element.data('async-content-error-message')}</p>`));
        return element.trigger('cell:error');
      }
    });
  }));
  return true;
})(jQuery);
