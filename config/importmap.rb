# JavaScript modules loaded with import maps (see app/views/layouts/*)

# Application modules (app/javascript)
pin 'application', to: 'application.js'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'legacy_globals', to: 'legacy_globals.js'
pin 'duke_widget', to: 'duke_widget.js'
pin_all_from 'app/javascript/components', under: 'components'
pin_all_from 'app/javascript/duke', under: 'duke'
pin_all_from 'app/javascript/lib', under: 'lib'
pin_all_from 'app/javascript/pages', under: 'pages'
pin_all_from 'app/javascript/services', under: 'services'
pin 'services/i18n/translations', to: 'services/i18n/translations.json', preload: false

# Vendored libraries (vendor/javascript)
pin "autocompleter" # @6.1.3
pin "autosize" # @4.0.2
pin "flatpickr" # @4.5.7
pin "i18n-js" # @3.7.1
pin "leaflet" # @1.2.0
pin "leaflet-draw" # @0.4.12
pin "lodash" # @4.17.20
pin "moment" # @2.27.0
pin "rbush" # @3.0.1
pin "flatpickr/dist/l10n/ar", to: "flatpickr--dist--l10n--ar.js" # @4.5.7
pin "flatpickr/dist/l10n/de", to: "flatpickr--dist--l10n--de.js" # @4.5.7
pin "flatpickr/dist/l10n/es", to: "flatpickr--dist--l10n--es.js" # @4.5.7
pin "flatpickr/dist/l10n/fr", to: "flatpickr--dist--l10n--fr.js" # @4.5.7
pin "flatpickr/dist/l10n/it", to: "flatpickr--dist--l10n--it.js" # @4.5.7
pin "flatpickr/dist/l10n/ja", to: "flatpickr--dist--l10n--ja.js" # @4.5.7
pin "flatpickr/dist/l10n/pt", to: "flatpickr--dist--l10n--pt.js" # @4.5.7
pin "flatpickr/dist/l10n/zh", to: "flatpickr--dist--l10n--zh.js" # @4.5.7
pin "flatpickr/dist/plugins/confirmDate/confirmDate", to: "flatpickr--dist--plugins--confirmDate--confirmDate.js" # @4.5.7
