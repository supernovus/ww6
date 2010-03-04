use Websight;
use Perlite::Math :num;

class Websight::WTML does Websight;

method processPlugin (%opts?) {
    my $debug = 1; #$.parent.debug;
    say "Entered WTML plugin" if $debug;
    my %config = self.getConfig(:type(Hash)) // %opts;
    my $content = $.parent.content;
    # TODO: Port the full Perlite::Parser::* to Perlite::Markover
    # Add in the new features for if statements. Then, presto, WTML is born!
    if %config.has('comments', :true) {
        $content.=subst(/^^#.*?$$/, '', :global);
    }
    if %config.has('tags') && %config<tags> ~~ Array {
        say "We've got tags!" if $debug;
        for @(%config<tags>) -> $tagset {
            say "Looking up '$tagset'" if $debug;
            my $tags = $.parent.metadata.has($tagset, :defined, :return);
            say "Tags is " ~ $tags.WHAT if $debug;
            if not defined $tags { next; }
            $content = self!parseTags($content, $tags, :name($tagset));
            my $clean = self.matcher("\\<$tagset..*?\\>");
            $content.=subst($clean, '', :global);
        }
    }
    if %config.has('if', :true) {
        $content = self!parseIf($content);
    }
    $.parent.content = $content;
}

method !parseTags ($content is copy, $data, :$name is copy) {
    my $debug = 1; #$.parent.debug;
    say "Entered parseTags" if $debug;
    if $data ~~ Hash {
        for $data.kv -> $key, $val {
            if $val ~~ Array | Hash {
                $content = self!parseTags($content, $val, :name("$name.$key"));
                if $val ~~ Array {
                    $val = +@($val);
                }
                elsif $val ~~ Hash {
                    $val = '_HASH_';
                }
            }
            my $block = self.matcher("\\<$name.$key\\/*\\>");
            $content.=subst($block, $val, :global);
            my $ifblock = self.matcher("\\<if .*?$name\\.$key.*?\\>");
            $content.=subst($ifblock, "\"$val\"", :global);
        }
    }
    elsif $data ~~ Array {
        my $block = self.matcher("\\<$name\\>(.*?)\\<\\/$name\\>");
        if $content ~~ $block {
            my $newcontent = '';
            my $snippet = ~$0;
            my $count = 0;
            for @($data) -> $repl {
                if not $repl ~~ Hash { next; } ## We only accept hashes.
                my $template = $snippet;
                my $rowtype = Perlite::Math::numType $count;
                $repl<ROW> = $rowtype;
                $repl<ID> = $count++;
                $template.=self!parseTags($template, $repl, :name($name));
                $newcontent ~= $template;
            }
            $content.=subst($block, $newcontent, :global);
        }
    }
    return $content;
}

