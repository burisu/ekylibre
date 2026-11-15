visualization.Points = class Points {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.options = options;
    this.items = [];
    console.log("Layer: ", this.layer);
    for (var zone of Array.from(this.data)) {
      var lnglat = zone.shape.coordinates;
      this.items.push({
        name: zone.name,
        point: [lnglat[1], lnglat[0]],
        radius: zone.radius != null ? zone.radius : this.options.radius
      });
    }
    if (this.valid()) {
      this.items = this.items.sort((a, b) => a.name > b.name);
      this.colors = this.options.colors != null ? this.options.colors : [];
      if (this.items.length > this.colors.length) {
        for (let x = this.colors.length, end = this.items.length, asc = this.colors.length <= end; asc ? x <= end : x >= end; asc ? x++ : x--) {
          this.colors.push(visualization.colors[x] != null ? visualization.colors[x] : "#000000");
        }
      }
      for (let index = 0; index < this.items.length; index++) {
        var item = this.items[index];
        item.fillColor = this.colors[index];
      }
      console.log("Points computed");
    } else {
      console.warn("Invalid categories");
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    let zone, zoneStyle;
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    // Shadow
    if (this.options.stroke) {
      for (zone of Array.from(this.items)) {
        zoneStyle = {
          fillColor: zone.color != null ? zone.color : this.options.color,
          radius: (zone.radius != null ? zone.radius : this.options.radius) + this.options.weight,
          stroke: false,
          fillOpacity: 0.8
        };
        console.log(zone.point);
        group.push(new L.circleMarker(zone.point, zoneStyle));
      }
    }
    // Core
    for (zone of Array.from(this.items)) {
      console.log(zone);
      zoneStyle = {
        fillColor: zone.fillColor != null ? zone.fillColor : this.options.fillColor,
        radius: zone.radius != null ? zone.radius : this.options.radius,
        stroke: false,
        fillOpacity: 1
      };
      console.log(zoneStyle);
      var zoneLayer = new L.circleMarker(zone.point, zoneStyle);
      widget._bindPopup(zoneLayer, zone);
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given points computed layer
  buildLegend() {
    let html  = `<div class='leaflet-legend-item' id='legend-${this.layer.name}'>`;
    html += `<h3>${this.layer.label}</h3>`;
    html += "<div class='leaflet-legend-body leaflet-categories-scale'>";
    html += "<span class='leaflet-categories-items'>";
    for (var name in this.items) {
      var item = this.items[name];
      html += "<span class='leaflet-categories-item'>";
      html += `<i class='leaflet-categories-sample' style='background-color: ${item.fillColor};'></i>`;
      html += ` ${item.name}`;
      html += "</span>";
    }
    html += "</span>";
    html += "</div>";
    html += "</div>";
    return html;
  }

  // Returns the item matching the given name
  itemFor(name) {
    let back = null;
    this.items.forEach(function(item, index, array) {
      if (item.name === name) { return back = item; }
    });
    return back;
  }

  // Check if categories are valid
  valid() {
    return this.items.length > 0;
  }
};

visualization.registerLayerType("points", visualization.Points);
