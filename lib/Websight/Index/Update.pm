use Websight;
use Perlite::Match;

class Websight::Index::Update does Websight;

method processPlugin (%opts?) {
    if not $.parent.req.get('INDEX') {
        return;
    }
    my $config = self.getConfig(:type(Hash));
    if ! $config { return; }
    my $file = $config.has('data', :notempty, :return);
    if ! $file { return; }
    my $index = slurp $.parent.findFile($file);
    my $path = $.parent.uri;
    my $elements = $config.has('elements', :defined, :type(Array), :return);
    my $getsnippet = $config.has('snippet', :true);

    ## First, delete any existing entries.
    my $exist = matcher("^^ \\- \\n <.ws> path\\: <.ws> '$path' \\n .*? (^^\\-|\$)");
    $index.=subst($exist, { $_[0] });

    ## Now, let's add the new entry.
    my $newcontent = "-\n";
    $newcontent ~= "  path: $path\n";
    for @($elements) -> $element {
        my $value = $.parent.metadata<page>.has($element, :defined, :return);
        if defined $value {
            if $value ~~ Array {
                $value = '[' ~ $value.join(',') ~ ']';
            }
            $newcontent ~= "  $element: $value\n";
        }
    }

    if $getsnippet {
        if $.parent.content ~~ /\<div class\=\"snippet\"\>(.*?)\<\/div\>/ {
            my $snippet = "  content: |\n$0";
            $snippet.=subst("\n", "\n    ", :global);
        }
    }

    $newcontent ~= $index;

    my $savefile = open $file, :w;
    $savefile.print: $newcontent;
    $savefile.close;

}

