use WW::Controller;

## Note: This is nearly identical to the Controllers::Page from the
## 'webapp' template, but for another example of how to do things, instead
## of calling Flower using the WW::Controller::Flower role, we're letting
## the Flower Websight plugin handle output.
## So, all flower-view() methods in this have been replaced with load-view().
## Honestly, I think if you are going to use Lighter, using the role is a
## better idea than using the Flower Websight plugin, but hey, all the power
## is in your hands.

class Controllers::Page does WW::Controller;

method handle_index (*@opts) {
  self.data<page><title> = 'Index page';
  self.data<page><message> = 'You have reached an example page.';
  self.load-view('page.xhtml');
}

method handle_error (*@opts) {
  self.data<page><title> = 'Error page';
  self.data<page><message> = 'The page you requested doesn\'t exist.';
  self.load-view('page.xhtml');
}

method handle_example (*@opts) {
  self.data<page><title> = 'Example page';
  self.data<page><message> = 'The example page has the following options: '~
    @opts.join(', ');
  self.load-view('page.xhtml');
}

