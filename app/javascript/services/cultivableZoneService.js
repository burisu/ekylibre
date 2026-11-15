import http from "lib/http";
class CultivableZoneService {
  get(id) {
    return http.get(`/backend/cultivable-zones/${id}.json`).then((res) => res.data);
  }
}
export {
  CultivableZoneService
};
