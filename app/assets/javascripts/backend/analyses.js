(function(E, $) {

  $(document).on('ajax:success', "#analysis-items", function(event, item) {
    const items = $(this);
    return $(item).children('input').each(function(_index, input) {
      if ((input.id.slice(0, 25) === "analysis_items_attributes") && (input.id.slice(-14) === "indicator_name")) {
        const select = $("select[name='indicator_name']")[0];
        return $(select.options).each(function(_ind, option) {
          if (option.value === input.value) {
            option.setAttribute('hidden', 'true');
            option.setAttribute('disabled', 'true');
            const next_option = $(select).find('option:not([disabled])').first();
            console.log(next_option);
            if (next_option.length > 0) {
              if (select.value === input.value) {
                return select.value = next_option.val();
              }
            } else {
              return items.find('.links').hide();
            }
          }
        });
      }
    });
  });

  return $(document).on('cocoon:before-remove', "#analysis-items", function(event, item) {
    const items = $(this);
    return item.children('input').each(function(_index, input) {
      if ((input.id.slice(0, 25) === "analysis_items_attributes") && (input.id.slice(-14) === "indicator_name")) {
        const select = $("select[name='indicator_name']")[0];
        $(select.options).each(function(_ind, option) {
          if (option.value === input.value) {
            option.removeAttribute('hidden');
            return option.removeAttribute('disabled');
          }
        });
        const option = $(select).find('options:not(:disabled)').first();
        const links = items.find('.links');
        if ((option != null) && links.is(':hidden')) {
          return links.show();
        }
      }});
});


})(ekylibre, jQuery);
