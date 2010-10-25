use WW::Controller;

class Controllers::Index does WW::Controller;

method handle_index (*@opts) {
  self.load-view('index.xhtml');
}

method handle_error (*@opts) {
  self.load-view('error.xhtml');
}

