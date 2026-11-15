import { onElementDetected } from "lib/domEventUtils";
import http from "lib/http";
import { Modal } from "components/modal";
import { translate as t } from "services/i18n";
onElementDetected("generate-land-parcel-btn", (element) => {
  element.addEventListener("click", async (_e) => {
    const params = {};
    const zone = element.dataset.cultivableZone;
    if (zone) {
      params["cultivable_zone"] = zone;
    }
    const response = await http.get("/backend/controller_helpers/activity_production_creations/new", { params });
    const title = t("front-end.land_parcel.create_modal.title");
    const modal = new Modal(title, response.data, { size: "lg" });
    modal.open();
    modal.on("submit", "form", (e) => {
      const form = e.target;
      e.preventDefault();
      const data = new FormData(form);
      http.post(form.action, data).then((response2) => {
        if (response2.headers.location) {
          window.location.href = response2.headers.location;
        } else {
          modal.getBodyElement().prepend("An error occured");
        }
      }).catch(({ response: response2 }) => {
        if (response2.status === 400) {
          modal.setBodyString(response2.data);
        }
      });
    });
  });
});
