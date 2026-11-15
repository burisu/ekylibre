(((E, $) => $(document).on("load change", "input[data-always-check]", function() {
  const $input = $(this);
  const $target = $($input.data('always-check'));
  const checked = $input.is(':checked');
  $target.attr('disabled', checked);
  if (checked) { return $target.get(0).checked = true; }
})))(ekylibre, jQuery);
