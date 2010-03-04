use Perlite::Match;
use Perlite::Math :num;

module Perlite::Parser;

sub parseTags ($content is copy, $data, :$name is copy) is export(:DEFAULT) {
    my $debug = 0; 
    say "Entered parseTags" if $debug;
    if $data ~~ Hash {
        for $data.kv -> $key, $val is copy {
            if $val ~~ Array | Hash {
                $content = parseTags($content, $val, :name("$name.$key"));
                if $val ~~ Array {
                    $val = +@($val);
                }
                elsif $val ~~ Hash {
                    $val = '_HASH_';
                }
            }
            my $block = matcher("\\<$name.$key\\/*\\>");
            $content.=subst($block, $val, :global);
            my $ifblock = matcher("(\\<[else ]?if .*?)$name\\.$key(.*?\\>)");
            $content.=subst($ifblock, { $_[0] ~ "\"$val\"" ~ $_[1] }, :global);
        }
    }
    elsif $data ~~ Array {
        my $block = matcher("\\<$name\\>(.*?)\\<\\/$name\\>");
        if $content ~~ $block {
            my $newcontent = '';
            my $snippet = ~$0;
            my $count = 0;
            for @($data) -> $repl is copy {
                if not $repl ~~ Hash { next; } ## We only accept hashes.
                my $rowtype = Perlite::Math::numType $count;
                $repl<ROW> = $rowtype;
                $repl<ID> = $count++;
                $newcontent ~= parseTags($snippet, $repl, :name($name));
            }
            $content.=subst($block, $newcontent, :global);
        }
    }
    return $content;
}

