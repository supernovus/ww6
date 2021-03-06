role WW::Controller::JSON;

## This is not to be used on it's own, but in conjunction with WW::Controller.

## Provides a pre-fab output() method that JSON-izes the output from your
## methods, ensures caching is disabled, and returns the JSON string.
## Note: This addon expects the output method has not been remapped from
## 'output()'. Stick with the defaults, they are sane.

## NOTE: If you are using AJAX with JSON data, you don't use the
## self.input.get() method, as the POST data does not contain standard
## CGI parameters, but the raw JSON string. In this case, use self.input.body
## instead, which represents the raw POST data.

use DateTime::Utils;
use JSON::Tiny;

method output ($output) {
  my $rfctime = rfc2822();
  $.parent.addHeader('Last-Modified', $rfctime);
  $.parent.addHeader('Expires', $rfctime);
  $.parent.addHeader('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0, post-check=0, pre-check=0');
  $.parent.addHeader('Pragma', 'no-cache');

  $.parent.mimeType('application/json');

  to-json($output);
}

