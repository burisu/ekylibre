import http from "lib/http";
class MasterProductionService {
  get(reference_name) {
    return http.get(`/backend/master_productions/${reference_name}.json`).then((res) => res.data);
  }
}
export {
  MasterProductionService
};
