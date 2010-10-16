use Websight;

role WW::Plugin does Websight;

has $.plugns is rw = 'Plugins::';
has $.addns  is rw = 'Addons::';

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

method load-plugin ($plugin, $namespace? is copy) {
  my $plug = $.parent.loadPlugin($plugin, :$namespace, :prefix($.plugns));
  $plug.plugns = $.plugns;
  $plug.addns  = $.addns;
  self.add-attribute($namespace, $plug);
}

method load-addon ($addon) {
  my $plug = $.parent.loadPlugin($addon, :prefix($.addns), :noload);
  self does $add;
}

