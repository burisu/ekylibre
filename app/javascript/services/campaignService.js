import http from "lib/http";
class CampaignService {
  getByName(name) {
    return http.get(`/backend/campaigns/show_by_name.json?name=${name}`).then((res) => res.data);
  }
}
export {
  CampaignService
};
