use Websight;

class Websight::Dispatch does Websight;

method processPlugin (%opts?) {
    my @rules = self.getConfig; ## TODO: Add optional type check to getConfig.
    self!matchRule(@rules);
}

method matchRules (@rules) {
    for @rules -> $rule {
        my $continue = 1;
        my &checkContinue = -> $check, $value {
            if $continue == 1 { $continue = 0 }
            if not $check ~~ self.matcher($rule{$value}) {
                next;
            }
            else {
                if !$continue { last; }
            }
        }
        if not $rule ~~ Hash { next; } ## Skip non-hashes, they are invalid.

        if $rule<continue> {
            $continue = 2;
        }
        if $rule<host> {
            checkContinue($.parent.host, 'host');
        }
        if $rule<path> {
            checkContinue($.parent.path, 'path');
        }
        if $rule<root> {
            $.parent.metadata<root>.unshift: $rule<root>;
        }
        if $rule<set> {
            $.parent.loadMetadata($rule<set>);
        }
        if $rule<redirect> {
            $.parent.redirect($rule<redirect>);
        }

    }
}

