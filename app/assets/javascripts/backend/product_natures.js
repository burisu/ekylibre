(function(E, $) {
  "use strict";

  // Check or uncheck accesses recursively if needed
  $.fn.refreshAbilityValue = function() {
    $(this).each(function() {
      const element = $(this);
      const parameters = element.find("*[data-ability-parameter]");
      const field = element.find(".ability-value");
      let value = element.data("ability");
      if (parameters.length > 0) {
        value += "(";
        for (let index = 0, end = parameters.length - 1, asc = 0 <= end; asc ? index <= end : index >= end; asc ? index++ : index--) {
          if (index > 0) { value += ", "; }
          value += element.find(`*[data-ability-parameter='${index}']`).val();
        }
        value += ")";
      }
      return field.val(value);
    });
    return $(this);
  };

  // Refresh ability on change
  $(document).on("click keyup change", "*[data-ability] select[data-ability-parameter]", function() {
    return $(this).closest("*[data-ability]").refreshAbilityValue();
  });

  $(document).on('selector:change', '#product_nature_variant_nature_id', function() {
    let result;
    const id = $(this).selector("value");
    return result = $.getJSON(`/backend/product_natures/${id}/compatible_varieties`, data => {
      const $selector = $("select#product_nature_variant_variety");
      $selector.find('option').remove();
      return $selector.append(data.data.map(e =>  new Option(e.human_name, e.name)));
    });
  });


  $(document).on("click", ".abilities-list *[data-add-ability]", function() {
    const element = $(this);
    const root = element.closest(".abilities-list");
    const pool = root.find(".abilities");
    const select = root.find(element.attr("href"));
    const option = select.find("option:selected");
    const ability = $("<div>", {class: "ability"});
    ability.attr("data-ability", option.val());
    ability.append($("<label>").html(option.html()));
    ability.append($("<input>").attr("type", "hidden").attr("class", "ability-value").attr("name", element.data("add-ability")));
    if (option.data("ability-parameters") != null) {
      const parameters = option.data("ability-parameters").split(/\s*,\s*/g);
      for (let index = 0; index < parameters.length; index++) {
        var parameter = parameters[index];
        ability.append(" ");
        ability.append($("<select>").attr("data-ability-parameter", index).html(root.find(`*[data-ability-parameter-list='${parameter}']`).html()));
      }
    }
    ability.append($("<a>").attr("href", "#").attr("data-remove-closest", ".ability").html($("<i>")));
    pool.append(ability);
    ability.refreshAbilityValue();
    return false;
  });

  $(document).on("mouseenter", ".nomenclature-item", function() {
    if ($(this).attr("title") == null) {
      return $(this).attr("title", $(this).find("span").html());
    }
  });

  $(document).on("click change", ".nomenclature-item input", function() {
    if ($(this).is(":checked")) {
      return $(this).closest("label").addClass("checked");
    } else {
      return $(this).closest("label").removeClass("checked");
    }
  });

  $(document).on("click change", ".control-group.product_nature_frozen_indicators_list .nomenclature-item input", function() {
    const item = $(this);
    const mirror = $(`.control-group.product_nature_variable_indicators_list .nomenclature-item input[value='${item.val()}']`);
    if (mirror.is(":checked")) {
      return mirror.prop("checked", !item.prop("checked")).trigger("change");
    }
  });

  return $(document).on("click change", ".control-group.product_nature_variable_indicators_list .nomenclature-item input", function() {
    const item = $(this);
    const mirror = $(`.control-group.product_nature_frozen_indicators_list .nomenclature-item input[value='${item.val()}']`);
    if (mirror.is(":checked")) {
      return mirror.prop("checked", !item.prop("checked")).trigger("change");
    }
});


})(ekylibre, jQuery);
