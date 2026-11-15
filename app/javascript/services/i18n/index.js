import I18n from "i18n-js";
import translations from "services/i18n/translations" with { type: "json" };
import { ext } from "services/i18n/ext";
const ISO3_LANG_KEY = "data-lang-iso3";
const DEFAULT_LANGUAGE = "fra";
function getLocaleFromDocument() {
  const element = document.firstElementChild;
  if (element && element.hasAttribute(ISO3_LANG_KEY)) {
    return element.getAttribute(ISO3_LANG_KEY);
  } else {
    return DEFAULT_LANGUAGE;
  }
}
I18n.defaultLocale = getLocaleFromDocument();
I18n.locale = I18n.defaultLocale;
I18n.translations = translations;
I18n.ext = ext;
const translate = I18n.translate.bind(I18n);
export {
  I18n,
  translate
};
