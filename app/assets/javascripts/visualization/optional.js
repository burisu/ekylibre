visualization.Optional = class Optional {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.options = options;
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    for (var zone of Array.from(this.data)) {
      var zoneLayer = new L.GeoJSON(zone.shape, globalStyle);
      widget._bindPopup(zoneLayer, zone);
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given categories computed layer
  buildLegend() {
    let html = `<div class='leaflet-legend-item' id='legend-${this.layer.name}' style='display: none;'>`;
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    html += "<span class='leaflet-categories-items'>";
    html += "<span class='leaflet-categories-item'>";
    html += `<i class='leaflet-categories-sample' style='background-color: ${this.layer.fillColor || this.options.parent.options.layerDefaults[this.layer.type].fillColor };'></i>`;
    html += `<span class='leaflet-categories-item_label'>${this.layer.label}</span>`;
    html += `<span class='leaflet-categories-item_label zoom-guidance'>(${this.options.zoomGuidance})</span>`;
    html += "</span>";
    html += "</span>";
    html += "</div>";
    html += "</div>";
    return html;
  }

  // Check if categories are valid
  valid() {
    return true;
  }
};

visualization.registerLayerType('optional', visualization.Optional);
