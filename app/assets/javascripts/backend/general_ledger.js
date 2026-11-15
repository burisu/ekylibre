(function(E, $) {
  'use strict';

  $(document).on('change', '#ledger', function(e) {
    const form = $(this).closest("form");
    return form.submit();
  });

  $(document).ready(function() {
    $('input[data-mask-lettered-items]').each(function() {
      return E.ledgers.toggleLetteredItemsVisibility.call($(this));
    });

    $('input[data-mask-lettered-items]').on('change', function(e) {
      return E.ledgers.toggleLetteredItemsVisibility.call($(this), true);
    });

    $('input[data-mask-draft-items]').each(function() {
      return E.ledgers.toggleDraftItemsVisibility.call($(this));
    });

    return $('input[data-mask-draft-items]').on('change', function(e) {
      return E.ledgers.toggleDraftItemsVisibility.call($(this), true);
    });
  });

  return E.ledgers = {
    toggleLetteredItemsVisibility(changed) {
      let left;
      const $input = $(this);
      const $list = $($input.data('mask-lettered-items'));
      const $letteredItems = $list.find('.lettered-item');
      $letteredItems.toggle(!$input.is(':checked'));

      return $.ajax({
        url: $input.data('preference-url'),
        type: 'PATCH',
        data: {
          masked: (left = $input.is(':checked')) != null ? left : {'true' : 'false'}
        },
        success() {
          if (changed) { return location.reload(); }
        }
      });
    },

    toggleDraftItemsVisibility(changed) {
      let left;
      const $input = $(this);
      const $list = $($input.data('mask-draft-items'));
      const $draftItems = $list.find('.draft-item');
      $draftItems.toggle(!$input.is(':checked'));

      return $.ajax({
        url: $input.data('preference-url'),
        type: 'PATCH',
        data: {
          masked: (left = $input.is(':checked')) != null ? left : {'true' : 'false'}
        },
        success() {
          if (changed) { return location.reload(); }
        }});
    }
  };

})(ekylibre, jQuery);
