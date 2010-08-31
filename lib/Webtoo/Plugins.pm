role Webtoo::Plugins;

has @.plugins;

method processPlugins {

    say "Entered processPlugins" if $.debug;

    while my $plugin = @.plugins.shift {
        say "Processing $plugin" if $.debug;
        self.callPlugin($plugin, 'processPlugin');
    }

    say "Leaving processPlugins" if $.debug;

}

method callPlugin ($spec, $command is copy, :$opts is copy) {

    say "Entered callPlugin..." if $.debug;

    my %opts;
    if $opts { %opts = %($opts) };

    my $plugin;

    if $spec ~~ Hash {
        ## For Hash based specs, the 'name' value is required.
        if hash-has($spec, 'name', :notempty) {
            $plugin = $spec<name>;
        }
        else {
            return self.err: "No plugin name specified.";
        }

        ## The others are optional, and just overide the defaults.
        if hash-has($spec, 'opts', :defined, :type(Hash)) {
            %opts = $spec<opts>;
        }
        if hash-has($spec, 'command', :notempty) {
            $command = $spec<command>;
        }
    }
    elsif $spec ~~ Str {
        $plugin = $spec;
    }
    else {
        return self.err: "Invalid callPlugin specification passed.";
    }

    ## Okay, now continue processing.

    my regex nsSep    { \: \: }
    my regex nsStart  { ^^ <&nsSep> }

    say "<def> $plugin" if $.debug;
    my $namespace = $plugin.lc;
    if $plugin ~~ /<&nsStart>/ {
        $plugin.=subst(/<&nsStart>/, '', :global);
        $namespace.=subst(/<&nsStart>/, '', :global);
    }
    else {
        $plugin = $!NS ~ $plugin;
    }
    $namespace.=subst(/<&nsSep>/, '-', :global); # Convert :: to - for NS.
    if $plugin ~~ / \+ / {
        $plugin.=subst(/ \+ .* /, '');
    }
    elsif $plugin ~~ / \= / {
        $namespace = $plugin.split(/\=/)[1];
        $plugin.=subst(/ \= .* /, '');
    }

    say "<class> $plugin" if $.debug;
    say "<namespace> $namespace" if $.debug;
    #my $classfile = $plugin.subst(/<&nsSep>/, '/', :global); # Needed hackery.
    #$classfile ~= '.pm';
    #require $classfile;
    eval("use $plugin"); # Evil hack to replace 'require'.
    say "We got past require" if $.debug;
    my $plug = eval($plugin~".new()"); # More needed hackery.
    $plug.parent = self;
    $plug.namespace = $namespace;
    $plug."$command"(%opts);
}


