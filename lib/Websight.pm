use Perlite::Match;

role Websight;

has $.parent is rw;
has $.namespace is rw;

method getConfig (:$type) {
    return $.parent.metadata.has($.namespace, :type($type), :return);
}

## A method to call plugins from plugins using a spec from rules.
method callPlugin ($spec, $command='processPlugin', :%opts is copy) {
    if $spec ~~ Array {
        for $spec -> $subspec {
            $.parent.callPlugin($subspec, $command, :opts(%opts));
        }
        return;
    }
    else {
        $.parent.callPlugin($spec, $command, :opts(%opts));
    }
}

