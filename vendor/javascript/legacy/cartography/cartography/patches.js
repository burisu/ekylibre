(function() {
	var originalOnTouch = L.Draw.Polyline.prototype._onTouch;
	L.Draw.Polyline.prototype._onTouch = function( e ) {
		if( e.originalEvent.pointerType != 'mouse' ) {
			return originalOnTouch.call(this, e);
		}
	}
})();
