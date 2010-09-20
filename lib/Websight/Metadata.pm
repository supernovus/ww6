use Websight::XML;

class Websight::Metadata is Websight::XML;

method processPlugin ($opts?) {
  self.make-xml;
  my $debug = $.parent.debug;
  my $name = $.namespace;
  loop (my $i=0; $i < $.parent.content.nodes.elems; $i++) {
    if $.parent.content.nodes[$i] !~~ Exemel::Element { next; }
    my $id = $.parent.content.nodes[$].get('id');
    if $id && $id eq $name {
      my $md_node = $.parent.content.nodes[$].nodes[0];
      if $md_node ~~ Exemel::Text {
        my $data = ~$md_node;
        $.parent.metadata.load($data);
      }
      $.parent.content.nodes.splice($i, 1);
      last;
    }
  }
}

