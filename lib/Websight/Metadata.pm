use Websight;

class Websight::Metadata does Websight;

method processPlugin (%opts?) {
    my $content = $.parent.content;
    my $name = $.namespace;
    my $block = self.matcher("\<$name\>(.*?)\<\/$name\>");
    if $content ~~ $block {
        my $definition = ~$0;
        $.parent.loadMetadata($definition);
        $content.=subst($block, '');
        $.parent.content =  $content;
    }
}

