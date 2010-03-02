use Websight;

class Websight::Template does Websight;

method processPlugin (%opts?) {
    my $template = self.getConfig(:type(Str));
    if ! $template { return; }
    my $ext = 'tmpl';
    if $template ~~ /\.(\w+)$/ {
        $ext = ~$0;
        $template.=subst(/\.\w+$/, '');
    }
    my $file = $.parent.findFile($template, $ext);
    if $file {
        my $content = slurp $file;
        my $pagecontent = $.parent.content;
        $content.=subst(/\<content\>/, $pagecontent, :global);
        $.parent.content = $content;
    }
}

