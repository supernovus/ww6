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
  my $debug = $.parent.debug;
  say "content is of type: "~$.parent.content.WHAT if $debug;
  ## We want an Exemel::Document. Let's make one.
  if $.parent.content !~~ Exemel::Document {
    say "We're not an Exemel::Document already" if $debug;
    my $xml;
    if $.parent.content ~~ Exemel::Element {
      say "Turning an Exemel::Element into a Document." if $debug;
      $xml = Exemel::Document.new(:root($.parent.content));
    }
    else {
      say "Parsing the text" if $debug;
      $xml = Exemel::Document.parse($.parent.content);
    }
    say "XML is: $xml" if $debug;
    say "XML is of type: "~$xml.WHAT if $debug;
    $.parent.content = $xml;
  }
}

## The default if you do call this plugin directly.
method processPlugin ($opts?) {
  self.make-xml();
}

