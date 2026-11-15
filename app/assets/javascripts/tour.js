//= require tether
//= require shepherd

(function(E, $) {
  "use strict";

  return $(document).ready(function() {
    $("body[data-tour]").each(function() {
      let k, v;
      const element = $(this);
      const options = element.data('tour');
      const {
        defaults
      } = options;
      for (k in defaults.buttons) {
        v = defaults.buttons[k];
        if (v.action === 'next') {
          v.action = () => Shepherd.activeTour.next();
        }
      }
      const tour = new Shepherd.Tour({
        defaults});
      for (var step of Array.from(options.steps)) {
        for (k in step.buttons) {
          v = step.buttons[k];
          if (v.action === 'next') {
            v.action = () => Shepherd.activeTour.next();
          }
        }
        tour.addStep(step.id, step);
      }
      tour.on('complete', () => $.ajax({
        url: options.url,
        method: 'POST'
      }));
      tour.on('cancel', () => $.ajax({
        url: options.url,
        method: 'POST'
      }));
      return tour.start();
    });
    return true;});


})(ekylibre, jQuery);
