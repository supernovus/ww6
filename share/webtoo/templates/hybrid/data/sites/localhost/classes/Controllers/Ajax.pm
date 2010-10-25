use WW::Controller;
use WW::Controller::JSON;

class Controllers::Ajax does WW::Controller does WW::Controller::JSON;

## Since this example template is using the Flower Websight plugin, we
## need to tell flower NOT to parse stuff when this is loaded.
method prepare {
  $.parent.metadata<flower><skip> = True;
}

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

