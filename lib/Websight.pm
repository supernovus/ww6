role Websight;

use Perlite::Hash;

has $.parent is rw;
has $.namespace is rw;

method getConfig (:$type) {
    return hash-has($.parent.metadata, $.namespace, :type($type), :return);
}

method saveConfig ($config) {
    $.parent.metadata{$.namespace} = $config;
}

## A method to call plugins from plugins using a spec from rules.
method callPlugin ($spec, $command=$.parent.defCommand, :$opts is copy) {
    if $spec ~~ Array {
        for $spec -> $subspec {
            $.parent.callPlugin($subspec, :$command, :opts($opts));
        }
        return;
    }
    else {
        $.parent.callPlugin($spec, :$command, :opts($opts));
    }
}

