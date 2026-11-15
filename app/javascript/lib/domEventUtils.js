function onElementDetected(selector, callback) {
  onDomReady((_e) => {
    const element = document.getElementById(selector);
    if (element !== null) {
      callback(element);
    }
  });
}
function onDomReady(callback) {
  document.addEventListener("turbo:load", callback);
}
function delegateListener(element, eventName, selector, callback) {
  element.addEventListener(
    eventName,
    function(e) {
      for (let target = e.target; target && target != this; target = target.parentNode) {
        if (target.matches(selector)) {
          callback(e);
          break;
        }
      }
    },
    false
  );
}
export {
  delegateListener,
  onDomReady,
  onElementDetected
};
