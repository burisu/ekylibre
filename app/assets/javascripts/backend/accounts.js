(function(E, $) {
  'use strict';

  $(document).ready(function() {
    $('input[data-mask-lettered-items]').each(function() {
      return E.accounts.toggleLetteredItemsVisibility.call($(this));
    });

    $('input[data-mask-lettered-items]').on('change', function(e) {
      return E.accounts.toggleLetteredItemsVisibility.call($(this));
    });

    return $('input[data-refresh-lettered-items]').on('change', function(e) {

      let left;
      const $input = $(this);
      $("#mark_journal_entry_items tbody").html("");

      return $.ajax({
        url: $input.data('refresh-list-url'),
        type: 'GET',
        data: {
          masked: (left = $input.is(':checked')) != null ? left : {'true' : 'false'},
          period: $input.data('period'),
          started_on: $input.data('started-on'),
          stopped_on: $input.data('stopped-on')
        }
      });
    });
  });

  return E.accounts = {
    toggleLetteredItemsVisibility() {
      let left;
      const $input = $(this);
      const $list = $($input.data('mask-lettered-items'));
      const $letteredItems = $list.find('.lettered-item');
      $letteredItems.toggle(!$input.is(':checked'));

      return $.ajax({
        url: $input.data('preference-url'),
        type: 'PATCH',
        datatype: 'JS',
        data: {
          masked: (left = $input.is(':checked')) != null ? left : {'true' : 'false'}
        }});
    }
  };



})(ekylibre, jQuery);
