//= require backend/golumn/helpers/knockout_globals

(function(ko, $) {

  //connect items with observableArrays
  return ko.bindingHandlers.sortable = {
    init(element, valueAccessor, allBindingsAccessor, data, context) {
      const $element = $(element);
      const value = ko.utils.unwrapObservable(valueAccessor()) || {};
      const templateOptions = ko.utils.prepareTemplateOptions(valueAccessor, 'foreach');
      const sortable = {};
      let startActual = undefined;
      let updateActual = undefined;
      stripTemplateWhitespace(element, templateOptions.name);
      //build a new object that has the global options with overrides from the binding
      $.extend(true, sortable, ko.bindingHandlers.sortable);
      if (value.options && sortable.options) {
        ko.utils.extend(sortable.options, value.options);
        delete value.options;
      }
      ko.utils.extend(sortable, value);
      //if allowDrop is an observable or a function, then execute it in a computed observable
      if (sortable.connectClass && (ko.isObservable(sortable.allowDrop) || (typeof sortable.allowDrop === 'function'))) {
        ko.computed({
          read() {
            let value;
            value = ko.utils.unwrapObservable(sortable.allowDrop);
            const shouldAdd = typeof value === 'function' ? value.call(this, templateOptions.foreach) : value;
            ko.utils.toggleDomNodeCssClass(element, sortable.connectClass, shouldAdd);
          },
          disposeWhenNodeIsRemoved: element
        }, this);
      } else {
        ko.utils.toggleDomNodeCssClass(element, sortable.connectClass, sortable.allowDrop);
      }
      //wrap the template binding
      ko.bindingHandlers.template.init(element, (() => templateOptions), allBindingsAccessor, data, context);
      //keep a reference to start/update functions that might have been passed in
      startActual = sortable.options.start;
      updateActual = sortable.options.update;
      //initialize sortable binding after template binding has rendered in update function
      const createTimeout = setTimeout((function() {
        const dragItem = undefined;
        $element.sortable(ko.utils.extend(sortable.options, {
          helper(e, item) {
            let container;
            let elements = [];
            let helper = undefined;
            if ((ko.utils.domData.get(item[0], ko.constants.GROUPKEY) !== undefined) || (ko.utils.domData.get(item[0], ko.constants.CONTAINERKEY) !== undefined)) {
//TODO: cause dragging issue
//helper = $(item[0]).addClass('group-dragging');
              helper = $(item[0]);
            } else if (ko.utils.domData.get(item[0], ko.constants.ITEMKEY) !== undefined) {
              elements = $('.checker.active').closest('.golumn-item').find('.golumn-item-title').clone();
              if (!elements.length) {
                elements.push(item.clone());
              }
              helper = $('<div class=\'animate-dragging\' style=\'width: 130px; height: 30px\'></div>');
              if (elements.length > 1) {
                helper.append($('<div class=\'animate-dragging-number\'>' + elements.length + '</div>'));
                let z = 0;
                let render = 3;
                if (elements.length < render) {
                  render = elements.length;
                }
                let i = 0;
                while (i < render) {
                  var t = -i * 5;
                  container = $('<div style=\'width: 130px; height: 30px; color: white; vertical-align: middle; text-align: center; font-weight: bold; font-size:14px; line-height:20px; background-color: #428bca; box-shadow: 1px 1px 8px #000000;\'></div>');
                  $(container).css('top', t + 'px');
                  $(container).css('left', -t + 'px');
                  $(container).css('z-index', z);
                  container.append($(elements[i]).text());
                  container.addClass('animate-dragging-img');
                  helper.append(container);
                  z = z - 1;
                  i++;
                }
              } else {
                container = $('<div style=\'width: 130px; height: 30px; vertical-align: middle; text-align: center; font-size:14px; line-height:20px\'></div>');
                container.append($(elements[0]).text());
                container.addClass('animate-dragging-text');
                helper.append(container);
              }
            } else {
              //fallback
              helper = $('<div class=\'animate-dragging\' style=\'width:50px;height:50px\'></div>');
            }
            return helper;
          },
          sort(event, ui) {
            //var $target = $(event.target);
            //if (!/html|body/i.test($target.offsetParent()[0].tagName)) {
            //    var left = event.pageX - $target.offsetParent().offset().left - (ui.helper.outerHeight(true) / 2);
            //    ui.helper.css({'left' : left + 'px'});
            //}
          },
          start(event, ui) {
            //track original index
            let el = ui.item[0];
            //Moving an animal
            if (ko.utils.domData.get(el, ko.constants.ITEMKEY) !== undefined) {
              el = $('.checker.active').closest('.golumn-item').not('.ui-sortable-placeholder');
              if (el.length) {
                ui.item.data('items', el);
              }
              $('.golumn-group .body .animal-dropzone').addClass('grow-empty-zone');
              $('.add-container').css('display', 'block');
              $('.add-container').addClass('grow-empty-zone');
            }
            if (ko.utils.domData.get(el, ko.constants.GROUPKEY) !== undefined) {
              //Need to set current array position
              ko.utils.domData.set(el, ko.constants.INDEXKEY, ko.utils.arrayIndexOf(ui.item.parent().children(), el));
            }
            let containerItem = undefined;
            if ((containerItem = ko.utils.domData.get(el, ko.constants.CONTAINERKEY)) !== undefined) {
              ko.utils.domData.set(el, ko.constants.INDEXKEY, containerItem.position());
            }
            //make sure that fields have a chance to update model
            ui.item.find('input:focus').change();
            if (startActual) {
              startActual.apply(this, arguments);
            }
          },
          over(event, ui) {
            const sortableIn = 1;
            $('.sorting-animal-placeholder').css('display', 'block');
          },
          out(event, ui) {
            const sortableIn = 0;
            $('.sorting-animal-placeholder').css('display', 'none');
          },
          receive(event, ui) {
            let el = ui.item[0];
            if ((ko.utils.domData.get(el, ko.constants.ITEMKEY) !== undefined) && sortableIn) {
              const containerEl = ui.item.closest('.golumn-group')[0];
              const animals = [];
              let containerItem = undefined;
              if (containerEl !== undefined) {
                containerItem = ko.utils.domData.get(containerEl, ko.constants.CONTAINERKEY);
                let observableItem = undefined;
                if (ui.item.data('items')) {
                  el = ui.item.data('items');
                } else {
                  el = ui.item;
                }
                ko.utils.arrayForEach(el, function(item) {
                  if ((observableItem = ko.utils.domData.get(item, ko.constants.ITEMKEY)) !== null) {
                    animals.push(observableItem);
                    $(item).remove();
                  }
                });
              }
              window.app.toggleMoveAnimalModal(animals, containerItem);
            }
            if (!sortableIn) {
              $(ui.sender || this).sortable('cancel');
            }
          },
          stop(e, ui) {
            const el = ui.item[0];
            $('.golumn-group .body .animal-dropzone').removeClass('grow-empty-zone');
            $('.add-container').removeClass('grow-empty-zone');
            $('.add-container').css('display', 'none');
            if (ko.utils.domData.get(el, ko.constants.GROUPKEY) !== undefined) {} 
              //$(el).removeClass('group-dragging');
            else {}
          },
          update(event, ui) {
            let observableItem, sourceIndex, targetIndex, targetParent;
            const el = ui.item[0];
            if ((observableItem = ko.utils.domData.get(el, ko.constants.GROUPKEY)) !== undefined) {
              const sourceParent = ko.utils.domData.get(el, PARENTKEY);
              sourceIndex = ko.utils.domData.get(el, ko.constants.INDEXKEY);
              targetParent = ko.utils.domData.get(el.parentNode, LISTKEY);
              targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el);
              //do the actual move
              if (targetIndex >= 0) {
                if (sourceParent) {
                  sourceParent.splice(sourceIndex, 1);
                }
                targetParent.splice(targetIndex, 0, observableItem);
              }
              //update preferences
              window.app.updatePreferences();
            }
            if (ko.utils.domData.get(el, ko.constants.CONTAINERKEY) !== undefined) {
              const sourceParentGroup = ko.utils.domData.get($(el).closest('.golumn-column')[0], ko.constants.GROUPKEY);
              sourceIndex = ko.utils.domData.get(el, ko.constants.INDEXKEY);
              targetParent = ko.utils.domData.get(ui.item.closest('.golumn-column')[0], ko.constants.GROUPKEY);
              targetIndex = ko.utils.arrayIndexOf(ui.item.parent().children(), el);
              let containerItem = undefined;
              containerItem = ko.utils.domData.get(el, ko.constants.CONTAINERKEY);
              if (sourceParentGroup && targetParent && !isNaN(sourceIndex) && !isNaN(targetIndex)) {
                window.app.moveContainer(containerItem, sourceParentGroup, sourceIndex, targetParent, targetIndex);
              }
            }
            if (updateActual) {
              updateActual.apply(this, arguments);
            }
          },
          connectWith: sortable.connectClass ? '.' + sortable.connectClass : false
        })
        );
        //handle enabling/disabling sorting
        if (sortable.isEnabled !== undefined) {
          ko.computed({
            read() {
              $element.sortable(ko.utils.unwrapObservable(sortable.isEnabled) ? 'enable' : 'disable');
            },
            disposeWhenNodeIsRemoved: element
          });
        }
      }), 0);
      //handle disposal
      ko.utils.domNodeDisposal.addDisposeCallback(element, function() {
        //only call destroy if sortable has been created
        if ($element.data('ui-sortable') || $element.data('sortable')) {
          $element.sortable('destroy');
        }
        ko.utils.toggleDomNodeCssClass(element, sortable.connectClass, false);
        //do not create the sortable if the element has been removed from DOM
        clearTimeout(createTimeout);
      });
      return { 'controlsDescendantBindings': true };
    },
    update(element, valueAccessor, allBindingsAccessor, data, context) {
      const templateOptions = ko.utils.prepareTemplateOptions(valueAccessor, 'foreach');
      //attach meta-data
      ko.utils.domData.set(element, LISTKEY, templateOptions.foreach);
      //call template binding's update with correct options
      ko.bindingHandlers.template.update(element, (() => templateOptions), allBindingsAccessor, data, context);
    },
    connectClass: 'ko_container',
    allowDrop: true,
    afterMove: null,
    beforeMove: null,
    options: {}
  };
})(ko, jQuery);