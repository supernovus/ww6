module Perlite::Time;

sub formatTime ($timestamp, $format='ISO') is export(:DEFAULT) {
    $*ERR.say: 'Warning: formatTime not implemented yet.';
    return $timestamp;
}

