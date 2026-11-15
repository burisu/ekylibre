// Add sprockets directives below:
//= require visualization/gradient

visualization.Choropleth = class Choropleth extends visualization.Gradient {

  constructor(layer, data, options) {
    if (options == null) { options = {}; }
    super(data, layer.reference, options);
    this.layer = layer;
    this.data = data;

    if (this.valid()) {

      // Compute colors
      const start = new visualization.Color(options.startColor);
      const stop  = new visualization.Color(options.stopColor);
      for (var grade of Array.from(this.grades)) {
        var level = grade.index / (this.levelNumber - 1.0);
        grade.fillColor = visualization.Color.toString({
          red:   start.red   + (Math.round(stop.red   - start.red)   * level),
          green: start.green + (Math.round(stop.green - start.green) * level),
          blue:  start.blue  + (Math.round(stop.blue  - start.blue)  * level)
        });
      }
      console.log("Colors computed");
    } else {
      console.warn(`Invalid choropleth for ${this.layer.reference}`);
      console.warn(this.data);
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    for (var zone of Array.from(this.data)) {
      var zoneStyle =
        {fillColor: this.gradeFor(zone[this.layer.reference]).fillColor};
      var zoneLayer = new L.GeoJSON(zone.shape, $.extend(true, {}, globalStyle, zoneStyle));
      widget._bindPopup(zoneLayer, zone);
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given choropleth computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}' style='display: none;'>`;
    html += `<h3>${this.layer.label}`+ (this.layer.unit ? ` (${this.layer.unit})` : "</h3>");
    html += "<div class='leaflet-legend-body leaflet-choropleth-scale'>";
    html += `<span class='min-value'>${this.grades[0].minLabel}</span>`;
    html += `<span class='max-value'>${this.grades[this.levelNumber - 1].maxLabel}</span>`;
    html += "<span class='leaflet-choropleth-grades'>";
    for (var grade of Array.from(this.grades)) {
      html += `<i class='leaflet-choropleth-grade' style='width: ${100 / this.levelNumber}%; background-color: ${grade.fillColor}' title='${grade.minLabel} ~ ${grade.maxLabel}'></i>`;
    }
    html += "</span>";
    html += "</div>";
    html += "</div>";
    return html;
  }
};

visualization.registerLayerType("choropleth", visualization.Choropleth);
