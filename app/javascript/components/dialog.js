import http from "lib/http";
import { openRemote } from "components/modal";
function handleTitle(modal) {
  const h1 = modal.getBodyElement().querySelector("h1");
  if (h1 !== null) {
    modal.setTitle(h1.textContent || "");
    h1.remove();
  }
}
const requestConfigDefaults = {
  headers: {
    "X-Requested-With": "XMLHTTPRequest"
  }
};
function sendDialogShowEvent(modal) {
  modal.getBodyElement().dispatchEvent(new Event("dialog:show", { bubbles: true }));
}
async function openDialog(url, options) {
  const { modal } = await openRemote(url, { size: "lg", requestConfig: { ...requestConfigDefaults, params: { dialog: "1" } } });
  handleTitle(modal);
  sendDialogShowEvent(modal);
  modal.on("submit", "form", (e) => {
    e.preventDefault();
    const form = e.target;
    const data = new FormData(form);
    data.set("dialog", "1");
    const formMethod = form.method.toLowerCase();
    const dataOrParams = {};
    if (formMethod == "get" || formMethod == "head") {
      dataOrParams.params = Object.fromEntries(data.entries());
    } else {
      dataOrParams.data = data;
    }
    http.request({ ...requestConfigDefaults, method: formMethod, url: form.action, ...dataOrParams }).then((response) => {
      const statusCode = response.headers["x-return-code"];
      if (!statusCode || statusCode == "invalid") {
        if (statusCode == "invalid" && options.invalid) {
          options.invalid && options.invalid(response);
        }
        modal.setBodyString(response.data);
        handleTitle(modal);
        sendDialogShowEvent(modal);
      } else {
        options.success && options.success(response);
        modal.close();
      }
    }).catch(({ response }) => {
      options.error && options.error(response);
    });
  });
  modal.on("click", ".form-actions a.btn", (e) => {
    e.preventDefault();
    modal.close();
  });
  return this;
}
export {
  openDialog
};
