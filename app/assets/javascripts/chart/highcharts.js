// Needs base HighCharts files
//
//= require jquery
//= require jquery_ujs
//= require highcharts/highcharts
//= require highcharts/highcharts-more
//= require highcharts/modules/data
//= require highcharts/modules/drilldown
//= require highcharts/modules/exporting
//= require highcharts/modules/export-data
//= require highcharts/modules/treemap
//= require highcharts/modules/accessibility

(function($) {
  "use strict";

  $.widget("ui.highchart", {
    options: {
      chart: {
        style: {
          fontFamily: "\"Open Sans\", \"Droid Sans\", \"Liberation Sans\", Helvetica, sans-serif",
          fontSize: "13px"
        }
      },
      credits: {
        enabled: false
      },
      tooltip: {
        enabled: true
      },
      legend: {
        enabled: false
      },
      title: {
        text: ""
      }
    },

    _create() {
      $.extend(true, this.options, this.element.data("highcharts"));
      return this.element.highcharts(this.options);
    },

    _destroy() {
      return console.log("No highcharts destroy");
    }
  }
  );

  $.loadHighcharts = function() {
    $("*[data-highcharts]").each(function() {
      const chartitem = $(this);
      return chartitem.highchart();
    });
  };

  $(document).on("turbolinks:load cocoon:after-insert cell:load", $.loadHighcharts);

  return Highcharts.setOptions({
    lang: I18n.t("front-end.highcharts")
});

})(jQuery);
