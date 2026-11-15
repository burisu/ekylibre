// Permit to test is avalue is blank
(function($) {
  'use strict';

  // Work like $.isArray, $.isFunction...
  $.isBlank = obj => (obj == null) || ($.trim(obj) === "");

  return true;
})(jQuery);
