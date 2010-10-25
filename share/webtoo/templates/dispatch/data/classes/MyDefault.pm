## MyClass, an example handler for the Dispatch example template.

use Websight;

class MyDefault does Websight;

method processPlugin($config?) {
  my $content = '<html><head><title>Dispatch example</title></head>';
  $content   ~= '<body><h1>Dispatch example</h1><ul>';
  $content   ~= '<li><a href="test">Test plugin</a></li>';
  $content   ~= '<li><a href="author">A redirect</a></li>';
  $content   ~= '<li><a href="example?with=some&amp;and=more">Built-in example class</a></li>';
  $content   ~= '<li><a href="morbid?name=Rewrite">Rewrite test</a></li>';
  $content   ~= '</ul></body></html>';
  $.parent.content = $content;
}
