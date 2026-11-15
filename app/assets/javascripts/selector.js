// Selectors for unroll action

(function(E, $) {
  "use strict";

  // This widget is one of the main. It's a classical dynamic selector
  $.widget("ui.selector", {
    options: {
      clear: false
    },

    id: null,

    _create() {
      this.lastSearch = this.element.val();
      if (this.element.parent().is('.selector')) {
        const parent = this.element.parent();
        this.dropDownButton = parent.find('.selector-dropdown[rel="dropdown"]').first();
        this.dropDownMenu = parent.find('.selector-choices-list').first();
        this.valueField = parent.find('.selector-value').first();
      } else {
        this.element.wrap($("<div>", {class: "selector"}));

        this.element.attr("autocomplete", "off");
        this.element.addClass('selector-search');

        // Create drop down button
        this.dropDownButton = $("<a>", {
            href: `#${this.element.attr('id')}`,
            rel: 'dropdown',
            tabindex: -1,
            class: 'selector-dropdown btn btn-default dropdown-toggle sr-only'
          }).insertAfter(this.element);

        // Create drop down menu
        this.dropDownMenu = $("<div>",
            {class: "items-menu selector-choices-list"})
          .hide()
          .insertAfter(this.element);

        // Create value field if it doesn't exist
        if (this.element.data("valueField") != null) {
          this.valueField = $(this.element.data("valueField"));
        } else {
          this.valueField = $("<input>", {
            type: "hidden",
            name: this.element.attr('name'),
            class: 'selector-value',
            'data-parameter-name': this.element.attr('data-value-parameter-name')
          }
          );
          this.element.after(this.valueField);
        }
        this.element.removeAttr("name");
        if (this.element.attr("required") === "true") {
          this.valueField.attr("required", "true");
        }
        if ((this.valueField.val() == null) || (this.valueField.val() === '')) {
          this.valueField.attr("value", this.element.val());
        }
      }
      this._on(this.element, {
        keypress: "_keypress",
        keyup: "_keyup"
      }
      );
//        focusout: "_focusOut"
      this._on(this.dropDownButton,
        {click: "_buttonClick"});
//        focusout: "_focusOut"
      this._on(this.dropDownMenu, {
        "click ul li.item": "_menuItemClick",
        "mouseenter ul li.item": "_menuMouseEnter",
        "click .item-footer": "_actionFooterItemClick"
      }
      );

      $(document).on('mousedown',e => {
        if ($(e.target).hasClass('items-list') || $(e.target).hasClass('selector-dropdown')) {
          return e.stopPropagation();
        } else {
          return this._focusOut(e);
        }
      });

      this.initializing = true;
      if ((this.valueField.val() != null) && (this.valueField.val().length > 0)) {
        this._set(this.valueField.val(), true, false, { stayDisabled: true });
      } else if ((this.element.val() != null) && (this.element.val().length > 0)) {
        this._set(this.element.val(), true);
      } else {
        this.initializing = false;
      }
      this.element.prop("widgetInitialized", true);
      return this.element.trigger("selector:created");
    },

    value(newValue, triggerEvents, callback) {
      if (triggerEvents == null) { triggerEvents = false; }
      if (callback == null) { callback = false; }
      if ((newValue === null) || (newValue === undefined) || (newValue === "")) {
        let val = parseInt(this.valueField.val());
        if (isNaN(val)) { val = null; }
        return val;
      }
      return this._set(newValue, triggerEvents,  callback);
    },

    _set(id, triggerEvents, callback, options) {
      if (triggerEvents == null) { triggerEvents = false; }
      if (callback == null) { callback = false; }
      if (options == null) { options = {}; }
      if ((id === null) || (id === undefined) || (id === "")) {
        this.initializing = false;
        return this.valueField.val();
      }
      const url = this.sourceURL();
      $.ajax({
        url,
        dataType: "json",
        data: {
          id
        },
        success: (data, status, request) => {
          const listItem = $.parseJSON(request.responseText)[0];
          if (listItem != null) {
            this._select(listItem.id, listItem.label, triggerEvents, null, options);
            if (callback !== false) { return callback(); }
          } else {
            return console.warn(`JSON cannot be parsed. Get: ${request.responseText}.`);
          }
        },
        error(request, status, error) {
          return alert(`Cannot get details of item on ${url} (${request.status}/${request.readyState}/${request.statusCode()}) (${status}): ${error}`);
        }
      });
      return this;
    },

    url(newURL) {
      if ((newURL === null) || (newURL === undefined) || (newURL === "")) {
        return this.element.attr("data-selector");
      } else {
        return this.element.attr("data-selector", newURL);
      }
    },

    sourceURL(newURL) {
      if ((newURL === null) || (newURL === undefined) || (newURL === "")) {
        return this.element.attr("data-selector");
      } else {
        return this.element.attr("data-selector", newURL);
      }
    },

    clear(triggerChange) {
      if (triggerChange == null) { triggerChange = true; }
      this.element.val('');
      this.valueField.val('');
      if (triggerChange) { this.element.trigger('selector:change'); }
      return this.element.trigger('selector:clear');
    },

    // Check that current selection is valid
    // If autoselect, autoselect first record if empty
    check(autoselect) {
      if (autoselect == null) { autoselect = false; }
      const id = this.valueField.val();
      if ((id === null) || (id === undefined) || (id === "")) {
        this.autoselect();
      } else {
        $.ajax({
          url: this.sourceURL(),
          dataType: "json",
          data: {
            ids: [id]
          },
          success: (data, status, request) => {
            if (data.length <= 0) {
              return this.autoselect();
            }
          },
          error(request, status, error) {
            return console.error(`Cannot get details of item on ${url} (${request.status}/${request.readyState}/${request.statusCode()}) (${status}): ${error}`);
          }
        });
      }
      return this;
    },


    // Select first record if exist
    autoselect() {
      return $.ajax({
        url: this.sourceURL(),
        dataType: "json",
        data: {
          limit: 1
        },
        success: (data, status, request) => {
          if ((data != null) && (data[0] != null)) {
            return this._set(data[0].id, true);
          } else {
            return this.clear();
          }
        },
        error(request, status, error) {
          return console.error(`Cannot get details of item on ${url} (${request.status}/${request.readyState}/${request.statusCode()}) (${status}): ${error}`);
        }
      });
    },

    _select(id, label, triggerEvents, selectedElement = null, options) {
      let param, redirect;
      if (triggerEvents == null) { triggerEvents = false; }
      if (options == null) { options = {}; }
      this.lastSearch = label;
      const len = 4 * Math.round(Math.round(1.11 * label.length) / 4);
      this.element.attr("size", (len < 20 ? 20 : (len > 80 ? 80 : len)));
      this.element.val(label);
      this.valueField.prop("itemLabel", label);
      this.valueField.val(id);
      this.id = parseInt(id);
      if (this.dropDownMenu.is(":visible")) {
        this._closeMenu();
      }
      if (!$(document).data('editedMode')) {
        const was_initializing = this.initializing;
        if (this.initializing) {
          this.valueField.trigger("selector:initialized");
          this.element.trigger("selector:initialized");
          this.initializing = false;
        }
        if (triggerEvents === true) {
          this.valueField.trigger("selector:change", [null, was_initializing]);
          this.valueField.get(0).dispatchEvent(new CustomEvent('unroll:selector:change', {bubbles: true, detail: {unroll: this, wasInitializing: was_initializing}}));
          this.element.trigger("selector:change", [selectedElement, was_initializing]);
          this.element.get(0).dispatchEvent(new CustomEvent('unroll:selector:change', {bubbles: true, detail: {unroll: this, wasInitializing: was_initializing}}));
        }
        this.valueField.trigger("selector:set", [was_initializing]);
        this.element.trigger("selector:set", [was_initializing]);
      }
      $(document).data('editedMode', false);

      if ((redirect = this.element.data("redirect-on-change-url")) && (param = this.element.attr('id')) && id) {
        if (this.element.closest('form').data('dialog') === undefined) {
          window.location = redirect + "?" + param + "="+ id;
        } else {
          const dialog = $(`#${this.element.closest('form').data('dialog')}`);

          const returns = dialog.prop('dialogSettings').returns ||{ returns: {
            success(frame, data, status, request) {
              frame.dialog("close");
            },

            invalid(frame, data, status, request) {
              frame.html(request.responseText);
            }
          }
        };

          // open it in a new dialog
          const url = redirect + "?" + param + "="+ id;
          E.dialog.open(url, {
            returns,
            inherit: this.element.closest('form').data('dialog')
          }
          );
        }
      }

      return this;
    },

    _openMenu(search) {
      const data = {};
      if (search != null) {
        data.q = search;
      }
      if (this.element.data("selector-new-item")) {
        data.insert = 1;
      }
      if (this.element.data("with")) {
        $(this.element.data("with")).each(function() {
          const paramName = $(this).data("parameter-name") || $(this).attr("name") || $(this).attr("id");
          if (paramName != null) {
            return data[paramName] = $(this).val() || $.trim($(this).html());
          }
        });
      }
      const menu = this.dropDownMenu;
      const url = this.sourceURL();
      return $.ajax({
        url,
        dataType: "html",
        data,
        success: (data, status, request) => {
          menu.html(data);
          if (data.length > 0) {
            menu.show();
            this.element.trigger('selector:menu-opened');
            return this.element.get(0).dispatchEvent(new CustomEvent('unroll:menu-opened', {bubbles: true, detail: {unroll: this}}));
          } else {
            return menu.hide();
          }
        },
        error(request, status, error) {
          return alert(`Selector failure on ${url} (${status}): ${error}`);
        }
      });
    },

    close() {
      return this._closeMenu();
    },

    _closeMenu() {
      // console.log "closeMenu"
      let search;
      if (this.element.attr("required") === "true") {
        // Restore last value if possible
        if (this.valueField.val().length > 0) {
          search = this.valueField.prop("itemLabel");
        }
      } else {
        // Empty values if empty
        if (this.element.val().length <= 0) {
          this.valueField.val("");
          search = "";
        } else if (this.valueField.val().length > 0) {
          search = this.valueField.prop("itemLabel");
        }
      }
      this.lastSearch = search;
      this.element.val(search);
      if (this.dropDownMenu.is(":visible")) {
        this.dropDownMenu.hide();
        this.element.trigger('selector:menu-closed');
        this.element.get(0).dispatchEvent(new CustomEvent('unroll:menu-closed', {bubbles: true, detail: {unroll: this}}));
      }
      return true;
    },

    _choose(selected) {
      // console.log "choose"
      if (selected == null) { selected = this.dropDownMenu.find("ul li.item.selected").first(); }
      if (selected.length > 0) {
        if (selected.is("[data-item-label][data-item-id]")) {
          this._select(selected.data("item-id"), selected.data("item-label"), true, selected);
        } else if (selected.is("[data-new-item]")) {
          const parameters = {};
          if (selected.data("new-item").length > 0) {
            parameters.name = selected.data("new-item");
          }

          E.Dialog.open(this.element.data("selector-new-item"), {
            success: response => {
              return this._set(response.headers['x-saved-record-id'], true);
            },
            error: response => {
              return console.error('Selector dialog error', response);
            }
          }
          );

        } else {
          console.log("Don't known how to manage this option");
          console.log(selected);
          alert("Don't known how to manage this option");
        }
      } else {
        console.log("No selected item to choose...");
      }
      return this;
    },

    _keypress(event) {
      const code = (event.keyCode || event.which);
      if ((code === 13) || (code === 10)) { // Enter
        if (this.dropDownMenu.is(":visible")) {
          this._choose();
          return false;
        }
      } else if (code === 40) { // Down
        if (this.dropDownMenu.is(":hidden")) {
          this._openMenu(this.element.val());
          return false;
        }
      }
      return true;
    },


    _keyup(event) {
      const code = (event.keyCode || event.which);
      const search = this.element.val();
      if (this.lastSearch !== search) {
        if (this.searchRequestTimeout != null) {
          window.clearTimeout(this.searchRequestTimeout);
        }
        this.searchRequestTimeout = window.setTimeout(
          () => {
            if (search.length > 0) {
              return this._openMenu(search);
            } else {
              return this._closeMenu();
            }
          }
          , 500);
        this.lastSearch = search;
      } else if (this.dropDownMenu.is(":visible")) {
        let selected = this.dropDownMenu.find("ul li.selected.item").first();
        if (code === 27) { // Escape
          this._closeMenu();
        } else if ((selected[0] === null) || (selected[0] === undefined)) {
          selected = this.dropDownMenu.find("ul li.item").first();
          selected.addClass("selected");
        } else {
          if (code === 40) { // Down
            if (!selected.is(":last-child")) {
              selected.removeClass("selected");
              selected.next().addClass("selected");
            }
          } else if (code === 38) { // Up
            if (!selected.is(":first-child")) {
              selected.removeClass("selected");
              selected.prev().addClass("selected");
            }
          }
        }
      }
      if ((code === 46) || (code === 8)) { // backspace or delete
        if (this.element.val().length === 0) {
          this.valueField.val("");
          this.valueField.trigger("selector:cleared");
          this.element.trigger("selector:cleared");
        }
      }
      return true;
    },

    _focusOut(event) {
      // console.log "focusout"
      setTimeout(() => {
        return this._closeMenu();
      }
      , 300);
      return true;
    },

    _buttonClick(event) {
      if (this.dropDownMenu.is(":visible")) {
        this._closeMenu();
      } else if (!this.element.is(":disabled")) {
        this._openMenu();
      }
      return false;
    },

    _menuItemClick(event) {
      // console.log "menuclick"
      // console.log event.target
      this._choose();
      return false;
    },

    _actionFooterItemClick(event) {
      this._choose($(event.target));
      return false;
    },

    _menuMouseEnter(event) {
      const item = $(event.target);
      item.closest("ul").find("li.item.selected").removeClass("selected");
      item.addClass("selected");
      return false;
    }
  }
  );

  $(document).behave("load", "input[data-selector]", event => $("input[data-selector]").each(function() {
    return $(this).selector();
  }));

  $(document).on("selector:change", function(changeEvent, value) {
    $("*[data-selector-update]").each(function() {
      const updateSource = $(this)
        .closest($(this).data("selector-use-closest"))
        .find("*[data-selector-id='"+$(this).data("selector-update")+"']")[0];
      if (updateSource === changeEvent.target) {
        if (value) {
          return $(this).html($(value).data("item-"+$(this).data("selector-update-with")));
        }
      }
    });

    return $("*[data-add-details]").each(function() {
      if (!value || ($(this)[0] !== changeEvent.target)) { return; }
      return displayDetails($(this));
    });
  });

  $(document).on('cocoon:after-insert', function(e, newRow) {
    const detailedInput = $(newRow).find('[data-add-details]');
    if (!detailedInput) { return; }
    const dateInput = $(detailedInput).data('add-details-on');
    return $(dateInput).on('change', () => displayDetails($(detailedInput)));
  });

  var displayDetails = function(detailedInput) {
    const cell = $(detailedInput).closest('td');
    $(cell).find('.added-details').remove();
    $(cell).removeClass('with-details');
    const id = $(detailedInput).next('.selector-value').val();
    const date = $(detailedInput).closest('form').find($(detailedInput).data('add-details-on')).val();
    if (!id || !date) { return; }
    const url = $(detailedInput).data('add-details').replace(/:id/, id) + `?date=${date}`;
    const request = $.get(url);

    return request.success(function(data) {
      $(detailedInput).closest('.selector').append(data);
      return $(cell).addClass('with-details');
    });
  };

  $(document).on('selector:change', '[data-filter-unroll]', function(e, _a, _b, options) {
    if (options == null) { options = {}; }
    return filterableUnroll.filter($(this), options);
  });

  $(document).on('selector:menu-opened', '.selector', function(e) {
    const $currentDropDown = $(this);
    return $('.selector').not($currentDropDown).each(function() {
      return $($(this).find('input[data-selector]').get(0)).selector('close');
    });
  });

  var filterableUnroll = {
    filter($filteringUnroll, options) {
      const filterId = $filteringUnroll.selector('value');
      if (!filterId) { return; }

      const $filteredUnroll = this._retrieveFilteredUnroll($filteringUnroll);
      const url = $filteredUnroll.data('filters-url');
      const values = this._retrieveValues($filteredUnroll, $filteringUnroll);

      return $.getJSON(url, _.merge(values, {filter_id: filterId}))
        .done(data => {
          this._handleEnable($filteredUnroll, $filteringUnroll, options.stayDisabled);
          if (data.scope_url) { this._handleScope($filteredUnroll, data.scope_url); }
          if (data.new_url) { this._handleNew($filteredUnroll, data.new_url); }
          this._handleClear($filteredUnroll, data.clear);
          if (data.disable) { return this._handleDisable($filteredUnroll, $filteringUnroll, data.disable); }
      }).fail(e => {
          this._handleDisable($filteredUnroll, $filteringUnroll, I18n.translate('front-end.unroll.server_error'));
          return console.error('Error while trying to filter an unroll', e);
      });
    },

    _handleEnable($filteredUnroll, $filteringUnroll, stayDisabled) {
      if (!stayDisabled) {
        $filteredUnroll.attr('disabled', false);
        $filteredUnroll.siblings(':last').removeClass('disabled');
      }
      if ($filteredUnroll.data('msg-container')) { return $filteredUnroll.closest($filteringUnroll.data('parent')).find($filteredUnroll.data('msg-container')).text(''); }
    },

    _handleScope($filteredUnroll, scope_url) {
      $filteredUnroll.data('selector', scope_url);
      return $filteredUnroll.attr('data-selector', scope_url);
    },

    _handleNew($filteredUnroll, new_url) {
      $filteredUnroll.data('selector-new-item', new_url);
      return $filteredUnroll.attr('data-selector-new-item', new_url);
    },

    _handleDisable($filteredUnroll, $filteringUnroll, disable) {
      $filteredUnroll.attr('disabled', true);
      if ($filteredUnroll.data('msg-container')) { return $filteredUnroll.closest($filteringUnroll.data('parent')).find($filteredUnroll.data('msg-container')).text(disable); }
    },

    _handleClear($filteredUnroll, clear) {
      if (clear) { return $filteredUnroll.first().selector('clear', false); } else { return $filteredUnroll.trigger('selector:change', [null, null, { manuallyTriggered: true }]); }
    },

    _retrieveFilteredUnroll($filteringUnroll) {
      return $filteringUnroll.closest($filteringUnroll.data('parent')).find($filteringUnroll.data('filter-unroll'));
    },

    _retrieveValues($filteredUnroll, $filteringUnroll) {
      const selectedValue = $filteredUnroll.next('.selector-value').val();
      const retrievedIds = [];
      if ($filteringUnroll.data('retrieve-unroll')) {
        $($filteringUnroll.data('retrieve-unroll')).each(function() {
          return retrievedIds.push($(this).selector('value'));
        });
      }

      return { retrieved_ids: retrievedIds, selected_value: selectedValue };
    }
  };

})(ekylibre, jQuery);
