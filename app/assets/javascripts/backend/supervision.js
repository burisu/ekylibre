//= require highcharts/highcharts
(function(E, $) {

  /*
   * In order to synchronize tooltips and crosshairs, override the
   * built-in events with handlers defined on the parent element.
   */

  /*
   * Synchronize zooming through the setExtremes event handler.
   */
  E.syncExtremes = function(e) {
    console.log("sync extremes");
    const thisChart = this.chart;
    return Highcharts.each(Highcharts.charts, function(chart) {
      if (chart !== thisChart) {
        if (chart.xAxis[0].setExtremes) {
          // It is null while updating
          return chart.xAxis[0].setExtremes(e.min, e.max);
        }
      }
    });
  };

  $(document).on('mousemove touchmove', '#graphs *[data-sync-chart]', function(e) {
    let point;
    let chart = $(this).highcharts();
    const masterSerie = chart.hoverSeries != null ? chart.hoverSeries : chart.series[0];
    const masterPoint = masterSerie.searchPoint(e, true);
    for (chart of Array.from(Highcharts.charts)) {
      var serie;
      e = chart.pointer.normalize(e);
      for (var s of Array.from(chart.series)) {
        if (s.name === masterSerie.name) { serie = s; }
      }
      if (serie == null) { serie = chart.hoverSeries; }
      if (serie == null) { serie = chart.series[0]; }
      point = serie.searchPoint(e, true);
      if (point) {
        // Show the hover marker
        if (serie.visible) {
          point.onMouseOver();
        } else {
          serie.onMouseOut();
        }
        // Show the tooltip
        chart.tooltip.refresh(point);
        // Show the crosshair
        chart.xAxis[0].drawCrosshair(e, point);
      }
    }
    // Show point on map
    const map = $('#map .map');
    if (point) {
      map.find('.crumb.hover').each(function() {
        return L.DomUtil.removeClass(this, 'hover');
      });
      console.log(map.find(`.crumb-t${point.x}`));
      L.DomUtil.addClass(map.find(`.crumb-t${point.x}`)[0], 'hover');
      return console.log(map.find(`.crumb-t${point.x}`));
    }
  });


  /*
   * Override the reset function, we don't need to hide the tooltips and crosshairs.
   */

  Highcharts.Pointer.prototype.reset = function() {};

  return $(document).ready(function() {
    $('*[data-sync-chart]').each(function() {
      const element = $(this);
      console.log(element);
      const dataset = element.data('sync-chart');
      return element.highcharts({
        chart: {
          marginLeft: 40,
          spacingTop: 20,
          spacingBottom: 20,
          height: 250,
          eventszzzz: {
            load() {
              console.log(">>", new Date, (new Date()).getTime());
              const {
                series
              } = this;
              setInterval((function() {
                const d = new Date;
                console.log("ok", d, d.getTimezoneOffset());
                const x = d.getTime() - (d.getTimezoneOffset() * 60 * 1000);
                return (() => {
                  const result = [];
                  for (var serie of Array.from(series)) {
                    var y = 100 * Math.random();
                    console.log(`${x}, ${y}`);
                    result.push(serie.addPoint([x, y], true, true));
                  }
                  return result;
                })();
                }), 5000);
            }
          }
        },

        title: {
          text: null
        },
        credits: {
          enabled: false
        },
        legend: {
          enabled: true
        },
        xAxis: {
          type: 'datetime',
          crosshair: true,
          events: {
            setExtremes: E.syncExtremes
          }
        },
        yAxis: {
          title: {
            text: null
          }
        },
        tooltip: {
          pointFormat: `{point.y} ${dataset.unit}`
        },
        series: dataset.series
      });
    });
    return setTimeout(( () => $(window).trigger('resize')), 400);});

})(ekylibre, jQuery);
