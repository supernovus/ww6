use Websight;

class Websight::Lighter does Websight;

use Hash::Has;

has $.opts      is rw = {};
has $.defcont   is rw = 'Index';
has $.defmethod is rw = 'index';  ## Controller.handle_index();
has $.errmethod is rw = 'error';  ## Controller.handle_error();
has $.outmethod is rw = 'output'; ## Controller.output();
has $.premethod is rw = 'prepare'; ## Controller.prepare();
has $.plugns    is rw = 'Plugins::';
has $.contns    is rw = 'Controllers::';
has $.modns     is rw = 'Models::';
has $.viewdir   is rw = 'views';
has $.classdir  is rw = 'classes';

has $!fallthrough is rw = False;

## Controllers MUST start with a capital letter, and have NO OTHER capital
## letters in their name. Handler methods inside controllers MUST start with
## 'handle_' and MUST be in all lowercase.
## The default controller is Controllers::Index, the default handler is
## handle_index(). The default error handler is handle_error().
## The output method is NOT a handler, it is a filter. If it exists in your
## controller, it will be passed the existing output and can process it in
## any way, including replacing it entirely. If it exists, it WILL be called.
## Unlike handlers, the output method does not start with handle_, it's called
## directly as specified.

## Models are currently implemented as being identical to Plugins, except that
## the load-model() method uses the Models:: namespace instead of Plugins::
## You can use anything you want as a class. If you want, you can include the
## WW::Plugin role to make your model extendable too.

method processPlugin ($default_opts) {
  my $defopts = {};
  if (defined $default_opts && $default_opts ~~ Hash) {
    $defopts = $default_opts;
  }
  $.opts = self.getConfig(:type(Hash), :default($defopts));

  self!set-opt($.defcont,   'default-controller');
  self!set-opt($.defmethod, 'default-handler');
  self!set-opt($.errmethod, 'error-handler');
  self!set-opt($.outmethod, 'output-method');
  self!set-opt($.plugns,    'plugin-namespace');
  self!set-opt($.contns,    'controller-namespace');
  self!set-opt($.modns,     'model-namespace');
  self!set-opt($.viewdir,   'view-folder');
  self!set-opt($.classdir,  'class-folder');

  self!set-opt($!fallthrough, 'fallthrough');

  ## First off, let's find the classes dir and add it to the @*INC;
  my $classdir = $.parent.findFile($.classdir, :dir);
  if (!$classdir) { return; } ## Cannot continue without a classdir.
  @*INC.unshift: $classdir; ## Add it to the @*INC, at the beginning.

  my $controller;
  my $handler = $.defmethod;

  ## Get parameters, ignoring leading, following and duplicate / marks.
  my @parameters = $.parent.path.split('/').grep({ $_ !~~ /^$/});
  if (@parameters.elems > 0) {
    my $name = '';
    while (@parameters.elems > 0) {
      my $path = @parameters.shift;
      if ($name ne '') { $name ~= '::'; }
      $name ~= $path.lc.ucfirst;
      my $class = self.load-controller($name);
      if ($class) {
        $controller = $class;
        last;
      }
    }
    if (@parameters.elems > 0) {
      my $path = @parameters.shift;
      $handler = $path.lc;
    }
    if ! $controller {
      if ($!fallthrough) { return; }
      $controller = self!default-controller();
      $handler = $.errmethod;
    }
  }
  else {
    if ($!fallthrough) { return; }
    $controller = self!default-controller();
  }

  my $content;

  ## First off, run any prep stuff.
  if $controller.can($.premethod) {
    $controller."{$.premethod}"();
  }

  ## Now let's get the content.
  if $controller.can-handle($handler) {
    $content = $controller.call-handler($handler, |@parameters);
  }
  elsif ($handler ne $.errmethod && $controller.can-handle($.errmethod)) {
    $content = $controller.call-handler($.errmethod);
  }
  else {
    if ($!fallthrough) { return; }
    $controller = self!default-controller();
    $handler = $.errmethod;
    if $controller.can-handle($handler) {
      $content = $controller.call-handler($handler);
    }
    else {
      die "default controller is missing a '$handler' method.";
    }
  }

  ## Finally, process the output if there is an output filter method.
  if $controller.can($.outmethod) {
    $content = $controller."{$.outmethod}"($content);
  }

  $.parent.content = $content;
}

method !default-controller() {
  my $class = self.load-controller($.defcont);
  if defined $class {
    return $class;
  }
  else {
    die "Could not load default controller '{$.defcont}'";
  }
}

method !set-opt($opt is rw, $key) {
  my $value = hash-has($.opts, $key, :notempty, :return);
  if defined $value { $opt = $value; }
}

method load-controller ($name) {
  my $namespace; ## Needed hackery until I fix how namespace works.
  my $controller = $.parent.loadPlugin($name, :$namespace, :prefix($.contns), :try);
  if defined $controller {
    $controller.plugns  = $.plugns;
    $controller.modns   = $.modns;
    $controller.viewdir = $.viewdir;
    return $controller;
  }
  else {
    return Nil;
  }
}

