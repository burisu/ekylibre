// This module permits to execute an procedure to generate operations
// with the user interaction.

(function(E, $) {
  'use strict';

  const PLANNED_REALISED_ACCEPTED_GAP = { intervention_doer: 1.2, intervention_tool: 1.2 , intervention_input: 1.2};

  const no_submit = () => false;

  E.value = function(element) {
    if (element.is(":ui-selector")) {
      return element.selector("value");
    } else {
      return element.val();
    }
  };

  // Interventions permit to enhances data input through context computation
  // The concept is: When an update is done, we ask server which are the impact on
  // other fields and on updater itself if necessary
  E.interventions = {
    updateProcedureLevelAttributes(form, attributes) {
      return (() => {
        const result = [];
        for (var name in attributes) {
          var properties = attributes[name];
          var parameterContainer = $(`[data-intervention-parameter='${name}']`).parent('.nested-association');
          if (properties.display) {
            var statusDisplay = parameterContainer.find(".display-info");
            statusDisplay.find(" .status")
                         .attr('data-display-status', properties.display);
            result.push(statusDisplay.show());
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    },

    handleComponents(form, attributes, prefix) {
      if (prefix == null) { prefix = ''; }
      return (() => {
        const result = [];
        for (var name in attributes) {
          var value = attributes[name];
          var subprefix = prefix + name;
          if (/\w+_attributes$/.test(name)) {
            result.push((() => {
              const result1 = [];
              for (var id in value) {
                var attrs = value[id];
                result1.push(E.interventions.handleComponents(form, attrs, subprefix + '_' + id + '_'));
              }
              return result1;
            })());
          } else {
            var input = form.find(`#${prefix}component_id`);
            var unrollPath = input.attr('data-selector');
            if (unrollPath) {
              var assemblyId = attributes["assembly_id"];
              if ((typeof(assemblyId) === 'undefined') || (assemblyId === null)) {
                assemblyId = "nil";
              }
              var componentReg = /(unroll\?.*scope.*components_of_product[^=]*)=([^&]*)(&?.*)/;
              var oldAssemblyId = unrollPath.match(componentReg)[2];
              unrollPath = unrollPath.replace(componentReg, `$1=${assemblyId}$3`);
              input.attr('data-selector', unrollPath);
              if (assemblyId.toString() !== oldAssemblyId.toString()) {
                console.log("CLEAR");
                result.push($(input).val(''));
              } else {
                result.push(undefined);
              }
            } else {
              result.push(undefined);
            }
          }
        }
        return result;
      })();
    },


    handleDynascope(form, attributes, prefix) {
      if (prefix == null) { prefix = ''; }
      return (() => {
        const result = [];
        for (var name in attributes) {
          var value = attributes[name];
          var subprefix = prefix + name;
          if (/\w+_attributes$/.test(name)) {
            result.push((() => {
              const result1 = [];
              for (var id in value) {
                var attrs = value[id];
                result1.push(E.interventions.handleDynascope(form, attrs, subprefix + '_' + id + '_'));
              }
              return result1;
            })());
          } else {
            if ((name === 'attributes') && (value != null)) {
              // for each attribute
              result.push((() => {
                const result2 = [];
                for (var k in value) {
                  var v = value[k];
                  var input = form.find(`#${prefix}${k}`);
                  var unrollPath = input.attr('data-selector');
                  if (unrollPath) {
                    // for each scope
                    for (var scopeKey in v.dynascope) {

                      var scopeValue = v.dynascope[scopeKey];
                      var scopeReg = new RegExp(`\
(.*\
unroll\\\\?.*scope.*${scopeKey}[^=]*)\
=([^&]*)\
(&?.*)\
`);
                      unrollPath = unrollPath.replace(scopeReg, `$1=${encodeURIComponent(scopeValue)}$3`);
                    }
                    result2.push(input.attr('data-selector', unrollPath));
                  } else {
                    result2.push(undefined);
                  }
                }
                return result2;
              })());
            } else {
              result.push(undefined);
            }
          }
        }
        return result;
      })();
    },

    toggleHandlers(form, attributes, prefix) {
      if (prefix == null) { prefix = ''; }
      return (() => {
        const result = [];
        for (var name in attributes) {
          var value = attributes[name];
          var subprefix = prefix + name;
          if (/\w+_attributes$/.test(name)) {
            result.push((() => {
              const result1 = [];
              for (var id in value) {
                var attrs = value[id];
                result1.push(E.interventions.toggleHandlers(form, attrs, subprefix + '_' + id + '_'));
              }
              return result1;
            })());
          } else {
            var select = form.find(`#${prefix}quantity_handler`);
            if (!(select.length > 0)) { console.warn(`Cannot find #${prefix}quantity_handler <select>`); }
            var option = select.find(`option[value='${name}']`);
            if (!(option.length > 0)) { console.warn(`Cannot find option ${name} of #${prefix}quantity_handler <select>`); }
            if (value) {
              result.push(option.show());
            } else {
              result.push(option.hide());
            }
          }
        }
        return result;
      })();
    },

    unserializeRecord(form, attributes, prefix, updater_id = null) {
      if (prefix == null) { prefix = ''; }
      return (() => {
        const result = [];
        for (var name in attributes) {
          var value = attributes[name];
          var subprefix = prefix + name;
          if (subprefix === updater_id) {
            // Nothing to update
            // console.warn "Nothing to do with #{subprefix}"
          } else if (/\w+_attributes$/.test(name)) {
            result.push(E.interventions.unserializeList(form, value, subprefix + '_', updater_id));
          } else {
  //          console.log subprefix
            result.push(form.find(`#${subprefix}`).each(function(index) {
              let needle;
              if ((needle = 'errors', Array.from(Object.keys(attributes)).includes(needle))) {
                $(this).parent('.nested-fields').find(".errors *").hide();
                for (var error in attributes.errors) {
                  var message = attributes.errors[error];
                  var errorMessage = $(this).parent('.nested-fields').find(`.errors .${error}`);
                  if (typeof(message) !== 'undefined') {
                    errorMessage.show();
                  }
                }
              }
              const element = $(this);
              if (element.is(':ui-selector')) {
                if (value !== element.selector('value')) {
                  if (value === null) {
                    console.log(`Clear #${subprefix}`);
                    return element.selector('clear');
                  } else {
                    console.log(`Updates #${subprefix} with: `, value);
                    return element.selector('value', value);
                  }
                }
              } else if (element.is(":ui-mapeditor")) {
                value = $.parseJSON(value);
                if (((value.geometries != null) && (value.geometries.length > 0)) || ((value.coordinates != null) && (value.coordinates.length > 0))) {
                  element.mapeditor("edit", value);
                  try {
                    return element.mapeditor("view", "edit");
                  } catch (error1) {}
                }
              } else if (element.is('select')) {
                const v = value === null ? '' : value;
                return element.find(`option[value='${v}']`)[0].selected = true;
              } else {
                const valueType = typeof value;
                let update = true;
                if ((value === null) && (element.val() === "")) { update = false; }
                if (valueType === "number") {
                  // When element doesn't have any value, element.numericalValue() == 0
                  if ((value === element.numericalValue()) && (element.numericalValue() !== 0)) { update = false; }
                } else {
                  if (value === element.val()) { update = false; }
                }
                // Don't clobber user input from a stale compute response:
                // - element is currently focused (user is typing)
                // - response wants to blank a field the user has already filled
                if (element.is(':focus')) { update = false; }
                if (((value === null) || (value === "")) && (element.val() != null) && (element.val() !== "")) { update = false; }
                if (update) {
                  console.log(`Updates #${subprefix} with: `, value);
                  element.val(value);
                  if (element.hasClass('flatpickr-input')) { element.next('input.flatpickr-input').val(moment(value).format('DD-MM-YYYY HH:mm')); }
                  return element.trigger('intervention-field:value-updated');
                }
              }
            }));
          }
        }
        return result;
      })();
    },

    unserializeList(form, list, prefix, updater_id) {
      if (prefix == null) { prefix = ''; }
      return (() => {
        const result = [];
        for (var id in list) {
          var attributes = list[id];
          result.push(E.interventions.unserializeRecord(form, attributes, prefix + id + '_', updater_id));
        }
        return result;
      })();
    },

    updateAvailabilityInstant(newTime) {
      if (newTime === '') { return; }
      return $("input.scoped-parameter").each(function(index, item) {
        let re;
        let scopeUri = decodeURI($(item).data("selector"));
        const itemIsTarget = /targets/.test($(item).data('intervention-updater'));
        if (itemIsTarget) {
          re =  /(scope\[availables\]\[\]\[at\]=)(.*?)(&)(scope\[land_parcel_alive\]\[\]\[at\]=)(.*?)(&)/;
          scopeUri = scopeUri.replace(re, "$1" + moment(newTime).format('YYYY-MM-DD HH:mm') + "$3" + "$4" + moment(newTime).format('YYYY-MM-DD HH:mm') + "$6");
        } else {
          re =  /(scope\[availables\]\[\]\[at\]=)(.*?)(&)/;
          scopeUri = scopeUri.replace(re, "$1" + moment(newTime).format('YYYY-MM-DD HH:mm') + "$3");
        }
        return $(item).attr("data-selector", encodeURI(scopeUri));
      });
    },

    _setWaiting(form, computing) {
      computing.prop('state', 'waiting');
      form.on('submit', no_submit);
      return form.find('.form-actions input[type="submit"]').prop('disabled', true);
    },

    _setReady(form, computing) {
      computing.prop('state', 'ready');
      form.off('submit', no_submit);
      return form.find('.form-actions input[type="submit"]').prop('disabled', false);
    },

    // Ask for a refresh of values depending on given update
    refresh(updater, options) {
      if (options == null) { options = {}; }
      if (updater == null) {
        console.error('Missing updater');
        return false;
      }
      const updaterId = updater.data('intervention-updater');
      if (updaterId == null) {
        console.warn('No updater id, so no refresh');
        return false;
      }
      const form = updater.closest('form');
      form.find("input[name='updater']").val(updaterId);
      const computing = form.find('*[data-procedure]').first();
      if (!(computing.length > 0)) {
        console.error('Cannot procedure element where compute URL is defined');
        return false;
      }
      if (computing.prop('state') !== 'waiting') {
        return $.ajax({
          url: computing.data('procedure'),
          type: "PATCH",
          data: form.serialize(),
          beforeSend() {
            return E.interventions._setWaiting(form, computing);
          },
          error(request, status, error) {
            E.interventions._setReady(form, computing);
            return false;
          },
          success(data, status, request) {
            console.group('Unserialize intervention updated by ' + updaterId);
            // Updates elements with new values
            E.interventions.toggleHandlers(form, data.handlers, 'intervention_');
            E.interventions.handleComponents(form, data.intervention, 'intervention_', data.updater_id);
            E.interventions.handleDynascope(form, data.intervention, 'intervention_', data.updater_id);
            E.interventions.unserializeRecord(form, data.intervention, 'intervention_', data.updater_id);
            E.interventions.updateProcedureLevelAttributes(form, data.procedure_states);
            E.interventions._setReady(form, computing);
            if (options.success != null) { options.success.call(this, data, status, request); }
            console.groupEnd();

            if (options['display_cost']) {
              const targettedElement = options['targetted_element'];
              const parentBlock = $(targettedElement).closest('.nested-product-parameter');
              const quantity = $(parentBlock).find('input[data-intervention-field="quantity-value"]').val();
              const unitName = $(parentBlock).find('select[data-intervention-field="quantity-handler"]').val();
              E.interventionForm.displayCost(targettedElement, quantity, unitName);
            }

            const isUsingMap = $("[data-intervention-updater$='working_zone_area_value']").length === 0;
            const isTargetProductUpdate = data.updater_id.includes('targets_attributes') && data.updater_id.includes('product_id');

            if (isUsingMap && isTargetProductUpdate) {
              return refreshQuantityWithDelay();
            }
          }
        });
      }
    },

    hideKujakuFilters(hideFilters) {
      if (hideFilters) {
        return $('.feathers input[name*="nature"], .feathers input[name*="state"]').closest('.feather').hide();
      } else {
        return $('.feathers input[name*="nature"], .feathers input[name*="state"]').closest('.feather').show();
      }
    },

    showInterventionParticipationsModal() {
      return $(document).on('click', '.has-intervention-participations', function(event) {

        let interventionParticipations;
        const targetted_element = $(event.target);
        const intervention_id = $('input[name="intervention_id"]').val();
        const product_id = $(event.target).closest('.nested-product-parameter').find(".selector .selector-value").val();
        const existingParticipation = $('.intervention-participation[data-product-id="' + product_id + '"]').val();
        let participations = $('intervention_participation');
        const interventionStartedAt = $('#intervention_working_periods_attributes_0_started_at').val();

        participations = [];

        const doersParameters = targetted_element.closest(".nested-parameters").siblings(".nested-doers");
        const tractorsParameters = targetted_element.closest('.nested-tractor').closest('.nested-tools');
        const doersToolsParameters = $('.nested-parameters.nested-doers, .nested-parameters.nested-tools');

        if (doersParameters.length > 0) {
          interventionParticipations = doersParameters.find('.intervention-participation');
        } else if (tractorsParameters.length > 0) {
          interventionParticipations = doersToolsParameters.find('.nested-product-parameter.nested-driver, .nested-product-parameter.nested-tractor').find('.intervention-participation');
        } else {
          interventionParticipations = doersToolsParameters.find('.nested-product-parameter').not('.nested-tractor').find('.intervention-participation');
        }

        interventionParticipations.each(function() {
          return participations.push($(this).val());
        });

        const autoCalculMode = $('#intervention_auto_calculate_working_periods').val();

        const datas = {};
        datas['intervention_id'] = intervention_id;
        datas['product_id'] = product_id;
        datas['existing_participation'] = existingParticipation;
        datas['participations'] = participations;
        datas['intervention_started_at'] = interventionStartedAt;
        datas['auto_calcul_mode'] = autoCalculMode;
        datas['intervention_form'] = $("#new_intervention").serialize();

        return $.post({
          url: "/backend/intervention_participations/participations_modal",
          data: datas,
          success(data, status, request) {
            this.workingTimesModal = new ekylibre.modal('#working_times');
            this.workingTimesModal.removeModalContent();
            this.workingTimesModal.getModalContent().append(data);
            return this.workingTimesModal.getModal().modal('show');
          }
        });
      });
    },


    addLazyLoading(taskboard, params) {
      let loadContent = false;
      let currentPage = 1;
      const taskHeight = 60;
      const halfTaskList = 12;

      return $('#core').scroll(function() {
        if (!loadContent && ($('#core').scrollTop() > ((currentPage * halfTaskList) * taskHeight))) {
          let comparePlannedRealised;
          currentPage++;
          params['page'] = currentPage;

          loadContent = true;
          if ($('#compare-planned-and-realised').attr('checked')) {
            comparePlannedRealised = true;
          }

          return $.ajax({
            url: "/backend/interventions/change_page",
            data: { interventions_taskboard: params, compare_planned_realised: comparePlannedRealised },
            success(data, status, request) {
              loadContent = false;
              return taskboard.addTaskClickEvent();
            }
          });
        }
      });
    },

    generateItemsArrayFromId(input){
      let intervention_id;
      if (input.parents().find('#intervention_id').val().length > 0) { intervention_id = input.parents().find('#intervention_id').val(); }
      const purchase_id = input.parent().find('.selector-value').val();
      $('.purchase-items-array').empty();
      if (!input.selector('value')) { return; }

      const itemHeader = [];
      itemHeader.push("<span class='header-name'>Article</span>");
      itemHeader.push("<span class='header-quantity'>Quantité</span>");
      itemHeader.push("<span class='header-conditioning-unit'></span>");
      itemHeader.push("<span class='header-unit-pretax-amount'>PU HT</span>");
      itemHeader.push("<span class='header-amount'>Prix total</span>");
      $('.purchase-items-array').append("<li class='header-line'>" + itemHeader.join('') + "</li>");
      return $.get({
        url: "/backend/interventions/purchase_order_items",
        data: { purchase_order_id: purchase_id, intervention_id},
        success(data, status, request) {
          return (() => {
            const result = [];
            for (let index = 0; index < data.items.length; index++) {
              var item = data.items[index];
              var itemLine = [];
              if ((intervention_id != null) && item.is_reception) {
                itemLine.push(`<span class='item-id'><input name='intervention[receptions_attributes][0][items_attributes][${-index}][id]' value='${item.id}' type='hidden'></input></span>`);
              }
              itemLine.push(`<span class='item-name'><input name='intervention[receptions_attributes][0][items_attributes][${-index}][variant_id]' value='${item.variant_id}' type='hidden'></input>` + item.name + "</span>");
              itemLine.push(`<span class='item-quantity'><input type='number' class='input-quantity' name='intervention[receptions_attributes][0][items_attributes][${-index}][conditioning_quantity]' value ='${item.quantity}'></input></span>`);
              itemLine.push(`<span class='item-conditioning-unit'><input name='intervention[receptions_attributes][0][items_attributes][${-index}][conditioning_unit_id]' value='${item.conditioning_unit_id}' type='hidden'></input>${item.conditioning_unit_name}</span>`);
              itemLine.push("<span class='item-unit-pretax-amount'>" + item.unit_pretax_amount + "</span>");
              itemLine.push("<span class='item-amount'>" + (item.unit_pretax_amount * item.quantity) +  "</span>");
              itemLine.push(`<span class='item-role'><input name='intervention[receptions_attributes][0][items_attributes][${-index}][role]' value='${item.role}' type='hidden'></input></span>`);
              itemLine.push(`<span class='item-purchase-order-item-id'><input name='intervention[receptions_attributes][0][items_attributes][${-index}][purchase_order_item_id]' value='${item.purchase_order_item}' type='hidden'></input></span>`);
              $('.purchase-items-array').append("<li class='item-line'>" + itemLine.join('') + "</li>");
              if ($('.cant-be-update').length > 0) {
                result.push($('.purchase-items-array').find('.item-line input').attr('disabled',true));
              } else {
                result.push(undefined);
              }
            }
            return result;
          })();
        }
      });
    },

    updateTotalAmount(input) {
      const quantity = parseFloat(input.val());
      const totalAmount = quantity * parseFloat(input.parents('li.item-line').find('.item-unit-pretax-amount').text());
      return input.parents('li.item-line').find('.item-amount').html(totalAmount.toFixed(2));
    },

    isPurchaseOrderSelectorEnabled(input) {
      const purchaseInput = input.parents('.fieldset-fields').find('.reception-purchase');
      if (input.val().length === 0) {
        purchaseInput.attr("disabled",true);
      } else {
        purchaseInput.attr("disabled",false);
      }
      if ($('.cant-be-update').length > 0) {
        return input.parents('.fieldset-fields').find('input').attr('disabled', true);
      }
    }
  };

  //#############################################################################
  // Triggers
  //
  $(document).on('cocoon:after-insert', function(e, i) {
    $('input[data-map-editor]').each(function() {
      return $(this).mapeditor();
    });
    return $('#working-periods *[data-intervention-updater]').each(function() {
      return E.interventions.refresh($(this), {
        success(stat, status, request) {
          return E.interventions.updateAvailabilityInstant($(".nested-fields.working-period:first-child input.intervention-started-at").first().val());
        }
      }
      );
    });
  });

  $(document).on('cocoon:after-remove', (e, i) => $('#working-periods *[data-intervention-updater]').each(function() {
    return E.interventions.refresh($(this));
  }));

  $(document).on('mapchange', '*[data-intervention-updater]', function() {
    return $(this).each(function() {
      return E.interventions.refresh($(this));
    });
  });

  $(document).ready(function() {
    const updaters = $('*[data-intervention-updater]');
    // Previous system was calling refresh method with each updater, we now use first updater because the returned values were all the same (except for a very specific case which we avoid by selecting first updater)
    const updater = updaters[0];
    E.interventions.refresh($(updater));
    // Stopped_at is not automaticaly updated to started_at + 1 hour if stopped_at is manually updated
    return E.interventionForm.setupStoppedAtInputBehaviour();
  });

  $(document).on('selector:change', '*[data-intervention-updater]', function(event, _element, wasInitializing) {
      if (wasInitializing) { return; }

      return $(this).each(function() {
        const options = {};
        options['display_cost'] = true;
        options['targetted_element'] = $(event.target);

        return E.interventions.refresh($(this), options);
      });
  });

  $(document).on('keyup', 'input[data-selector]', function(e) {
    return $(this).each(function() {
      return E.interventions.refresh($(this));
    });
  });

  $(document).on('keyup change', 'input[data-intervention-updater]:not([data-selector], .flatpickr-input)', function(event) {
    return $(this).each(function() {
      const options = {};
      options['display_cost'] = true;
      options['targetted_element'] = $(event.target);

      return E.interventions.refresh($(this), options);
    });
  });

  $(document).on('keyup change', 'select[data-intervention-updater]', function(event) {
    return $(this).each(function() {
      const options = {};
      options['display_cost'] = true;
      options['targetted_element'] = $(event.target);

      return E.interventions.refresh($(this), options);
    });
  });

  $(document).on('selector:change', '.intervention_group_parameters_targets_product .selector-search', function(event) {
    const toolId = $(event.target).closest('.selector').find('.selector-value').val();

    return $.ajax({
      url: `/backend/products/indicators/${ toolId }/variable_indicators`,
      success(data, status, request) {
        if (data['is_hour_counter'] === false) { return; }

        const hourCounterBlock = $(event.target).closest('.nested-product-parameter').find('.tool-nested-readings');

        if (hourCounterBlock.hasClass('visible')) { return; }

        hourCounterBlock.removeClass('hidden');
        hourCounterBlock.addClass('visible');

        const hourCounterLinks = hourCounterBlock.find('.links');
        if (hourCounterLinks.is(':visible')) { return hourCounterBlock.find('.add-reading').trigger('click'); }
      }
    });
  });

  $(document).on('selector:change', '.intervention_tools_product .selector-search', function(event) {
    const toolId = $(event.target).closest('.selector').find('.selector-value').val();

    return $.ajax({
      url: `/backend/products/indicators/${ toolId }/variable_indicators`,
      success(data, status, request) {
        if (data['is_hour_counter'] === false) { return; }

        const hourCounterBlock = $(event.target).closest('.nested-product-parameter').find('.tool-nested-readings');

        if (hourCounterBlock.hasClass('visible')) { return; }

        hourCounterBlock.removeClass('hidden');
        hourCounterBlock.addClass('visible');

        const hourCounterLinks = hourCounterBlock.find('.links');
        if (hourCounterLinks.is(':visible')) { return hourCounterBlock.find('.add-reading').trigger('click'); }
      }
    });
  });

  $(document).on("selector:change", 'input[data-selector-id="intervention_doer_product_id"], input[data-selector-id="intervention_tool_product_id"]', function(event) {
    const element = $(event.target);
    const blockElement = element.closest('.nested-fields');
    const participation = blockElement.find('.intervention-participation');
    const hasInterventionParticipationBlock = blockElement.find('.has-intervention-participations');

    if (participation.length > 0) {
      const newProductId = element.closest('.selector').find('.selector-value').val();
      const jsonParticipation = JSON.parse(participation.val());
      jsonParticipation.product_id = newProductId;
      participation.val(JSON.stringify((jsonParticipation)));
      participation.attr('data-product-id', newProductId);
    }

    if (hasInterventionParticipationBlock.length === 0) {
      let pictoTimer;
      if (participation.length > 0) {
        pictoTimer = $('<div class="has-intervention-participations picto picto-timer"></div>');
      } else {
        pictoTimer = $('<div class="has-intervention-participations picto picto-timer-off"></div>');
      }

      return $(blockElement).append(pictoTimer);
    }
  });


  $(document).on("selector:change", 'input[data-generate-items]', function() {
    return $(this).each(function() {
      return E.interventions.generateItemsArrayFromId($(this));
    });
  });

  $(document).on("keyup change", 'input.input-quantity', function() {
    return $(this).each(function() {
      return E.interventions.updateTotalAmount($(this));
    });
  });

  $(document).on("selector:change change", 'input.reception-supplier', function() {
    return $(this).each(function() {
      return E.interventions.isPurchaseOrderSelectorEnabled($(this));
    });
  });

  $(document).behave("load", ".reception-supplier", function() {
    const supplierLabel = $($(this).parents('.nested-receptions').find('.control-label')[0]);
    supplierLabel.addClass('required');
    return supplierLabel.prepend("<abbr title='Obligatoire'>*</abbr>");
  });

  $(document).on('change', '.nested-parameters .nested-cultivation .land-parcel-plant-selector', function(event) {
    const nestedCultivationBlock = $(event.target).closest('.nested-cultivation');
    const unrollElement = $(nestedCultivationBlock).find('.intervention_targets_product .selector-search');
    const unrollValueElement = $(nestedCultivationBlock).find('.intervention_targets_product .selector-value');

    if (unrollValueElement.val() !== "") {
      unrollValueElement.val('');
    }

    const harvestInProgressError = $(nestedCultivationBlock).find('.harvest-in-progress-error');
    if ($(harvestInProgressError).length > 0) { $(harvestInProgressError).remove(); }

    const plantLandParcelSelector = new E.PlantLandParcelSelector();
    return plantLandParcelSelector.changeUnrollUrl(event, unrollElement);
  });


  $(document).on('selector:change', '.nested-parameters .nested-cultivation .intervention_targets_product .selector-search', function(event) {
    const landParcelPlantSelectorElement = $(event.target).closest('.nested-cultivation').find('.land-parcel-plant-selector');
    const productId = $(event.target).closest('.selector').find('.selector-value').val();

    const nestedCultivationBlock = $(event.target).closest('.nested-cultivation');
    const harvestInProgressError = $(nestedCultivationBlock).find('.harvest-in-progress-error');
    if ($(harvestInProgressError).length > 0) { $(harvestInProgressError).remove(); }

    E.interventionForm.checkPlantLandParcelSelector(productId, landParcelPlantSelectorElement);
    return E.interventionForm.checkHarvestInProgress(event, productId, landParcelPlantSelectorElement);
  });


  $(document).on('keyup change dp.change', '.nested-fields.working-period input[data-intervention-updater]', function(event) {
    let nestedProductParameterBlock = $('.nested-product-parameter.nested-cultivation');
    if ($(nestedProductParameterBlock).length === 0) { nestedProductParameterBlock = $('.nested-product-parameter.nested-plant'); }
    if ($(nestedProductParameterBlock).length === 0) { nestedProductParameterBlock = $('.nested-product-parameter.nested-land_parcel'); }

    const productId = $(nestedProductParameterBlock).find('.selector .selector-value').val();

    if (productId === "") { return; }

    const landParcelPlantSelectorElement = $(nestedProductParameterBlock).find('.nested-product_parameter .land-parcel-plant-selector');

    const unrollBlock = $(nestedProductParameterBlock).find('.intervention_targets_product .controls');
    const harvestInProgressError = $(unrollBlock).find('.harvest-in-progress-error');

    if ($(harvestInProgressError).length > 0) { $(harvestInProgressError).remove(); }

    return E.interventionForm.checkHarvestInProgress(event, productId, landParcelPlantSelectorElement, nestedProductParameterBlock);
  });


  $(document).on('selector:change', '.nested-parameters .nested-plant .intervention_targets_product .selector-search', function(event, _selectedElement, wasInitializing) {
    const landParcelPlantSelectorElement = $(event.target).closest('.nested-product_parameter').find('.land-parcel-plant-selector');
    const productId = $(event.target).closest('.selector').find('.selector-value').val();

    const nestedCultivationBlock = $(event.target).closest('.nested-product_parameter');
    const harvestInProgressError = $(nestedCultivationBlock).find('.harvest-in-progress-error');
    if ($(harvestInProgressError).length > 0) { $(harvestInProgressError).remove(); }

    E.interventionForm.checkPlantLandParcelSelector(productId, landParcelPlantSelectorElement);
    return E.interventionForm.checkHarvestInProgress(event, productId, landParcelPlantSelectorElement);
  });

  $(document).on('selector:change', "[data-selector-id=intervention_target_product_id]", function(event, _selectedElement, wasInitializing) {
    if (wasInitializing) {
      return;
    }

    const productId = $(this).next().val();
    const $workingZoneAreaInput = $(this).closest('.nested-targets').find("[class$='targets_working_zone_area'] input");
    if ($workingZoneAreaInput.length === 0) {
      return;
    }

    return E.interventionForm.setWorkingZoneArea(productId, $workingZoneAreaInput);
  });

  $(document).on('change', '#compare-planned-and-realised', event => $.ajax({
    url: '/backend/preferences/compare_planned_and_realised',
    type: 'PATCH',
    data: { value: event.target.checked },
    success: data => {
      return window.location.reload(true);
    }
  }));

  $(document).on('click', '.calendar-img', function(event) {
    if ($(event.target).parents('.task-data').attr('class').includes('no-request')) { return; }
    const intervention_id = $(event.target).parents('.task').data('intervention').id;
    return $.ajax({
      url: '/backend/interventions/compare_realised_with_planned',
      data: { intervention_id },
      dataType: 'script',
      success: data => {}
    });
  });

  $(document).on('shown.bs.modal', '#compare-planned-with-realised', event => $('.details').each(function() {
    const product_id = $(this).data('productId');
    const type = $(this).data('type');
    const same_elements = $('.details[data-product-id=' + product_id + '][data-type=' + type + ']');
    if (same_elements.length === 1) {
      $(this).find('h4').addClass("warning");
      return true;
    }

    const planned_elements = $('.planned .details[data-product-id=' + product_id + '][data-type=' + type + ']');
    const realised_elements = $('.realised .details[data-product-id=' + product_id + '][data-type=' + type + ']');
    let planned_duration_sum = 0;
    let realised_duration_sum = 0;
    const data_selector = type === 'InterventionInput' ? 'quantity-population' : 'duration';
    planned_elements.each(function() {
      let planned_quantity = $(this).data(data_selector);
      planned_quantity = parseFloat(planned_quantity);
      return planned_duration_sum += planned_quantity;
    });
    realised_elements.each(function() {
      let realised_quantity = $(this).data(data_selector);
      realised_quantity = parseFloat(realised_quantity);
      return realised_duration_sum += realised_quantity;
    });

    const min_interval_error = planned_duration_sum / PLANNED_REALISED_ACCEPTED_GAP[_.snakeCase(type)];
    const max_interval_error = planned_duration_sum * PLANNED_REALISED_ACCEPTED_GAP[_.snakeCase(type)];
    if ((min_interval_error >= realised_duration_sum) || (max_interval_error <= realised_duration_sum)) {
      return $('.details[data-product-id=' + product_id + '][data-type=' + type + ']').find('.quantity').addClass("warning");
    }
  }));

  E.interventionForm = {
    displayCost(target, quantity, unitName) {

      quantity = $(target).closest('.nested-fields').find('input[data-intervention-handler="quantity"]').val();
      const productId = $(target).closest('.nested-product-parameter').find(".selector .selector-value").val();

      const intervention = {};
      intervention['quantity'] = quantity;
      intervention['intervention_id'] = $('input[name="intervention_id"]').val();
      intervention['product_id'] = productId;
      intervention['existing_participation'] = $('.intervention-participation[data-product-id="' + productId + '"]').val();
      intervention['intervention_started_at'] = $('#intervention_working_periods_attributes_0_started_at').val();
      intervention['intervention_stopped_at'] = $('#intervention_working_periods_attributes_0_stopped_at').val();

      if (unitName) {
        intervention['unit_name'] = unitName;
      }

      if (Object.values(intervention).every( val => val === undefined)) { return; }

      return $.ajax({
        url: "/backend/interventions/costs/parameter_cost",
        data: { intervention },
        success(data, status, request) {
          if (!data.human_amount.nature || (data.human_amount.nature !== "failed")) {
            const nestedProductParameter = $(target).closest('.nested-product-parameter');

            if ($(nestedProductParameter).find('.product-parameter-cost').length > 0) {
              return $(nestedProductParameter).find('.product-parameter-cost-value').text(data.human_amount);
            } else {
              const parameterCostBlock = $('<div class="product-parameter-cost help-block"></div>');
              parameterCostBlock.append('<span class="product-parameter-cost-label">Coût : </span>');
              parameterCostBlock.append('<span class="product-parameter-cost-value">' + data.human_amount + '</span>');

              return $(nestedProductParameter).find('.intervention_inputs_quantity').append(parameterCostBlock);
            }
          }
        }
      });
    },

    checkPlantLandParcelSelector(productId, landParcelPlantSelectorElement) {
      return $.ajax({
        url: `/backend/products/search_products/${ productId }/datas`,
        success(data, status, request) {
          if (data.type === 'LandParcel') {
            return landParcelPlantSelectorElement.find('.land-parcel-radio-button').prop('checked', true);
          } else {
            return landParcelPlantSelectorElement.find('.plant-radio-button').prop('checked', true);
          }
        }
      });
    },

    checkHarvestInProgress(event, productId, landParcelPlantSelectorElement, nestedCultivationBlock = null) {
      const interventionNature = $('.intervention_nature input[type="hidden"]').val();

      if (($('#is_harvesting').val() === "true") ||
                  landParcelPlantSelectorElement.find('.land-parcel-radio-button').is(':checked') ||
                  (interventionNature === "request")) { return; }

      const interventionStartedAt = $('.intervention-started-at').val();

      return $.ajax({
        url: `/backend/products/interventions/${ productId }/has_harvesting`,
        data: { intervention_started_at: interventionStartedAt },
        success(data, status, request) {
          if (!nestedCultivationBlock) { nestedCultivationBlock = $(event.target).closest('.nested-product-parameter'); }

          const unrollBlock = $(nestedCultivationBlock).find('.intervention_targets_product .controls');
          const harvestInProgressError = $(unrollBlock).find('.harvest-in-progress-error');

          if ($(harvestInProgressError).length > 0) {
            $(harvestInProgressError).remove();
          }

          if (data.has_harvesting) {
           const unrollElement = $(nestedCultivationBlock).find('.intervention_targets_product .selector-search');

           const error = $(`<span class='help-inline harvest-in-progress-error'>${ unrollElement.attr('data-harvest-in-progress-error-message') }</span>`);
           return $(unrollBlock).append(error);
         }
        }
      });
    },

    setupStoppedAtInputBehaviour() {
      const startedAtInput = document.querySelector("#intervention_working_periods_attributes_0_started_at");
      if (!startedAtInput) { return; }

      const fp = startedAtInput._flatpickr;
      const hiddenInput = $('#intervention_working_periods_attributes_0_stopped_at');
      let autoUpdateStoppedAt = '';
      fp.set('onOpen', function(selectedDates) {
        const oldDate = moment(selectedDates[0]);
        const stopDate = moment(hiddenInput.val());
        return autoUpdateStoppedAt = stopDate.diff(oldDate, 'seconds') === 3600;
      });
      return fp.set('onValueUpdate', function(selectedDates) {
        if (autoUpdateStoppedAt) {
          const newDate = moment(selectedDates[0]);
          const displayedInput = hiddenInput.next('.flatpickr-input');
          hiddenInput.val(moment(newDate).add(1, 'hours').format('Y-MM-DD H:mm'));
          displayedInput.val(moment(newDate).add(1, 'hours').format('DD-MM-Y H:mm'));
        }
        const started_at = $('#intervention_working_periods_attributes_0_started_at').val();
        return $(this).each(() => E.interventions.updateAvailabilityInstant(started_at));
      });
    },

    setWorkingZoneArea(productId, $workingZoneAreaInput) {
      return $.ajax({
        url: `/backend/products/${productId}.json`,
        success(data, status, request) {
          const workingZoneAreaValue = data.netSurfaceAreaInHectare;
          if (!workingZoneAreaValue) { return; }

          return $workingZoneAreaInput.val(workingZoneAreaValue).trigger('input');
        }
      });
    }
  };



  $(document).ready(function() {

    // E.interventions.hideKujakuFilters($('.view-toolbar a[data-janus-href="cobbles"]').hasClass('active'))

    if ($('.new_intervention, .edit_intervention').length > 0) {
      E.interventions.showInterventionParticipationsModal();
    }


    if ($('.edit_intervention').length > 0) {
      $('.nested-association.nested-inputs .nested-product-parameter').each(function(index, parameter) {
        const productParameterCostBlock = $(parameter).find('.product-parameter-cost');

        if (productParameterCostBlock.length > 0) {
          const target = $(parameter).find('.intervention_inputs_quantity');
          return $(productParameterCostBlock).appendTo(target);
        }
      });
    }

    if (($('.taskboard').length > 0) && ($('.kujaku').length > 0)) {

      const taskboard = new InterventionsTaskboard;
      taskboard.initTaskboard();

      const encodedUrlParams = $('.kujaku').find('form').serialize();
      const urlParams = decodeURIComponent(encodedUrlParams).split("&");
      const params = urlParams.reduce(function(map, obj) {
        const param = obj.split("=");
        map[param[0]] = param[1];
        return map;
      }
      , {});

      return E.interventions.addLazyLoading(taskboard, params);
    }
  });


  class InterventionsTaskboard {

    constructor() {
      this.taskboard = new ekylibre.taskboard('#interventions', true);
      this.taskboardModal = new ekylibre.modal('#taskboard-modal');
    }

    initTaskboard() {
      this.addHeaderActionsEvent();
      this.addEditIconClickEvent();
      this.addDeleteIconClickEvent();
      return this.addTaskClickEvent();
    }

    getTaskboard() {
      return this.taskboard;
    }

    getTaskboardModal() {
      return this.taskboardModal;
    }

    addHeaderActionsEvent() {

      const instance = this;

      return this.taskboard.addSelectTaskEvent(function(event) {

          const selectedField = $(event.target);
          const columnIndex = instance.getTaskboard().getColumnIndex(selectedField);
          const header = instance.getTaskboard().getHeaderByIndex(columnIndex);
          const checkedFieldsCount = instance.getTaskboard().getCheckedSelectFieldsCount(selectedField);

          if (checkedFieldsCount === 0) {

            return instance.getTaskboard().hiddenHeaderIcons(header);
          } else {
            return instance.getTaskboard().displayHeaderIcons(header);
          }
      });
    }

    addEditIconClickEvent() {

      const instance = this;

      return this.taskboard.getHeaderActions().find('.edit-tasks').on('click', function(event) {

        const interventionsIds = instance._getSelectedInterventionsIds(event.target);
        return $.ajax({
          url: "/backend/interventions/modal",
          data: {interventions_ids: interventionsIds},
          success(data, status, request) {

            return instance._displayModalWithContent(data);
          }});
      });
    }


    addDeleteIconClickEvent() {

      const instance = this;

      return $('.delete-tasks').on('click', function(event) {

        ekylibre.stopEvent(event);

        const confirmMessage = $(event.target).attr('data-confirm');
        const answer = confirm(confirmMessage);

        if (!answer) {
          return;
        }

        let displayDeleteModal = true;
        const columnSelector = event.target;
        const interventionsIds = instance._getSelectedInterventionsIds(columnSelector);

        const tasksWithAttribute = instance.getTaskboard().getColumnTasksFilledDataAttribute(columnSelector, 'data-request-intervention-id');

        if (!tasksWithAttribute || (tasksWithAttribute.length === 0)) {
          displayDeleteModal = false;
        } else {
          tasksWithAttribute.each(function(index, taskWithAttribute) {

            const attributeValue = $(taskWithAttribute).attr('data-request-intervention-id');
            const tasksWithThisAttributeValue = instance.getTaskboard().getColumnTasksByDataAttributeValue(columnSelector, 'data-request-intervention-id', attributeValue);

            if (tasksWithThisAttributeValue && (tasksWithThisAttributeValue.length > 1)) {
              return displayDeleteModal = false;
            }
          });
        }

        if (displayDeleteModal) {
          return $.ajax({
            url: "/backend/interventions/modal",
            data: {modal_type: "delete", interventions_ids: interventionsIds},
            success(data, status, request) {

              return instance._displayModalWithContent(data);
            }
          });
        } else {
          return instance._removeInterventions(columnSelector, interventionsIds);
        }

      });
    }

    _removeInterventions(columnSelector, interventionsIds) {

      const instance = this;

      return $.ajax({
        method: 'POST',
        url: "/backend/interventions/change_state",
        data: {
          'intervention': {
            interventions_ids: JSON.stringify(interventionsIds),
            state: 'rejected'
          }
        },
        success(data, status, request) {

          interventionsIds.forEach(intervention_id => $('#interventions-list tr[id*="'+intervention_id+'"]').remove());

          const selectedTasks = instance.getTaskboard().getSelectedTasksByColumnSelector(columnSelector);
          selectedTasks.remove();

          const titleElement = $(columnSelector).closest('.taskboard-header').find('.title');
          const columnTitle = titleElement.text();
          const beginInterventionCount = columnTitle.indexOf("(") + 1;
          const columnInterventionCount = columnTitle.slice(beginInterventionCount, -1);
          const newInterventionCount = parseInt(columnInterventionCount) - interventionsIds.length;
          const newColumnTitle = columnTitle.slice(0, beginInterventionCount) + newInterventionCount+")";
          titleElement.text(newColumnTitle);

          if (newInterventionCount === 0) {
            return $(columnSelector).closest('.taskboard-column').find('.tasks').remove();
          }
        }
      });
    }


    _getSelectedInterventionsIds(columnSelector) {

      const selectedTasks = this.taskboard.getSelectedTasksByColumnSelector(columnSelector);

      const interventionsIds = [];
      selectedTasks.each( function() {

        const interventionDatas = JSON.parse($(this).attr('data-intervention'));
        return interventionsIds.push(interventionDatas.id);
      });

      return interventionsIds;
    }


    addTaskClickEvent() {

      const instance = this;

      return this.taskboard.addTaskClickEvent(function(event) {

        const element = $(event.target);

        if (element.is(':input[type="checkbox"]') || ($(event.target).attr('class') === 'calendar-img')) {
          return;
        }

        const task = element.closest('.task');

        const intervention = JSON.parse(task.attr('data-intervention'));
        return $.ajax({
          url: "/backend/interventions/modal",
          data: {intervention_id: intervention.id},
          success(data, status, request) {

            instance._displayModalWithContent(data);
            return instance.getTaskboardModal().getModal().find('.dropup a').on('click', function(event) {

              const dropdown = $(this).closest('.dropup');
              dropdown.removeClass('open');

              const dropdownButton = dropdown.find('.dropdown-toggle');
              dropdownButton.text(dropdownButton.attr('data-disable-with'));
              return dropdownButton.attr('disabled', 'disabled');
            });
          }});
      });
    }


    _displayModalWithContent(data) {

      this.taskboardModal.removeModalContent();
      this.taskboardModal.getModalContent().append(data);
      return this.taskboardModal.getModal().modal('show');
    }
  }

  true;

  $(document).ready(function() {
    //TODO: Refacto this to not be coupled so tight to URL
    let intervention;
    if (window.location.pathname.includes('/backend/interventions/')) {
      const path = window.location.pathname;
      intervention = path.substring(path.lastIndexOf('/') + 1);
      $.ajax({
        url: '/backend/interventions/generate_buttons',
        data: { interventions: [intervention] },
        success: data => {
          if (data !== null) {
            return $('.main-toolbar').append(data);
          }
        }
      });
    }

    $(document).on('change', '#interventions-list .list-selector', e => {
      e.stopImmediatePropagation();
      const interventions = $.map( $(".list-data input:checked"), (n, i) => n.value);
      $('.duplicate-intervention').remove();

      return $.ajax({
        url: '/backend/interventions/generate_buttons',
        data: { interventions },
        success: data => {
          return $('.main-toolbar').append(data);
        }
      });
    });

    $(document).on('change', '.requests #check_nature', e => {
      e.stopImmediatePropagation();
      $(e.currentTarget).parent('.task');
      $(e.currentTarget).closest('.taskboard-column').find(".taskboard-header");
      const interventions = $.map($('.requests .tasks input:checked'), (n, i) => $(n).closest('.task').data().intervention.id);
      $('.requests .duplicate-intervention').remove();
      return $.ajax({
        url: '/backend/interventions/generate_buttons',
        data: { interventions, icon_btn: true },
        success: data => {
          if (data !== null) {
            $('.requests .edit-tasks').after(`<i class='picto picto-plus duplicate-intervention' title='${data.translation}'></i>`);
            return $('.duplicate-intervention').data('interventions', interventions);
          }
        }
      });
    });


    $('#taskboard-modal').on('show.bs.modal', e => {
      e.stopImmediatePropagation();
      intervention = $(e.currentTarget).find(".modal-body").data().interventionId;
      return $.ajax({
        url: '/backend/interventions/generate_buttons',
        data: { interventions: [intervention] },
        success: data => {
          if (data !== null) {
            $(e.currentTarget).find('.duplicate-intervention').remove();
            return $(e.currentTarget).find('.modal-footer').append(data);
          }
        }
      });
    });


    $(document).on('click', '.duplicate-intervention', e => {
      e.stopImmediatePropagation();
      const {
        interventions
      } = $(e.currentTarget).data();
      return $.ajax({
        url: '/backend/interventions/duplicate_interventions',
        data: { interventions },
        success: data => {
          let interventionModal;
          if ($('#taskboard-modal').length > 0) {
            interventionModal = new ekylibre.modal('#taskboard-modal');
            interventionModal.getModal().modal('hide');
          } else {
            interventionModal = new ekylibre.modal('#create-intervention-modal');
            interventionModal.getModal().modal('hide');
          }
          $('#wrap').after(data);
          const duplicateModal = new ekylibre.modal('#duplicate-modal');
          return duplicateModal.getModal().modal('show');
        }
      });
    });

    $(document).on('click', '#duplicate-modal #validate-duplication', e => {
      e.stopImmediatePropagation();
      ({
        intervention
      } = $(e.currentTarget).data());
      const {
        interventions
      } = $(e.currentTarget).data();
      let duplicateModal = new ekylibre.modal('#duplicate-modal');
      const date = $('#duplicate-modal #duplicate_date').val();
      const form = $('.edit_intervention:visible');
      return $.ajax({
        type: 'post',
        url: '/backend/interventions/create_duplicate_intervention',
        data: { intervention, interventions, date, form: form.serialize() },
        success: data => {
          if (data === null) {
            duplicateModal.getModal().modal('hide');
            return location.reload();
          } else if (data.errors !== undefined) {
            return $('#duplicate-modal .modal-header').append(`<div class='errors'>${data.errors}</div>`);
          } else {
            duplicateModal.getModal().modal('hide');
            $('#duplicate-modal').remove();
            $('#wrap').after(data);
            duplicateModal = new ekylibre.modal('#duplicate-modal');
            return duplicateModal.getModal().modal('show');
          }
        }
      });
    });

    $(document).on('change intervention-field:value-updated', '.nested-fields.working-period input', () => updateHarvestDelayWarnings());

    $(document).on('selector:change', ".nested-targets .intervention_targets_product", function(event, _selectedElement, wasInitializing) {
      if (wasInitializing) { return; }
      return updateHarvestDelayWarnings();
    });

    return $(document).on('cocoon:after-remove', '.nested-working_periods', () => updateHarvestDelayWarnings());
  });

  const queryDelayWarningsForPeriod = ($periodElement, $parcelSelectors) => {
    console.log('retrieve succeeded');
    const $dateInput = $periodElement.find("input[id*='started_at']")[0];
    const $dateEndInput = $periodElement.find("input[id*='stopped_at']")[0];
    const date = moment($dateInput.value).toISOString();
    const dateEnd = moment($dateEndInput.value).toISOString();
    const parcels = $parcelSelectors.get().map(e => $(e).find('.selector input:first-child').get(0) ).map(e => $(e).selector('value')).filter(e => e !== null);

    if (parcels.length === 0) { return Promise.resolve([]); }

    const params = {
      date,
      date_end: dateEnd,
      targets: parcels
    };

    const intervention_id = $('#intervention_id').val();
    if (intervention_id !== "") {
      params['ignore_intervention'] = intervention_id;
    }

    let p = E.ajax.json({url: `/backend/interventions/validate_reentry_delay?${$.param(params)}`})
      .then(filter_for('reentry'));

    if ($('#updater').data('procedure-computing') === "harvesting") {
      const p2 = E.ajax.json({url: `/backend/interventions/validate_harvest_delay?${$.param(params)}`})
        .then(filter_for('harvest'));

      p = Promise.all([p, p2]).then(array => {
        const reentry = array[0];
        const harvest = array[1];
        return harvest.map(t => {
          if (t.possible) {
            return reentry.filter(el => el.id === t.id)[0];
          } else {
            return t;
          }
        });
      });
    }
    return p;
  };

  var updateHarvestDelayWarnings = _.debounce(function() {
    const $parcelSelectors = $('.nested-targets .intervention_targets_product');
    const promises = $('.nested-fields.working-period').toArray().map(e => {
      return queryDelayWarningsForPeriod($(e), $parcelSelectors);
    });

    return Promise.all(promises).then(values => {
      removeHarvestWarnings($parcelSelectors);
      return values.forEach(problems => {
        const harvestImpossible = problems.filter(t => t.possible === false);
        return displayWarningMessages(harvestImpossible);
      });
    });
  }
  , 400);


  var filter_for = action => {
    return data => {
      return data.targets.map(t => {
        t['action'] = action;
        return t;
      });
    };
  };

  var removeHarvestWarnings = $parcelSelectors => {
    return $parcelSelectors.find('.controls .harvest-warning').remove();
  };

  var displayWarningMessages = warnings => {
    return (() => {
      const result = [];
      for (var data of Array.from(warnings)) {
        var date = moment(data.date).format('DD-MM-YYYY HH:mm');
        var harvestWarning = $(`.selector-value[value='${data.id}']`).closest('.controls');
        var message = I18n.translate(`front-end.intervention.nature.${data.action}`);
        harvestWarning.append(`<div class='harvest-warning'><i class='picto picto-clear'></i> <span>${message} ${date}</span></div>`);
        if (($(".harvest-warning").length === 1) && (data.action === "reentry") && (moment.duration(data.period_duration).asHours() === 8)) {
          var addTwoHours = I18n.translate("front-end.intervention.nature.add_two_hours");
          result.push($(".harvest-warning").append(`<span>${addTwoHours}</span>`));
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  };

  const settingForm = {
    updateInsertedSettingName($settingField, insertedItem) {
      const builtCount = $settingField.find(".parameter-setting").length;
      const $nameInput = insertedItem.find('[name$="[name]"]');
      const name = $nameInput.val();
      const nameIndexRegex = /[0-9]*$/; //match 15 in 'Réglage nº15'
      const newName = name.replace(nameIndexRegex, builtCount );
      return $nameInput.val(newName);
    }
  };

  $(document).on('cocoon:after-insert', '#parameter-settings', function(e, insertedItem ) {
    return settingForm.updateInsertedSettingName($(this), insertedItem);
  });

  const productService = new E.ProductService();

  var sprayerForm = {
    selectors: {
      toolInput: '.intervention_tools_product [data-selector]',
      editSprayerLink: '#edit-product',
      configureProductDiv: '#configure-product',
      reloadSprayerLink: '#configure-product i'
    },

    handleConfigureProductDiv($nestedField) {
     const $configureProductDiv = $nestedField.find(sprayerForm.selectors.configureProductDiv);
     return $configureProductDiv.css('display', 'inline-block');
   },

    handleLinkToProductEdit($nestedField, id) {
      const $editSprayerLink = $nestedField.find(sprayerForm.selectors.editSprayerLink);
      return $editSprayerLink.attr("href", $editSprayerLink.attr("href").replace(/[0-9]*(?=\/edit)/, id));
    },

    setReadings($nestedField, readings) {
      const regex = /\[([^\]\[]+)\]$/;
      return (() => {
        const result = [];
        for (var _i in readings) {
          var reading = readings[_i];
          var $readingDiv = $nestedField.find(`.${reading.indicator_name}`);
          result.push($readingDiv.find('input').each( function(_index) {
            const match = regex.exec(this.name);
            const name = match[1];
            if (this.disabled === true) {
              return this.setAttribute('value', reading['measure_value_unit_symbol']);
            } else {
              return this.setAttribute('value', reading[name]);
            }
              // this.classList.add('disabled')
          }));
        }
        return result;
      })();
    },

    updateReadingInputs($selector, id) {
      return productService.get(id).then( product => sprayerForm.setReadings($selector, product.readings));
    },

    onSelectorChange($selector, id) {
      const $nestedField = $selector.parents(".nested-fields");
      this.handleLinkToProductEdit($nestedField, id);
      this.handleConfigureProductDiv($nestedField);
      return this.updateReadingInputs($nestedField,id);
    }
  };

  $(document).on('selector:change', sprayerForm.selectors.toolInput, function(_event, _selectedElement, was_initializing) {
    if (was_initializing) {
      return;
    }
    const id = $(this).next().val();
    return sprayerForm.onSelectorChange($(this), id);
  });

  $(document).on('click', sprayerForm.selectors.reloadSprayerLink, function(event) {
    const $nestedField = $(this).parents(".nested-fields");
    const productId = $nestedField.find(sprayerForm.selectors.toolInput).next().val();
    return sprayerForm.updateReadingInputs($nestedField,productId);
  });
  
  var refreshQuantityWithDelay =  () => $("*[data-intervention-updater$='quantity_value']").each(function(i) {
    const that = this;
    const debounceTime = 1000 * (1 + (i * 2)); // Refresh won't be performed if executed at the same time, each quantity refresh will be performed every seconds
    return _.debounce( () => E.interventions.refresh($(that))
    , debounceTime)();
  });

  const refreshQuantityWhenTargetChange = function() {
    $(document).on('mapchange', "[data-intervention-updater$='working_zone']",
      refreshQuantityWithDelay);

    return $(document).on('input', "[data-intervention-updater$='working_zone_area_value']",
      refreshQuantityWithDelay);
  };

  // Hack: we need to recompute quantity population when target change
  return refreshQuantityWhenTargetChange();


})(ekylibre, jQuery);
