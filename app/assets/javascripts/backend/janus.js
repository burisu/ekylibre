(function(E, $) {
  'use strict';

  // Removed for now for performance reasons. Letting Turbo handle that one.
  const ajax_toggle = false;

  $(document).on("click", "*[data-janus] a[data-toggle='face']", function() {
    if (!ajax_toggle) { return true; }

    const button = $(this);
    $("*[data-toggle='face']").removeClass('active');
    button.addClass('active');
    const target = button.attr('data-janus-href');
    $("*[data-face].active").removeClass('active').trigger('face:deactivate');
    $(`*[data-face='${target}']`).addClass('active').trigger('face:activate');
    $(window).trigger('resize');
    const janus = button.closest("*[data-janus]");
    $.ajax({
      url: janus.data("janus"),
      data: {
        face: target
      },
      type: 'POST'
    });
    return false;
  });

  $(document).ready(() => $("*[data-face] *[data-list-source]").each(function() {
    const list = $(this);
    const face = list.closest("*[data-face]");
    if (!face.hasClass("active")) {
      const list_id = list.attr("id");
      return $(`*[data-list-ref='${list_id}']`).hide();
    }
  }));

  $(document).on("face:deactivate", "*[data-face]", function() {
    $(this).find("*[data-list-source]").each(function() {
      const list = $(this);
      const list_id = list.attr("id");
      return $(`*[data-list-ref='${list_id}']`).hide();
    });
    return false;
  });

  return $(document).on("face:activate", "*[data-face]", function() {
    $(this).find("*[data-list-source]").each(function() {
      const list = $(this);
      const list_id = list.attr("id");
      return $(`*[data-list-ref='${list_id}']`).show();
    });
    $(this).find("*[data-visualization]").each(function() {
      if (!$(this).hasClass('rebuilt')) {
        $(this).visualization('rebuild');
        return $(this).addClass('rebuilt');
      }
    });
    return false;
});

})(ekylibre, jQuery);
