// The scheduler allows to render a layerGroup at a specified level (compared to others).
// It "schedules" the layerGroup i.e. it replays layerGroup's rendering to the right time.
L.LayersScheduler = L.Class.extend({

  // flow is an array of layerGroup ids
  initialize(flow, options) {
    if (flow == null) { flow = []; }
    if (options == null) { options = {}; }
    L.Util.setOptions(this, options);
    return this.flow = flow;
  },


  addTo(map) {
    return this._map = map;
  },

  insert(id, options) {
    if (options == null) { options = {}; }
    if (options.back) { this.flow.unshift(id); } else { this.flow.push(id); }
    return this.flow;
  },

  // Note: if layer not found in the flow, we consider to let it in top.
  schedule(layerGroup) {

    if (layerGroup == null) { layerGroup = undefined; }
    if (layerGroup && layerGroup._leaflet_id) {
      const index = this.flow.indexOf(layerGroup._leaflet_id);

      // unless layerGroup to schedule is already the last element
      if ((index !== -1) && (index !== (this.flow.length - 1))) {
        // we need to find the next element to place it before
        const nextSibling = this._map._layers[this.flow[index + 1]];

        // to do that, we need to iterate until finding geometry layer and its first svg path
        if (nextSibling && nextSibling.getLayers().length) {
          // as a ILayer (including feature layer)
          let objectLayer = nextSibling;

          while (true) {
            if ((!objectLayer || !Object.keys(objectLayer._layers || []).length) && !!objectLayer._latlngs) { break; }
            objectLayer = objectLayer.getLayers()[0];
          }

          if (objectLayer._container) { return layerGroup.bringBefore(objectLayer._container); }
        }
      }
    }

    else {}
  }
});
      //redraw all ?

// factory
L.layersScheduler = function(flow, options) {
  if (flow == null) { flow = []; }
  if (options == null) { options = {}; }
  return new L.LayersScheduler(flow, options);
};


L.LayerGroup.include({
  bringBefore(node) {
    return this.invoke('bringBefore', node);
  }
});

L.Path.include({
  bringBefore(node) {
    const root = this._map._pathRoot;
    const path = this._container;
    return root.insertBefore(path, node);
  }
});

