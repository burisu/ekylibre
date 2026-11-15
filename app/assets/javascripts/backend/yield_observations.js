$(document).on('change', '.edit_yield_observation .plant-fields select', function(event) {
  const id = event.target.value;
  const prefix = event.target.id.split('product_id')[0];
  const map_selector = prefix + 'working_zone';
  return $.ajax({
    url: `/backend/plants/${id}.json`,
    success(data) {
      const value = $.parseJSON(data.shape);
      if (((value.geometries != null) && (value.geometries.length > 0)) || ((value.coordinates != null) && (value.coordinates.length > 0))) {
        const element = $(`#${map_selector}`);
        element.mapeditor("edit", value);
        try {
          return element.mapeditor("view", "edit");
        } catch (error) {}
      }
    }
  });
});

$(document).on('selector:change', '#yield_observation_activity_id', function(event) {
  const activity_id = $(event.target).parent().find('.selector-value')[0].value;
  return $.ajax({
    url: `/backend/activities/${activity_id}.json`,
    success(data) {
      const unroll_selector = $('#yield_observation_vegetative_state_id');
      const scope_url = decodeURIComponent(unroll_selector.data('selector'));
      const string_to_replace = scope_url.split('scope[of_variety]=')[1];
      const final_url = scope_url.replace(string_to_replace, data.variety);
      return unroll_selector.attr('data-selector', final_url);
    }
  });
});

$(document).on('cocoon:after-insert', '.issues', function(event, insertedItem) {
  const selected_category = $('select#issue_nature_category').find('option:selected').attr('value');
  insertedItem.find('.issue-category').html(selected_category);
  return insertedItem.find('select').find('option').each(function() {
    if ($(this).data('category') !== selected_category) { return $(this).remove(); }
  });
});
