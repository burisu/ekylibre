(function(E, $) {
  const retrieveTargetsData = () => {
    return $('[data-phytosanitary-target]').toArray()
      .filter(el => !el.classList.contains('removed-nested-fields'))
      .map(element => {
        const shape_value = $(element).find('.intervention_targets_working_zone input').val() || $(element).find('.intervention_group_parameters_targets_working_zone input').val();
        const working_zone_area_value = $(element).find('.intervention_targets_working_zone_area input').val() || $(element).find('.intervention_group_parameters_targets_working_zone_area input').val();
        return {
          id: $(element).find("[data-selector-id='intervention_target_product_id']").next('.selector-value').val(),
          shape: shape_value,
          working_zone_area_value
        };
    });
  };

  const retrieveMaxStoppedAt = () => {
    const stoppedAtDates = $(".intervention-stopped-at[type='hidden']").map(function() {
      if ($(this).val()) { return new Date($(this).val()); } else { return null; }
    });

    return moment(_.max(_.compact(stoppedAtDates)));
  };

  const productsInfos = {
    display() {
      if (this._debouncedDisplay == null) { this._debouncedDisplay = _.debounce(this._displayNow.bind(this), 400); }
      return this._debouncedDisplay();
    },

    _displayNow() {
      const that = this;
      this._inFlight?.abort?.();
      $('.nested-plant_medicine').each(function() { return that._clear($(this)); });
      const values = this._retrieveValues();

      return this._inFlight = $.ajax({url: '/backend/registered_phytosanitary_products/get_products_infos',dataType: "json", data: values, method: 'POST'})
       .done( data => {
          return (() => {
            const result = [];
            for (var id in data) {
              var infos = data[id];
              var $productField = $(`.selector-value[value='${id}']`).closest('.nested-plant_medicine');

              this._displayAllowedMentions($productField, infos.allowed_mentions);
              this._displayBadge($productField, infos.state, infos.check_conditions);
              result.push(this._displayMessages($productField, infos.messages));
            }
            return result;
          })();
        })
       .always(() => { return this._inFlight = null; });
    },

    _displayAllowedMentions($productField, allowedMentions) {
      $productField.find('span.allowed-mentions').insertAfter($productField.find('.intervention_inputs_product .selector'));
      return Array.from(allowedMentions).map((mention) =>
        $productField.find(`#${mention}`).show());
    },

    _displayBadge($productField, state, checkConditions) {
      new StateBadgeSet($productField.find('#intervention-products-badges')).setState(state);
      if (checkConditions) { return $productField.find('.input-authorization__text').show(); }
    },

    _displayMessages($productField, messages) {
      return (() => {
        const result = [];
        for (var key in messages) {
          var value = messages[key];
          if (key === 'usage') {
            var htmlString = '<span id="usage-authorization-message"></span>';
            $productField.find('.intervention_inputs_usage .controls .lights-message').html(htmlString);
          }
          result.push($productField.find(`#${key}-authorization-message`).html(messages[key].join('<br>')));
        }
        return result;
      })();
    },

    _clear($productField) {
      $productField.find('.allowed-mentions img').each(function() { return $(this).hide(); });
      new StateBadgeSet($productField.find('#intervention-products-badges')).setState(null);
      $productField.find('.input-authorization__text').hide();
      return $productField.find('#product-authorization-message').html('');
    },

    _retrieveValues() {
      const targetsData = retrieveTargetsData();

      const productsData = Array.from(document.querySelectorAll(".nested-plant_medicine"))
        .filter(el => !el.classList.contains('removed-nested-fields'))
        .map(element => {
          return {
            product_id: element.querySelector('.intervention_inputs_product input.selector-value').value,
            usage_id: element.querySelector('.intervention_inputs_usage input.selector-value').value,
            quantity: element.querySelector('.intervention_inputs_quantity input').value,
            unit_name: element.querySelector('.intervention_inputs_quantity select').selectedOptions[0].dataset.handlerUnit,
            input_id: element.querySelector('#intervention_parameter_id').value,
            live_data: element.querySelector('.intervention_inputs_using_live_data input').value
          };
      });

      const interventionId = $('input#intervention_id').val();

      const startedAtDates = $(".intervention-started-at[type='hidden']").map(function() {
        if ($(this).val()) { return new Date($(this).val()); } else { return null; }
      });

      const minStartedAt = _.min(_.compact(startedAtDates));

      return {
        products_data: _.reject(productsData, data => data.product_id === ''),
        targets_data: _.reject(targetsData, data => data.id === ''),
        intervention_id: interventionId,
        intervention_started_at: moment(minStartedAt).format(),
        intervention_stopped_at: retrieveMaxStoppedAt().format()
      };
    }
  };


  const usageMainInfos = {
    display($input, $productField) {
      this._clear($productField);
      $productField.find("input[data-intervention-field='quantity-value']").trigger('input');
      const usageId = $input.next('.selector-value').val();
      if (!usageId) { return; }
      const values = this._retrieveValues($productField);

      return $.ajax({url: `/backend/registered_phytosanitary_usages/${usageId}/get_usage_infos`, dataType: "json", data: values, method: 'POST'})
        .done( data => {
          this._displayInfos($productField, data.usage_infos);
          this._displayApplication($input, data.usage_application);
          this.displayAuthorizationDisclaimer($productField, data.modified);
          return sprayingMap.refresh();
        });
    },

    displayAuthorizationDisclaimer($productField, modified) {
      if (modified) {
        $('.authorization-disclaimer--past').hide();
        $('.authorization-disclaimer--present').show();
        return $productField.find('.intervention_inputs_using_live_data input').val(true);
      }
    },

    _displayInfos($productField, infos) {
      for (var key in infos) {
        var value = infos[key];
        if ((key === "usage_conditions") && (value !== null)) {
          value = value.replace(/\n/, '<br />');
        }

        $productField.find(`[data-usage-attribute='${key}']`).html(value || '-');
      }

      return $productField.find('.usage-infos-container').show();
    },

    _displayApplication($input, application) {
      return (() => {
        const result = [];
        for (var key in application) {
          var value = application[key];
          var addedClass = key === 'stop' ? 'warning' : '';
          $input.closest('.controls').find('.lights').addClass(`lights-${key}`);
          result.push($input.closest('.controls').find('.lights-message').addClass(addedClass).text(`${value}`));
        }
        return result;
      })();
    },

    _clear($productField) {
      $productField.find('.lights').removeClass('lights-go lights-caution lights-stop');
      $productField.find('.lights-message').removeClass('warning').text('');
      $productField.find('#product-authorization-message').text('');
      return $productField.find('.usage-infos-container').hide();
    },

    _retrieveValues($productField) {
      const interventionId = $('input#intervention_id').val();
      const inputId = $productField.find('#intervention_parameter_id').val();
      const productId = $productField.find("[data-selector-id='intervention_input_product_id']").first().selector('value');
      const liveData = $productField.find('.intervention_inputs_using_live_data input').val();
      const $plantInputs = $('.nested-cultivation').filter(function() { return $(this).find("[data-selector-id='intervention_target_product_id']").first().selector('value'); });
      const targetsData = retrieveTargetsData();
      const stopped_at = retrieveMaxStoppedAt().format();

      return { product_id: productId, targets_data: targetsData, intervention_id: interventionId, input_id: inputId, live_data: liveData, intervention_stopped_at: stopped_at };
    }
  };


  const usageDoseInfos = {
    displayAll() {
      const that = this;
      return $('.nested-plant_medicine').each(function() { 
        return that.display($(this).find("input[data-intervention-field='quantity-value']"), $(this));
      });
    },

    display($quantityInput, $productField) {
      this._clearLights($quantityInput);
      const usageId = $productField.find("[data-selector-id='intervention_input_usage_id']").next('.selector-value').val();
      if (!usageId) { return; }
      const values = this._retrieveValues($quantityInput, $productField);
      if (!values.product_id || !values.quantity || !values.unit_name || !values.targets_data) { return; }

      return $.ajax({url: `/backend/registered_phytosanitary_usages/${usageId}/dose_validations`, dataType: "json", data: values, method: 'POST'})
        .done( data => {
          this._displayDose($quantityInput, data);
          return usageMainInfos.displayAuthorizationDisclaimer($productField, data.modified);
        });
    },

    _displayDose($input, data) {
      return (() => {
        const result = [];
        for (var key in data.dose_validation) {
          var value = data.dose_validation[key];
          var addedClass = key === 'stop' ? 'warning' : '';
          $input.closest('.nested-plant_medicine').find('.intervention_inputs_quantity .lights').addClass(`lights-${key}`);
          result.push($input.closest('.nested-plant_medicine').find('.intervention_inputs_quantity .lights-message').addClass(addedClass).text(`${value}`));
        }
        return result;
      })();
    },

    _clearLights($input) {
      $input.closest('.nested-plant_medicine').find('.intervention_inputs_quantity .lights').removeClass("lights-go lights-caution lights-stop");
      return $input.closest('.nested-plant_medicine').find('.intervention_inputs_quantity .lights-message').removeClass("warning");
    },

    _retrieveValues($input, $productField) {
      const interventionId = $('input#intervention_id').val();
      const inputId = $productField.find('#intervention_parameter_id').val();
      const productId = $productField.find("[data-selector-id='intervention_input_product_id']").first().selector('value');
      const liveData = $productField.find('.intervention_inputs_using_live_data input').val();
      const quantity = $productField.find('.intervention_inputs_quantity input').val();
      const unitName = $productField.find('.intervention_inputs_quantity select').get(0).selectedOptions[0].dataset.handlerUnit;
      const targetsData = retrieveTargetsData();
      const sprayVolume = $productField.find("[data-intervention-field='spray-volume']").first().val();

      return {
        product_id: productId,
        quantity,
        unit_name: unitName,
        targets_data: targetsData,
        intervention_id: interventionId,
        input_id: inputId,
        live_data: liveData,
        spray_volume: sprayVolume
      };
    }
  };


  var sprayingMap = {
    refresh() {
      const value = this._retrieveValue();
      const usagesIds = $("[data-selector-id='intervention_input_usage_id']").map(function() { return $(this).selector('value'); });

      return $('[data-map-editor]').each(function() {
        if (value && !!usagesIds.length) {
          return $(this).mapeditor('displayOptionalOverlay', `aquatic_nta_${value}`);
        } else if (!value && !!usagesIds.length) {
          return $(this).mapeditor('hideOptionalOverlays');
        } else {
          const defaultOverlay = $(this).data('map-editor').default_optional_data;
          if (defaultOverlay) { return $(this).mapeditor('displayOptionalOverlay', defaultOverlay); }
        }
      });
    },

    _retrieveValue() {
      let values = $("[data-usage-attribute='untreated_buffer_aquatic']").map(function() { return parseFloat($(this).text()); });
      values = _.reject(values, val => isNaN(val));
      if (_.isEmpty(values)) { return null; } else { return Math.max(values); }
    }
  };

  var productListManager = {
    retrieveProductsIds() {
      return Array.from(document.querySelectorAll(".nested-plant_medicine"))
          .filter(el => !el.classList.contains('removed-nested-fields'))
          .map(element => {
            const productInputelement = element.querySelector('.intervention_inputs_product input.selector-value');

            if (productInputelement) {
              return productInputelement.value;
            }
      });
    },

    filterProducts() {
      const productsIds = productListManager.retrieveProductsIds();
      const $productSelectors = $('[data-selector-id="intervention_input_product_id"]');
      return $productSelectors.each(function() { return productListManager.filterProduct($(this), productsIds); });
    },

    filterProduct($productSelector, productsIds) {
      const is_input = $productSelector.data('selectorId') === 'intervention_input_product_id';
      const data_selector =  is_input ? $productSelector.attr('data-selector') : $productSelector.data('selector');
      const url = new URL(window.location.origin.concat(data_selector));
      const selectorId = $productSelector.next('.selector-value').val();
      url.searchParams.set('scope[excluding_ids]', _.reject(productsIds, n => n === selectorId));
      const dataSelectorUrl = url.pathname.concat(url.search);
      $productSelector.data('selector', dataSelectorUrl);
      return $productSelector.attr('data-selector', dataSelectorUrl);
    }
  };

  var sprayVolume = {
    selectors: {
      primaryInput: ".master-spray-volume input[id$='measure_value_value']",
      replicaInput: "[data-intervention-field='spray-volume']",
    },

    bindEvents() {
      $(document).on('input', this.selectors.primaryInput, function() {
        const $replicaInputs = $(sprayVolume.selectors.replicaInput);
        return sprayVolume._updateReplicaInputs($replicaInputs, this.value);
      });
      
      return $(document).on('cocoon:after-insert', '.nested-product-parameter', function(_e, $insertedItem) {
        const $replicaInput = $insertedItem.find(sprayVolume.selectors.replicaInput);
        const value = $(sprayVolume.selectors.replicaInput)
          .toArray()
          .filter( e => e.value !== '')
          .map( e => e.value)[0];
        return sprayVolume._updateReplicaInputs($replicaInput, value || '', false);
      });
    },

    _updateReplicaInputs(replicaInputs, value, trigger ) {
      if (trigger == null) { trigger = true; }
      return replicaInputs.each(function() {
        $(this).val(value);
        if (trigger) { return $(this).trigger('change'); }
      });
    }
  };

  sprayVolume.bindEvents();

  // Update products infos on target remove
  $(document).on('cocoon:after-remove', '.nested-targets', () => $("[data-selector-id='intervention_input_product_id']").trigger('selector:change'));

  $(document).on('cocoon:after-remove', '.nested-product-parameter', function() {
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change');
    productListManager.filterProducts();
    return sprayingMap.refresh();
  });

  $(document).on('selector:created', ".nested-plant_medicine [data-selector-id='intervention_input_product_id']", function() {
    return productListManager.filterProduct($(this), productListManager.retrieveProductsIds());
  });

  // Re-trigger all filters on target change
  $(document).on('selector:change', "[data-selector-id='intervention_target_product_id']", function(event, _selectedElement, wasInitializing) {
    if (wasInitializing) { return; }
    return $("[data-selector-id='intervention_input_product_id']").trigger('selector:change');
  });

  $(document).on('selector:change', "[data-selector-id='intervention_input_usage_id']", function(event, _selectedElement, wasInitializing) {
    if (wasInitializing) { return; }
    productsInfos.display();
    return usageMainInfos.display($(this), $(this).closest('.nested-plant_medicine'));
  });

  // Refresh usages, allowed mentions and badges on product update
  $(document).on('selector:change', "input[data-selector-id='intervention_input_product_id']", function(event, _selectedElement, wasInitializing) {
    if (wasInitializing) { return; }
    productsInfos.display();
    const $usageInput = $(this).closest('.nested-plant_medicine').find("[data-selector-id='intervention_input_usage_id']").first();
    if ($(this).val() !== '') {
      return $usageInput.attr('disabled', false);
    }
  });

  $(document).on('selector:change', "input[data-selector-id='intervention_input_product_id']", function(event, _selectedElement, wasInitializing) {
    if (wasInitializing) { return; }
    return productListManager.filterProducts();
  });

  // Update allowed doses on quantity change
  // And compute authorization badge again
  $(document).on('input change', "input[data-intervention-field='quantity-value']", function() {
    productsInfos.display();
    return usageDoseInfos.display($(this), $(this).closest('.nested-plant_medicine'));
  });

  $(document).on('input change', "input[data-intervention-field='spray-volume']", function() {
    productsInfos.display();
    const $nestedPlantMedicine = $(this).closest('.nested-plant_medicine');
    return usageDoseInfos.display($nestedPlantMedicine.find("input[data-intervention-field='quantity-value']"), $nestedPlantMedicine);
  });
  
  $(document).on('input change', "input[data-intervention-field='working-zone-area-value']", function() {
    productsInfos.display();
    return usageDoseInfos.displayAll();
  });

  $(document).on('selector:clear', "[data-selector-id='intervention_input_usage_id']", function() {
    $('.nested-plant_medicine').each(function() { return usageMainInfos.displayAuthorizationDisclaimer($(this), true); });
    return sprayingMap.refresh();
  });

  $(document).on('change intervention-field:value-updated', ".nested-fields.working-period input[type='hidden']", () => productsInfos.display());

  $(document).on('cocoon:after-remove', '.nested-working_periods', () => productsInfos.display());

  $(document).on('mapeditor:optional_data_loaded', '[data-map-editor]', () => sprayingMap.refresh());

  return $(document).on('mapchange', '[data-map-editor]', () => productsInfos.display());

})(ekylibre, jQuery);
