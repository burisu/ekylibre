/*
 * Extend L.Tooltip to provide a label on centroid, calculated from a L.Latlng[]
 * options:
 *   toBack {boolean} if true, label is set to objectsPane, allowing to be covered by higher level pane
 *   opacity: {string} ([0..1] | 'inherit') inherit allows to use opacity in your class. Default: 'inherit'
  */
L.GhostLabel = L.Tooltip.extend({
  __initialize: L.Tooltip.prototype.initialize,
  _onAdd: L.Tooltip.prototype.onAdd,
  __setOpacity: L.Tooltip.prototype.setOpacity,

  initialize(options, source) {
    if (!options.opacity) { options.opacity = 'inherit'; }
    if (!options.direction) { options.direction = 'center'; }
    if (!options.permanent) { options.permanent = 'true'; }

    return this.__initialize.apply(this, arguments);
  },

  /*
   * Set the latLng[] to calculate the centroid
    */
  toCentroidOfBounds(latLngs) {
    // To center of bounds if centroid can't be calculated during onAdd
    this._latlng = L.latLngBounds(latLngs).getCenter();
    this._latLngs = latLngs;
    return this;
  },

  onAdd(map) {
    // Don't hide labels on click
    this.options.noHide = true;

    if (this.options.toBack) {
      if (!map.getPane('objectsPane')) {
        map.createPane('objectsPane').style.zIndex = 300;
      }
      this.options.pane = 'objectsPane';
    }


    this._onAdd.apply(this, arguments);

    map.on('zoomend', this._onZoomEnd, this);

  },

  setOpacity(opacity) {
    if (opacity !== 'inherit') {
      return this.__setOpacity.call(this, opacity);
    }
  },

  getLatLng() {
    return this._latlng;
  },

  _onZoomEnd(e) {
    return this.getCenter(e.target);
  },

  getCenter(map){
    if (this._latLngs) {
      const poly = L.polygon(this._latLngs);
      poly._map = this._map || map;
      this._latlng = poly.__getCenter();
    }

    return this._latlng;
  },

  updateZIndex(zIndex){
    this._zIndex = zIndex;

    if (this._container && this._zIndex) {
      return this._container.style.zIndex = zIndex;
    }
  }
});

L.extendedMethods = {
  // Allow to be updated
  bindGhostLabel(object, options) {

    if (!this.label) {
      this.label = object;
      this._tooltip = object;
    }

  },
  
  updateLabelContent(content) {
    if (this.label) {
      return this.setTooltipContent(content);
    }
  }
};

L.Polygon.include(L.extendedMethods);
L.FeatureGroup.include(L.extendedMethods);

