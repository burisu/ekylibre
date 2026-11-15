visualization.PauseGroup = class PauseGroup {

  constructor(layer, data, options) {
    this.layer = layer;
    this.data = data;
    if (options == null) { options = {}; }
    this.options = options;
    this.items = [];
    for (var zone of Array.from(this.data)) {
      var lnglat = zone.shape.coordinates;
      this.items.push({
        name: zone.name,
        point: [lnglat[1], lnglat[0]],
        radius: zone.radius != null ? zone.radius : this.options.radius,
        group: zone.group,
        fillColor: zone.shapeColor,
        popup: zone.popup,
        sensorId: zone.sensorId
      });
    }
    if (this.valid()) {
      this.items = this.items.sort((a, b) => a.name > b.name);
      this.groups = {};
      for (var {group, name, fillColor} of Array.from(this.items)) {
        if (!this.groups[group]) { this.groups[group] = fillColor; }
      }
      console.log("Icon group computed");
    } else {
      console.warn("Invalid categories");
    }
  }

  // Build layer as wanted
  buildLayerGroup(widget, globalStyle) {
    if (globalStyle == null) { globalStyle = {}; }
    const group = [];
    // Shadow
    for (var zone of Array.from(this.items)) {
      console.log(zone);
      var zoneStyle = {
        icon: new L.Icon.Pause(),
        fillColor: zone.fillColor != null ? zone.fillColor : this.options.fillColor,
        radius: zone.radius != null ? zone.radius : this.options.radius,
        stroke: false,
        fillOpacity: 1
      };
      console.log(zoneStyle);
      var zoneLayer = new L.marker(zone.point, zoneStyle);
      zoneLayer.sensorId = zone.sensorId;
      widget._bindPopup(zoneLayer, zone);
      group.push(zoneLayer);
    }
    return group;
  }

  // Build HTML legend for given points computed layer
  buildLegend() {
    let html  = "<div class='leaflet-legend-item' >";
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

visualization.registerLayerType("pause_group", visualization.PauseGroup);
