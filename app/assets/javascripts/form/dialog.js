(function(E, $) {
  "use strict";

  E.dialog = {
    count: 0,

    open(url, settings) {
      let frame_id = `dialog-${E.dialog.count}`;

      if (settings.inherit != null) {
        frame_id = settings.inherit;
      }

      let width = $(document).width();
      const defaultSettings = {
        header: "X-Return-Code",
        width: 0.9,
        height: 0.9
      };

      if ((settings === null) || (settings === undefined)) { settings = {}; }
      settings = $.extend({}, defaultSettings, settings);
      const data = settings.data || {};
      data.dialog = frame_id;
      $.ajax(url, {
        data,
        success(data, status, request) {

          let frame;
          if ($(`#${frame_id}`).length) {
            frame = $(`#${frame_id}`);
          } else {
            frame = $(document.createElement("div"));
            $("body").append(frame);
          }

          width = undefined;
          let height = undefined;
          frame.attr({
            id: frame_id,
            class: "dialog ajax-dialog",
            style: "display:none;"
          });

          frame.html(data);
          frame.prop("dialogSettings", settings);
          if (settings.width === 0) {
            width = "auto";
          } else if (settings.width < 1) {
            width = $(window).width() * settings.width;
          } else {
            ({
              width
            } = settings);
          }
          if (settings.height === 0) {
            height = "auto";
          } else if (settings.height < 1) {
            height = $(window).height() * settings.height;
          } else {
            ({
              height
            } = settings);
          }

          if (frame.is(':ui-dialog')) {

            //Ensure dialog content is visible
            frame.addClass('ui-dialog-content');
          }

          frame.dialog({
            autoOpen: false,
            show: "fade",
            modal: true,
            width,
            maxHeight: height
          });
          frame.css("overflow-y", "auto");

          E.dialog.initialize(frame);
          frame.dialog("open");

          frame.trigger('dialog:show');

          $(`#${frame_id}`).on('selector:menu-opened', function(e) {
            const $el = $(this).find('.form-fields:visible');
            const pad = parseInt($el.css('padding-top').replace('px','')) + parseInt($el.css('padding-bottom').replace('px',''));
            if ($el[0].scrollHeight > ($el.height() + pad)) { return $el.height($el[0].scrollHeight-pad); }
          });

          $(`#${frame_id}`).on('selector:menu-closed', function(e) {
            return $(this).find('.form-fields:visible').height('auto');
          });

        },

        error(request, status, error) {
          E.ajaxErrorHandler(request, status, error);
          const frame = $(`#${frame_id}`);
          frame.dialog("close");
          frame.remove();
        }
      }
      );

      E.dialog.count += 1;
    },

    initialize(frame) {
      const frame_id = frame.attr("id");
      let {
        title
      } = frame.prop("dialogSettings");
      let heading = undefined;
      if ((title === null) || (title === undefined)) {
        heading = $(`#${frame_id} h1`);
        if ((heading[0] !== null) && (heading[0] !== undefined)) {
          title = heading.text();
          heading.remove();
        }
      }
      frame.dialog("option", "title", title);
      return $(`#${frame_id} form`).each(function(index, form) {
        $(form).attr("data-dialog", frame_id);
      });
    },

    submit() {
      const form = $(this);
      const frame_id = form.attr("data-dialog");
      let frame = $(`#${frame_id}`);
      const settings = frame.prop("dialogSettings");
      const field = $(document.createElement("input"));
      field.attr({
        type: "hidden",
        name: "dialog",
        value: frame_id
      });

      form.append(field);
      $.ajax(form.attr("action"), {
        type: form.attr("method") || "POST",
        data: form.serialize(),
        success(data, status, request) {
          const returnCode = request.getResponseHeader(settings.header);
          const {
            returns
          } = settings;
          let unknownReturnCode = true;
          for (var code in returns) {
            if (returns.hasOwnProperty(code) && (returnCode === code) && $.isFunction(returns[code])) {
              returns[code].call(form, frame, data, status, request);
              unknownReturnCode = false;
              // no need to force triggering. If needed, call it in returns.
//              E.dialog.initialize frame
//              frame.trigger('dialog:show')
              break;
            }
          }
          if (unknownReturnCode) {
            if ($.isFunction(settings.defaultReturn)) {
              settings.defaultReturn.call(form, frame, data, status, request);
            } else {
              console.error(`FAILURE (Unknown return code for header ${settings.header}): ${returnCode}`);
              alert(`FAILURE (Unknown return code for header ${settings.header}): ${returnCode}`);
            }
          }
        },

        error(request, status, error) {
          E.ajaxErrorHandler(request, status, error);
          frame = $(`#${frame_id}`);
          frame.dialog("close");
          frame.remove();
        }
      }
      );

      // if ($.isFunction(settings.error)) { settings.error.call(form, frame, request, status, error); }
      return false;
    }
  };


  // Submits dialog forms
  $(document).on("submit", ".ajax-dialog form[data-dialog]", E.dialog.submit);


  // Opens a dialog for a resource creation
  $(document).on("click", "a[data-add-item]", function() {
    const element = $(this);
    const list_id = element.data('add-item');
    const list = $(list_id);
    const url = element.attr("href");
    return E.dialog.open(url, {
      returns: {
        success(frame, data, status, request) {
          const record_id = request.getResponseHeader("X-Saved-Record-Id");
          if (list[0] !== undefined) {
            $.ajax(list.attr("data-refresh"), {
              data: {
                selected: record_id
              },

              success(data, status, request) {
                list.replaceWith(request.responseText);
                $(`${list_id} input`).trigger("emulated:change");
              }
            }
            );
          } else {
            console.log("Cannot do anything in return");
          }

          frame.dialog("close");
        },

        invalid(frame, data, status, request) {
          frame.html(request.responseText);
        }
      }
    }
    );
  });

  return $(document).on('dialog:show', '.dialog', function() {
    if ($('.modal').length) {
      return $(this).parent().css('z-index', '1050');
    }
});

})(ekylibre, jQuery);
