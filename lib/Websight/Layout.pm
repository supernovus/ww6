use Websight::XML;

class Websight::Layout is Websight::XML;

method processPlugin ($opts?) {
    my $debug = $.parent.debug;
    say "We're in Template plugin" if $debug;
    my $template = self.getConfig(:type(Str)) // $opts;
    if ! $template { return; }
    say "Our template is $template" if $debug;
    self.make-xml;
    ## We are overriding the layout configuration.
    ## Instead of a string, it's now going to be a Hash.
    my %layoutconf = {
      'template' => $template,
      'content'  => $.parent.content.root.nodes;
    };
    $.parent.metadata<layout> = %layoutconf;
    ## Unlike URL requests, templates must have the extention specified.
    my $file = $.parent.findFile($template);
    if $file {
        my $content = slurp $file;
        $.parent.content = Exemel::Document.parse($content);
        ## Make sure your layout template has a place to put the
        ## $.parent.metadata<layout><content> (tal:replace="layout/content")
        ## The original content will be inserted into it.
    }
}

