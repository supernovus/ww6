use Websight;

role WW::Plugin does Websight;

has $.plugns is rw = 'Plugins::';
has $.addns  is rw = 'Addons::';
has $.modns  is rw = 'Models::';

## A shortcut to the data. Let's you do:
## self.data<page><title> = 'My title';
method data () {
  return $.parent.metadata;
}

## A shortcut to the WebRequest object.
## Let's you do self.input.get('param');
method input () {
  return $.parent.req;
}

method add-attribute ($attrib, $value) { 
  my $role = eval('role { has $.'~$attrib~' is rw; }'); 
  self does $role; 
  self."$attrib"() = $value; 
}

method load-plugin (
  $plugin, :$namespace is copy, :$prefix=$.plugns, :$noadd
) {
  my $plug = $.parent.loadPlugin($plugin, :$namespace, :$prefix);
  $plug.plugns = $.plugns;
  $plug.addns  = $.addns;
  $plug.modns  = $.modns;
  if (!$noadd) {
    self.add-attribute($namespace, $plug);
  }
  return $plug;
}

method load-addon ($addon) {
  my $plug = $.parent.loadPlugin($addon, :prefix($.addns), :noload);
  self does $plug;
}

## Actually calls load-plugin, but with a different default namespace.
method load-model (
  $model, :$namespace is copy, :$prefix=$.modns, :$noadd
) {
  return self.load-plugin($model, :$prefix, :$namespace, :$noadd);
}

