(function(E, $) {
  'use strict';


  return $(document).on('keyup change dp.change', '.inspection_sampled_at #inspection_sampled_at', function(event) {
    const selectedValue = $(event.target).val();
    const unrollElement = $('.inspection_product input.selector-search');

    const unrollRegex = /(unroll\?.*scope.*availables([^&]*)at[^=]*)=([^&]*)/;
    let unrollPath = $(unrollElement).attr('data-selector');
    unrollPath = unrollPath.replace(unrollRegex, `$1=${ selectedValue }`);

    $(unrollElement).attr('data-selector', unrollPath);
    return $(unrollElement).trigger('selector:set');
});


})(ekylibre, jQuery);
