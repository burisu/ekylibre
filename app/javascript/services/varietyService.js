import http from "lib/http";
class VarietyService {
  selection(specie) {
    return http.get(`/backend/varieties/selection.json?specie=${specie}`).then((res) => res.data);
  }
}
export {
  VarietyService
};
