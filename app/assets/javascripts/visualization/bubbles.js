// Add sprockets directives below:
//= require visualization/gradient
//

visualization.Bubbles = class Bubbles extends visualization.Gradient {

  constructor(layer, data, options) {
    if (options == null) { options = {}; }
    if (options.levelNumber == null) { options.levelNumber = 5; }

    super(data, layer.reference, options);
    this.layer = layer;
    this.data = data;

    if (this.valid()) {

      // Compute radius
      if (options.startRadius == null) { options.startRadius = 4; }
      if (options.stopRadius == null) {  options.stopRadius = 24; }
      const start = options.startRadius;
      const stop  = options.stopRadius;
      for (var grade of Array.from(this.grades)) {
        var level = grade.index / (this.levelNumber - 1.0);
        grade.radius = start + Math.round((stop - start) * level);
        grade.fillColor = options.fillColor;
        grade.color  = options.color;
        grade.weight = options.weight;
        grade.stroke = options.stroke;
      }
      console.log("Radiuses computed");
    } else {
      console.warn("Invalid bubbles");
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    let grade, zone, zoneStyle;
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    // Shadow
    for (zone of Array.from(this.data)) {
      grade = this.gradeFor(zone[this.layer.reference]);
      if (grade.stroke) {
        zoneStyle = {
          fillColor: grade.color,
          radius: grade.radius + grade.weight,
          stroke: false,
          fillOpacity: 0.8
        };
        group.push(new L.CircleMarker(this._centroid(zone.shape), zoneStyle));
      }
    }
    // Core
    for (zone of Array.from(this.data)) {
      grade = this.gradeFor(zone[this.layer.reference]);
      zoneStyle = {
        fillColor: grade.fillColor,
        radius: grade.radius,
        stroke: false,
        fillOpacity: 1
      };
      var zoneLayer = new L.CircleMarker(this._centroid(zone.shape), zoneStyle);
      widget._bindPopup(zoneLayer, zone);
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given bubbles computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    html += `<h3>${this.layer.label}</h3>`;
    html += "<div class='leaflet-legend-body leaflet-bubbles-scale'>";
    html += `<span class='min-value'>${this.grades[0].minLabel}</span>`;
    html += "<span class='leaflet-bubbles-grades'>";
    for (var grade of Array.from(this.grades)) {
      html += `<i class='leaflet-bubbles-grade' style='width: ${2 * grade.radius}px; height: ${2 * grade.radius}px; background-color: ${grade.fillColor}; border-width: ${grade.weight}px; border-color: ${grade.color}' title='${grade.minLabel} ~ ${grade.maxLabel}'></i>`;
    }
    html += "</span>";
    html += `<span class='max-value'>${this.grades[this.levelNumber - 1].maxLabel}</span>`;
    html += "</div>";
    html += "</div>";
    return html;
  }

  // Compute a centroid based on bounds
  // The point can be out of the surface...
  _centroid(shape) {
    const geojson = new L.GeoJSON(shape);
    return geojson.getBounds().getCenter();
  }
};

visualization.registerLayerType("bubbles", visualization.Bubbles);
