//= require_self
//= require mapeditor/simple
//= require mapeditor/categories

(function(M, $) {
  "use strict";
  /*
  *# Series managment:
  Series allows to display multiple layers of data on a single map, which can be hidden with the selector.
  I/ Serie handlers:
    Specify series to work with in a hash:
      key: the uniq identifier of the serie
      value: the data of a serie, as a geojson
  II/ Layers handlers:
    Specify layers to display data, in an array of hashes:
      name: identifier of the layer
      label: Visible name in the legend and the selector
      serie: the serie identifier as in the handlers
      type: 'simple' or 'categories', see below
      legend: boolean (true), displays the layer name and color in the legend.
      popup: An array of hashes, which define the way popup is shown:
        type: 'label' or 'input'. A label is a static text whereas an input provide a form to edit properties.
        property_label: text displayed before value
        property_value: the name of the feature property to show/edit
      Handler support layer-scoped styling, as supported by Leaflet (stroke, color, etc.)
  III/ Layer types:
     'simple': Display a single layer, identified by a name and a color.
     'categories': Display a layer where geometries have their own set of properties, as color or opacity.
        reference: The key allows to group geometries to a property, to display distinct categories.
  Example: show: {series: {land_parcels_serie: land_parcels, plants_serie: plants},layers: [{name: :land_parcels, label: :land_parcels.tl, serie: :land_parcels_serie, type: :simple }, {name: :plants, label: :plant.tl, serie: :plants_serie, reference: 'variety', stroke: 2, fillOpacity: 0.7, type: :categories, popup: [{type: :label, property_label: 'My name', property_value: :name}]}]}

  *# Others options:
  withoutLabel: boolean (false), bind label to edition layer
  */
  M.layer = function(layer, data, options) {
    let type;
    if (this.layerTypes == null) { this.layerTypes = {}; }
    if (type = this.layerTypes[layer.type]) {
      return new type(layer, data, options);
    } else {
      console.warn(`Invalid layer type: ${layer.type}`);
      return null;
    }
  };

  M.registerLayerType = function(name, klass) {
    if (this.layerTypes == null) { this.layerTypes = {}; }
    return this.layerTypes[name] = klass;
  };

  // allow to inject jquery objects and interpolate
  L.Map.Modal.prototype.reloadContent = function(content) {
    $(this._getInnerContentContainer()).find('.modal-body').empty();
    $(this._getInnerContentContainer()).find('.modal-body').append($(content));
    return this.update();
  };

  $.widget("ui.mapeditor", {
    options: {
      box: {
        height: 400,
        width: null
      },
      minZoom: 0,
      maxZoom: 25,
      customClass: '',
      back: [],
      overlays: [],
      show: {
        layers: {},
        layerDefaults: {
          simple: {
            color: "#333",
            fillColor: "#333",
            weight: 2,
            opacity: 0.8,
            fillOpacity: 0.4,
            legend: true
          },
          optional: {
            color: "#333",
            fillColor: "#CBCFFB",
            weight: 1,
            opacity: 1,
            fillOpacity: 0.5,
            legend: true,
            zoomGuidance: I18n.t("front-end.leaflet.zoomGuidance")
          },
          categories: {
            color: "#333",
            fillColor: "#333",
            weight: 2,
            opacity: 0.8,
            fillOpacity: 0.4,
            legend: true
          }
        }
      },
      edit: null,
      change: null,
      view: 'auto',
      useFeatures: false,
      withoutLabel: false,
      showStyle: {
        color: "#333",
        fillOpacity: 0.4,
        weight: 2,
        opacity: 0.8
      },
      ghostStyle: {
        weight: 4,
        color: "#FFF",
        fillOpacity: 0
      },
      defaultLabel: 'Unnamed',
      defaultLevelLabel: 'Level',
      allowAttributesPopup: false,
      editStyle: {
        weight: 2,
        color: "#33A",
        fillOpacity: 0.7
      },
      controls: {
        draw: {
          edit: {
            featureGroup: null,
            edit: {
              color: "#A40",
              popup: false
            }
          },
          draw: {
            marker: false,
            polyline: false,
            rectangle: false,
            circle: false,
            circlemarker: false,
            polygon: {
              allowIntersection: false,
              allowOverlap: true,
              showArea: false
            },
            reactiveMeasure: true
          }
        },
        zoom: {
          position: "topleft",
          zoomInText: "",
          zoomOutText: "",
          zoomInTitle: I18n.t("front-end.leaflet.zoomInTitle"),
          zoomOutTitle: I18n.t("front-end.leaflet.zoomOutTitle")
        },
        scale: {
          position: "bottomleft",
          imperial: false,
          maxWidth: 200
        },
        fullscreen: {
          position: 'topleft',
          title: I18n.t("front-end.leaflet.fullscreenTitle")
        },
        reactiveMeasure: {
          position: "bottomleft",
          metric: true,
          feet: false,
          tooltip: true
        },
        importers: {
          gml: true,
          geojson: true,
          kml: true,
          title: '',
          content: '',
          buttonTitle: I18n.t("front-end.leaflet.importerButtonTitle"),
          template: `<div class="modal-header"><i class="leaflet-importer-ctrl"></i><span>{title}</span></div> \
<div class="modal-body">{content}</div> \
<div class="modal-footer"> \
<button type="submit" class="{OK_CLS}" data-editor-submit=true>{okText}</button> \
<button class="{CANCEL_CLS}" data-editor-cancel=true>{cancelText}</button> \
</div>`,
          okText: 'Ok',
          cancelText: 'Cancel',
          OK_CLS: 'btn',
          CANCEL_CLS: 'btn'
        }
      }
    },

    colors: ["#00de00", "#6f006f", "#4ade94", "#004ab9", "#de6f4a", "#b9b925", "#00b994", "#25946f", "#de00b9", "#94006f", "#de6f94", "#252594", "#dede94", "#4a2594", "#940000", "#deb9de", "#00b9b9", "#00de94", "#25254a", "#6fde6f", "#4a0094", "#256f4a", "#6f4a25", "#4a4a00", "#b9006f", "#4a6f25", "#6f946f", "#009425", "#6f4ade", "#2525de", "#b9946f", "#b9b994", "#b9de94", "#de256f", "#b900b9", "#4a4a6f", "#4a2525", "#006fde", "#940025", "#250094", "#b900de", "#4ab9b9", "#00004a", "#6f6fde", "#256fde", "#b92594", "#6f944a", "#6f6f25", "#4ab9de", "#de2525", "#2525b9", "#944a94", "#b94a94", "#946f94", "#b94a6f", "#000094", "#4a6f6f", "#006f00", "#946f4a", "#00256f", "#6f4a6f", "#de6fb9", "#6fdeb9", "#de6f00", "#94b94a", "#94b994", "#6f6fb9", "#b925de", "#de2594", "#dede25", "#6f4a94", "#946f6f", "#de25de", "#b92525", "#6fde94", "#254a25", "#4adeb9", "#00deb9", "#b9b9b9", "#6f4a4a", "#256f25", "#25deb9", "#6f25de", "#94b925", "#b9254a", "#4ade25", "#4a006f", "#25006f", "#94de00", "#6fb925", "#259425", "#6f9425", "#944a00", "#25b9b9", "#25de4a", "#00254a", "#94254a", "#4a6f94", "#002500", "#6fdede", "#deb925", "#b9b9de", "#4a4a94", "#004a4a", "#25b994", "#6f6f00", "#b92500", "#b925b9", "#940094", "#2594de", "#4ade4a", "#949400", "#256f6f", "#de00de", "#6fde25", "#4a6fde", "#4a4ab9", "#deb96f", "#6f0025", "#00b925", "#0000b9", "#254a94", "#4a25b9", "#b9004a", "#b9de00", "#6f254a", "#6f2500", "#94b96f", "#25de00", "#b99425", "#b90025", "#0094b9", "#4ab925", "#4ab96f", "#6fde00", "#b9b96f", "#94b9b9", "#de4a6f", "#4a2500", "#de0000", "#4a4a4a", "#259494", "#9400b9", "#b9deb9", "#254a00", "#0000de", "#dede4a", "#94dede", "#94de25", "#4a9494", "#4a94de", "#6fb9b9", "#dede00", "#b9256f", "#de9494", "#009494", "#006f4a", "#94944a", "#4ab900", "#6f6f4a", "#b99494", "#6f004a", "#4a256f", "#00b9de", "#b99400", "#00b96f", "#deb9b9", "#4a6f00", "#000025", "#00006f", "#00de4a", "#b96f94", "#6fb9de", "#946fde", "#deb900", "#004ade", "#254ab9", "#25de6f", "#94deb9", "#b994de", "#004a25", "#94256f", "#250025", "#6f6f6f", "#4a944a", "#4a25de", "#00b94a", "#4a4a25", "#9400de", "#94004a", "#4a94b9", "#94de94", "#6f256f", "#6fb900", "#b9944a", "#de94de", "#944a25", "#6f2594"],


    _create() {
      this.oldElementType = this.element.attr("type");
      this.element.attr("type", "hidden");

      $.extend(true, this.options, this.element.data("map-editor"));

      this.mapElement = $("<div>", {class: `map ${this.options.customClass}`})
        .insertAfter(this.element);
      this.map = L.map(this.mapElement[0], {
        zoomControl: false,
        attributionControl: true,
        drawControlTooltips: false
      }
      );

      this.controls = {};
      this.seriesReferencesLayers = {};

      this.elementSeries = $('<input>').insertAfter(this.mapElement);
      this.elementSeries.attr("type", "hidden");

      const widget = this;

      this.counter = 1;

      this.ghostLabelCluster = L.ghostLabelCluster({type: 'number', innerClassName: 'leaflet-ghost-label-collapsed'});
      this.ghostLabelCluster.addTo(this.map);

      this.ghostLayerLabelCluster = L.ghostLabelCluster({type: 'hidden'});
      this.ghostLayerLabelCluster.addTo(this.map);

      this.layersScheduler = L.layersScheduler();
      this.layersScheduler.addTo(this.map);

      this.map.on("draw:created", e => {
        //Attempt to add a geojson feature
        try {
          const feature = e.layer.toGeoJSON();

          widget.edition.addData(feature);
        } catch (error) {
          widget.edition.addLayer(e.layer);
        }


        this._refreshControls();
        return widget.update();
      });

      this.map.on("draw:edited", e => widget.update());


      this.map.on("draw:deleted", function(e) {
        const {
          layers
        } = e;
        layers.eachLayer(layer => {
          return widget.element.trigger('mapeditor:feature_delete', layer.feature);
        });

        return widget.update();
      });

      this._resize();
      // console.log "resized"
      this._refreshBackgroundLayer();
      this._refreshGhostLayerGroup();
      // console.log "backgrounded"
      this._refreshReferenceLayerGroup();
      // console.log "shown"
      this._refreshEditionLayerGroup();

      // console.log "edited"
      this._refreshView();
      // console.log "viewed"
      this._refreshControls();
      // console.log "controlled"

      this.updateAttributesSeries = e => {
        if ((e.which !== 1) && (e.which !== 13)) { return; }
        e.preventDefault();
        const featureId = $(e.currentTarget).closest('.leaflet-popup-content').find('*[data-internal-id]').data('internal-id');
        const $newFields = $(e.currentTarget).closest('.popup-content').find('.updateAttributesSerieLabelInput');

        const layer = this.findLayer(featureId);

        for (var field of Array.from($newFields)) {
          this.updateFeatureProperties(featureId, $(field).attr('name'), $(field).val());
        }

        if (layer.feature && layer.feature.geometry && (layer.feature.geometry.type === 'MultiPolygon')) {
          layer.eachLayer(layer => layer.closePopup());
        } else {
          layer.closePopup();
        }

        return this.popupizeSerie(layer.feature, layer);
      };




      this.updateAttributes = e => {
        if ((e.which !== 1) && (e.which !== 13)) { return; }
        e.preventDefault();
        const featureId = $(e.currentTarget).closest('.leaflet-popup-content').find('*[data-internal-id]').data('internal-id');
        const newName = $(e.currentTarget).closest('.popup-content').find('input[type="text"]').val();

        if (this.options.multiLevels != null) {
          const level = $(e.currentTarget).closest('.popup-content').find('select').val();
          this.updateFeatureProperties(featureId, 'level', level);
        }

        const layer = this.findLayer(featureId);

        let already_exist = this.findLayerByName(newName);

        if (already_exist !== undefined) {
          if (already_exist.feature.properties.internal_id !== layer.feature.properties.internal_id) {
            already_exist = true;
          }
        }


        if (already_exist === true) {
          // Don't change the name if a different layer use this name
          $(e.currentTarget).closest('.leaflet-popup-content').find('.leaflet-popup-warning').removeClass('hide');


        } else {

          this.updateFeatureProperties(featureId, 'name', newName);


          //update label
          layer.updateLabelContent(layer.feature.properties.name);

          layer.setStyle(this.setFeatureStyle(layer.feature));

          layer.closePopup();

          //update popup
          this.popupize(layer.feature, layer);

          $(this.element).trigger('mapeditor:feature_update', layer.feature);
        }

        return false;
      };

      $(this.mapElement).on('keypress', '.updateAttributesLabelInput', this.updateAttributes);
      $(this.mapElement).on('click', '.updateAttributesInPopup', this.updateAttributes);

      $(this.mapElement).on('click', '.updateAttributesSerieInPopup', this.updateAttributesSeries);

//      @map.on "viewreset", (e) =>
//        console.log "NEW BOUNDING BOX", e.target.getBounds().toBBoxString()
//        @setDynamicSeries()

      this._buildLegendContainer();
      this._bindOverlays();

      this.setDynamicSeries();
      if (!this.options.dynamic_series) { this.optionalDataLoading(); }

      return widget.element.trigger("mapeditor:loaded");
    },

    setDynamicSeries() {
      if (this.options.dynamic_series == null) { return; }

      $.ajax({
        method: 'GET',
        dataType: 'json',
        url: this.options.dynamic_series,
        beforeSend: () => {
          this.dynamic_loading = new L.control({position: "bottomleft"});
          this.dynamic_loading.onAdd = map => {
            return L.DomUtil.create('div', 'leaflet-dynamic loading');
          };

          return this.map.addControl(this.dynamic_loading);
        },
        success: data => {
          $.extend(true, this.options.show, data.show);
          this._refreshReferenceLayerGroup();
          this._refreshControls();
          return this.optionalDataLoading();
        },
        complete: () => {
          return this.map.removeControl(this.dynamic_loading);
        }
      });

      //Ensure edition layer is on top
      if (this.edition) { return this.edition.bringToFront(); }
    },

    optionalDataLoading() {
      let url;
      if (!(url = this.options.optional_data_url)) { return; }

      const _refreshOptionalData = () => {
        const optionalLayerDisplayed = this._optionalLayersDisplayed()[0];
        const boundsBuffer = optionalLayerDisplayed.bounds_buffer ? this._computeBoundsBuffer() : 0;

        if (this.zoom() >= 16) {
          const urlWithoutParams = url.replace(/\?.+/, '');
          return $.getJSON(urlWithoutParams, {bounds: this.bounds(boundsBuffer), layers: [optionalLayerDisplayed.name]}, data => {
            for (var layer of Array.from(data.show.layers)) {
              this.options.show.series[layer.serie] = data.show.series[layer.serie];
              var serieData = this._getSerieData(layer.serie);
              var options = $.extend(true, {}, this.options.show.layerDefaults[layer.type], layer, {parent: this});
              var renderedLayer = M.layer(layer, serieData, options);
              if (!renderedLayer || !renderedLayer.valid()) { return; }

              $(this.controls.legend.getContainer()).find('.zoom-guidance').hide();
              var displayedOverlay = _.find(this.options.show.layers, ['name', layer.name]).overlay;
              var layerGroup = renderedLayer.buildLayerGroup(this, options);
              displayedOverlay.clearLayers();

              for (var _k in layerGroup._layers) {
                var layr = layerGroup._layers[_k];
                displayedOverlay.addLayer(layr);
              }
            }
          });

        } else {
          return (() => {
            const result = [];
            for (var layer of Array.from(_.filter(this.options.show.layers, ['type', 'optional']))) {
              $(this.controls.legend.getContainer()).find('.zoom-guidance').show();
              result.push(layer.overlay.clearLayers());
            }
            return result;
          })();
        }
      };


      return $.getJSON(url, data => {
        $.extend(true, this.options.show.series, data.show.series);

        for (var layer of Array.from(data.show.layers)) {
          this.options.show.layers.push(layer);
          this._addLayer(layer);
          this.layerSelector.addOverlay(this.seriesReferencesLayers[layer.label], layer.label);
        }

        this.map.on('overlayadd', event => {
          if (this._optionalLayer(event.name)) {
            if (this._optionalLayersDisplayed().length === 1) { this.map.on('moveend', _refreshOptionalData); }
            this._optionalSiblings(event.name).forEach(layer => { if (this.map.hasLayer(layer.overlay)) { return delay(1, () => this.map.removeLayer(layer.overlay)); } });
            return delay(1, () => _refreshOptionalData());
          }
        });

        this.map.on('overlayremove', event => {
          if (!this._optionalLayersDisplayed().length) { return this.map.off('moveend', _refreshOptionalData); }
        });

        return this.element.trigger('mapeditor:optional_data_loaded');
      });
    },

    updateFeature(feature_id, attributeName, attributeValue) {
      this.updateFeatureProperties(feature_id, attributeName, attributeValue);
      const layer = this.findLayer(feature_id);

      //update label
      layer.updateLabelContent(layer.feature.properties.name);

      //update style
      layer.setStyle(this.setFeatureStyle(layer.feature));

      //update popup
      return this.popupize(layer.feature, layer);
    },


    updateFeatureProperties(feature_id, attributeName, attributeValue) {
      const layer = this.findLayer(feature_id);

      if (layer) {
        return layer.feature.properties[attributeName] = attributeValue;
      }
    },

    setFeatureStyle(feature) {
      let levelStyle = {};

      if (this.options.multiLevels != null) {
        levelStyle = {fillColor: this.colorize(feature.properties.level)};
      }

      return $.extend(true, {}, this.options.editStyle, levelStyle);
    },

    findLayer(feature_id) {
      let containerLayer = undefined;
      this.map.eachLayer(layer => {
        if (layer.feature && (parseInt(layer.feature.properties.internal_id) === feature_id)) {
          containerLayer = layer;
          return;
        }
      });
      return containerLayer;
    },

    findLayerByName(feature_name) {
      let containerLayer = undefined;
      this.edition.eachLayer(layer => {
        if (layer.feature.properties.name === feature_name) {
          containerLayer = layer;
          return;
        }
      });

      return containerLayer;
    },

    navigateToLayer(layer) {
      return this.map.panInsideBounds(layer.getBounds(), {animate: true});
    },

    removeLayer(layer) {
      return this.edition.removeLayer(layer);
    },

    displayOptionalOverlay(layerName) {
      let layer;
      if (!(layer = this._optionalLayer(layerName))) { return; }
      if (!this.map.hasLayer(layer)) { return this.map.addLayer(layer.overlay); }
    },

    hideOptionalOverlays() {
      return Array.from(this._optionalLayersDisplayed()).map((layer) => this.map.removeLayer(layer.overlay));
    },

    popupize(feature, layer) {
      let popup = "";
      popup += "<div class='popup-header'>";
      const id = (feature.properties.id != null) ? `${feature.properties.id}: ` : '';
      popup += `<span class='popup-block-content' data-internal-id='${feature.properties.internal_id}'>${id}${feature.properties.name || this.options.defaultLabel}</span>`;
      popup += "<span class='leaflet-popup-warning right hide'></span>";
      popup += "</div>";
      popup += "<div class='popup-content'>";
      popup += `<input type='text' class='updateAttributesLabelInput' value='${feature.properties.name || this.options.defaultLabel}'/>`;

      if (this.options.multiLevels != null) {
        popup += "<select>";

        for (let start = parseInt(this.options.multiLevels.maxLevel), level = start, end = parseInt(this.options.multiLevels.minLevel), asc = start <= end; asc ? level <= end : level >= end; asc ? level++ : level--) {
          var selected = "";

          if (level === parseInt(feature.properties.level)) {
            selected = "selected";
          }

          //TODO i18n this
          var label = level === 0 ? 'RDC' : `${this.options.multiLevels.levelLabel} ${level}`;

          popup += `<option value='${level}' ${selected}>${label}</option>`;
        }

        popup += "</select>";
      }

      popup += "<input class='updateAttributesInPopup' type='button' value='ok'/>";
      popup += "</div>";

      return layer.bindPopup(popup, {keepInView: true, maxWidth: 600, className: 'leaflet-popup-pane'});
    },

    popupizeSerie(feature, layer) {
      let popup = "";
      popup += "<div class='popup-header'>";
      popup += `<span class='popup-block-content' data-internal-id='${feature.properties.internal_id}'>${feature.properties.name || ''}</span>`;
      popup += "<span class='leaflet-popup-warning right hide'></span>";
      popup += "</div>";
      popup += "<div class='popup-content'>";
      for (var attribute of Array.from(feature.properties['popupAttributes'])) {
        popup += "<div>";
        popup += `<label for='${attribute.property_value}'>${attribute.property_label} : </label>`;
        switch (attribute.type) {
          case 'input':
            popup += `<input type='text' name='${attribute.property_value}' class='updateAttributesSerieLabelInput' value='${feature.properties[attribute.property_value] || ""}'/>`;
            break;
          default:
            // include label
            popup += `<span>${feature.properties[attribute.property_value] || ''}</span>`;
        }
        popup += "</div>";
      }

      popup += "<input class='updateAttributesSerieInPopup' type='button' value='ok'/>";
      popup += "</div>";

      if (layer.feature && layer.feature.geometry && (layer.feature.geometry.type === 'MultiPolygon')) {
        return layer.eachLayer(layer => layer.bindPopup(popup, {keepInView: true, maxWidth: 600, className: 'leaflet-popup-pane'}));
      } else {
        return layer.bindPopup(popup, {keepInView: true, maxWidth: 600, className: 'leaflet-popup-pane'});
      }
    },

    colorize(level) {
      //levels rane is set to [-3,3]
      const minLevel = -3;
      const start = this.colors.indexOf(this.options.multiLevels.startColor);
      const stop = this.colors.indexOf(this.options.multiLevels.stopColor);
      const colorsRange = this.colors.slice(start, stop);
      return colorsRange[Math.abs(minLevel - parseInt(level))];
    },

    _destroy() {
      this.element.attr(this.oldElementType);
      return this.mapElement.remove();
    },

    back(back) {
      if (back == null) { return this.options.back; }
      this.options.back = back;
      return this._refreshBackgroundLayer();
    },

    show(geojson) {
      if (geojson == null) { return this.options.show; }
      this.options.show = geojson;
      return this._refreshReferenceLayerGroup();
    },

    edit(geojson, zoom) {
      if (zoom == null) { zoom = false; }
      if (geojson == null) { return this.options.edit; }
      this.options.edit = geojson;
      this._saveUpdates();
      this._refreshEditionLayerGroup();
      if (zoom) {
        return this._refreshView('edit');
      }
    },

    view(view) {
      if (view == null) { return this.options.view; }
      this.options.view = view;
      return this._refreshView();
    },

    zoom(zoom) {
      if (zoom == null) { return this.map.getZoom(); }
      this.options.view.zoom = zoom;
      return this._refreshZoom();
    },

    height(height) {
      if (height == null) { return this.options.box.height(); }
      this.options.view.box.height = height;
      return this._resize();
    },

    bounds(buffer) {
      if (buffer == null) { buffer = 0; }
      return this.map.getBounds().pad(buffer).toBBoxString();
    },

    _computeBoundsBuffer() {
      const zoomBuffers = { 16: 0.15, 17: 0.3, 18: 0.6, 19: 1.2 };
      return zoomBuffers[this.zoom()];
    },

    _resize() {
      if (this.options.box != null) {
        if (this.options.box.height != null) {
          this.mapElement.height(this.options.box.height);
        }
        if (this.options.box.width != null) {
          this.mapElement.width(this.options.box.width);
        }
        return this._trigger("resize");
      }
    },

    _refreshBackgroundLayer() {
      if (this.backgroundLayer != null) {
        this.map.removeLayer(this.backgroundLayer);
      }
      if (this.options.back != null) {
        let back;
        if (this.options.back.constructor.name === "Array") {

          let backgroundLayer, baseLayers, index, layer, opts;
          if (this.options.back.length > 0) {
            baseLayers = {};
            for (index = 0; index < this.options.back.length; index++) {
              layer = this.options.back[index];
              opts = {};
              if (layer.attribution != null) { opts['attribution'] = layer.attribution; }
              opts['minZoom'] = layer.minZoom || this.options.minZoom;
              opts['maxZoom'] = layer.maxZoom || this.options.maxZoom;
              if (layer.subdomains != null) { opts['subdomains'] = layer.subdomains; }
              if (layer.tms) { opts['tms'] = true; }

              backgroundLayer = L.tileLayer(layer.url, opts);
              baseLayers[layer.name] = backgroundLayer;
              if (layer.byDefault) { this.map.addLayer(backgroundLayer); }
            }

          } else {
            // no backgrounds, set defaults
            back = ['OpenStreetMap.HOT',"OpenStreetMap.Mapnik", "Thunderforest.Landscape", "Esri.WorldImagery"];

            baseLayers = {};
            for (index = 0; index < back.length; index++) {
              layer = back[index];
              backgroundLayer = L.tileLayer.provider(layer);
              baseLayers[layer] = backgroundLayer;
              if (index === 0) { this.map.addLayer(backgroundLayer); }
            }
            this.map.fitWorld( { maxZoom: this.options.maxZoom } );
          }

          const overlayLayers = {};

          if (this.options.overlays.length > 0) {
            for (index = 0; index < this.options.overlays.length; index++) {
              layer = this.options.overlays[index];
              opts = {};
              if (layer.attribution != null) { opts['attribution'] = layer.attribution; }
              opts['minZoom'] = layer.minZoom || this.options.minZoom;
              opts['maxZoom'] = layer.maxZoom || this.options.maxZoom;
              if (layer.subdomains != null) { opts['subdomains'] = layer.subdomains; }
              if ((layer.opacity != null) && !isNaN(layer.opacity)) { opts['opacity'] = (layer.opacity / 100).toFixed(1); }
              if (layer.tms) { opts['tms'] = true; }
              console.log(opts);

              overlayLayers[layer.name] =  L.tileLayer(layer.url, opts);
            }
          }


          this.layerSelector = new L.Control.Layers(baseLayers, overlayLayers);
          this.map.addControl(this.layerSelector);
        } else {
          console.log(`How to set background with ${this.options.back}?`);
          console.log(this.options.back);
        }
      }
      return this;
    },

    _optionalLayersDisplayed() {
      return _.filter(this.options.show.layers, layer => (layer.type === 'optional') && this.map.hasLayer(layer.overlay));
    },

    _optionalSiblings(layerName) {
      return _.reject(this.options.show.layers, layer => (layer.type !== 'optional') || (layer.label === layerName));
    },

    _optionalLayer(layerName) {
      return _.find(this.options.show.layers, layer => (layer.type === 'optional') && ((layer.label === layerName) || (layer.name === layerName)));
    },

    // Retuns data from a serie found with the given name
    _getSerieData(name) {
      if (this.options.show.series[name] != null) {
        return this.options.show.series[name];
      } else {
        return console.error(`Cannot find serie ${name}`);
      }
    },

    _refreshReferenceLayerGroup() {
      if (this.reference != null) {
        this.map.removeLayer(this.reference);
      }
      if ((this.options.show != null) && (this.options.show.layers.length > 0)) {
        if (this.options.useFeatures) {

          if (this.options.show.series != null) {

            for (var layer of Array.from(_.reject(this.options.show.layers, ['type', 'optional']))) { this._addLayer(layer); }

          } else {
            this.reference = L.geoJson(this.options.show, {
              onEachFeature: (feature, layer) => {
                if (!feature.properties) { feature.properties = {}; }
                //required for cap_land_parcel_clusters as names are set later
                if ((feature.properties.name == null)) {
                  return feature.properties.name = (feature.properties.id != null) ? `${this.options.defaultEditionFeaturePrefix}${feature.properties.id}` : this.defaultLabel;
                }
              }
            });
          }
        } else {
          this.reference = L.GeoJSON.geometryToLayer(this.options.show);
        }

        if (this.reference != null) {
          this.reference.setStyle(this.options.showStyle);
          this.reference.addTo(this.map);
        }
      }
      return this;
    },

    _buildLegendContainer() {
      this.controls.legend = new L.control({position: "bottomright"});

      this.controls.legend.onAdd = map => {
        return L.DomUtil.create('div', 'leaflet-legend-control');
      };

      this.map.addControl(this.controls.legend);

      if (this.options.multiLevels == null) {
        return L.DomUtil.addClass(this.controls.legend.getContainer(), 'leaflet-hidden-control');
      }
    },

    _bindOverlays() {
      this.map.on("overlayadd", event => {
        this.layersScheduler.schedule(event.layer);
        console.log("Add legend control...");
        const legend = $(this.controls.legend.getContainer());
        legend.children(`#legend-${event.layer.name}`).show();
        legend.children(".first").removeClass("first");
        legend.children(":visible:first").addClass("first");
        legend.removeClass("empty");

        if (this.options.overlaySelector != null) {
          event.layer.eachLayer(layer => {
            if (layer.label !== undefined) { return this.ghostLabelCluster.bind(layer.label, layer); }
          });
          return this.ghostLabelCluster.refresh();
        }
      });

      return this.map.on("overlayremove", event => {
        console.log("Remove legend control...");
        const legend = $(this.controls.legend.getContainer());
        legend.children(`#legend-${event.layer.name}`).hide();
        legend.children(".first").removeClass("first");
        legend.children(":visible:first").addClass("first");
        if (legend.children(":visible").length <= 0) { legend.addClass("empty"); }

        if (this.options.overlaySelector != null) {
          event.layer.eachLayer(layer => {
            if (layer.label !== undefined) { return this.ghostLabelCluster.removeLayer({target: { label: layer.label }}); }
          });
          return this.ghostLabelCluster.refresh();
        }
      });
    },

    _addLayer(layer) {
      const data = this._getSerieData(layer.serie);
      const options = $.extend(true, {}, this.options.show.layerDefaults[layer.type], layer, {parent: this});
      const renderedLayer = M.layer(layer, data, options);
      if (renderedLayer && renderedLayer.valid()) {
        // Build layer group
        const layerGroup = renderedLayer.buildLayerGroup(this, options);
        layerGroup.name = layer.name;
        layerGroup.renderedLayer = renderedLayer;

        this.controls.legend.getContainer().innerHTML += renderedLayer.buildLegend();
        L.DomUtil.removeClass(this.controls.legend.getContainer(), 'leaflet-hidden-control');

        if ((this.seriesReferencesLayers[layer.label] != null) && (layer.type !== 'optional')) {
          this.map.removeLayer(this.seriesReferencesLayers[layer.label]);
        }

        layer.overlay = (this.seriesReferencesLayers[layer.label] = layerGroup);
        if (layer.type !== 'optional') { return this.map.addLayer(layerGroup); }
      }
    },

    _refreshGhostLayerGroup() {
      if (this.ghost != null) {
        this.map.removeLayer(this.ghost);
      }
      if (this.options.ghost != null) {
        if (this.options.useFeatures) {
          this.ghost = L.geoJson(this.options.ghost, {
            onEachFeature: (feature, layer) => {

              const label = new L.GhostLabel({className: 'leaflet-ghost-label', toBack: true}).setContent(feature.properties.name || feature.properties.id).toCentroidOfBounds(layer.getLatLngs());
              return this.ghostLayerLabelCluster.bind(label, layer);
            }

          });
        } else {
          this.ghost = L.GeoJSON.geometryToLayer(this.options.ghost);
        }

        this.ghost.setStyle(this.options.ghostStyle);
        this.ghost.addTo(this.map);
      }
      return this;
    },

    onEachFeature(feature, layer) {
      if (feature.properties != null) {
        if ((feature.properties.internal_id == null)) {
          feature.properties['internal_id'] = new Date().getTime();
          feature.properties['removable'] = true;
        }

        if ((feature.properties.name == null)) {
          feature.properties.name = (feature.properties.id != null) ? `${this.counter}-  ${this.options.defaultEditionFeaturePrefix}${feature.properties.id}` : `${this.counter}-  ${this.options.defaultLabel}`;
        }

        this.counter += 1;
        if ((this.options.multiLevels != null) && (feature.properties.level == null)) { feature.properties['level'] = 0; }

        if (!this.options.withoutLabel) {
          const label = new L.GhostLabel({className: 'leaflet-ghost-label'}).setContent(feature.properties.name || feature.properties.id).toCentroidOfBounds(layer.getLatLngs());
          this.ghostLabelCluster.bind(label, layer);
        }
      }


      $(this.element).trigger('mapeditor:feature_add', feature);

      if ((feature.properties != null) && !!this.options.allowAttributesPopup) {
        return this.popupize(feature, layer);
      }
    },

    featureStyling(feature) {
      let levelStyle = {};

      if (this.options.multiLevels != null) {
        levelStyle = {fillColor: this.colorize(feature.properties.level)};
      }

      return $.extend(true, {}, this.options.editStyle, levelStyle);
    },

    _refreshEditionLayerGroup() {
      if (this.edition != null) {
        //remove overlay
        this.layerSelector.removeLayer(this.edition);
        this.map.removeLayer(this.edition);
      }
      if (this.options.edit != null) {
        if (this.options.useFeatures) {

          const polys = [];
          this.edition = L.geoJson(this.options.edit, {
            onEachFeature: (feature, layer) => {
              //nested function cause geojson doesn't seem to pass binding context
              return this.onEachFeature(feature, layer);
            },

            style: feature => {
              return this.featureStyling(feature);
            },
            filter: feature => {
              if (feature.type === 'MultiPolygon') {
                for (var coordinates of Array.from(feature.coordinates)) {
                  polys.push({type: 'Polygon', coordinates});
                }
              }
              return !(feature.type === 'MultiPolygon');
            }
          });
          this.edition.addData(polys);
        } else {
          this.edition = L.GeoJSON.geometryToLayer(this.options.edit);
        }
      } else {
        this.edition = L.geoJson(this.options.edit, {
          onEachFeature: (feature, layer) => {
            //nested function cause geojson doesn't seem to pass binding context
            return this.onEachFeature(feature, layer);
          },

          style: feature => {
            return this.featureStyling(feature);
          }
        });
      }

      // this.edition.setStyle this.options.editStyle
      this.edition.addTo(this.map);
      this._refreshControls();
      this._saveUpdates();
      return this;
    },

    buildMultiLevelLegend(layers) {
      let html = "";
      const levels = [];
      layers.eachLayer(layer => {
        const level =  parseInt(layer.feature.properties.level);
        if (!Array.from(levels).includes(level)) { return levels.push(level); }
      });

      levels.sort((a, b) => b-a);

      for (var level of Array.from(levels)) {
        html += "<div class='leaflet-legend-item'>";
        html += `<div class='leaflet-legend-body leaflet-multilevel-legend' data-level='${level}'>`;

        var color = this.colorize(level);

        var label = level === 0 ? 'RDC' : `${this.options.defaultLevelLabel} ${level}`;

        html += `<i class='active' style='background-color: ${color}' title='${label}'></i>`;
        html += `<span>${label}</span>`;
        html += "</div>";
        html += "</div>";
      }

      return html;
    },

    _refreshView(view) {
      if (view == null) { ({
        view
      } = this.options); }
      if (view === 'auto') {
        try {
          this._refreshView('show');
        } catch (error) {
          try {
            this._refreshView('edit');
          } catch (error1) {
            this._setDefaultView();
          }
        }
      } else if (view === 'show') {
        try {
          this.map.fitBounds(this.reference.getLayers()[0].getBounds());
        } catch (error2) {
          try {
            this.map.fitBounds(this.ghost.getLayers()[0].getBounds());
          } catch (error3) {
            this._setDefaultView();
          }
        }
      } else if (view === 'edit') {
        try {
          this.map.fitBounds(this.edition.getLayers()[0].getBounds());
        } catch (error4) {
          this._setDefaultView();
        }
      } else if (view === 'default') {
        this._setDefaultView();
      } else if (view.center != null) {
        const center = L.latLng(view.center[0], view.center[1]);
        if (view.zoom != null) {
          this.map.setView(center, view.zoom);
        } else {
          this.map.setView(center, 15);
        }
      } else if (view.bounds != null) {
        this.map.fitBounds(view.bounds);
      } else {
        console.log(`How to set view with ${view}?`);
      }
      return this;
    },

    _setDefaultView() {
      this.map.fitWorld();
      return this.map.setZoom(6);
    },

    _refreshZoom() {
      if (this.options.view.zoom != null) {
        return this.map.setZoom(this.options.view.zoom);
      }
    },

    _refreshControls() {
      if (this.controls != null) {
        for (var name in this.controls) {
          var control = this.controls[name];
          if (name !== 'legend') { this.map.removeControl(control); }
        }
      }
      if (this.options.controls.zoom !== false) {
        this.controls.zoom = new L.Control.Zoom(this.options.controls.zoom);
        this.map.addControl(this.controls.zoom);
      }
      if (this.options.controls.fullscreen !== false) {
        this.controls.fullscreen = new L.Control.FullScreen(this.options.controls.fullscreen);
        this.map.addControl(this.controls.fullscreen);
      }
      if (this.edition != null) {
        if (this.options.controls.reactiveMeasure !== false) {
          this.controls.reactiveMeasureControl = new L.ReactiveMeasureControl(this.edition, this.options.controls.reactiveMeasure);
        }
        this.controls.draw = new L.Control.Draw($.extend(true, {}, this.options.controls.draw, {edit: {featureGroup: this.edition}}));
        this.map.addControl(this.controls.draw);
      }
      if (this.options.controls.scale !== false) {
        this.controls.scale = new L.Control.Scale(this.options.controls.scale);
        this.map.addControl(this.controls.scale);
      }
      if ((this.options.controls.importers.gml !== false) || (this.options.controls.importers.geojson !== false) || (this.options.controls.importers.kml !== false)) {

        this.controls.importers_ctrl = new L.Control.EasyButton(`<i class='leaflet-importer-ctrl' title='${this.options.controls.importers.buttonTitle}'></i>`, (btn, map) => {
          const args = {
            title: this.options.controls.importers.title,
            onShow: evt => {
              const {
                modal
              } = evt;
              modal.reloadContent(this.options.controls.importers.content);

              $('*[data-editor-submit]', modal._container).on('click', function(e) {
                $(modal._container).find('form[data-importer-form]').submit();
                e.preventDefault;
                return false;
              });

              $('*[data-editor-cancel]', modal._container).on('click', e => {
                e.preventDefault;
                modal.hide();
                return false;
              });

              $('form[data-importer-form]', modal._container).submit(function() {
                return $(this).find('[data-importer-spinner]').addClass('active');
              });

              return $(modal._container).on('ajax:complete','form[data-importer-form]', (e,data) => {
                const parser = new DOMParser();
                const kml = parser.parseFromString(data.responseText.trim(), 'text/xml');
                const track = new L.KML(kml);
                this.edition = track;
                this.edition.addTo(this.map);

                const bounds = track.getBounds();
                this.map.fitBounds(bounds);

                this.update();
                modal.hide();


                return this.navigateToLayer(this.edition);
              });
            },

            onHide(evt) {
              const {
                modal
              } = evt;
              return $('*[data-editor-submit], *[data-editor-cancel]', modal._container).off('click');
            }
          };


          return map.fire('modal', $.extend(true, {}, this.options.controls.importers, args ));
        });

        this.controls.importers_ctrl.button['type'] = 'button';

        this.map.addControl(this.controls.importers_ctrl);
        this.map.addControl(this.controls.reactiveMeasureControl);
      }

      if ((this.options.multiLevels != null) && (this.controls.legend != null)) {
        const legend = this.controls.legend.getContainer();

        legend.innerHTML = this.buildMultiLevelLegend(this.edition);

        $(legend).on('click', '.leaflet-multilevel-legend', e => {
          e.preventDefault();
          const level = $(e.currentTarget).data('level');
          if (level != null) {
            return this.edition.eachLayer(layer => {
              if (parseInt(layer.feature.properties.level) === level) {
                const shape = $(layer.getElement());
                const label = $(layer.label.getElement());
                shape.toggle();
                label.toggle();
                return $(e.currentTarget).children('i').toggleClass('active');
              }
            });
          }
        });
      }

      if (this.options.overlaySelector != null) {
        const selector = this.layerSelector || new L.Control.Layers();

        if ((this.ghost != null) && this.ghost.getLayers().length) {
          this._removeFromLayerControl(this.ghost);
          selector.addOverlay(this.ghost, this.options.overlaySelector.ghostLayer);
          this.layersScheduler.insert(this.ghost._leaflet_id, {back: true});
        }

        if ((this.reference != null) && (this.reference.getLayers().length > 0)) {
          this._removeFromLayerControl(this.reference);
          selector.addOverlay(this.reference, this.options.overlaySelector.referenceLayer);
          this.layersScheduler.insert(this.reference._leaflet_id);
        }


        if (this.seriesReferencesLayers != null) {
          for (var label in this.seriesReferencesLayers) {
            var layer = this.seriesReferencesLayers[label];
            this._removeFromLayerControl(layer);
            selector.addOverlay(layer, label);
            this.layersScheduler.insert(layer._leaflet_id);
          }
        }

        if ((this.edition != null) && (this.edition.getLayers().length > 0)) {
          this._removeFromLayerControl(this.edition);
          selector.addOverlay(this.edition, this.options.overlaySelector.editionLayer);
          return this.layersScheduler.insert(this.edition._leaflet_id);
        }
      }
    },

    _removeFromLayerControl(layer){
      if (this.layerSelector._layers.filter(clItem => clItem.overlay).map(clItem => clItem.layer).includes(layer)) {
        return this.layerSelector.removeLayer(layer);
      }
    },

    _saveUpdates() {
      if (this.edition != null) {
        this.element.val(JSON.stringify(this.edition.toGeoJSON()));
      }
      return true;
    },

    _saveUpdatesSeries() {
      if (this.seriesReferencesLayers != null) {
        const geojson = [];
        for (var layerGroup of Array.from(this.seriesReferencesLayers)) {
          geojson.push(layerGroup.serie.toGeoJSON());
        }

        this.elementSeries.val(JSON.stringify(geojson));
      }
      return true;
    },

    update() {
      this._saveUpdates();
      this._saveUpdatesSeries();
      this._refreshControls();
      return this.element.trigger("mapchange");
    }
  }
  );

  var delay = (time, method) => setTimeout(method, time);

  const detectNewComponents = () => $("input[data-map-editor]").each(function() {
    return $(this).mapeditor();
  });

  $(document).ready(() => detectNewComponents());

  return $(document).on('dialog:show', () => detectNewComponents());

})(mapeditor, jQuery);
