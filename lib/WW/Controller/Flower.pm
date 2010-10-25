role WW::Controller::Flower;

## This role is not meant to be used alone. It must be used in conjunction
## with the WW::Controller role. E.g.:
##
##  class MyController does WW::Controller does WW::Controller::Flower;
##

use Flower;

## A replacement for load-view, that instead of loading the raw text,
## parses the document with Flower. It allows you to pass a list of
## Flower modifier plugins that you want to load. E.g.:  
##
##        self.flower-view('index.xhtml', 'Text', 'Date');
##
## Will parse the file in 'views/index.xhtml' and add the
## Flower::Utils::Text and Flower::Utils::Date modifier plugins.
##

method flower-view ($template, *@modifiers) {
  my $find = sub ($file) { $.parent.findFile($file) };
  my $flower = Flower.new(:file($.viewdir~'/'~$template), :$find);
  if (@modifiers) {
    $flower.load-modifiers(|@modifiers);
  }
  return $flower.parse(|$.parent.metadata);
}

