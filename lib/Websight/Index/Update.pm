use Websight::XML;

class Websight::Index::Update is Websight::XML;

method saveIndex($index, $file) {
    my $fh = open $file, :w;
    $fh.say: $.parent.metadata.parser.encode($index);
    $fh.close;
}

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
    my $index = $.parent.metadata.parseFile($file);
    my $path = $.parent.uri.split('?', 2)[0];
    say "URI: $path" if $debug;
    my $elements = hash-has($config, 'elements', :defined, :type(Array), :return);
    my $getsnippet = hash-has($config, 'snippet', :true);

    ## First, delete any existing entries.
    loop (my $i=0; $i < $index.elems; $i++) {
      if $index[$i]<path> eq $path {
        $index.splice($i, 1);
        last;
      }
    }

    ## Now, let's add the new entry.
    my %newpage;
    %newpage<path> = $path;
    for @($elements) -> $element {
        my $value = hash-has($.parent.metadata<page>, $element, :defined, :return);
        if defined $value {
            %newpage{$element} = $value;
        }
    }

    if $getsnippet {
        self.make-xml;
        my $snippet = $.parent.content.elements(:id<snippet>);
        if $snippet {
          %newpage<snippet> = $snippet;
        }
    }

    $index.unshift: %newpage;

    self.saveIndex($index, $file);

}

