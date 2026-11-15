//= require jquery

(function($) {
  "use strict";

  // Removes all nodes triggering event on them
  $.fn.deepRemove = function(event) {
    if ((event === null) || (event === undefined)) {
      event = 'remove';
    }
    this.each(function() {
      const element = $(this);
      const allChildren = element.find('*');
      allChildren.detach();
      allChildren.trigger(event);
      allChildren.remove();
      element.detach();
      element.trigger(event);
      return element.remove();
    });
    return $;
  };

  // Takes a GET-serialized string, e.g. first=5&second=3&a=b and sets input tags (e.g. input name="first") to their values (e.g. 5)
  $.unparam = function(params) {
    if ((params === null) || (params === undefined)) {
      return {};
    }
    // this small bit of unserializing borrowed from James Campbell's "JQuery Unserialize v1.0"
    params = params.split('&');
    const unserializedParams = {};
    $.each(params, function() {
      const properties = this.split('=');
      if ((typeof properties[0] !== 'undefined') && (typeof properties[1] !== 'undefined')) {
        unserializedParams[properties[0].replace(/\+/g, ' ')] = properties[1].replace(/\+/g, ' ');
      }
    });
    return unserializedParams;
  };

  // Build URL from base url and additional parameters
  $.buildURL = function(url, params) {
    const tempArray = url.split('?');
    const baseURL = tempArray[0];
    params = $.extend($.unparam(tempArray[1]), params);
    return baseURL + '?' + $.param(params);
  };

})(jQuery);
