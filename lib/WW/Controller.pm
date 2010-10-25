use WW::Plugin;

role WW::Controller does WW::Plugin;

has $.viewdir is rw = 'views';

## load-view does NOT parse the template, it just loads it.
## You will need to use another Websight Plugin such as Flower
## to parse it. If you want to have parsing inside of Lighter,
## you can add a role such as WW::Controller::Flower which adds
## a flower-view() method which you would call INSTEAD of load-view().
method load-view($template) {
  my $viewfile = $.parent.findFile($.viewdir~'/'~$template);
  if $viewfile {
    return slurp($viewfile);
  }
  else {
    return;
  }
}

## can-handle: does this controller have a specific handler?
method can-handle ($handler) {
  self.can("handle_$handler");
}

## call-handler: call the specified handler, with given parameters.
method call-handler ($handler, *@parameters) {
  self."handle_$handler"(|@parameters);
}

