//= require backend/golumn/helpers/knockout_globals

(((ko, $) => ko.bindingHandlers.droppable = {

  init(element, valueAccessor, allBindingsAccessor) {
    const $element = $(element);

    ko.utils.domNodeDisposal.addDisposeCallback(element, function() {

      //only call destroy if droppable has been created
      if ($element.data('ui-droppable') || $element.data('droppable')) {
        return $element.droppable('destroy');
      }
    });

  },

  update(element, valueAccessor, allBindingsAccessor, data, context) {
    const $element = $(element);
    const value = ko.utils.unwrapObservable(valueAccessor()) || {};
    const droppableOptions = ko.utils.extend({}, value.options || {});

    if (ko.utils.unwrapObservable(value.active)) {

      return $element.droppable(ko.utils.extend(droppableOptions, {
        out(e, ui) {
        },
        over(e, ui) {
        },
        drop(event, ui) {
          const target = context.$data;

          if (target) {

            let container = undefined;
            let group = target;

            if (target.constructor.name === 'Container') {
              container = target;
              group = target.parent;
            }

            app.moveAnimals(container, group);

            return;
          }
        }
      }
      )
      );

    } else {
      if ($element.data('ui-droppable') || $element.data('droppable')) {
        return $element.droppable('destroy');
      }
    }
  },

  targetIndex: null,
  afterMove: null,
  beforeMove: null,
  options: {}
}))(ko, jQuery);