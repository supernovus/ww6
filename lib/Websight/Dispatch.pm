use Websight;

class Websight::Dispatch does Websight;

method processPlugin (%opts?) {
    my $rules = self.getConfig(:type(Array));
    if defined $rules {
        self!matchRules($rules);
        $.parent.metadata.delete($.namespace);
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
        if hash-has($rule, 'continue', :true) {
            $continue = 2;
        }

        ## Conditions, if they don't match, skip this rule.
        if hash-has($rule, 'host', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.host ~~ matcher($rule<host>) {
                next;
            }
        }
        if hash-has($rule, 'path', :notempty, :type(Str)) {
            say "Parsing 'path' rule: "~$rule<path> if $debug;
            if $continue == 1 { $continue = 0 }
            if not $.parent.path ~~ matcher($rule<path>) {
                say "Which did not match." if $debug;
                next;
            }
        }
        if hash-has($rule, 'proto', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.proto ~~ matcher($rule<proto>) {
                next;
            }
        }
        if hash-has($rule, 'file', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            my $file = $rule<file>;
            my $ext = $.parent.dlext;
            if $file ~~ /\.(\w+)$/ {
                $ext = $0;
                $file.=subst(/\.\w+$/, '');
            }
            if not $.parent.findFile($file, :ext($ext)) {
                next;
            }
        }

        ## Response settings
        if hash-has($rule, 'mime', :notempty, :type(Str)) {
            $.parent.mimeType($rule<mime>);
        }
        if hash-has($rule, 'headers', :defined, :type(Hash)) {
            $.parent.addHeaders($rule<headers>);
        }

        ## Redirects, they are mutually exclusive.
        #  'redirect' redirects to either a full URL
        #  or to an absolute path on the current host.
        #  You can also redirect the same URI to a different protocol
        #  by specifying 'http' or 'https' as the redirect location.
        if hash-has($rule, 'redirect', :notempty, :type(Str)) {
            $.parent.redirect($rule<redirect>);
            if !$continue { last; }
        }

        ## Adding 'root' paths. This just adds to the beginning of the
        #  list. If you need more control use a 'set' statement.
        if hash-has($rule, 'root', :defined) {
            $.parent.metadata<root>.unshift: $rule<root>
        }

        ## Metadata Processing
        if hash-has($rule, 'set', :notempty, :type(Str)) {
            $.parent.loadMetadata($rule<set>);
        }

        ## Plugin Processing
        if hash-has($rule, 'plugin', :defined) {
            self.callPlugin($rule<plugin>);
        }

        ## Include files must be either a direct Array
        #  Or include a hash element called 'dispatch' which is said array.
        if hash-has($rule, 'include', :notempty, :type(Str)) {
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
               && hash-has($subrules, 'dispatch', :type(Array)) {
                @subrules = @($subrules<dispatch>);
            }
            if @subrules {
                self!matchRules(@subrules);
            }
        }

        ## For chaining dispatch rules inline, there are two types.
        #  Either a string, which will be parsed as WTDL AFTER matching.
        #  Or an array, which will be passed directly to matchRules.
        if hash-has($rule, 'dispatch', :notempty, :type(Str)) {
            self!matchRules(
                $.parent.parseData(
                    $rule<dispatch>.split,
                    [],
                    0,
                    [ $.parent.metadata ],
                )
            );
        }
        elsif hash-has($rule, 'dispatch', :type(Array)) {
            self!matchRules($rule<chain>);
        }

        ## End of normal rules, now see if we continue parsing.
        if !$continue { last; }

    }
}

