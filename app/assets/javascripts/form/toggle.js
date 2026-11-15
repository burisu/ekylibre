(function($) {

  // Interpolate data value with attribute values
  $.fn.extend({
    interpolatedData(dataName) {
      const element = $(this);
      const data = element.data(dataName);
      if (data == null) { return null; }
      if (typeof data !== 'string') { return data; }
      return element.data(dataName).replace(/\{\{(\w+)\}\}/i, (str, p1, offset, s) => element.attr(p1));
    }
  });

  // Toggle check boxes and radio buttons target
  const toggleCheckboxes = function() {
    const checkable = $(this);
    const checked = $("input[type='radio'][data-show]:checked, input[type='radio'][data-hide]:checked").first();
    const masterShow = checked.formScopedSelect(checked.interpolatedData("show"));
    const masterHide = checked.formScopedSelect(checked.interpolatedData("hide"));
    let toShow = checkable.formScopedSelect(checkable.interpolatedData("show"));
    let toHide = checkable.formScopedSelect(checkable.interpolatedData("hide"));
    const slidingOptions = {
      complete() {
        return $(this).trigger("visibility:change", this);
      }
    };
    if (checkable.prop("checked")) {
      toShow.filter(':not(:visible)').slideDown(slidingOptions);
      toHide.filter(':visible').slideUp(slidingOptions);
    } else {
      toShow = toShow.filter((_, element) => {
        return !$(element).is(masterShow);
      });
      toHide = toHide.filter((_, element) => {
        return !$(element).is(masterHide);
      });
      toShow.filter(':visible').slideUp(slidingOptions);
      toHide.filter(':not(:visible)').slideDown(slidingOptions);
    }
  };

  const toggleRadios = function() {
    $("input[type='radio'][data-show], input[type='radio'][data-hide]").each(toggleCheckboxes);
  };

  // Hide/show blocks depending on check boxes
  $(document).behave("load", "input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", toggleCheckboxes);
  $(document).on("change", "input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", toggleCheckboxes);
  $(document).behave("load", "input[type='radio'][data-show], input[type='radio'][data-hide]", toggleRadios);
  $(document).on("change", "input[type='radio'][data-show], input[type='radio'][data-hide]", toggleRadios);
  $(document).behave("load", ".ui-dialog", function() {
    $("input[type='radio'][data-show], input[type='radio'][data-hide]").on("change", toggleRadios);
    return $("input[type='checkbox'][data-show], input[type='checkbox'][data-hide]").on("change", toggleCheckboxes);
  });


  $(document).ready(function() {
    $("[data-trigger-container] i[data-trigger]").on('click', function() {
      $(this).toggleClass('plus');
      return $(this).closest("[data-trigger-container]").find("[data-triggerable]").slideToggle();
    });

    $("[data-checkable] input[type='checkbox'][name='check_all']").on('click', function() {
      const value = $(this).prop('checked');
      return $(this).closest('[data-checkable]').find("input[type='checkbox'][name='check']").each(function() {
        if ($(this).prop('checked') !== value) { return $(this).click(); }
      });
    });

    $("select[data-trigger-visibility]").on('change', function() {
      const id = $(this).val();
      const affectedElement = $(this).data('trigger-visibility');
      if (!id) { return $(`${affectedElement}`).hide(); }
      const url = window.location.origin + $(this).data('trigger-visibility-url').replace(/:id/, id);

      const toggleUnlessSepa = data => $(`${affectedElement}`).toggle(!data['sepa']);

      return $.getJSON(url, toggleUnlessSepa);
    });

    $("input[type='checkbox'][data-check-on-load='true']").click();
    return $("select[data-trigger-visibility]").trigger('change');
  });

})(jQuery);
