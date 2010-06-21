role Webtoo::Data;
# The Webtoo Data/Definition Language (WTDL)
# Kinda based on YAML, in a loose sort of way.
# There will be support for wtdlc files, which will
# have pre-compiled Perl definitions instead of WTDL.
# But that functionality is not ready yet.
#
# It supports various forms of appending/merging/deleting, etc.

method parseDataFile(
    $file, 
    $data is copy, 
    :@path=%.metadata<root>,
    :@cache,
) {
    my $config = self.findFile($file, :path(@path));
    if $config {
        my @definition = lines $config;
        return self.parseData(@definition, $data, 0, @cache);
    }
    else {
        self.err: "Data file '$file' not found in any root path.";
        return {};
    }
}

method parseData (
    @definition is rw, 
    $data is copy, 
    $level=0, 
    $multiline is rw =0,
    @cache?,
) {
    my $debug = $.debug;
    my $element   = '_';
    my $arrayop   = '';

    say "We are in parseData" if $debug;

    if $multiline == 2 {
        $data = '';        ## Replace $data with an empty string.
    }

    while defined (my $line = @definition.shift) {
        say "Parsing line: $line" if $debug;
        if $line ~~ /:s ^ \#/ | /:s ^ $ / { 
            say "Skipping." if $debug;
            ## Kill comments and blank lines.
            next; 
        } 
        if $line ~~ /^(<.ws>)/ {
            my $space = $0.chars;
            if $level > $space {
                say "Leaving level $level with {$data.perl}" if $debug;
                ## Re-add this line, the previous call will want it.
                @definition.unshift: $line;
                return $data;
            }
            elsif $level < $space && $multiline < 2 {
                ## Advance to next level of multiline.
                if $multiline == 1 { $multiline = 2; }
                say "Found a nested level $space" if $debug;
                ## Re-add the line we're on, for nested processing.
                @definition.unshift: $line;
                if $data ~~ Array {
                    say "Processing nested array" if $debug;
                    my @localcache = @cache;
                    @localcache.push: $data;
                    my @arraydata = self.parseData(
                        @definition, $data, $space, @localcache, $multiline,
                    );
                    if $arrayop eq '+' | '<' {
                        $data.unshift: @arraydata;
                    }
                    else {
                        $data.push: @arraydata;
                    }
                }
                else {
                    my @localcache = @cache;
                    @localcache.push: $data;
                    $data{$element} = self.parseData(
                        @definition, 
                        $data{$element}, 
                        $space, 
                        @localcache, 
                        $multiline,
                    );
                }
                ## Remove multiline setting if it had been set.
                $multiline=0;
                next;
            }
            else {
                ## Any further processing should be done with shortened
                #  lines, with no extra space on them.
                $line.=substr($level);
                if $multiline == 2 {
                    $data ~= $line ~ "\n";
                    next;
                }
            }
        }
        given $line {
            when /:s ^ \@include\: (.+?) $/ {
                my @includes = ~$0.split(',');
                my @path = @(%.metadata<root>);
                say "Include path: {@path.perl}" if $debug;
                if @cache && @cache[0] ~~ Hash && @cache[0]<root> {
                    say "We're using the local version" if $debug;
                    @path = @cache[0]<root>;
                }
                my @localcache = @cache;
                @localcache.push: $data;
                for @includes -> $include {
                    $data = self.parseDataFile(
                        $include, $data, :path(@path), :cache(@localcache),
                    );
                }
            }
            when /:s ^ (\+|\-|\<|\>) (.*?) $/ { ## Array assignment
                if not $data ~~ Array {
                    say "Data is not an array: " ~ $data.WHAT if $debug;
                    my @subarray;
                    if defined $data && not $data ~~ Hash {
                        @subarray.push: $data;
                    }
                    $data = @subarray;
                }
                $arrayop = $0;
                if ~$1 {
                    my $value = ~$1;
                    if $value ~~ /:s \| $/ {
                        $multiline = 1;
                        next; ## Let's gather lines.
                    }
                    if $value ~~ /:s \@ref\: (.+?) $/ {
                        $value = self!getDataRef(
                            ~$0, self!localCache($data, @cache),
                        );
                    }
                    say "Array assignment: '$value' using '$arrayop'" if $debug;
                    if $arrayop eq '+' | '<' {
                        $data.unshift: ~$value;
                    }
                    else {
                        $data.push: ~$value;
                    }
                }
            }
            regex hashKey { ^ ( .*? ) \: }
            when /:s <hashKey> / { ## Any hash assignment
                $element = ~$/<hashKey>[0];
                if not $data ~~ Hash {
                    $data = {};
                }
                continue; ## Make sure it continues!
            }
            when /:s <hashKey> \| $/ {
                $multiline = 1;
                next; ## Breakout!
            }
            when /:s <hashKey> \@ref\: (.+?) $/ {
                $data{$element} = self!getDataRef(
                    ~$0, self!localCache($data, @cache),
                );
            }
            when /:s <hashKey> (.?)\[(.+?)\] $/ {
                my $comp = $0;
                my $arraystring = $1;
                say "Setting array '$element', to '$arraystring', using '$comp'." if $debug;
                my @array = $arraystring.split(',');
                if $comp eq '~' {
                    $data{$element} = @array;
                }
                elsif $comp eq '+' | '<' {
                    if $data{$element} ~~ Array {
                        $data{$element}.unshift: @array;
                    }
                    else {
                        if defined $data{$element} {
                            @array.push: $data{$element};
                        }
                        $data{$element} = @array;
                    }
                }
                elsif $comp eq '-' { # Magical delete.
                    if $data{$element} ~~ Hash {
                        for @array -> $item {
                            $data{$element}.delete($item);
                        }
                    }
                    elsif $data{$element} ~~ Array {
                        for @array -> $item {
                            my $c=0;
                            for @($data{$element}) -> $subitem {
                                if $subitem ~~ $item {
                                    $data{$element}.splice($c, 1);
                                }
                                $c++;
                            }
                        }
                    }
                }
                else {
                    if $data{$element} ~~ Array {
                        $data{$element}.push: @array;
                    }
                    else {
                        if defined $data{$element} {
                            @array.unshift: $data{$element};
                        }
                        $data{$element} = @array;
                    }
                }
            }
            when /:s <hashKey> \~ $/ {
                $data.delete($element); # Death to element.
            }
            when /:s <hashKey> (.+?) $/ {
                $data{$element} = ~$0;
            }
        }
    }
    say "End of data with {$data.perl}" if $debug;
    return $data;
}

