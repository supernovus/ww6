use Websight;

role WW::ChainLoader does Websight;

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

