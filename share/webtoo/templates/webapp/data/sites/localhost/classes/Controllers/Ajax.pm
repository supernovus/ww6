use WW::Controller;
use AJAX::JSON;

class Controllers::Ajax does WW::Controller does AJAX::JSON;

method handle_error (*@opts) {
  return '';
}

method handle_user (*@opts) {
  my $user = 'default';
  if (@opts.elems > 0) {
    $user = @opts[0];
  }
  my $sid = 1000.rand.Int;
  my %data = {
    'user' => $user,
    'sid'  => $sid,
    'home' => "/home/$sid/$user",
  }
  return %data;
}

