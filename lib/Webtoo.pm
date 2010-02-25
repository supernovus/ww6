use Webtoo::Data;
use Webtoo::CGI;

class Webtoo does Webtoo::Data does Webtoo::CGI;

constant PLUGINS  = "Websight::";

has %!headers = { Status => 200, 'Content-type' => 'text/html' };
has %.metadata is rw = {
    :plugins( [ 'Dispatch' ] ),
    :root('/'),
};
has $.content is rw = '';
has $!redirect;
has $.page = %*ENV{'PATH_INFO'} // %*ENV{'REQUEST_URI'} // @*ARGS[0];
has $.proto is rw = %*ENV{'HTTPS'} ?? 'https' !! 'http';
has $.host = %*ENV{'HTTP_HOST'} // %*ENV{'HOSTNAME'};
has $.debug = %*ENV{'DEBUG'};
has $.mlext = 'wtml';
has $.dlext = 'wtdl';
has $.datadir is rw;

method setStatus ($code?) {
    if $code {
        %!headers<Status> = $code;
    }
    else {
        return %!headers<Status>;
    }
}

method mimeType ($type?) {
    if $type {
        %!headers<Content-type> = $type;
    }
    else {
        return %!headers<Content-type>;
    }
}

method addHeader ($name, $value, Bool $append=False) {
    if $append && %!headers{$name} {
        if %!headers{$name} ~~ Array {
            %!headers{$name}.push: $value;
        }
        else {
            my @array = %!headers{$name};
            @array.push: $value;
            %!headers{$name} = @array;
        }
    }
    else {
        %!headers{$name} = $value;
    }
}

method delHeader ($name) {
    return %!headers.delete($name);
}

method !buildHeaders {
    say "Entered buildHeaders" if $.debug;
    my $eol = "\r\n";
    my $headers = "Status: " ~ %!headers.delete('Status') ~ $eol;
    for %!headers.kv -> $key, $value {
        if $value ~~ Array {
            for @($value) -> $header {
                $headers ~= "$key: $header$eol";
            }
        }
        else {
            $headers ~= "$key: $value$eol";
        }
    }
    $headers ~= $eol;
    say "Leaving buildHeaders" if $.debug;
    return $headers;
}


method processPlugins {

    say "Entered processPlugins" if $.debug;

    while my $plugin = %.metadata<plugins>.shift {
        say "Processing $plugin" if $.debug;
        self.callPlugin($plugin, 'processPlugin');
    }

    say "Leaving processPlugins" if $.debug;

}

method callPlugin ($plugin is copy, $command, *%opts) {

    regex nsSep    { \: \: }
    regex nsStart  { ^^ <nsSep> }

    say "<def> $plugin" if $.debug;
    my $namespace = $plugin.lc;
    if $plugin.match(/<nsStart>/) {
        $plugin.=subst(/<nsStart>/, '', :global);
        $namespace.=subst(/<nsStart>/, '', :global);
    }
    else {
        $plugin = PLUGINS ~ $plugin;
    }
    $namespace.=subst(/<nsSep>/, '.', :global); # Convert :: to . for NS.
    if $plugin.match(/ \+ /) {
        $plugin.=subst(/ \+ .* /, '');
        $namespace.=subst(/ \+ /, '.'); # Convert + to . for subspaces.
    }
    elsif $plugin.match(/ \= /) {
        $namespace = $plugin.split(/\=/)[1];
        $plugin.=subst(/ \= .* /, '');
    }

    say "<class> $plugin" if $.debug;
    say "<namespace> $namespace" if $.debug;
    ## This is hackery, but needed at the moment.
    my $classfile = $plugin.subst(/<nsSep>/, '/');
    $classfile ~= '.pm';
    require $classfile;
    say "We got past require" if $.debug;
    my $plug = eval("$plugin.new()");
    $plug.parent = self;
    $plug.namespace = $namespace;
    $plug."$command"(%opts);
}

method processContent (Bool :$noheaders, Bool :$noplugins) {
    say "Entered processContent" if $.debug;
    self.processPlugins if ! $noplugins;
    say "About to build headers" if $.debug;
    my $output = '';
    $output = self!buildHeaders if ! $noheaders;
    say "About to add the content" if $.debug;
    $output ~= $.content;
    say "Built output" if $.debug;
    say %.metadata.perl;
    return $output;
}

