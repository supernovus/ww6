use Websight::XML;

class Websight::Petal is Websight::XML;

use Perlite::Hash;
use Flower;

# This plugin must be called AFTER any others that add metadata that
# needs to be parsed in the template.

method processPlugin ($default_opts?) {
  self.make-xml;
  my $opts = self.getConfig(:type(Hash)) // $default_opts;
  my $find = sub ($file) { $.parent.findFile($file) };
  my $flower = Flower.new(:template($.parent.content), :$find);
  if $opts {
    if hash-has($opts, 'modifiers', :type(Array)) {
      for @($opts<modifiers>) -> $modifier {
        my $plugin = $modifier;
        if $plugin !~~ /'::'/ {
          $plugin = "Flower::Utils::$plugin";
        }
        ## Okay, let's load the Flower plugins.
        eval("use $plugin");
        $flower.add-modifiers(eval($plugin~'::all()'));
      }
    }
  }
  $.parent.content = $flower.parse(|$.parent.metadata);
}
