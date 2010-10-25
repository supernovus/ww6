## MyClass, an example handler for the Dispatch example template.

use Websight;

class MyTest does Websight;

method processPlugin($config?) {
  $.parent.mimeType('text/plain');
  $.parent.content = "Environment dump:\n" ~ $.parent.env.fmt('%s: %s', "\n");
}

