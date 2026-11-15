/*
 * Provides clustering for GhostLabels

 * options:
 *   type {string} ('number' || 'hidden') if number, display count of collapsed items inside a group. If hide, collapsed items are hidden.
 *   className {string} Overrides container class name. By default, it inherits from layer
 *   innerClassName {string} Set a custom inner class name
 *   margin: {number (as px)} Wrap labels in a margin box, considering as the clustering limits. Default: 0
 *
 *
 * Thanks to LayerGroup.collision for inspiration https://github.com/MazeMap/Leaflet.LayerGroup.Collision
 * Thanks to RBush for awesome lib https://github.com/mourner/rbush
 *
  */

L.GhostLabelCluster = L.LayerGroup.extend({
  __initialize: L.LayerGroup.prototype.initialize,
  __addLayer: L.LayerGroup.prototype.addLayer,
  __removeLayer: L.LayerGroup.prototype.removeLayer,
  __clearLayers: L.LayerGroup.prototype.clearLayers,

  initialize(options) {
    L.setOptions(this, options);
    this._originalLayers =  [];
    this._clusterIndex = [];
    this._visibleLayers = {};
    this._cachedRelativeBoxes = [];
    this._margin = 0;
    this.__initialize.call(this, options);
    this._margin = options.margin || 0;
    this._rbush = new RBush();
  },

  addLayer(layer) {
    if (this._originalLayers.indexOf(layer) === -1) { this._originalLayers.push(layer); }
    if (this._map) {
      this.__addClusteredLayer(layer);
    }
  },

  bind(layer, parent) {
    this.addLayer(layer);

    if (this._originalLayers.indexOf(layer) !== -1) {
      // To be updated when feature name change
      parent.bindGhostLabel(layer);
      return parent.on('remove', this.removeLayer, this);
    }
  },


  removeLayer(e) {
    const layer = e.target.label;
    this._rbush.remove(this._cachedRelativeBoxes[layer._leaflet_id]);
    delete this._cachedRelativeBoxes[layer._leaflet_id];

    const i = this._originalLayers.indexOf(layer);
    if (i !== -1) {
      this._originalLayers.splice(i, 1);
    }

    delete this._visibleLayers[layer._leaflet_id];
    this.__removeLayer.call(this, layer);

  },

  clearLayers() {
    this._rbush.clear();
    ({_clusterIndex: []});
    this._originalLayers = [];
    this._visibleLayers = {};
    this._cachedRelativeBoxes = [];
    this.__clearLayers.call(this);
  },

  onAdd(map) {
    if (!this._map) {
      this._map = map;
    }
    this.refresh();
    return map.on('zoomend', this.refresh, this);
  },

  onRemove(map) {
    map.off('zoomend', this.refresh, this);
  },

  __addClusteredLayer(layer) {
    const className = (this.options.className != null) ? this.options.className : layer.options.className;
    const innerClass = (this.options.innerClassName != null) ? this.options.innerClassName : '';

    const bush = this._rbush;

    let box = this._cachedRelativeBoxes[layer._leaflet_id];
    let visible = false;
    if (!box) {
      // Add the layer to the map so it's instantiated on the DOM,
      //   in order to fetch its position and size.
      this.__addLayer.call(this, layer);
      visible = true;

      box = this._getContainerBox(layer._container);

      this._cachedRelativeBoxes[layer._leaflet_id] = box;
    }

    box = this._positionBox(this._map.latLngToLayerPoint(layer.getLatLng()), box);

    // Search collisions from absolute position
    const collidedItems = bush.search(box);

    // Add reference to layer to track collided layers. Take advantage of rbush properties
    box['id'] = layer._leaflet_id;

    if (collidedItems.length === 0) {
      if (!visible) {
        this.__addLayer.call(this, layer);
      }
      this._visibleLayers[layer._leaflet_id] = layer;
      bush.load([box]);
    } else {
      let collapsedLayer;
      this.__removeLayer.call(this, layer);
      // Layers which collided
      const latLngBounds = new L.LatLngBounds;
      latLngBounds.extend(layer.getLatLng());

      const idsToCollapse = [];
      for (var item of Array.from(collidedItems)) {
        var bounds;
        var otherLayer = this.getLayer(item.id);

        if (otherLayer) {
          bounds = otherLayer.getLatLng();
          this.__removeLayer.call(this, otherLayer);
          idsToCollapse.push(otherLayer._leaflet_id);
        } else {
          collapsedLayer = this._visibleLayers[this._clusterIndex[item.id]];
          if (collapsedLayer !== undefined) { bounds = collapsedLayer.getLatLng(); }
        }

        if (bounds !== undefined) { latLngBounds.extend(bounds); }
      }


      if (!collapsedLayer) { collapsedLayer = new L.GhostLabel({className}); }

      collapsedLayer.setLatLng(latLngBounds.getCenter());


      // add to this layer group
      this.__addLayer.call(this, collapsedLayer);

      this._visibleLayers[collapsedLayer._leaflet_id] = collapsedLayer;


      // clustering track
      this._clusterIndex[layer._leaflet_id] = collapsedLayer._leaflet_id;
      for (var id of Array.from(idsToCollapse)) {
        this._clusterIndex[id] = collapsedLayer._leaflet_id;
      }

      if (this.options.type === 'number') {
        const count = this._clusterIndex.filter(i => i === collapsedLayer._leaflet_id).length;
        collapsedLayer.setContent(`<span class='${innerClass}'>${count}</span>`);

        collapsedLayer.setLatLng(latLngBounds.getCenter());
      }
    }


  },

  _getContainerBox(el) {
    const styles = window.getComputedStyle(el);
    return [
      parseInt(styles.marginLeft),
      parseInt(styles.marginTop),
      parseInt(styles.marginLeft) + parseInt(styles.width),
      parseInt(styles.marginTop) + parseInt(styles.height)
    ];
  },

  _positionBox(offset, box) {
    return {
      minX: (box[0] + offset.x) - (this._margin),
      minY: (box[1] + offset.y) - (this._margin),
      maxX: box[2] + offset.x + this._margin,
      maxY: box[3] + offset.y + this._margin,
    };
  },

  refresh() {
    let layer;
    for (var id in this._visibleLayers) {
      layer = this._visibleLayers[id];
      this.__removeLayer.call(this, layer);
      delete this._visibleLayers[id];
    }

    this._rbush.clear();

    for (layer of Array.from(this._originalLayers)) {
      this.__addClusteredLayer(layer);
    }
  }
});


L.ghostLabelCluster  = options => new (L.GhostLabelCluster)(options || {});

