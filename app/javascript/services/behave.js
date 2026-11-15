function resolveElements(root, selector) {
  if (typeof selector === "string") {
    return Array.from(root.querySelectorAll(selector));
  } else {
    return selector(root);
  }
}
class Behavior {
  constructor(element, selector, handler, sequence2) {
    this.element = element;
    this.selector = selector;
    this.handler = handler;
    this.sequence = sequence2;
  }
  refresh() {
    resolveElements(this.element, this.selector).forEach((e) => {
      const elem = e;
      const key = `alreadyBound${this.sequence}`;
      if (!elem[key]) {
        elem[key] = true;
        this.handler.call(e);
      }
    });
  }
}
const behaviors = [];
let sequence = 0;
function register(element, selector, handler) {
  const b = new Behavior(element, selector, handler, sequence++);
  behaviors.push(b);
  b.refresh();
}
function refresh() {
  behaviors.forEach((b) => b.refresh());
}
export {
  refresh,
  register
};
