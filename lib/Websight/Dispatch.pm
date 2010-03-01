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

        ## Use 'continue: 1' if you want a block with a condition to continue
        #  parsing further rules. By default, a matching condition or a
        #  redirect/redirect-proto statement end processing.
        if $rule.has('continue', :true) {
            $continue = 2;
        }

        ## Conditions, if they don't match, skip this rule.
        if $rule.has('host', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.host ~~ self.matcher($rule<host>) {
                next;
            }
        }
        if $rule.has('path', :notempty, :type(Str)) {
            say "Parsing 'path' rule: "~$rule<path> if $debug;
            if $continue == 1 { $continue = 0 }
            if not $.parent.path ~~ self.matcher($rule<path>) {
                say "Which did not match." if $debug;
                next;
            }
        }
        if $rule.has('proto', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.proto ~~ self.matcher($rule<proto>) {
                next;
            }
        }
        if $rule.has('datafile', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.findFile($rule<datafile>) {
                next;
            }
        }
        if $rule.has('pagefile', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.findFile($rule<pagefile>, :ext($.parent.mlext)) {
                next;
            }
        }

        ## Response settings
        if $rule.has('mime', :notempty, :type(Str)) {
            $.parent.mimeType($rule<mime>);
        }
        if $rule.has('headers', :defined, :type(Hash)) {
            $.parent.addHeaders($rule<headers>);
        }

        ## Redirects, they are mutually exclusive.
        #  'redirect' redirects to either a full URL
        #  or to an absolute path on the current host.
        #  'redirect-proto' redirects to the same URI, but with
        #  the specified protocol. Use 'redirect-proto: https' to
        #  force SSL usage.
        if $rule.has('redirect', :notempty, :type(Str)) {
            $.parent.redirect($rule<redirect>);
            if !$continue { last; }
        }
        elsif $rule.has('redirect-proto', :noempty, :type(Str)) {
            $.parent.redirectProto($rule<redirect-proto>);
            if !$continue { last; }
        }

        ## Adding 'root' paths.
        if $rule.has('root', :defined, :type(Str)) {
            $.parent.metadata<root>.unshift: $rule<root>;
        }

        ## Metadata Processing
        if $rule.has('set', :notempty, :type(Str)) {
            $.parent.loadMetadata($rule<set>);
        }

        ## Include files must be either a direct Array
        #  Or include a hash element called 'dispatch' which is said array.
        if $rule.has('include', :notempty, :type(Str)) {
            my @subrules;
            my $subrules = $.parent.parseDataFile(
                $rule<include>, 
                [], 
                :cache([ $.parent.metadata ]),
            );
            if $subrules ~~ Array {
                @subrules = @($subrules);
            }
            elsif $subrules ~~ Hash 
               && $subrules.has('dispatch', :type(Array)) {
                @subrules = @($subrules<dispatch>);
            }
            if @subrules {
                self!matchRules(@subrules);
            }
        }

        ## For chaining dispatch rules inline, there are two types.
        #  Either a string, which will be parsed as WTDL AFTER matching.
        #  Or an array, which will be passed directly to matchRules.
        if $rule.has('dispatch', :notempty, :type(Str)) {
            self!matchRules(
                $.parent.parseData(
                    $rule<dispatch>.split,
                    [],
                    0,
                    [ $.parent.metadata ],
                )
            );
        }
        elsif $rule.has('dispatch', :type(Array)) {
            self!matchRules($rule<chain>);
        }

        ## End of normal rules, now see if we continue parsing.
        if !$continue { last; }

    }
}

