use Websight;

class Websight::Dispatch does Websight;

use Hash::Has;

method processPlugin ($config? is copy) {
    if (!$config) { $config = self.getConfig(:type(Array)); }
    if defined $config {
        self!matchRules($config);
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
            if not $.parent.host ~~ eval("/$rule<host>/") {
                next;
            }
        }
        if hash-has($rule, 'path', :notempty, :type(Str)) {
            say "Parsing 'path' rule: "~$rule<path> if $debug;
            if $continue == 1 { $continue = 0 }
            if not $.parent.path ~~ eval("/$rule<path>/") {
                say "Which did not match." if $debug;
                next;
            }
        }
        if hash-has($rule, 'proto', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            if not $.parent.proto ~~ eval("/$rule<proto>/") {
                next;
            }
        }
        if hash-has($rule, 'file', :notempty, :type(Str)) {
            if $continue == 1 { $continue = 0 }
            my $file = $rule<file>;
            if not $.parent.findFile($file) {
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

        ## Metadata Processing, takes a Hash, and the contents of the
        #  Hash will be merged with the metadata object.
        if hash-has($rule, 'set', :notempty, :type(Hash)) {
            $.parent.metadata.merge($rule<set>);
        }

        ## Plugin Processing, pass it a plugin spec Hash.
        if hash-has($rule, 'plugin', :defined) {
            self.callPlugin($rule<plugin>);
        }

        ## Include files must be either a direct Array
        #  Or include a hash element called 'dispatch' which is said array.
        if hash-has($rule, 'include', :notempty, :type(Str)) {
            my @subrules;
            my $subrules = $.parent.metadata.parseFile($rule<include>);
            if $subrules ~~ Array {
                @subrules = @($subrules);
            }
            elsif 
            ( $subrules ~~ Hash 
              && hash-has($subrules, 'dispatch', :type(Array)) 
            ) {
                @subrules = @($subrules<dispatch>);
            }
            if @subrules {
                self!matchRules(@subrules);
            }
        }

        ## Rule chaining. Pass an array, and it will be parsed as a nested
        # set of dispatch rules.
        if hash-has($rule, 'dispatch', :type(Array)) {
            self!matchRules($rule<chain>);
        }

        ## End of normal rules, now see if we continue parsing.
        if !$continue { last; }

    }
}

