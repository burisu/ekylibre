(function(E, $) {
  'use strict';


  $(document).ready(function() {
    if (!($('.naming-format-form').length > 0)) { return; }

    E.NamingFormats.changeAllFieldsLabels();
    return E.NamingFormats.showExample();
  });


  $(document).on('click', '.naming-format-form .nested-add', function() {
    const nestedFields = $('.nested-association .nested-fields');
    const newNestedFieldLabel = nestedFields.last().find('.control-label');
    const newLabel = `${ newNestedFieldLabel.text() } ${ nestedFields.length }`;

    newNestedFieldLabel.text(newLabel);
    return E.NamingFormats.showExample();
  });


  $(document).on('click', '.naming-format-form .nested-remove', function(event) {
    $(event.target).closest('.nested-association').find('.nested-fields:first .plus-sign').remove();
    E.NamingFormats.changeAllFieldsLabels();
    return E.NamingFormats.showExample();
  });


  $(document).on('change', '.naming-format-form .control-group .controls select', event => E.NamingFormats.showExample());


  $(document).on('click', '.edit_naming_format_land_parcel .form-actions input[type="submit"]', function(event) {
    if ($('.naming-format-form input[type="hidden"][name="update_records"]').length < 1) {
      event.preventDefault();
      return $('#namingFormatModal').modal('show');
    }
  });


  $(document).on('click', '#namingFormatModal .modal-footer .no-update-plans', function() {
    $('.naming-format-form').append('<input type="hidden" name="update_records" value="false"/>');
    $('.simple_form').submit();

    return $('#namingFormatModal').modal('hide');
  });


  $(document).on('click', '#namingFormatModal .modal-footer .update-plans', function() {
    $('.naming-format-form').append('<input type="hidden" name="update_records" value="true"/>');
    $('.simple_form').submit();

    return $('#namingFormatModal').modal('hide');
  });


  return E.NamingFormats = {
    changeAllFieldsLabels() {
      return $('.nested-association .nested-fields').each(function(index, nestedField) {
        const fieldLabel = $(nestedField).find('.control-group .controls select').attr('data-label');
        const nestedFieldLabel = $(nestedField).find('.control-label');
        const newNestedFieldText = `${ fieldLabel } ${ index + 1 }`;
        return nestedFieldLabel.text(newNestedFieldText);
      });
    },

    showExample() {
      const fieldsValues = { 'fields_values': [] };

      $('.nested-association .nested-fields').each(function(index, nestedField) {
        const nestedFieldValue = $(nestedField).find('.control-group .controls select').val();
        return fieldsValues['fields_values'].push(nestedFieldValue);
      });

      return $.ajax({
        url: "/backend/naming_format_land_parcels/build_example",
        data: fieldsValues,
        success(data, status, request) {
          const newExempleElement = $(`<h3><em></em>${ data.example }</h3>`);
          $('.naming-format-form .naming-format-example').empty();
          return $('.naming-format-form .naming-format-example').append(newExempleElement);
        }});
    }
  };


})(ekylibre, jQuery);
