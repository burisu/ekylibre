(function(E, $) {
  'use strict';

  $(document).ready(function() {
    const working_div = $('.apply-fy-date .controls');
    working_div.append($('#financial-year-dates'));
    const input = working_div.find('input');

    $.checkDate(input);

    return input.on('dp.change', e => $.checkDate(e));
  });

  return $.checkDate = function(e) {
    const current_date = new Date(e.date || e.val());
    const alert_span = $('.apply-fy-date .controls #financial-year-dates');

    const started_date = new Date(alert_span.data('startedOn'));
    const stopped_date = new Date(alert_span.data('stoppedOn'));

    if(!isNaN(current_date)) {
      if((started_date <= current_date) && (current_date <= stopped_date)) {
        return alert_span.hide();
      } else {
        return alert_span.show();
      }
    }
  };


})(ekylibre, jQuery);
