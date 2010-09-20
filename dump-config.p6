#!/usr/bin/env perl6

BEGIN { @*INC.push: './lib' }

use Perlite::Data::JSON;

my $c = Perlite::Data::JSON.make(:file(@*ARGS[0]));

say $c.perl;

