use WW::ChainLoader;

class Websight::Dispatch does WW::ChainLoader;

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

        ## Use 'continue: 1' if you want a block with a condition to 
        ## continue parsing further rules. 
        ## By default, a matching condition or a 
        ## redirect statement end processing.
        if hash-has($rule, 'continue', :true) {
          $continue = 2;
        }

        ## Conditions, if they don't match, skip the rule.

        ## Primary conditions, the Dispatch instance checking these
        ## should be the first plugin loaded.

        ## Does the hostname match a certain string?
        if hash-has($rule, 'host', :notempty, :type(Str)) {
          if $continue == 1 { $continue = 0 }
          if not $.parent.host ~~ eval("/$rule<host>/") { next; }
        }
        ## Does the URL path match a certain string?
        if hash-has($rule, 'path', :notempty, :type(Str)) {
          say "Parsing 'path' rule: "~$rule<path> if $debug;
          if $continue == 1 { $continue = 0 }
          if not $.parent.path ~~ eval("/$rule<path>/") {
              say "Which did not match." if $debug;
              next;
          }
        }
        ## Does the protocol match a certain string?
        if hash-has($rule, 'proto', :notempty, :type(Str)) {
          if $continue == 1 { $continue = 0 }
          if not $.parent.proto ~~ eval("/$rule<proto>/") { next; }
        }
        elsif hash-has($rule, 'not-proto', :notempty, :type(Str)) {
          if $continue == 1 { $continue = 0; }
          if $.parent.proto ~~ eval("/$rule<proto>/") { next; }
        }

        ## Either-or Conditions, can be primary, or secondary.
        ## Like primary conditions, these stop if matched by default.

        ## Does a file exist in the known roots?
        if hash-has($rule, 'file', :notempty, :type(Str)) {
          if $continue == 1 { $continue = 0 }
          my $file = $rule<file>;
          if not $.parent.findFile($file) { next; }
        }
        elsif hash-has($rule, 'no-file', :notempty, :type(Str)) {
          if $continue == 1 { $continue = 0; }
          my $file = $rule{'no-file'};
          if $.parent.findFile($file) { next; }
        }

        ## Secondary Conditions, these are meant for inclusion in additional
        ## instances of Dispatch, with their own namespaces.
        ## They don't have explicit stops. If you want one to stop the
        ## processing if matched, use 'stop: 1' in the rule.

        ## Has content been set?
        if hash-has($rule, 'has-content', :true) {
          if ! $.parent.content { next; }
        }
        elsif hash-has($rule, 'no-content', :true) {
          if $.parent.content { next; }
        }

        ## Is the mime-type a specific value?
        if hash-has($rule, 'is-mime', :notempty, :type(Str)) {
          if $.parent.mimeType() ne $rule{'is-mime'} { next; }
        }
        elsif hash-has($rule, 'not-mime', :notempty, :type(Str)) {
          if $.parent.mimeType() eq $rule{'not-mime'} { next; }
        }

        ## Do specific headers exist?
        if hash-has($rule, 'has-headers', :type(Array)) {
          my $failed = False;
          for @($rule{'has-headers'}) -> $header {
            if ! self!has-header($header) { $failed = True; last; }
          }
          if $failed { next; }
        }
        elsif hash-has($rule, 'no-headers', :type(Array)) {
          my $failed = False;
          for @($rule{'no-headers'}) -> $header {
            if self!has-header($header) { $failed = True; last; }
          }
          if $failed { next; }
        }
        elsif hash-has($rule, 'has-header', :notempty, :type(Str)) {
          if ! self!has-header($rule{'has-header'}) { next; }
        }
        elsif hash-has($rule, 'no-header', :notempty, :type(Str)) {
          if self!has-header($rule{'no-header'}) { next; }
        }

        ## Do specific HTTP GET or POST parameters exist?
        if hash-has($rule, 'has-params', :type(Array)) {
          my $failed = False;
          for @($rule{'has-params'}) -> $param {
            if ! self!has-param($param) { $failed = True; last; }
          }
          if $failed { next; }
        }
        elsif hash-has($rule, 'no-params', :type(Array)) {
          my $failed = False;
          for @($rule{'no-params'}) -> $param {
            if self!has-param($param) { $failed = True; last; }
          }
          if $failed { next; }
        }
        elsif hash-has($rule, 'has-param', :notempty, :type(Str)) {
          if ! self!has-param($rule{'has-param'}) { next; }
        }
        elsif hash-has($rule, 'no-param', :notempty, :type(Str)) {
          if self!has-param($rule{'no-param'}) { next; }
        }

        ## End of conditions, Start of actions.

        ## Path Rewriting, even if you used a primary condition without
        ## continue, this forces continue. The only way to override it
        ## is to use 'stop: 1', which isn't really recommended when using
        ## Path Rewriting, as it loses the chaining ability.
        if hash-has($rule, 'rewrite', :notempty, :type(Str)) {
          $.parent.path = $rule<rewrite>;
          $continue = 1;
        }

        ## The 'stop' modifier is checked after rules have matched.
        ## If the rule matches, and stop is there, then we won't
        ## continue. It's mutually exclusive with 'continue', and overrides it.
        if hash-has($rule, 'stop', :true) {
          $continue = 0;
        }

        ## Response settings
        if hash-has($rule, 'mime', :notempty, :type(Str)) {
            $.parent.mimeType($rule<mime>);
        }
        if hash-has($rule, 'headers', :defined, :type(Hash)) {
            $.parent.addHeaders($rule<headers>);
        }

        ## Redirection
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

        ## Adding a site path to @*INC.
        if hash-has($rule, 'classpath', :notempty, :type(Str)) {
          my $classdir = $.parent.findFile($rule<classpath>, :dir);
          if $classdir { @*INC.push: $classdir; }
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

method !has-header($header) {
  $.parent.headers.exists($header);
}

method !has-param($param) {
  $.parent.req.params.exists($param);
}

