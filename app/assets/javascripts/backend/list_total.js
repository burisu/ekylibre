(function($, E) {
  "use strict";

  const absoluteSum = function() {
    if ($('table').height() > ($(window).height() - ($('header').height() * 2) - $('nav').height())) {
      if ($(window).width() > 1327) {
        $('#computation-results').css({
            position: 'absolute',
            bottom: '0px',
            'max-width': $('#computation-results').closest('table').width() + 'px'
          });
      }
      let count = 0;
      return $("#computation-results > td").each(function() {
        const totest = $(this).closest('table').find($('thead > tr > th'))[count];
        $(this).css('max-width', 'none');
        $(this).width($(totest).width());
        return count++;
      });
    }
  };


  return $(document).ready(function() {
    absoluteSum();

    $('*[data-list-source]').on('turbolinks:load', absoluteSum);

    let timer = 0;
    return $('.list-selector').click(function() {
      if ((new Date - timer) > 1000) {
        timer = new Date;
        return $('#computation-results > td > div').each(function() {
          const myParent = $(this).parent();
          const myWidth = myParent.width();
          const myClass = myParent.attr('class');
          if ($('.' + myClass).width() !== myWidth) {
            return $('.' + myClass).width(myWidth);
          }});
      }});});

})(jQuery, ekylibre);
