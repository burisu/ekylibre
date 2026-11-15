/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

__webpack_require__(1);
module.exports = __webpack_require__(4);


/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

var L, _,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

L = __webpack_require__(2);

_ = __webpack_require__(3);

L.Control.ControlPanel = (function(superClass) {
  extend(ControlPanel, superClass);

  ControlPanel.prototype.options = {
    position: 'bottomleft',
    className: 'leaflet-control-controlPanel',
    titleClassName: 'leaflet-control-controlPanel-title',
    propertiesClassName: 'leaflet-control-controlPanel-properties',
    actionsClassName: 'leaflet-control-controlPanel-actions',
    expanded: true,
    ignoreActions: false
  };

  function ControlPanel(_toolbar, options) {
    this._toolbar = _toolbar;
    if (options == null) {
      options = {};
    }
    this.options = _.merge(this.options, options);
    this._toolbar.on('enable', this.addPanel, this);
    this._toolbar.on('disable', this.removePanel, this);
    this._actionButtons = [];
  }

  ControlPanel.prototype.addPanel = function() {
    L.DomUtil.remove(this._toolbar._actionsContainer);
    this._toolbar._map.addControl(this);
    return L.DomEvent.on(this._toolbar._map._container, 'keyup', this._onCancel, this);
  };

  ControlPanel.prototype.removePanel = function() {
    L.DomEvent.off(this._toolbar._map._container, 'keyup', this._onCancel, this);
    return this._toolbar._map.removeControl(this);
  };

  ControlPanel.prototype._onCancel = function(e) {
    if (e.keyCode === 27) {
      return this._toolbar.disable();
    }
  };

  ControlPanel.prototype.onAdd = function(map) {
    this._container = L.DomUtil.create('div', this.options.className);
    if (this.options.expanded) {
      L.DomUtil.addClass(this._container, 'large');
    }
    if (this.options.title) {
      this._titleContainer = L.DomUtil.create('div', this.options.titleClassName, this._container);
      this._titleContainer.innerHTML = this.options.title;
    }
    this._propertiesContainer = L.DomUtil.create('div', this.options.propertiesClassName, this._container);
    L.DomEvent.disableScrollPropagation(this._container);
    if (!this.options.ignoreActions) {
      this._actionsContainer = L.DomUtil.create('div', this.options.actionsClassName, this._container);
      this._showActionsToolbar();
    }
    this.addProperties();
    return this._container;
  };

  ControlPanel.prototype.addProperties = function() {
    this._addAnimatedHelper();
    return this._addPointerCoordinates();
  };

  ControlPanel.prototype.onRemove = function() {};

  ControlPanel.prototype._createActions = function(handler) {
    var button, buttons, container, di, div, dl, i, l, results;
    container = this._actionsContainer;
    buttons = this._toolbar.getActions(handler);
    l = buttons.length;
    di = 0;
    dl = this._actionButtons.length;
    while (di < dl) {
      this._toolbar._disposeButton(this._actionButtons[di].button, this._actionButtons[di].callback);
      di++;
    }
    this._actionButtons = [];
    while (container.firstChild) {
      container.removeChild(container.firstChild);
    }
    i = 0;
    results = [];
    while (i < l) {
      if ('enabled' in buttons[i] && !buttons[i].enabled) {
        i++;
        continue;
      }
      div = L.DomUtil.create('div', 'button', container);
      button = this._toolbar._createButton({
        title: buttons[i].title,
        text: buttons[i].text,
        container: div,
        callback: buttons[i].callback,
        context: buttons[i].context
      });
      this._actionButtons.push({
        button: button,
        callback: buttons[i].callback
      });
      results.push(i++);
    }
    return results;
  };

  ControlPanel.prototype._showActionsToolbar = function() {
    var buttonIndex, lastButtonIndex, toolbarPosition;
    buttonIndex = this._toolbar._activeMode.buttonIndex;
    lastButtonIndex = this._toolbar._lastButtonIndex;
    toolbarPosition = this._toolbar._activeMode.button.offsetTop - 1;
    this._createActions(this._toolbar._activeMode.handler);
    this._actionsContainer.style.top = toolbarPosition + 'px';
    if (buttonIndex === 0) {
      L.DomUtil.addClass(this._actionsContainer, 'leaflet-draw-actions-top');
    }
    if (buttonIndex === lastButtonIndex) {
      L.DomUtil.addClass(this._actionsContainer, 'leaflet-draw-actions-bottom');
    }
    this._actionsContainer.style.display = 'block';
  };

  ControlPanel.prototype._hideActionsToolbar = function() {
    this._actionsContainer.style.display = 'none';
    L.DomUtil.removeClass(this._actionsContainer, 'leaflet-draw-actions-top');
    L.DomUtil.removeClass(this._actionsContainer, 'leaflet-draw-actions-bottom');
  };

  ControlPanel.prototype._addAnimatedHelper = function() {
    var container, img;
    container = L.DomUtil.create('div', 'property', this._propertiesContainer);
    this._animatedHelperContainer = L.DomUtil.create('div', 'property-content', container);
    if (this.options.animatedHelper) {
      img = L.DomUtil.create('img', 'animated-helper', this._animatedHelperContainer);
      return img.src = this.options.animatedHelper;
    }
  };

  ControlPanel.prototype._addPointerCoordinates = function() {
    var container, containerTitle;
    container = L.DomUtil.create('div', 'property', this._propertiesContainer);
    containerTitle = L.DomUtil.create('div', 'property-title', container);
    containerTitle.innerHTML = this.options.coordinatesProperty;
    this._pointerCoordinatesContainer = L.DomUtil.create('div', 'property-content', container);
    return this._map.on('mousemove', this._onUpdateCoordinates, this);
  };

  ControlPanel.prototype._onUpdateCoordinates = function(e) {
    var coordinates, lat, latRow, lng, lngRow;
    coordinates = e.latlng;
    L.DomUtil.empty(this._pointerCoordinatesContainer);
    latRow = L.DomUtil.create('div', 'coordinates-row', this._pointerCoordinatesContainer);
    lat = L.DomUtil.create('div', 'coordinate', latRow);
    lat.innerHTML = "lat: " + coordinates.lat;
    lngRow = L.DomUtil.create('div', 'coordinates-row', this._pointerCoordinatesContainer);
    lng = L.DomUtil.create('div', 'coordinate', lngRow);
    return lng.innerHTML = "lng: " + coordinates.lng;
  };

  return ControlPanel;

})(L.Control);


/***/ }),
/* 2 */
/***/ (function(module, exports) {

module.exports = L;

/***/ }),
/* 3 */
/***/ (function(module, exports) {

module.exports = _;

/***/ }),
/* 4 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ })
/******/ ]);