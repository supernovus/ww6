role AJAX::JSON;

## Provides a pre-fab output() method that JSON-izes the output from your
## methods, ensures caching is disabled, and returns the JSON string.
## Note: This addon expects the output method has not been remapped from
## 'output()'. Stick with the defaults, they are sane.

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

