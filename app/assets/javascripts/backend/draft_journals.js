(function(E, $) {
  'use strict';

  $(document).on('click', '.fec-compliance .fec-icon-error', function(e) {
    const entryId = $(e.target).parents('tr').data('entryId');
    const category = $(e.target).data('category');
    return $.get({
      url: 'draft_journal/fec_compliance_errors',
      data: { entry_id: entryId, category },
      success(data) {
        const modal = new ekylibre.modal('#fec-compliance-errors');
        modal.removeModalContent();
        modal.getModalContent().append(data);
        return modal.getModal().modal('show');
      }
    });
  });

})(ekylibre, jQuery);
