module Perlite::Match;

## A workaround for Rakudo's bug with variables in regexes.
sub matcher ($regex_string) is export(:DEFAULT) {
    ## The newest Rakudo shouldn't need this workaround anymore.
    #my $matcher = eval("/$regex_string/");
    #return $matcher;
    return /$regex_string/;
}

