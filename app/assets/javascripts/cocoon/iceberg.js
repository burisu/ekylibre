(function(E, $) {
  'use strict';

  class Iceberg {
    constructor(line, mode) {
      this.line = line;
      this.display = this.line.find('.item-display');

      this._bindButtons(this.newForm());

      this._bindEditEvent();

      this.toggleInputVisibility();

      this.setFormSubmitable();

      this.setCocoonFormSubmitable();

      this.retrievePreviousItemValue();

      this.line.trigger("iceberg:inserted", [this.line]);

      $(this.line).data('_iceberg', this);

      if ((mode !== "add") && !(this.line.find('.error').length > 0) && !(this.line.find('.prefilled').length > 0)) {
        this.display.removeClass('hidden');
        this.oldForm().remove();
        this.bindSelectorsInitialization(form => {
          return this.interpolate(form);
        });
        this.newForm().addClass('hidden');
        this.setFormSubmitable();
      }
    }

    _bindButtons(form) {
      const that = this;
      $(form).find('[data-validate="item-form"]').each(function() {
        return $(this).click(function(event) {
          that.validate();
          return event.preventDefault();
        });
      });

      return $(form).find('[data-cancel="item-form"]').each(function() {
        return $(this).click(function(event) {
          that.cancel();
          return event.preventDefault();
        });
      });
    }

    _bindEditEvent() {
      return this.line.find('*[data-edit="item-form"]').click(() => {
        $(document).data('edited-mode', true);
        this.display.addClass('hidden');
        const clone = this.oldForm().clone();
        clone.insertBefore(this.oldForm());
        clone.trigger('cocoon:after-insert');
        clone.removeClass('hidden');
        this._bindButtons(this.newForm());
        this._bindEdition(this.oldForm());
        this._bindEdition(this.newForm());
        this.toggleInputVisibility();
        this.setFormSubmitable();
        this.setCocoonFormSubmitable();
        this.line.trigger("iceberg:inserted");
        const value = this.line.first().find('[data-item-value="input.order-unit-amount"]').text();
        return this.line.first().find('.nested-item-form').find('.order-unit-amount').val(value);
      });
    }

    _bindEdition(form) {
      return form.find('input').on('input', () => {
        this.setFormSubmitable();
        return this.setCocoonFormSubmitable();
      });
    }

    bindSelectorsInitialization(callback) {
      const form = this.newForm();
      return form.find('*[data-selector]').parent().each(function() {
        return $(this).on('selector:change selector:set selector:initialize', () => callback(form));
      });
    }

    validate() {
      this.interpolate();

      this.display.removeClass('hidden');
      this.oldForm().remove();
      this.newForm().addClass('hidden');
      this.setFormSubmitable();
      return this.line.trigger('iceberg:validated', {iceberg: this, line: this.line});
    }

    interpolate(form) {
      if (form == null) { form = this.newForm(); }
      this.display.find('*[data-item-value]').each(function() {
        let value;
        const element = $(this);
        const target = $(form).find(element.data("item-value")).first();
        if (target.is("input[data-use-as-value]")) {
          if (target.val() === target.data("with-value")) {
            value = $(form).find(target.data("use-as-value")).val();
          } else if (target.is("input[type='radio']")) {
            value = target.parent().text();
          } else if (target.is("input[type='checkbox']")) {
            if (target.is('input[data-warn-if-checked]:checked')) {
              value = $('<span class="warn-message"></span>').html(target.data('warn-if-checked'));
            } else {
              value = "";
            }
          } else {
            value = target.val();
          }
        } else if (target.is("input[data-interpolate-if-input]")) {
          const dependingInput = $(form).find(target.data('interpolate-if-input'));
          if (dependingInput.is("input[type='checkbox']")) {
            if (dependingInput.is(':checked') === target.data('with-value')) {
              value = target.val();
            } else {
              value = "";
            }
          }
        } else if (target.is("input:not([data-use-as-value])")) {
          if (target.is("input[type='radio']")) {
            value = target.parent().text();
          } else if (target.is("input[type='checkbox']")) {
            if (target.is('input[data-warn-if-checked]:checked')) {
              value = $('<span class="warn-message"></span>').html(target.data('warn-if-checked'));
            } else {
              value = "";
            }
          } else {
            value = target.val();
          }
        } else if (target.is('[data-interpolate-data-attribute]')) {
          value = target.data('interpolate-data-attribute');
        } else {
          value = target.html();
        }
        return element.html(value);
      });
      return this.interpolateStoring();
    }

    cancel() {
      if (this.line.find('.nested-item-form').length === 1) {
        this.line.remove();
      } else {
        this.display.removeClass('hidden');
        this.newForm().remove();
      }
      this.setFormSubmitable();
      return this.line.trigger('iceberg:cancelled', {iceberg: this, line: this.line});
    }

    setFormSubmitable() {
      if ($('.nested-item-form:visible').length >= 1) {
        return $('.form-actions .primary').attr("disabled",true);
      } else {
        return $('.form-actions .primary').attr("disabled",null);
      }
    }

    setCocoonFormSubmitable() {
      E.toggleValidateButton(this.line);
      return E.setStorageUnitName(this.line);
    }

    toggleInputVisibility() {
      this.line.find('input[data-input-to-show]').each((index, input) => {
        if ($(input).is("input[type='checkbox']")) {
          if ($(input).is(':checked') === $(input).data('with-value')) {
            return this.line.find($(input).data('input-to-show')).removeClass('hidden');
          }
        } else if ($(input).is("input[type='radio']:checked")) {
          if ($(input).val() === $(input).data('with-value')) {
            return this.line.find($(input).data('input-to-show')).removeClass('hidden');
          }
        }
      });
      return this.line.find('input[data-input-to-show]').click(event => {
        const element = $(event.target);
        if (element.is("input[type='checkbox']")) {
          if (element.is(':checked') === element.data('with-value')) {
            return this.line.find(element.data('input-to-show')).removeClass('hidden');
          } else {
            return this.line.find(element.data('input-to-show')).addClass('hidden');
          }
        } else if (element.is("input[type='radio']")) {
          if (element.val() === element.data('with-value')) {
            return this.line.find(element.data('input-to-show')).removeClass('hidden');
          } else {
            return this.line.find(element.data('input-to-show')).addClass('hidden');
          }
        }
      });
    }

    oldForm() {
      return this.line.find('.nested-item-form:hidden');
    }

    newForm() {
      return this.line.find('.nested-item-form:visible');
    }

    interpolateStoring() {
      const zones = [];
      const form = this.newForm().length > 0 ? this.newForm() : this.oldForm();
      const form_nature = this.line.find('#storing-display').length > 0 ? 'reception' : 'purchase';
      form.find('.storing-fields').not('.removed-nested-fields').each(function() {
        return zones.push({
          quantity: $(this).find('input.storing-quantity').val(),
          unit: form_nature === 'reception' ? $(this).find('input.reception-conditionning').val() : $(this).find('input.invoice-conditioning').val(),
          name: $(this).find('input.parcel-item-storage').val()
        });
      });         

      form.find('.role-row--non-merchandise').each(function() {
        return zones.push({
          quantity: $(this).find('input.reception-quantity').val(),
          unit: $(this).find('[data-coefficient]').data('interpolate-data-attribute')
        });
      });
      const data = {zones};
      this.line.find('#conditioning-display').html(storing_display_template(zones, 'conditioning'));
      return this.line.find('#storing-display').html(storing_display_template(zones, 'zone'));
    }

    retrievePreviousItemValue() {
      const {
        line
      } = this;
      const all_lines = line.parent().find('.nested-fields');
      if (all_lines.length > 1) {
        const input_values_hash = {};
        all_lines.first().find('*[data-remember]').each(function() {
          if ($(this).is('.selector-search')) {
            return input_values_hash[$(this).data('remember')] = $(this).parent().find('.selector-value').val();
          }
        });
        return Array.from(Object.keys(input_values_hash)).map((item) =>
          line.find('*[data-remember=' + item + ']').val(input_values_hash[item]));
      }
    }
  }

  var storing_display_template = (zones, name) => {
    return zones.map(zone => {
      const val = name === 'zone' ? zone.name : `${zone.quantity} ${zone.unit}`;
      return `\
<p>
  <span class="storage-${name}">${val}</span>
</p>\
`;
      }).reduce(((a, b) => a + b), '');
  };
      
  return $(document).ready(function() {
    $('*[data-iceberg]').each(function() {
      let iceberg, mode;
      if (typeof($(this).data("display-items-form")) !== 'undefined') { mode = "add"; }
      return iceberg = new Iceberg($(this), mode);
    });

    return $('table.list').on('cocoon:after-insert', function(event, inserted) {
      if (inserted != null) { const iceberg = new Iceberg($(inserted), "add"); }

      return $('*[data-unit-name]').each(function() {
        return $(this).find('.item-population-unit-name').html($(this).attr('data-unit-name'));});
  });});

})(ekylibre, jQuery);
