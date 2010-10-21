use Websight;

class Websight::Lighter does Websight;

use Hash::Has;

has $.opts      is rw = {};
has $.defcont   is rw = 'Index';
has $.defmethod is rw = 'index';  ## Controller.handle_index();
has $.errmethod is rw = 'error';  ## Controller.handle_error();
has $.outmethod is rw = 'output'; ## Controller.output();
has $.plugns    is rw = 'Plugins::';
has $.addns     is rw = 'Addons::';
has $.contns    is rw = 'Controllers::';
has $.modns     is rw = 'Models::';
has $.viewdir   is rw = 'views';
has $.classdir  is rw = 'classes';


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
## A simple role called WW::Model will be available, which will allow  you to
## use any database model you want. Additionally, WW::Model::Table will be
## available in a later release, and will offer a simple to use model (similar
## to, but entirely unlike ActiveRecord, see docs/Model-Table.txt for details.)

method processPlugin ($default_opts = {}) {
  $.opts = self.getConfig(:type(Hash), :default($default_opts));

  self!set-opt($.defcont,   'default-controller');
  self!set-opt($.defmethod, 'default-handler');
  self!set-opt($.errmethod, 'error-handler');
  self!set-opt($.outmethod, 'output-method');
  self!set-opt($.plugns,    'plugin-namespace');
  self!set-opt($.addns,     'addon-namespace');
  self!set-opt($.contns,    'controller-namespace');
  self!set-opt($.modns,     'model-namespace');
  self!set-opt($.viewdir,   'view-folder');
  self!set-opt($.classdir,  'class-folder');

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
      $controller = self!default-controller();
      $handler = $.errmethod;
    }
  }
  else {
    $controller = self!default-controller();
  }

  my $content;

  ## Okay, now that we've found the controller, lets use it.
  if $controller.can-handle($handler) {
    $content = $controller.call-handler($handler, |@parameters);
  }
  elsif ($handler ne $.errmethod && $controller.can-handle($.errmethod)) {
    $content = $controller.call-handler($.errmethod);
  }
  else {
    $controller = self!default-controller();
    $handler = $.errmethod;
    if $controller.can-handle($handler) {
      $content = $controller.call-handler($handler);
    }
    else {
      die "default controller is missing a '$handler' method.";
    }
  }

  if $controller.can($.outmethod) {
    $content = $controller."{$.outmethod}"($content);
  }

  $.parent.content = $content;
}

method !default-controller() {
  my $class = self.load-controller($.defcont);
  if $class {
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
  my $controller = $.parent.loadPlugin($name, :prefix($.contns), :try);
  if defined $controller && $controller.does('WW::Controller') {
    $controller.plugns  = $.plugns;
    $controller.addns   = $.addns;
    $controller.modns   = $.modns;
    $controller.viewdir = $.viewdir;
    return $controller;
  }
}

