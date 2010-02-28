## Webtoo: The Core Engine for ww6.

use v6;
use Webtoo::Data;
use Webtoo::Request;

class Webtoo does Webtoo::Data;

constant PLUGINS  = "Websight::";

has %.env = %*ENV; # Override this if using SCGI or FastCGI.
has %!headers = { Status => 200, 'Content-Type' => 'text/html' };
has $.content is rw = '';
has $!redirect;
has $.req = Webtoo::Request.new( :env(%.env) );
has $.page = %.env{'PATH_INFO'} // %.env{'REQUEST_URI'} // @*ARGS[0];
has $.proto = %.env{'HTTPS'} ?? 'https' !! 'http';
has $.port = %.env{'SERVER_PORT'};
has $.host = %.env{'HTTP_HOST'} // %*ENV{'HOSTNAME'};
has $.debug = %*ENV{'DEBUG'};
has $.mlext = 'wtml';
has $.dlext = 'wtdl';
has $.datadir = './';
has @.plugins = 'Dispatch';  # The default plugins.
has %.metadata is rw = {
    :plugins( @.plugins ),
    :root( [] ),
    'webtoo' => {
        :host($.host),
        :proto($.proto),
        :page($.page),
    },
};

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
        %!headers<Content-Type> = $type;
    }
    else {
        return %!headers<Content-Type>;
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
    my $status = %!headers.delete: 'Status';
    if $status == 204 | 304 { %!header.delete: 'Content-Type'; }
    my $headers = "Status: " ~ $status ~ $eol;
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
    if $plugin ~~ /<nsStart>/ {
        $plugin.=subst(/<nsStart>/, '', :global);
        $namespace.=subst(/<nsStart>/, '', :global);
    }
    else {
        $plugin = PLUGINS ~ $plugin;
    }
    $namespace.=subst(/<nsSep>/, '-', :global); # Convert :: to - for NS.
    if $plugin ~~ / \+ / {
        $plugin.=subst(/ \+ .* /, '');
    }
    elsif $plugin ~~ / \= / {
        $namespace = $plugin.split(/\=/)[1];
        $plugin.=subst(/ \= .* /, '');
    }

    say "<class> $plugin" if $.debug;
    say "<namespace> $namespace" if $.debug;
    my $classfile = $plugin.subst(/<nsSep>/, '/'); # Needed hackery.
    $classfile ~= '.pm';
    require $classfile;
    say "We got past require" if $.debug;
    my $plug = eval("$plugin.new()"); # More needed hackery.
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
    say %.metadata.perl if $.debug;
    return $output;
}

