use Websight;

class Websight::Template does Websight;

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    say "We're in Template plugin" if $debug;
    my $template = self.getConfig(:type(Str));
    if ! $template { return; }
    say "We had a config" if $debug;
    my $ext = 'tmpl';
    if $template ~~ /\.(\w+)$/ {
        $ext = ~$0;
        $template.=subst(/\.\w+$/, '');
    }
    my $file = $.parent.findFile($template, :ext($ext));
    if $file {
        my $content = slurp $file;
        my $pagecontent = $.parent.content;
        $content.=subst(/\<content\>/, $pagecontent, :global);
        $.parent.content = $content;
    }
}

