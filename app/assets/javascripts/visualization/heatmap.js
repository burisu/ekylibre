visualization.Heatmap = class Heatmap {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.items = [];
    const property = this.layer.reference;
    console.log(property);
    console.log(this.data);
    for (var zone of Array.from(this.data)) {
      var coords =  zone.shape.coordinates;
      this.items.push([coords[1], coords[0], ]);
    }

    if (this.valid()) {
      console.log("Heatmap computed");
    } else {
      console.warn("Invalid heatmap points");
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    const overlay = new L.TileLayer.WebGLHeatMap({
      size: 12,
      opacity: 0.8,
      autoresize: true
    });
    overlay.setData(this.items);

    group.push(overlay);
    return group;
  }

  // Build HTML legend for given categories computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    html += `<h3>${this.layer.label}</h3>`;
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    // html += "<span class='leaflet-categories-items'>"
    // for name, item of @items
    //   html += "<span class='leaflet-categories-item'>"
    //   html += "<i class='leaflet-categories-sample' style='background-color: #{item.fillColor};'></i>"
    //   html += " #{item.name}"
    //   html += "</span>"
    // html += "</span>"
    html += "</div>";
    html += "</div>";
    return html;
  }

  // Check if categories are valid
  valid() {
    return this.items.length > 0;
  }
};

visualization.registerLayerType("heatmap", visualization.Heatmap);
