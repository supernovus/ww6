use Websight; 

## This plugin can be used standalone, but it's pretty boring.
## Better to make anything depending on it a subclass, and call
## the self.make-xml() method before trying to use the XML object.

class Websight::XML does Websight;

use Exemel;

## This method will turn a raw text content into an XML document.
## It also supports converting an Exemel::Element, but that's not
## a standard usage.
method make-xml() {
  ## We want an Exemel::Document. Let's make one.
  if $.parent.content !~~ Exemel::Document {
    my $xml;
    if $.parent.content ~~ Exemel::Element {
      $xml = Exemel::Document.new(:root($.parent.content));
    }
    else {
      $xml = Exemel::Document.parse($.parent.content);
    }
    $.parent.content = $xml;
  }
}

## The default if you do call this plugin directly.
method processPlugin ($opts?) {
  self.make-xml();
}

