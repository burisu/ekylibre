// Stimulus controllers of app/javascript/controllers (<name>_controller.js)
import { application } from 'controllers/application';
import { eagerLoadControllersFrom } from '@hotwired/stimulus-loading';

eagerLoadControllersFrom('controllers', application);
