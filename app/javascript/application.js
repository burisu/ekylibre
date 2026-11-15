// Application modules
import { Turbo } from '@hotwired/turbo-rails';
import 'controllers';
import 'pages';

// Turbo Drive handles links; forms are still submitted by the browser or by
// jquery_ujs (remote forms), as controllers render invalid forms with 200
if (Turbo.config && Turbo.config.forms) {
    Turbo.config.forms.mode = 'off';
} else {
    Turbo.setFormMode('off');
}
