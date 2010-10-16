role Websight;

use Hash::Has;

has $.parent is rw;
has $.namespace is rw;

method getConfig (:$type, :$default) {
    return hash-has($.parent.metadata, $.namespace, :$type, :$default, :return);
}

method saveConfig ($config) {
    $.parent.metadata{$.namespace} = $config;
}

