(function(E, $) {
  "use strict";
  class DOMMutationObserver {
    constructor(element) {
      this.element = element;
      this.observer = null;
      this.listeners = [];
    }

    started() { return this.observer !== null; }

    start() {
      this._createObserver();
      return this._observe();
    }

    addListener(selector, callback) {
      this.listeners.push({
        selector,
        callback
      });
      if (!this.started()) { return this.start(); }
    }

    addListeners(hash) {
      return (() => {
        const result = [];
        for (var selector in hash) {
          var callback = hash[selector];
          result.push(this.addListener(selector, callback));
        }
        return result;
      })();
    }

    _createObserver() {
      return this.observer = new MutationObserver((mutationList, observer) => {
        for (var mutation of Array.from(mutationList)) {
          for (var listener of Array.from(this.listeners)) {
            var $element = $(listener.selector, mutation.addedNodes);
            if ($element.length) { listener.callback($element); }
          }
        }
      });
    }

    _observe() {
      return $(() => this.observer.observe(this.element, {childList: true, subtree: true}));
    }
  }

  //
  // AJAX error handler
  E.ajaxErrorHandler = function(request, status, error) {
    if (console.error != null) {
      console.error(`AJAX failure (${status}): ${error}`);
    } else {
      alert(`AJAX failure (${status}): ${error}`);
      console.log(`AJAX failure (${status}): ${error}`);
    }
    return true;
  };

  // This util method is used to simulate both
  // event.preventDefault() and event.stopPropagation().
  // It is used for compatibility issues as IE8 and below do
  // not handle event.preventDefault() or event.stopPropagation().
  E.stopEvent = function(event) {
    if (!event) {
      ({
        event
      } = window);
    }

    if (!event) {
      return;
    }

    if ((event.stopped === 'undefined') || (event.stopped === undefined)) {

      event.cancelBubble = true;
      event.returnValue = false;

      if (event.stopPropagation) {
        event.stopPropagation();
      }

      if (event.stopImmediatePropagation) {
        event.stopImmediatePropagation();
      }

      if (event.preventDefault) {
        return event.preventDefault();
      }
    }
  };

  E.toggleValidateButton = function(container, bindFields) {
    if (bindFields == null) { bindFields = true; }
    const requiredFields = container.find('[data-required]');
    const validateItemButton = container.find('button[data-validate]');

    const toggleState = function() {
      const toDisable = requiredFields.not(':hidden').filter(function() {
        return $(this).val() === '';}).length;

      return validateItemButton.attr("disabled", !!toDisable);
    };

    toggleState();

    if (bindFields) {
      requiredFields.each(function() {
        return $(this).on("selector:change change", toggleState);
      });

      return container.bind('visibility:change', toggleState);
    }
  };

  E.setStorageUnitName = container => container.find('.storing-fields:visible').last().find('.storage-unit-name').html(container.find('.storing-fields').first().find('.storage-unit-name').first().text());

  const domObserver = new DOMMutationObserver(document);
  return E.onDOMElementAdded = (selectorOrObj, callback) => {
    if (!callback && (typeof selectorOrObj === 'object')) {
      return domObserver.addListeners(selectorOrObj);
    } else {
      return domObserver.addListener(selectorOrObj, callback);
    }
  };

})(ekylibre, jQuery);
