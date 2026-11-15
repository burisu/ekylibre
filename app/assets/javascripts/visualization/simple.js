visualization.Simple = class Simple {

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
      if (!this.layer.withoutGhostLabel) {
        var label = new L.GhostLabel({className: 'leaflet-ghost-label', toBack: false}).setContent(zone.name).toCentroidOfBounds(zoneLayer.getLayers()[0].getLatLngs());
        widget.ghostLabelCluster.bind(label, zoneLayer.getLayers()[0]);
      }
      widget._bindPopup(zoneLayer, zone);
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given categories computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    // html += "<h3>#{@layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    html += "<span class='leaflet-categories-items'>";
    html += "<span class='leaflet-categories-item'>";
    html += `<i class='leaflet-categories-sample' style='background-color: ${this.layer.fillColor || this.options.parent.options.layerDefaults[this.layer.type].fillColor };'></i>`;
    html += ` <span class='leaflet-categories-item_label'>${this.layer.label}</span>`;
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

visualization.registerLayerType("simple", visualization.Simple);
