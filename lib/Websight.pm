role Websight;

# Note: We assume that the Webtoo object has at least the Plugins role loaded,
# and for getConfig/saveConfig that it has a Metadata role loaded as well.

use Hash::Has;

has $.parent is rw;
has $.namespace is rw;

method getConfig (:$type, :$default) {
    return hash-has($.parent.metadata, $.namespace, :$type, :$default :return);
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

