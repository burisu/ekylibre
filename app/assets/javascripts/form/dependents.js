(function($) {
  "use strict";

  $.refreshDependents = function(event) {
    const element = $(this);
    const params = {};
    if ((element.val() !== null) && (element.val() !== undefined)) {
      const dependents = element.data("dependents");
      const paramName = element.data("parameter-name") || element.attr("id") || "value";
      params[paramName] = element.val();
      $(dependents).each(function(index, item) {
        // item = $(this)
        console.log("Dependent: ", item);
        // Replaces element
        // url = $(item).data("refresh")

        if ($(item).attr("href") == null) {
          if ($(item).data("refresh") != null) {
            $(item).attr("href", $(item).data("refresh"));
          } else if ($(item).data("refresh-url") != null) {
            $(item).attr("href", $(item).data("refresh-url"));
          }
        }
        if (!$(item).attr("data-update")) {
          $(item).attr("data-update", "self");
        }
        console.log("Dependent: ", item);
        return $.rails.handleRemote($(item));
      });

        // mode = $(item).data("refresh-mode") or "replace"
        // if url?
        //   $.ajax url,
        //     data: params
        //     success: (data, status, response) ->
        //       console.log "Success"
        //       if mode is "update"
        //         $(item).html response.responseText
        //       else if mode is "update-value"
        //         if element.data("attribute")
        //           $(item).val $.parseJSON(data)[element.data("attribute")]
        //         else
        //           $(item).val response.responseText
        //       else
        //         $(item).replaceWith response.responseText
        //       console.log "Success done"

        //     error: (request, status, error) ->
        //       console.log "FAILURE (Error #{status}): #{error}"
        //       alert "FAILURE (Error #{status}): #{error}"

      return true;
    }
    return false;
  };


  // Refresh dependents on changes
  $(document).on("change emulated:change selector:change", "*[data-dependents]", $.refreshDependents);

  // Compensate for changes made with keyboard
  $(document).on("keypress", "select[data-dependents]", $.refreshDependents);

  return true;

})(jQuery);
