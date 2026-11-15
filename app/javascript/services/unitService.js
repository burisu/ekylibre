import http from "lib/http";
class UnitService {
  get(id) {
    return http.get(`/backend/units/${id}.json`).then((res) => res.data);
  }
}
export {
  UnitService
};
