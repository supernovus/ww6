use Websight;

class Websight::Flower is Websight;

use Hash::Has;
use Flower;

# This plugin must be called AFTER any others that add metadata that
# needs to be parsed in the template.

method processPlugin ($default_opts?) {
  my $opts = self.getConfig(:type(Hash), :default($default_opts));
  if $opts && hash-has($opts, 'skip', :true) { return; } ## Skip this request.
  my $find = sub ($file) { $.parent.findFile($file) };
  my $flower = Flower.new(:template($.parent.content), :$find);
  if $opts {
    if hash-has($opts, 'modifiers', :type(Array)) {
      $flower.load-modifiers(|@($opts<modifiers>));
    }
  }
  $.parent.content = $flower.parse(|$.parent.metadata);
}

