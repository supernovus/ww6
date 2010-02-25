role Webtoo::Data;
# The Webtoo Data/Definition Language (WTDL)
# Kinda based on YAML, in a loose sort of way.
# There will be support for wtdlc files, which will
# have pre-compiled Perl definitions instead of WTDL.
# But that functionality is not ready yet.
#
# It supports various forms of appending/merging/deleting, etc.

method getRootPath (@path=%.metadata<root>) {
    return $.datadir ~ '/' ~ @path.join('/') ~ '/';
}

method parseDataFile($file, $data is copy, @path=%.metadata<root>) {
    my $config = self.getRootPath(@path) ~ $file ~ '.' ~ $.dlext;
    if $config ~~ :e {
        my @definition = lines $config;
        return self.parseData(@definition, $data);
    }
    else {
        die "Config file not found: $config";
    }
}

method parseData (@definition is rw, $data is copy, $level=0, @cache?) {
    my $element   = '_';
    my $arrayop   = '';
   
    say "We are in parseData" if $.debug;

    while defined (my $line = @definition.shift) {
        say "Parsing line: $line" if $.debug;
        if $line ~~ /:s ^ \#/ | /:s ^ $ / { 
            say "Skipping." if $.debug;
            ## Kill comments and blank lines.
            next; 
        } 
        if $line ~~ /^(<.ws>)/ {
            my $space = $0.chars;
            if $level > $space {
                say "Leaving level $level with {$data.perl}" if $.debug;
                ## Re-add this line, the previous call will want it.
                @definition.unshift: $line;
                return $data;
            }
            elsif $level < $space {
                say "Found a nested level $space" if $.debug;
                ## Re-add the line we're on, for nested processing.
                @definition.unshift: $line;
                if $data ~~ Array {
                    say "Processing nested array" if $.debug;
                    my @arraydata = self.parseData(
                        @definition, $data, $space, @cache,
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
                        @definition, $data{$element}, $space, @localcache,
                    );
                }
                next;
            }
            else {
                ## Any further processing should be done with shortened
                #  lines, with no extra space on them.
                $line.=substr($space);
            }
        }
        given $line {
            when /:s ^ \@include\: (.*?) $/ {
                my @includes = ~$0.split(',');
                my @path = %.metadata<root>;
                if @cache && @cache[0] ~~ Hash && @cache[0]<root> {
                    @path = @cache[0]<root>;
                }
                for @includes -> $include {
                    $data = self.parseDataFile($include, $data, @path);
                }
            }
            when /:s ^ (\+|\-|\<|\>) (.*?) $/ { ## Array assignment
                if not $data ~~ Array {
                    say "Data is not an array: " ~ $data.WHAT if $.debug;
                    my @subarray;
                    if defined $data && not $data ~~ Hash {
                        @subarray.push: $data;
                    }
                    $data = @subarray;
                }
                $arrayop = $0;
                if ~$1 {
                    my $value = $1;
                    say "Array assignment: '$value' using '$arrayop'" if $.debug;
                    if $arrayop eq '+' | '<' {
                        $data.unshift: ~$value;
                    }
                    else {
                        $data.push: ~$value;
                    }
                }
            }
            regex hashKey { ^ (\w+)\: }
            when /:s <hashKey> / { ## Any hash assignment
                $element = $/<hashKey>[0];
                if not $data ~~ Hash {
                    $data = {};
                }
                continue; ## Make sure it continues!
            }
            when /:s ^ \w+\: (.?)\[(.+?)\] $/ {
                my $comp = $0;
                my $arraystring = $1;
                say "Setting array '$element', to '$arraystring', using '$comp'." if $.debug;
                my @array = $arraystring.split(',');
                #@array>>.=chomp;
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
            when /:s ^ \w+\: \~ $/ {
                $data.delete($element); # Death to element.
            }
            when /:s ^ \w+\: (.+?) $/ {
                $data{$element} = ~$0;
            }
        }
    }
    say "End of data with {$data.perl}" if $.debug;
    return $data;
}

method loadMetadataFile ($file) {
    say "loadMetadataFile Called" if $.debug;
    %.metadata = self.parseDataFile($file, %.metadata);
    say "loadMetadataFile Ended" if $.debug;
}

method loadMetadata (@definition is rw) {
    %.metadata = self.parseData(@definition, %.metadata);
}

