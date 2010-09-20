use Websight; 

class Websight::XML does Websight;

use Exemel;

method make-xml() {
  if $.parent.content !~~ Exemel::Element {
    my $xml;
    if $.parent.content ~~ Exemel::Document { ## too soon for Document.
      $xml = $.parent.content.root;
    }
    else {
      $xml = Exemel::Element.parse($.parent.content);
    }
    $.parent.content = $xml;
  }
}

## This is pretty boring when used alone. Best to subclass XML
#  and call the make-xml() function from the subclass.
method processPlugin ($opts?) {
  self.make-xml();
}
