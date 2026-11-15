//= require backend/golumn/helpers/knockout_globals

(function(ko, $) {

  ko.bindingHandlers.checkbox = {
    init(element, valueAccessor, allBindings, data, context) {
      const observable = valueAccessor();
      if (!ko.isWriteableObservable(observable)) {
        throw 'You must pass an observable or writeable computed';
      }
      const $element = $(element);
      $element.on('click', function() {
        observable(!observable());
      });
      ko.computed({
        disposeWhenNodeIsRemoved: element,
        read() {
          $element.toggleClass('active', observable());
        }
      });
    }
  };

  ko.bindingHandlers.modal = {
    init(element, valueAccessor) {
      $(element).modal({show: false});
      const value = valueAccessor();
      if (typeof value === 'function') {
        $(element).on('hide.bs.modal', function() {
          value(false);
        });
      }
      ko.utils.domNodeDisposal.addDisposeCallback(element, function() {
        $(element).modal('destroy');
      });
    },

    update(element, valueAccessor) {
      const value = valueAccessor();
      if (ko.utils.unwrapObservable(value)) {
        $(element).modal('show');
      } else {
        $(element).modal('hide');
      }
    }
  };

  return ko.bindingHandlers.selector = {
    init(element, valueAccessor) {
      let value;
      const $el = $(element);
      return value = ko.utils.unwrapObservable(valueAccessor());
    },

    update(element, valueAccessor) {
      const $el = $(element);
      const value = ko.utils.unwrapObservable(valueAccessor());
      if (value === undefined) { return; }
      if (value.id() === undefined) {
        $el.selector('clear');
      } else {
        $el.selector('value', value.id());
      }

      return $el.one('selector:change', function() {
        value.id($(`input[name=${$el.attr('id')}]`).val());
        return value.name =  $el.val();
    });
    }
  };


})(ko, jQuery);