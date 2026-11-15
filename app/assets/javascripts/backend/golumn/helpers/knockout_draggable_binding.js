//= require backend/golumn/helpers/knockout_globals
(((ko, $) => ko.bindingHandlers.draggable = {
  init(element, valueAccessor, allBindingsAccessor) {
    const $element = $(element);

    return ko.utils.domNodeDisposal.addDisposeCallback(element, function() {

      //only call destroy if draggable has been created
      if ($element.data('ui-draggable') || $element.data('draggable')) {
        return $element.draggable('destroy');
      }
    });
  },

  update(element, valueAccessor, allBindingsAccessor, data, context) {
    const $element = $(element);
    const value = ko.utils.unwrapObservable(valueAccessor()) || {};
    const draggableOptions = ko.utils.extend({}, value.options || {});

    if (ko.utils.unwrapObservable(value.active)) {

      return $(element).draggable(ko.utils.extend(draggableOptions, {
        helper(e) {
          const elements = app.selectedItemsIndex;
          const keys = Object.keys(elements);
          const helper = $(`<div class='animate-dragging' data-count='${keys.length}'></div>`);
          const container = $(`<div class='animate-dragging-text'>${elements[keys[0]].name}</div>`);
          helper.append(container);
          return helper;
        },
        start(event, ui) {
          context.$root.enableDropZones(true);
        },
        stop(e, ui) {
          context.$root.enableDropZones(false);
        }
      }
      )
      );
    } else {
      if ($element.data('ui-draggable') || $element.data('draggable')) {
        return $(element).draggable('destroy');
      }
    }
  },

  options: { helper: 'clone'
}
}))(ko, jQuery);