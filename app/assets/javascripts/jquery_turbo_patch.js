(function ($) {
    $.fn.ready = function (callback) {
        $(this).on('turbo:load', callback)
    };
})(jQuery);