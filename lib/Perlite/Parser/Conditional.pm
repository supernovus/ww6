use Perlite::Match;

grammar Perlite::Parser::Conditional::Grammar {
    rule TOP {
        | <ifTag> {*}     #= if
        | <elseIf> {*}    #= elsif
        | <elseTag> {*}   #= else
        | <closeIf> {*}   #= endif
    }
    rule ifTag { 
        \<if <ifStat> \> {*}
    }
    rule elseIf { 
        \<else <ifStat> \/*\> {*}
    }
    rule elseTag { 
        \<else \/*\> {*}
    }
    rule closeIf { 
        \<\/if\> {*} 
    }
    rule ifStat { 
        <ifCond> (<ifChain> <ifCond>)*
    }
    rule ifCond { 
        <ifOption>? <ifVar> ( <ifComp> <ifVar> )*
    }
    token ifVar { 
        '"'.*?'"'
    }
    token ifOption {
        | '!'          #= negate the match.
        | '?'          #= reserved for future use.
    }
    token ifComp { 
        | \=+
        | '!='
        | '~~'
        | 'gt'
        | 'lt'
        | 'gt='
        | 'lt='
    }
    token ifChain {
        | 'and'
        | 'or'
    }
}

class Perlite::Parser::Conditional::Parser {
    has $!level = 0;
    has @!match = 1; # First level always matches.

    method parseIf ($/) {
        ## Implement the actual parser.
        my $keep = self.parseTest($/<ifStat><ifCond>);
        my $count = +@($/<ifStat>);
        say "Count: $count";
        for @($/<ifStat>) -> $test {
            my $chain = ~$test<ifChain>;
            my $def   = $test<ifCond>;
            if $chain eq 'and' && !$keep { next; }
            $keep = self.parseTest($def);
        }
        self.setKeep($keep);
    }

    method parseTest ($test) {
        my $debug = 0;
        my $success = 1;
        my $failure = 0;
        my $options = $test<ifOption>;
        say "Options: $options";
        if $options && $options eq '!' {
            say "We found the negation";
            $success = 0;
            $failure = 1;
        }
        my $testvar = ~$test<ifVar>.subst('"', '', :global);
        say "** testvar: $testvar {$testvar.WHAT}" if $debug;
        my $hasComps = +@($test);
        say "Has comps: $hasComps";
        #my $compDef = $test<comp>;
        if ! $hasComps {
            # No comparisons were used. Check if the value is True.
            # False is an empty string or the number 0.
            if $testvar { return $success }
            else { return $failure } 
        }
        if $testvar eq '' { return 0 } # Always fail on empty strings.
        my $pass = $success;
        say @($test).perl;
        for @($test) -> $comps {
            my $comp = ~$comps<ifComp>;
            my $var  = ~$comps<ifVar>.subst('"', '', :global);
            my &fails = -> { $pass = $failure; if !$pass { last; } };
            say "** var: $var {$var.WHAT}" if $debug;
            given $comp {
                when '~~' {
                    my $match = matcher($var);
                    if not $testvar ~~ $match {
                       $pass = $failure;
                       last;
                    }
                }
                when 'gt' {
                    if not $testvar > $var {
                        $pass = $failure;
                        last;
                    }
                }
                when 'lt' {
                    if not $testvar < $var {
                        $pass = $failure;
                        last;
                    }
                }
                when 'gt=' {
                    if not $testvar >= $var {
                        $pass = $failure;
                        last;
                    }
                }
                when 'lt=' {
                    if not $testvar <= $var {
                        $pass = $failure;
                        last;
                    }
                }
                when '!=' {
                    if $testvar eq $var {
                        $pass = $failure;
                        last;
                    }
                }
                when '=' {
                    if not $testvar eq $var {
                        $pass = $failure;
                        last;
                    }
                }
                when '==' {
                    say "We're in the matcher" if $debug;
                    my $num = regex { ^\d+[\.\d+]?$ };
                    if $testvar ~~ $num && $var ~~ $num {
                        say "They are both numbers" if $debug;
                        if not $testvar == $var {
                            $pass = $failure;
                            last;
                        }
                    }
                    else {
                        if not $testvar eq $var {
                            $pass = $failure;
                            last;
                        }
                    }
                }
                default {
                    if not $testvar ~~ $var {
                        $pass = $failure;
                        last;
                    }
                }
            }
        }
        return $pass;
    }

    method ifTag ($/, $tag?) {
        $!level++;
        if self.keep(1) {
            self.parseIf($/);
        }
    }

    method elseIf ($/, $tag?) {
        if $.keep(1) && ! $.keep {
            self.parseIf($/);
        }
        else {
            self.setKeep(0);
        }
    }

    method elseTag ($/, $tag?) {
        if $.keep(1) && ! $.keep {
            @!match[$!level] = 1;
        }
        else {
            self.setKeep(0);
        }
    }

    method closeIf ($/, $tag?) {
       $!level--;
    }

    method keep ($back=0) {
        my $keep = @!match[$!level-$back];
        return $keep;
    }

    method setKeep ($keep) {
        @!match[$!level] = $keep;
    }

}

module Perlite::Parser::Conditional {

    sub parseIf ($content) is export(:DEFAULT) {
        my $debug = 0;
        my @newcontent;
        my @content = $content.split("\n");
        my $parser = Perlite::Parser::Conditional::Parser.new();
        for @content -> $line {
            say "== Parsing $line" if $debug;
            my $match = Perlite::Parser::Conditional::Grammar.parse(
                $line, :action($parser)
            );
            if $match {
                next; # Skip directives.
            }
            if $parser.keep {
                @newcontent.push: $line;
            }
        }
        return @newcontent.join("\n");
    }

}

