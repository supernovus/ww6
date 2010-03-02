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

## A method to call plugins from plugins using a spec from rules.
method callPlugin ($spec, $command='processPlugin', *%opts) {
    my $plugin;
    if $spec ~~ Array {
        for $spec -> $subspec {
            self!callPlugin($subspec, $command, %opts);
        }
        return;
    }
    elsif $spec ~~ Hash {
        if $spec.has('name', :notempty) {
            $plugin = $spec<name>;
        }
        if $spec.has('opts', :defined, :type(Hash)) {
            %opts = $spec<opts>;
        }
        if $spec.has('command', :notempty) {
            $command = $spec<command>;
        }
    }
    elsif $spec ~~ Str {
        $plugin = $spec;
    }
    else {
        $*ERR.say: "Plugin name was not specified in Websight.callPlugin.";
        return;
    }

    $.parent.callPlugin($plugin, $command, %opts);
}

