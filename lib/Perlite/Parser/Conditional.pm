grammar Perlite::Parser::Conditional::Grammar {
    token TOP { 
        | <ifTag> {*}     #= if
        | <elseIf> {*}    #= elsif
        | <elseTag> {*}   #= else
        | <closeIf> {*}   #= endif
    }
    rule ifTag { 
        \<if <ifStat>\> {*}
    }
    rule elseIf { 
        \<else if? <ifStat>\> {*}
    }
    rule elseTag { 
        \<else\/*\> {*}
    }
    rule closeIf { 
        \<\/if\> 
    }
    rule ifStat { 
        <ifCond> (<ifChain> <ifCond>)?
    }
    rule ifCond { 
        <ifVar> (<ifComp> <ifVar>)?
    }
    rule ifVar { 
        \".*?\"
    }
    #"  Formatting hack.
    rule ifComp { 
        | \=+
        | \~\~
        | gt
        | lt
        | gt\=
        | lt\=
    }
    rule ifChain {
        | and
        | or
    }
}

class Perlite::Parser::Conditional::Actions {
    method TOP ($/, $tag) {
        if $tag eq 'if' { say "Found an if"; }
    }
}

module Perlite::Parser::Conditional {

    sub parseIf ($content) is export(:DEFAULT) {
        #my @content = $content.split("\n");
        my $parser = Perlite::Parser::Conditional::Actions.new;
        my $match = Perlite::Parser::Conditional::Grammar.match(
            $content, :actions($parser)
        );
    }

}

