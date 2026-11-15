((E, $) => {
  const reduce = (array, reducer, initial) => {
    for (var element of Array.from(array)) {
      initial = reducer(initial, element);
    }
    return initial;
  };
  const filter = (array, predicate) => {
    const selected = [];
    for (var element of Array.from(array)) {
      if (predicate(element)) { selected.push(element); }
    }
    return selected;
  };

  const filterValidReducer = (elements, rule) => {
    const validElements = rule.elements[rule.$watched.val()] || [];
    const filtered = validElements.length ? filter(elements, (e => Array.from(validElements).includes(e.value))) : [];
    if (filtered.length) {
      return filtered;
    } else if (rule.emptyBehavior === 'all') {
      return elements;
    } else {
      return [];
    }
  };


  class ElementsFilter {
    constructor($element) {
      this.$element = $element;
      this.$parent = $element.closest('.control-group');
      this.$options = $element.find('option');
      this.rules = $element.data('filter-rules');
      this.onEmpty = $element.data('filter-on-empty');
      this._enableRules();
    }

    _enableRules() {
      return (() => {
        const result = [];
        for (var rule of Array.from(this.rules)) {
          rule.$watched = $(rule.watch);

          result.push(rule.$watched.change(() => {
            return this.valueChanged();
          }));
        }
        return result;
      })();
    }

    valueChanged() {
      const validOptions = reduce(this.rules, filterValidReducer, this.$options.not('[value=""]'));
      this.$options.hide();
      $(validOptions).show();
      if (validOptions.length) {
        this.$element.val(validOptions[0].value);
      } else {
        this.$element.find('[value=""]').show();
        this.$element.val('');
      }
      if ((this.onEmpty === 'hide') && (validOptions.length === 0)) {
        return this.$parent.hide();
      } else {
        return this.$parent.show();
      }
    }
  }

  const activateFilter = $element => {
    const f = new ElementsFilter($element);
    return f.valueChanged();
  };

  const selector = '[data-filter-rules]';
  E.onDOMElementAdded(selector, activateFilter);
  $(() => {
    return $(selector).each(function() { return activateFilter($(this)); });
  });


  return $(document).ready(() => $('[data-filter-collection]').on('keyup', function() {
    const value = $(this).val();
    const $selectInput = $($(this).data('filter-collection'));
    const url = $selectInput.data('filter-collection-url');

    return $.ajax(url, {
      type: 'GET',
      data: { filter_value: value }
    });
}));
}

)(ekylibre, jQuery);
