use WW::Plugin;

role WW::Controller does WW::Plugin;

use Flower;

has $.viewdir is rw = 'views';

## You don't have to use this, but it's a quick way to deal with 'views'.
## Unlike CodeIgniter, you can't chain views, since we're using Flower.
## Make sure your view statement is the last one in your Controller method.
method view ($template, *@modifiers) {
  my $viewfile = $.parent.findFile($!viewdir.'/'.$template);
  my $find = sub ($file) { $.parent.findFile($file) };
  my $flower = Flower.new(:file($viewfile), :$find);
  if (@modifiers) {
    $flower.load-modifiers(|@modifiers);
  }
  return $flower.parse(|$.parent.metadata);
}

