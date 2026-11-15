import { parseHTML } from "lib/parseHtml";
import { refresh as behaveRefresh } from "services/behave";
import { delegateListener } from "lib/domEventUtils";
import http from "lib/http";
function modalTemplate(id, size) {
  const additionalClass = size === "default" ? "" : `modal-${size}`;
  return `
        <div class="modal fade " id="${id}" role="dialog">
            <div class="modal-dialog modal-dialog-centered ${additionalClass}">
                <div class="modal-content">
                    <div class="modal-header modal-header-generic">
                        <button class="close" data-dismiss="modal">
                            <span><i class="icon icon-destroy"></i></span>
                        </button>
                        <b class="modal-title"></b>
                    </div>
                    <div class="modal-body" style="max-height: 80vh; overflow: auto">
                    </div>
                </div>
            </div>
        </div>
    `;
}
class EscListener {
  constructor(modal) {
    this.modal = modal;
  }
  handleEvent(e) {
    if (e instanceof KeyboardEvent && e.key === "Escape") {
      this.modal.close();
    }
  }
}
let idSequence = 0;
const defaultOptions = {
  size: "default"
};
class Modal {
  constructor(title, content, options = {}) {
    this.title = title;
    this.content = content;
    this.escListener = new EscListener(this);
    this.options = { ...defaultOptions, ...options };
  }
  getBodyElement() {
    return this.bodyElement;
  }
  setBodyString(content) {
    this.getBodyElement().innerHTML = content;
    behaveRefresh();
  }
  setTitle(title) {
    this.titleElement.textContent = title;
  }
  setBody(content) {
    if (content instanceof Element) {
      this.getBodyElement().innerHTML = "";
      this.getBodyElement().appendChild(content);
      behaveRefresh();
    } else {
      this.setBodyString(content);
    }
  }
  open() {
    const fragment = parseHTML(modalTemplate(`modal-${idSequence++}`, this.options.size));
    this.element = fragment.firstElementChild;
    this.titleElement = this.element.querySelector(".modal-title");
    this.bodyElement = this.element.querySelector(".modal-body");
    document.body.append(this.element);
    delegateListener(this.element, "click", '[data-dismiss="modal"]', (_e) => this.close());
    this.show();
    this.titleElement.textContent = this.title;
    this.setBody(this.content);
    this.on("unroll:menu-opened", "input", (e) => {
      const element = e.detail.unroll.dropDownMenu.get(0);
      const actions = this.getBodyElement().querySelector(".form-actions");
      if (actions) {
        actions.style.marginTop = `${element.clientHeight}px`;
      }
    });
    this.on("unroll:menu-closed", "input", (e) => {
      const actions = this.getBodyElement().querySelector(".form-actions");
      if (actions) {
        actions.style.marginTop = "";
      }
    });
  }
  on(eventName, selector, callback) {
    delegateListener(this.element, eventName, selector, callback);
  }
  close() {
    this.hide();
    this.element.remove();
  }
  show() {
    this.addBackdrop();
    this.element.classList.add("in");
    this.element.setAttribute("style", "display: block;");
    this.element.addEventListener("click", (e) => {
      if (e.target === this.element) {
        this.close();
      }
    });
    window.addEventListener("keyup", this.escListener);
  }
  hide() {
    window.removeEventListener("keyup", this.escListener);
    this.element.classList.add("out");
    this.element.classList.remove("in");
    this.element.setAttribute("style", "display: none;");
    this.removeBackdrop();
  }
  addBackdrop() {
    this.backdrop = document.createElement("div");
    this.backdrop.classList.add("modal-backdrop", "fade", "in");
    document.body.append(this.backdrop);
  }
  removeBackdrop() {
    this.backdrop.remove();
  }
}
function openRemote(url, options = {}) {
  return http.get(url, options.requestConfig).then((response) => {
    const { title = "" } = options;
    const modal = new Modal(title, response.data, options);
    modal.open();
    return { modal, responseText: response.data };
  });
}
function openFromElementDataAttributes(element) {
  const title = element.getAttribute("data-modal-title") || "";
  const body = element.getAttribute("data-modal-body") || "";
  return open(title, body);
}
function open(title, body) {
  const modal = new Modal(title, body);
  modal.open();
  return modal;
}
export {
  Modal,
  open,
  openFromElementDataAttributes,
  openRemote
};
