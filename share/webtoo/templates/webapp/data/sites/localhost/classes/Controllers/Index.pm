use WW::Controller;

class Controllers::Index does WW::Controller;

method handle_index (*@opts) {
  self.view('index.xhtml');
}

method handle_error (*@opts) {
  self.view('error.xhtml');
}

