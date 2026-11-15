//= require backend/golumn/helpers/knockout_globals

(function(ko, $) {

  ko.utils.addMetaDataAfterRender = function(elements, data) {
    //internal afterRender that adds meta-data to children
    ko.utils.arrayForEach(elements, function(element) {
      if (element.nodeType === 1) {
        if ($(element).hasClass('golumn-group')) {
          ko.utils.domData.set(element, ko.constants.CONTAINERKEY, data);
        } else if ($(element).hasClass('golumn-column')) {
          ko.utils.domData.set(element, ko.constants.GROUPKEY, data);
        } else if ($(element).hasClass('golumn-item')) {
          ko.utils.domData.set(element, ko.constants.ITEMKEY, data);
        }
        ko.utils.domData.set(element, ko.constants.PARENTKEY, ko.utils.domData.get(element.parentNode, ko.constants.LISTKEY));
      }
    });
  };

  ko.utils.prepareTemplateOptions = function(valueAccessor, dataName) {
    const result = {};
    const options = ko.utils.unwrapObservable(valueAccessor()) || {};
    let actualAfterRender = undefined;
    //build our options to pass to the template engine
    if (options.data) {
      result[dataName] = options.data;
      result.name = options.template;
    } else {
      result[dataName] = valueAccessor();
    }
    ko.utils.arrayForEach([
      'afterAdd',
      'afterRender',
      'as',
      'beforeRemove',
      'includeDestroyed',
      'templateEngine',
      'templateOptions',
      'nodes'
    ], function(option) {
      if (options.hasOwnProperty(option)) {
        result[option] = options[option];
      } else if (ko.bindingHandlers.sortable.hasOwnProperty(option)) {
        result[option] = ko.bindingHandlers.sortable[option];
      }
    });
    //use an afterRender function to add meta-data
    if (dataName === 'foreach') {
      if (result.afterRender) {
        //wrap the existing function, if it was passed
        actualAfterRender = result.afterRender;

        result.afterRender = function(element, data) {
          ko.utils.addMetaDataAfterRender.call(data, element, data);
          actualAfterRender.call(data, element, data);
        };

      } else {
        result.afterRender = ko.utils.addMetaDataAfterRender;
      }
    }
    //return options to pass to the template binding
    return result;
  };

  ko.utils.updateIndexFromDestroyedItems = function(index, items) {
    const unwrapped = ko.utils.unwrapObservable(items);
    if (unwrapped) {
      let i = 0;
      while (i < index) {
        //add one for every destroyed item we find before the targetIndex in the target array
        if (unwrapped[i] && ko.utils.unwrapObservable(unwrapped[i]._destroy)) {
          index++;
        }
        i++;
      }
    }
    return index;
  };

  //remove problematic leading/trailing whitespace from templates
  return ko.utils.stripTemplateWhitespace = function(element, name) {
    let templateSource = undefined;
    let templateElement = undefined;
    //process named templates
    if (name) {
      templateElement = document.getElementById(name);
      if (templateElement) {
        templateSource = new (ko.templateSources.domElement)(templateElement);
        templateSource.text($.trim(templateSource.text()));
      }
    } else {
      //remove leading/trailing non-elements from anonymous templates
      $(element).contents().each(function() {
        if (this && (this.nodeType !== 1)) {
          element.removeChild(this);
        }
      });
    }
  };

})(ko, jQuery);