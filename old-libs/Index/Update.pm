use Websight;
use Perlite::Match;

class Websight::Index::Update does Websight;

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    say "Entered Index Update plugin" if $debug;
    if not $.parent.req.get('INDEX') {
        say "Skipping, no INDEX variable found" if $debug;
        return;
    }
    my $config = self.getConfig(:type(Hash));
    if ! $config { return; }
    my $fileSpec = hash-has($config, 'data', :notempty, :return);
    if ! $fileSpec { return; }
    say "Passed the config tests." if $debug;
    my $file  = $.parent.findFile($fileSpec);
    if ! $file { return; }
    say "The index exists." if $debug;
    my $index = slurp $file;
    my $path = $.parent.uri.split('?', 2)[0];
    say "URI: $path" if $debug;
    my $elements = hash-has($config, 'elements', :defined, :type(Array), :return);
    my $getsnippet = hash-has($config, 'snippet', :true);

    ## First, delete any existing entries.
    my $exist = matcher("^^ \\- \\n <.ws> path\\: <.ws> '$path' \\n .*? (^^\\-|\$)");
    $index.=subst($exist, { $_[0] });

    ## Now, let's add the new entry.
    my $newcontent = "-\n";
    $newcontent ~= "  path: $path\n";
    for @($elements) -> $element {
        my $value = hash-has($.parent.metadata<page>, $element, :defined, :return);
        if defined $value {
            if $value ~~ Array {
                $value = '[' ~ $value.join(',') ~ ']';
            }
            $newcontent ~= "  $element: $value\n";
        }
    }

    if $getsnippet {
        if $.parent.content ~~ /:s \<div class \= \"snippet\" \>(.*?)\<\/div\>/ {
            say "Found a specified div snippet." if $debug;
            my $snippet = "  content: |\n$0";
            $snippet.=subst("\n", "\n    ", :global);
            $newcontent ~= $snippet ~ "\n";
        }
    }

    $newcontent ~= $index;

    my $savefile = open $file, :w;
    $savefile.print: $newcontent;
    $savefile.close;

}
