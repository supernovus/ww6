use Websight;

class Websight::Metadata does Websight;

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    my $content = $.parent.content;
    my $name = $.namespace;
    my $string = "\\<$name\\>(.*?)\\<\\/$name\\>";
    my $block = self.matcher($string);
    say "We're going to look for '$string'" if $debug;
    if $content ~~ $block {
        say "It matched!" if $debug;
        my $definition = ~$0;
        $.parent.loadMetadata($definition);
        say "Data loaded" if $debug;
        $content.=subst($block, '');
        $.parent.content =  $content;
    }
}

