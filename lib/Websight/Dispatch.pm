use Websight;

class Websight::Dispatch does Websight;

method processPlugin (%opts?) {
    my $rules = self.getConfig(:type(Array));
    if defined $rules {
        self!matchRules($rules);
    }
}

method !matchRules (@rules) {
    my $debug = $.parent.debug;
    say "we're in matchRules" if $debug;
    for @rules -> $rule {
        say "parsing: "~$rule.perl if $debug;
        my $continue = 1;
        if not $rule ~~ Hash { next; } ## Skip non-hashes, they are invalid.

        if $rule.has('continue', :true) {
            $continue = 2;
        }

        if $rule.has('host', :notempty) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.host ~~ self.matcher($rule<host>) {
                next;
            }
        }
        if $rule.has('path', :notempty) {
            say "Parsing 'path' rule: "~$rule<path> if $debug;
            if $continue == 1 { $continue = 0 }
            if not $.parent.path ~~ self.matcher($rule<path>) {
                say "Which did not match." if $debug;
                next;
            }
        }
        if $rule.has('hasfile', :notempty) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.findFile($rule<hasfile>) {
                next;
            }
        }
        if $rule.has('root', :defined) {
            $.parent.metadata<root>.unshift: $rule<root>;
        }
        if $rule.has('set', :notempty) {
            $.parent.loadMetadata($rule<set>);
        }
        if $rule.has('redirect', :notempty) {
            $.parent.redirect($rule<redirect>);
        }
        if $rule.has('include', :notempty) {
            self!matchRules(
                $.parent.parseDataFile(
                    $rule<include>, 
                    [], 
                    :cache([ $.parent.metadata ]),
                )
            );
        }
        if $rule.has('dispatch', :notempty) {
            self!matchRules(
                $.parent.parseData(
                    $rule<dispatch>.split,
                    [],
                    0,
                    [ $.parent.metadata ],
                )
            );
        }
        if $rule.has('chain', :type(Array)) {
            self!matchRules($rule<chain>);
        }

        ## End of normal rules, now see if we continue parsing.
        if !$continue { last; }

    }
}

