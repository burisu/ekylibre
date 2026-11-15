(function(E, $) {
  // Watch for element insertion via javascript
  E.onDOMElementAdded({
    "input[type='date']": $element => $element.each(function() { return E.forms.date.enableDatePicker(this); }),
    "input[type='datetime']": $element => $element.each(function() { return E.forms.date.enableDatetimePicker(this); }),
    "input[type='time']": $element => $element.each(function() { return E.forms.date.enableTimePicker(this); }),
    "input[type='daterange']": $element => $element.each(function() { return E.forms.date.enableDateRangePicker(this); })
  });

  // Initializes date fields
  return $(document).ready(() => {
    $("input[type='date']").each(function() { return E.forms.date.enableDatePicker(this); });
    $("input[type='datetime']").each(function() { return E.forms.date.enableDatetimePicker(this); });
    $("input[type='time']").each(function() { return E.forms.date.enableTimePicker(this); });
    return $("input[type='daterange']").each(function() { return E.forms.date.enableDateRangePicker(this); });
});

})(ekylibre, jQuery);
