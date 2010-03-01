role Websight;

has $.parent is rw;
has $.namespace is rw;

method getConfig {
    return $.parent.metadata{$.namespace};
}

## A workaround for Rakudo's bug with variables in regexes.
method matcher ($regex_string) {
    return eval("$regex_string");
}

