const ActiveList = {};

(function($, AL) {
  "use strict";

  // Main function which reload table with specified data parameters
  AL.refresh = function(list, options) {
    const table = list.find("table[data-current-page]").first();
    const parameters = {
      sort:     table.data("list-sort-by"),
      dir:      table.data("list-sort-dir"),
      page:     table.data("list-current-page"),
      per_page: table.data("list-page-size"),
      only:     "content",
      redirect: list.data("list-redirect")
    };
    const list_id = list.attr('id');
    $.extend(parameters, options);
    const url = list.data("list-source");
    $.ajax(url, {
      data: parameters,
      dataType: "html",
      success(data, status, request) {
        const content = $(data);
        const list_data = content.find(".list-data");
        const list_control = content.find(".list-control");
        for (var type of ["actions", "pagination", "footer-pagination","settings"]) {
          $(`*[data-list-ref='${list_id}'].list-${type}`).replaceWith(list_control.find(`.list-${type}`));
        }
        list.find(".list-data").html(list_data);
        const selection = list.prop('selection');
        if (selection != null) {
          for (var id of Array.from(Object.keys(selection))) {
            list.find(`input[data-list-selector='${id}']`)
              .attr('checked', 'checked')
              .closest('tr').addClass('selected');
          }
          AL.updateResults(list);
          AL.checkGlobalButtons(list);
        }
        list.trigger('page:change');
        $(document).trigger('list:page:change');
        return true;
      }
    }
    );

    return false;
  };

  const values_for_computation_of_rows = function(list, row, existing_hash) {
    let computes = {};
    if (existing_hash != null) { computes = existing_hash; }
    for (var cell of Array.from(row.find('td'))) {
      if (AL.computation_for(list, cell) == null) { continue; }
      var col_number = AL.column_number(list, cell);
      if (computes[col_number] == null) { computes[col_number] = []; }
      computes[col_number].push(parseFloat(AL.unaltered_value(cell)));
    }
    return computes;
  };

  AL.column_for = function(list, cell) {
    let column;
    if (typeof(cell) === "string") {
      column = cell;
    } else {
      column = $(cell).data('list-column-header');
    }
    return list.find(`th[data-list-column-cells='${column}']`);
  };

  AL.computation_for = (list, cell) => AL.column_for(list, cell).data('list-column-computation');

  AL.column_number = (list, cell) => AL.column_for(list, cell).data('list-column-cells');

  AL.unaltered_value = cell => $(cell).data('list-cell-value');

  // Select a row of "many" buttons
  AL.select = function(checkbox, update) {
    let needle;
    if (update == null) { update = true; }
    const list = checkbox.closest('*[data-list-source]');
    const row = checkbox.closest('tr');
    const selection = (list.prop('selection') != null) ? list.prop('selection') : {};
    const key = checkbox.data('list-selector');
    const present = (needle = String(key), Array.from(Object.keys(selection)).includes(needle));
    if (checkbox.is(":checked")) {
      if (!present) { selection[key] = values_for_computation_of_rows(list, row, selection[key]); }
      row.addClass("selected");
    } else {
      if (present) { delete selection[key]; }
      row.removeClass("selected");
    }
    list.prop('selection', selection);
    if (update) {
      AL.updateResults(list);
      return AL.checkGlobalButtons(list);
    }
  };

  AL.updateResults = function(list) {
    let column, values;
    const results = {};
    const selection = (list.prop('selection') != null) ? list.prop('selection') : {};
    for (var key in selection) {
      var columns = selection[key];
      for (column in columns) {
        values = columns[column];
        var computation = AL.computation_for(list, column);
        if ((computation !== 'sum') && (computation !== 'average')) {
          console.log(`Don't know how to handle computation ${computation}. Skipping.`);
          continue;
        }
        if (typeof(results[column]) === "undefined") { results[column] = []; }
        results[column] = results[column].concat(values);
      }
    }

    for (column in results) {
      var displayable_total;
      values = results[column];
      var float_values = (Array.from(values).map((e) => parseFloat(e)));
      var total = values.reduce((t, s) => t + s);
      if (AL.computation_for(list, column) === 'average') { total /= values.length; }
      list.attr(`data-list-result-${column}`, total);
      var unit_precision = parseInt(AL.column_for(list, column).data('list-column-unit-precision'));
      var unit_symbol    = AL.column_for(list, column).data('list-column-unit-symbol');
      if (unit_precision && unit_symbol) {
        var magnitude = Math.pow(10, unit_precision);
        var rounded = Math.round(total * magnitude) / magnitude;
        displayable_total = `${rounded.toFixed(unit_precision)} ${unit_symbol}`;
      }
      list.find(`#computation-results td[data-list-result-for=\"${column}\"] #list-computation-result`).html(displayable_total);
    }
    return (() => {
      const result = [];
      for (column of Array.from(list.find("th[data-list-column-computation]"))) {
        var col_number = $(column).data('list-column-cells');
        if ((typeof(results[col_number]) !== "undefined") && (results[col_number].length !== 0)) { continue; }
        list.removeAttr(`data-list-result-${col_number}`);
        result.push(list.find(`#computation-results td[data-list-result-for=\"${col_number}\"] #list-computation-result`).html(''));
      }
      return result;
    })();
  };

  // Hide/show needed global buttons
  AL.checkGlobalButtons = function(list) {
    const selection = list.prop('selection');
    const list_id = list.attr('id');
    const actions = $(`*[data-list-ref='${list_id}']`);
    const caption = $(list).find("tr.selected-count th");
    const {
      length
    } = Object.keys(selection);
    caption.text(caption.text().replace(new RegExp('(##NUM##|\\d+)'), length));
    if (length > 0) {
      caption.parent().show();
      actions.find("*[data-list-actioner='none']:visible").hide();
      actions.find("*[data-list-actioner='none']:visible").hide();
      actions.find("*[data-list-actioner='many']:hidden").show();
    } else {
      caption.parent().hide();
      actions.find("*[data-list-actioner='none']:hidden").show();
      actions.find("*[data-list-actioner='many']:visible").hide();
    }
    return actions.find("*[data-list-actioner='many']").each(function(index) {
      const button = $(this);
      if (button.prop('hrefPattern') == null) {
        button.prop('hrefPattern', button.attr('href'));
      }
      const pattern = button.prop('hrefPattern');
      const url = pattern.replace(encodeURIComponent("##IDS##"), Object.keys(selection).join(','), 'g');
      return button.attr("href", url);
    });
  };

  // Move to given page
  AL.moveToPage = function(list, page) {
    if (isNaN(page)) {
      console.error(`Cannot move to page ${page}. A number is expected`);
    }
    AL.refresh(list,
      {page});
    return false;
  };

  // Sort by one column
  $(document).on("click", "*[data-list-source] th[data-list-column][data-list-column-sort]", function(event) {
    const sorter = $(this);
    const list = sorter.closest("*[data-list-source]");
    AL.refresh(list, {
      sort: sorter.data("list-column"),
      dir:  sorter.data("list-column-sort")
    }
    );
    return false;
  });

  // Select row
  $(document).on("click", "*[data-list-source] td>input[data-list-selector]", function(event) {
    const mainCheckbox = $("input[data-list-selector]").first();
    const someChecked = $("*[data-list-source] td>input[data-list-selector]:checked").length > 0;
    const someUnchecked = $("*[data-list-source] td>input[data-list-selector]:not(:checked)").length > 0;
    mainCheckbox.prop("indeterminate", someChecked && someUnchecked);
    mainCheckbox.prop("checked", someChecked || !someUnchecked);
    AL.select($(this));
    return true;
  });

  // Adds title attribute based on link name
  $(document).on("hover", "*[data-list-source] tbody tr td.act a", function(event) {
    const element = $(this);
    const title = element.attr("title");
    if (title == null) { element.attr("title", element.html()); }
  });

  // Change number of item per page
  $(document).on("click", "*[data-list-ref] *[data-list-change-page-size]", function(event) {
    const sizer = $(this);
    const per_page = sizer.data("list-change-page-size");
    if (isNaN(per_page)) {
      console.error(`@list-change-page-size attribute is not a number: ${per_page}`);
    } else {
      const list = $(`#${sizer.closest('*[data-list-ref]').data('list-ref')}`);
      list.prop('selection', {});
      AL.updateResults(list);
      AL.checkGlobalButtons(list);
      AL.refresh(list,
        {per_page});
    }
    return false;
  });

  // Toggle visibility of a column
  $(document).on("click", "*[data-list-ref] *[data-list-toggle-column]", function(event) {
    const toggler = $(this);
    let visibility = "";
    const columnId = toggler.data("list-toggle-column");
    const list = $(`#${toggler.closest('*[data-list-ref]').data('list-ref')}`);
    const column = list.find(`th[data-list-column=\"${columnId}\"]`);

    let className = column.data("list-column-cells");
    if (className == null) { className = columnId; }
    const search = `.${className}`;
    if (column.hasClass("hidden")) {
      list.find(search).removeClass("hidden");
      column.removeClass("hidden");
      toggler.removeClass("unchecked");
      toggler.addClass("checked");
      visibility = "shown";
    } else {
      list.find(search).addClass("hidden");
      column.addClass("hidden");
      toggler.removeClass("checked");
      toggler.addClass("unchecked");
      visibility = "hidden";
    }
    $.ajax(list.data("list-source"), {
      dataType: "html",
      data: {
        visibility,
        column: columnId
      }
    }
    );
    return false;
  });

  $(document).on("change", "input[data-list-selector=all]", function(event) {
    const check = $(this).is(':checked');
    $(this).closest("table").find("td > input[data-list-selector]").each(function() {
      $(this).prop('checked', check).parents('tr').toggleClass('selected', check);
      return AL.select($(this), false);
    });
    AL.updateResults($(this).closest('*[data-list-source]'));
    return AL.checkGlobalButtons($(this).closest('*[data-list-source]'));
  });

  // Change page of table on link clicks
  $(document).on("click", "*[data-list-ref] a[data-list-move-to-page]", function(event) {
    const pager = $(this);
    const list = $(`#${pager.closest('*[data-list-ref]').data('list-ref')}`);
    return AL.moveToPage(list, pager.data("list-move-to-page"));
  });

  // Change page of table on input changes
  $(document).on("change", "*[data-list-ref] input[data-list-move-to-page]", function(event) {
    const pager = $(this);
    const list = $(`#${pager.closest('*[data-list-ref]').data('list-ref')}`);
    return AL.moveToPage(list, pager.data("list-move-to-page"));
  });

})(jQuery, ActiveList);
