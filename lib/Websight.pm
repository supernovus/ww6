role Websight;

has $.parent is rw;
has $.namespace is rw;

method getConfig (:$type) {
    return $.parent.metadata.has($.namespace, :type($type), :return);
}

## A workaround for Rakudo's bug with variables in regexes.
method matcher ($regex_string) {
    my $matcher = eval("/$regex_string/");
    return $matcher;
}

