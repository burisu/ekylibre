(function(E, $) {
  'use strict';

  E.refresh = {
    filter: '*[data-refresh-after][data-url]',
    delay: 4,

    run() {
      const element = $(this);
      const signatureDetails = $('span.signature-trigger').length;
      return $.ajax({
        url: element.data('url') + `?archives=${signatureDetails}`,
        success: (data, status, request) => {
          return element.replaceWith(data);
        }
      });
    },

    all() {
      return $(E.refresh.filter).each(function() {
        return E.refresh.run.call(this);
      });
    }
  };

  $(document).ready(function() {
    window.clearInterval(E.refresh.interval);
    return E.refresh.interval = window.setInterval(E.refresh.all, E.refresh.delay * 1000);
  });

  $(document).on('change', 'select#import_nature', function(event) {
    const pos = $('#core').scrollTop();
    $(this).closest('form').find('.import-file-upload').toggle(!!$(this).val());
    return $('#core').scrollTop(pos);
  });

  return $(document).on('click', 'button.btn[data-hide-content]', function(e) {
    e.preventDefault();
    const pos = $('#core').scrollTop();
    const $selector = $(this).closest('form').find($(this).data('hide-content'));
    $selector.hide();
    $('#core').scrollTop(pos);
    return $(this).closest('form').find('select#import_nature').prop('selectedIndex', 0);
});

})(ekylibre, jQuery);
