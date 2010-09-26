use Websight::XML;

class Websight::Metadata is Websight::XML;

method processPlugin ($opts?) {
  self.make-xml;
  my $debug = $.parent.debug;
  my $name = $.namespace;
  loop (my $i=0; $i < $.parent.content.root.nodes.elems; $i++) {
    if $.parent.content.root.nodes[$i] !~~ Exemel::Element { next; }
    my $id = $.parent.content.root.nodes[$i].attribs<id>;
    if $id && $id eq $name {
      ## The metadata element should have only one node.
      my $md_node = $.parent.content.root.nodes[$i].nodes[0];
      if $md_node ~~ Exemel::Text { ## We need a text node.
        my $data = ~$md_node;
        $.parent.metadata.load($data);
      }
      $.parent.content.root.nodes.splice($i, 1);
      last;
    }
  }
}

