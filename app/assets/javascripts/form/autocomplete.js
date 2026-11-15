//= require twitter/typeahead

(function($) {

  $.loadTypeahead = function() {
    const element = $(this);
    const wrapper = element.closest('.twitter-typeahead');
    if (wrapper.length <= 0) {
      const completer = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        // prefetch: element.data('autocomplete')
        remote: {
          url: element.data('autocomplete') + "?q=%QUERY",
          wildcard: '%QUERY'
        }
      });
      element.typeahead(null, {
        source: completer,
        limit: 10
      }
      );
      element.attr('typeaheadloaded', 'yes');
    }
  };

  $(document).ready(() => $("input[data-autocomplete]").each(function() {
    return $.loadTypeahead.call(this);
  }));

  $(document).on("turbolinks:load cocoon:after-insert dialog:show", () => $("input[data-autocomplete]").each(function() {
    return $.loadTypeahead.call(this);
  }));

})(jQuery);
