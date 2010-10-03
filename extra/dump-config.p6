#!/usr/bin/env perl6

use HashConfig::Magic;

my $c = HashConfig::Magic.make(:file(@*ARGS[0]));

say $c.perl;

