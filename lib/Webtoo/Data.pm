role Webtoo::Data;
# The Webtoo Data/Definition Language (WTDL)
# Kinda based on YAML, in a loose sort of way.
# There will be support for wtdlc files, which will
# have pre-compiled Perl definitions instead of WTDL.
# But that functionality is not ready yet.
#
# It supports various forms of appending/merging/deleting, etc.

method parseDataFile($file, $data is copy) {
    my @definition = lines $file;
    return self.parseData(@definition, $data);
}

method parseData (@definition is rw, $data is copy, $level=0, @cache) {
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
                    if not $data{$element} ~~ Hash {
                        $data{$element} = {};
                    }
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
        if $line ~~ /:s (\w+)\: / { ## Any hash assignment
            $element = $0;
            if not $data ~~ Hash {
                $data = {};
            }
        }
        given $line {
            when /:s ^ (\+|\-|\<|\>) (.*?) $/ { ## Array assignment
                if not $data ~~ Array {
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
            when /:s (\w+)\: $/ {
                $element = $0;
            }
            when /:s (\w+)\: \~ $/ {
                $element = $0;
                $data.delete($element); # Death to element.
            }
            when /:s (\w+)\: (.?)\[(.+?)\] $/ {
                $element = $0;
                my $comp = $1;
                my $arraystring = $2;
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
            when /:s (\w+)\: (.+?) $/ {
                $element = $0;
                $data{$element} = ~$1;
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

