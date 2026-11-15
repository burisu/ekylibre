// Apache ECharts glue for Ekylibre.
//
// This file is the replacement for chart/highcharts. It exposes:
//   - $.widget "ui.echart"     : jQuery UI widget that reads `data-echarts`
//                                from a DOM node and instantiates an ECharts
//                                chart on it.
//   - $.loadECharts()          : initializes all unloaded `[data-echarts]`
//                                elements in the current document.
//   - $.echartFor(selector)    : returns the ECharts instance bound to the
//                                first matching element (or null). Used by
//                                plugins (e.g. ekylibre-economic) to mutate
//                                a chart's options at runtime.
//
// The Ruby helper (`ChartsHelper`) emits ECharts-shaped JSON in the
// `data-echarts` attribute. A custom `__drilldown` key inside that JSON
// (optional) carries Highcharts-style drilldown series; the widget wires
// them as click handlers + setOption swaps.
//
//= require jquery
//= require jquery_ujs
//= require echarts/dist/echarts.min

(function($) {
  "use strict";

  const instances = new WeakMap();

  const DEFAULT_TEXT_STYLE = {
    fontFamily: "\"Open Sans\", \"Droid Sans\", \"Liberation Sans\", Helvetica, sans-serif",
    fontSize: 13
  };

  const DEFAULT_DECIMALS = 2;

  // Format a number with `decimals` digits after the decimal mark.
  // French-style separators (space for thousands, comma for decimals)
  // match the rest of the Ekylibre UI. Non-numbers pass through as-is.
  const formatNumber = function(value, decimals) {
    if (decimals == null) { decimals = DEFAULT_DECIMALS; }
    if ((typeof value !== "number") || !isFinite(value)) { return value; }
    const sign = value < 0 ? "-" : "";
    const abs = Math.abs(value).toFixed(decimals);
    const [intPart, decPart] = Array.from(abs.split("."));
    const intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    if (decPart != null) { return `${sign}${intFmt},${decPart}`; } else { return `${sign}${intFmt}`; }
  };

  // Walk the options tree and turn strings shaped like "function(...) { ... }"
  // into real functions. JSON cannot carry callables, so the Ruby helper
  // serialises them as strings (e.g. bubble's symbolSize) and we revive
  // them here.
  var reviveFunctions = function(node) {
    let v;
    if (node == null) { return node; }
    if ((typeof node === "string") && /^\s*function\s*\(/.test(node)) {
      try {
        return new Function(`return (${node})`)();
      } catch (error) {
        return node;
      }
    }
    if (Array.isArray(node)) {
      for (let i = 0; i < node.length; i++) {
        v = node[i];
        node[i] = reviveFunctions(v);
      }
      return node;
    }
    if (typeof node === "object") {
      for (var k of Object.keys(node || {})) {
        v = node[k];
        node[k] = reviveFunctions(v);
      }
      return node;
    }
    return node;
  };

  // Substitute Highcharts/ECharts placeholders in a template string
  // using formatted values. Supports {c}, {b}, {a} — the placeholders
  // the Ruby helper produces via convert_point_format.
  const substituteTemplate = function(tpl, params) {
    const p = Array.isArray(params) ? params[0] : params;
    if (p == null) { return tpl; }
    const {
      value
    } = p;
    const name = p.name || "";
    const seriesName = p.seriesName || "";
    const formattedValue = formatNumber(value, DEFAULT_DECIMALS);
    return tpl
      .replace(/\{c\}/g, formattedValue)
      .replace(/\{b\}/g, name)
      .replace(/\{a\}/g, seriesName);
  };

  // Build a tooltip/label callback from a template string. This wrapper
  // is needed because ECharts' tooltip.valueFormatter is ignored when a
  // tooltip.formatter (even a string template) is set — values would
  // otherwise be substituted raw, with 8-decimal floats.
  const buildTemplateFormatter = tpl => params => substituteTemplate(tpl, params);

  // Add a small toolbox in the top-right corner of every chart, with a
  // single feature: save-as-image (PNG). Mirrors the Highcharts "export
  // menu" affordance users had before. Callers can opt out or extend
  // by setting their own `toolbox` option.
  const applyDefaultToolbox = function(opts) {
    if (opts.toolbox != null) { return; }
    let label = "Télécharger l'image";
    try {
      if (window.I18n?.t != null) {
        label = window.I18n.t("front-end.echarts.save_as_image") || label;
      }
    } catch (error) {}
    opts.toolbox = {
      show: true,
      right: 10,
      top: 6,
      itemSize: 14,
      itemGap: 8,
      feature: {
        saveAsImage: {
          show: true,
          title: label,
          name: "chart",
          pixelRatio: 2,
          backgroundColor: "#ffffff"
        }
      }
    };
  };

  // Series whose name starts with "__" are considered internal helpers
  // (e.g. waterfall connector lines). They must render on the chart but
  // never appear in the legend.
  const hideInternalSeriesFromLegend = function(opts) {
    if (!Array.isArray(opts.series)) { return; }
    const visible = opts.series
      .filter(s => (s?.name != null) && !/^__/.test(s.name))
      .map(s => s.name);
    if (opts.legend) {
      if (!opts.legend.data) { opts.legend.data = visible; }
    }
  };

  // Apply sensible default formatters so charts don't render raw
  // 8-decimal floating point garbage. When the caller supplies a string
  // template via tooltip.formatter / series.label.formatter, we wrap it
  // in a callback that does substitution AND number formatting.
  const applyDefaultFormatters = function(opts) {
    if (!opts.tooltip) { opts.tooltip = { show: true }; }
    const fmt = opts.tooltip.formatter;
    if (typeof fmt === "string") {
      opts.tooltip.formatter = buildTemplateFormatter(fmt);
    } else if ((fmt == null) && (opts.tooltip.valueFormatter == null)) {
      opts.tooltip.valueFormatter = value => formatNumber(value, DEFAULT_DECIMALS);
    }

    // yAxis is the value axis in most cases; xAxis carries values only
    // when the chart is a bar chart (we don't try to detect that here —
    // the helper sets sane axis types). Format integers (no decimals) on
    // axis ticks to keep them readable on dense plots.
    for (var axisKey of ["yAxis", "xAxis"]) {
      var axes = opts[axisKey];
      if (!axes) { continue; }
      if (!Array.isArray(axes)) { axes = [axes]; }
      for (var ax of Array.from(axes)) {
        if (!ax || (ax.type !== "value")) { continue; }
        if (!ax.axisLabel) { ax.axisLabel = {}; }
        if (!ax.axisLabel.formatter) { ax.axisLabel.formatter = value => formatNumber(value, 0); }
      }
    }

    if (Array.isArray(opts.series)) {
      for (var s of Array.from(opts.series)) {
        if (!s?.label?.show) { continue; }
        var lf = s.label.formatter;
        if (typeof lf === "string") {
          s.label.formatter = buildTemplateFormatter(lf);
        } else if ((lf == null)) {
          s.label.formatter = function(params) {
            const v = (params != null) && "value" in params ? params.value : params;
            return formatNumber(v, DEFAULT_DECIMALS);
          };
        }
      }
    }

  };

  const installDrilldown = function(chart, spec, baseOption) {
    // spec: { series: { <id>: [{name, data, type, ...}] } }
    if ((spec == null) || (spec.series == null)) { return; }
    const seriesById = spec.series;

    chart.on("click", function(params) {
      const pt = params?.data;
      if ((pt == null) || (typeof pt !== "object")) { return; }
      const id = pt.drilldown;
      if (!id || !seriesById[id]) { return; }
      let drillSeries = seriesById[id];
      if (!Array.isArray(drillSeries)) { drillSeries = [drillSeries]; }
      const newSeries = drillSeries.map(s => $.extend(true, {}, s, { type: s.type || "bar" }));
      chart.setOption({ series: newSeries }, true, true);
      return showBackButton(chart, baseOption);
    });

  };

  var showBackButton = function(chart, baseOption) {
    const dom = chart.getDom();
    const $dom = $(dom);
    if ($dom.find(".echart-drilldown-back").length > 0) { return; }
    const $btn = $("<button type='button' class='echart-drilldown-back'>‹ Retour</button>");
    $btn.css({
      position: "absolute",
      top: "8px",
      right: "8px",
      "z-index": 10
    });
    $btn.on("click", function() {
      chart.setOption(baseOption, true, true);
      return $btn.remove();
    });
    // Make sure container is positioned so the button anchors correctly.
    if ($dom.css("position") === "static") {
      $dom.css("position", "relative");
    }
    $dom.append($btn);
  };

  $.widget("ui.echart", {
    options: {},

    _create() {
      const raw = this.element.data("echarts") || {};
      const opts = $.extend(true, {}, this.options, raw);
      const drilldownSpec = opts.__drilldown;
      if (drilldownSpec != null) { delete opts.__drilldown; }

      // Apply default text style if the option does not carry one.
      opts.textStyle = $.extend(true, {}, DEFAULT_TEXT_STYLE, opts.textStyle || {});

      reviveFunctions(opts);
      hideInternalSeriesFromLegend(opts);
      applyDefaultToolbox(opts);
      applyDefaultFormatters(opts);

      this.chart = echarts.init(this.element[0]);
      this.chart.setOption(opts);
      instances.set(this.element[0], this.chart);

      if (drilldownSpec != null) {
        installDrilldown(this.chart, drilldownSpec, opts);
      }

      this._resizeHandler = () => this.chart?.resize();
      $(window).on(`resize.echart-${this.uuid}`, this._resizeHandler);
      return this.element.on(`cell:load.echart-${this.uuid}`, this._resizeHandler);
    },

    _destroy() {
      $(window).off(`resize.echart-${this.uuid}`);
      this.element.off(`cell:load.echart-${this.uuid}`);
      instances.delete(this.element[0]);
      return this.chart?.dispose();
    },

    uuid() { return this.element[0].__echartUuid || (this.element[0].__echartUuid = (Math.random().toString(36).slice(2))); }
  }
  );

  $.loadECharts = function() {
    $("[data-echarts]:not(.echart-loaded)").each(function() {
      return $(this).addClass("echart-loaded").echart();
    });
  };

  $.echartFor = function(selector) {
    const el = $(selector)[0];
    if (!el) { return null; }
    return instances.get(el);
  };

  return $(document).on("turbo:load cocoon:after-insert cell:load", $.loadECharts);

})(jQuery);
