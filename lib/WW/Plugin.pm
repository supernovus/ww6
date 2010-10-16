use Websight;

role WW::Plugin does Websight;

has $.plugns is rw = 'Plugins::';

## A shortcut to the data. Let's you do:
## self.data<page><title> = 'My title';
method data () {
  return $.parent.metadata;
}

method add-attribute ($attrib, $value) { 
  my $role = eval('role { has $.'~$attrib~' is rw; }'); 
  self does $role; 
  self."$attrib"() = $value; 
}

method load-plugin ($plugin is copy, $namespace? is copy) {
  my $plug = $.parent.loadPlugin($plugin, :$namespace, :prefix($.plugns));
  $plug.plugns = $.plugns;
  self.add-attribute($namespace, $plug);
}

