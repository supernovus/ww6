module Perlite::Match;

## A workaround for Rakudo's bug with variables in regexes.
sub matcher ($regex_string) is export(:DEFAULT) {
    my $matcher = eval("/$regex_string/");
    return $matcher;
}