method !localCache ($data, @cache) {
    my @localcache;
    if @cache { 
        @localcache = @cache;
        if not @cache[*-1] ~~ $data {
            @localcache.push: $data;
        }
    }
    else { 
        @localcache.push: $data 
    }
    return @localcache;
}

method !getDataRef ($refs, @cache) {
    my $debug = $.debug;
    my $idata;
    if $refs ~~ /^(\.+)/ {
        my $back = $0.chars;
        $refs.=subst(/^\.+/, ''); ## Kill dots.
        $idata = @cache[*-$back];
    }
    else {
        $idata = @cache[0];
    }
    my @refs = $refs.split('.');
    for @refs -> $ref {
        print "- $ref " if $debug;
        if $idata ~~ Array {
            say "is an Array" if $debug;
            $idata = $idata[+$ref];
        }
        elsif $idata ~~ Hash {
            say "is a Hash" if $debug;
            $idata = $idata{~$ref};
        }
    }
    return $idata;
}

method loadMetadataFile ($file) {
    my $debug = $.debug;
    say "loadMetadataFile Called" if $debug;
    %.metadata = self.parseDataFile($file, %.metadata);
    say "loadMetadataFile Ended" if $debug;
}

multi method loadMetadata (@definition is rw) {
    %.metadata = self.parseData(@definition, %.metadata);
}

multi method loadMetadata (Str $definition) {
    my @definition = $definition.split("\n");
    self.loadMetadata(@definition);
}

