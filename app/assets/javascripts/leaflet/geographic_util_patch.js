L.GeographicUtil = class GeographicUtil {
  static Polygon(points, polyline) { // (Array of [lat,lng] pair)
    let point;
    if (polyline == null) { polyline = false; }
    const geod = GeographicLib.Geodesic.WGS84;
    
    let poly = geod.Polygon(false);
    for (point of Array.from(points)) {
      poly.AddPoint(point[0], point[1]);
    }

    poly = poly.Compute(false, true);

    let poly2 = geod.Polygon(true);
    for (point of Array.from(points)) {
      poly2.AddPoint(point[0], point[1]);
    }

    poly2 = poly2.Compute(false, true);

    const extrapolatedArea = Math.abs(poly.area);

    return {
      extrapolatedPerimeter: poly.perimeter,
      extrapolatedArea,
      area: extrapolatedArea,
      perimeter: poly2.perimeter
    };
  }
};