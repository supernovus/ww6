use Websight;
use Perlite::Parser;
use Perlite::Parser::Conditional;

class Websight::WTML does Websight;

# This plugin must be called AFTER any others that call the
# Perlite::Parser library, IF there are <if> statements using
# tags of those types. Because WTML replaces the Conditional plugin
# from ww5, any if statements using tags, must have been parsed already.

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    say "Entered WTML plugin" if $debug;
    my %config = self.getConfig(:type(Hash)) // %opts;
    my $content = $.parent.content;
    if hash-has(%config, 'comments', :true) {
        $content.=subst(/^^\#.*?\n/, '', :global);
    }
    if hash-has(%config, 'tags') && %config<tags> ~~ Array {
        say "We've got tags!" if $debug;
        for @(%config<tags>) -> $tagset {
            say "Looking up '$tagset'" if $debug;
            my $tags = hash-has($.parent.metadata, $tagset, :defined, :return);
            say "Tags is " ~ $tags.WHAT if $debug;
            if not defined $tags { next; }
            $content = parseTags($content, $tags, :name($tagset), :clean(1));
        }
    }
    if hash-has(%config, 'if', :true) {
        $content = parseIf($content);
    }
    $.parent.content = $content;
}

