use Perlite::Match;
use Perlite::Math :num;

module Perlite::Parser;

sub parseTags (
    $content is copy, 
    $data, 
    :$name is copy, 
    :$clean,
    :$trim=0,
    :$sep=",",
) is export(:DEFAULT) {
    my $debug = 0; 
    say "Entered parseTags, name: '$name'" if $debug;
    if $data ~~ Hash {
        say "is Hash" if $debug;
        for $data.kv -> $key, $val is copy {
            say "Element: $key" if $debug;
            if $val ~~ Array | Hash {
                $content = parseTags(
                    $content, $val, 
                    :name("$name.$key"), :trim($trim), :sep($sep),
                );
                if $val ~~ Array {
                    $val = +@($val);
                }
                elsif $val ~~ Hash {
                    $val = 'HASH{}';
                }
            }
            #my $block = matcher("\\<$name\\.$key\\/?\\>[.*?\\<\\/$name\\.$key\\>"]?);
            my $block = matcher("\\<$name\\.$key\\/?\\>");
            $content.=subst($block, $val, :global);
            my $ifblock = matcher("\\\$ $name\\.$key");
            $content.=subst($ifblock, "\"$val\"", :global);
            my $tagblock = matcher("'%' $name\\.$key");
            ## TODO: This should urlencode the var properly.
            $content.=subst($tagblock, $val.trans(' ' => '+'), :global);
        }
    }
    elsif $data ~~ Array {
        say "is Array" if $debug;
        my $block = matcher("\\<$name\\>(.*?)\\<\\/$name\\>");
        if $content ~~ $block {
            say "Matched!" if $debug;
            my $newcontent = '';
            my $snippet = ~$0;
            if $trim +& 1 {
                say "Trimming the frontend" if $debug;
                $snippet.=subst(/^\n/, '');
            }
            if $trim +& 2 {
                say "Trimming the backend" if $debug;
                $snippet.=subst(/\n$/, '');
            }
            if $trim +& 4 {
                say "Trimming the leading space" if $debug;
                $snippet.=subst(/^\s*/, '');
            }
            my $count = 0;
            for @($data) -> $repl is copy {
                if not $repl ~~ Hash { ## Recurse items MUST be hashes. 
                    my %hash;
                    %hash<ITEM> = $repl;
                    $repl = %hash;
                }
                my $rowtype = Perlite::Math::numType $count;
                if $count < $data.end {
                    $repl<SEP> = $sep;
                }
                else {
                    $repl<SEP> = '';
                }
                $repl<LAST> = $data.end;
                $repl<ROW> = $rowtype;
                $repl<ID> = $count++;
                $newcontent ~= parseTags(
                    $snippet, $repl, 
                    :name($name), :trim($trim), :sep($sep),
                );
            }
            $content.=subst($block, $newcontent, :global);
        }
    }
    if $clean {
        say "We've gone to the cleaners." if $debug;
        #my $recurseclean = matcher("\\<$name\\.(.*?)\\>.*?\\<\\/$name\\.$0\\>");
        #say "recurseclean: " ~ $recurseclean.WHAT;
        #$content.=subst($recurseclean, '', :global);
        my $clean = matcher("\\<$name\\..*?\\>");
        say "clean: " ~ $clean.WHAT if $debug;
        $content.=subst($clean, '', :global);
        my $ifclean = matcher("(\\\$|'%') $name\\.[\\w|\\.]+");
        say "Ifclean: " ~ $ifclean.WHAT if $debug;
        $content.=subst($ifclean, {
            if $_[0] eq '$' { '""'; }
            else { '' }
        }, :global);
    }
#    my $df = open './debug.txt', :w;
#    $df.say: $content;
#    $df.close;
    return $content;
}

