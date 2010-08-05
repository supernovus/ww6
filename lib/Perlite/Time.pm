module Perlite::Time;

use DateTime::Utils;

sub rfc2822(DateTime $dt=DateTime.now) is export(:DEFAULT) {
    ## TODO: Put in %z when the patch is applied.
    strftime('%a, %d %b %Y %T %z', $dt);
}

