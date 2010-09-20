use Websight::XML;

class Websight::Layout is Websight::XML;

method processPlugin ($opts?) {
    my $debug = $.parent.debug;
    say "We're in Template plugin" if $debug;
    my $template = self.getConfig(:type(Str)) // $opts;
    if ! $template { return; }
    say "Our template is $template" if $debug;
    self.make-xml;
    $.parent.metadata<content> = $.parent.content.root.nodes;
    my $file = $.parent.findFile($template);
    if $file {
        my $content = slurp $file;
        $.parent.content = Exemel::Document.parse($content);
        ## Make sure your layout template has a content/replace for 'content'.
        ## The original content will be inserted into it.
    }
}

