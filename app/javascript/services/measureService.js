import http from "lib/http";
class MeasureService {
  convert(value, from, to) {
    return http.get("/backend/measures/convert", {
      params: {
        value,
        from,
        to
      }
    }).then((res) => res.data);
  }
}
export {
  MeasureService
};
