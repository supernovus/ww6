use WW::Controller;
use WW::Controller::Flower;

class Controllers::Page does WW::Controller does WW::Controller::Flower;

method handle_index (*@opts) {
  self.data<page><title> = 'Index page';
  self.data<page><message> = 'You have reached an example page.';
  self.flower-view('page.xhtml');
}

method handle_error (*@opts) {
  self.data<page><title> = 'Error page';
  self.data<page><message> = 'The page you requested doesn\'t exist.';
  self.flower-view('page.xhtml');
}

method handle_example (*@opts) {
  self.data<page><title> = 'Example page';
  self.data<page><message> = 'The example page has the following options: '~
    @opts.join(', ');
  self.flower-view('page.xhtml');
}

