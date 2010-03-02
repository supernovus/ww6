## Webtoo: The Core Engine for ww6.

use v6;
use Webtoo::Data;
use Webtoo::Request;

class Hash is also {
    method has (
        $what, :$true, :$defined is rw, :$notempty, :$return, :$type,
    ) {
        if $notempty || $true { $defined = 1; }
        if self.exists($what) 
          && ( !$defined  || defined self{$what} )
          && ( !$type     || self{what} ~~ $type )
          && ( !$notempty || self{$what} ne ''   )
          && ( !$true     || self{$what}         )
        {
            if $return { return self{$what}; }
            else { return True; }
        }
        else {
            return;
        }
    }
}

class Webtoo does Webtoo::Data;

constant PLUGINS  = "Websight::";

has %.env = %*ENV; # Override this if using SCGI or FastCGI.
has %!headers = { Status => 200, 'Content-Type' => 'text/html' };
has $.content is rw = '';
has $.req = Webtoo::Request.new( :env(%.env) );
has $.path = %.env.has('PATH_INFO', :notempty, :return) 
    // %.env.has('REQUEST_URI', :defined, :return) 
    // @*ARGS[0] // '';
has $.uri = %.env.has('REQUEST_URI', :defined, :return)
    // $.path;
has $.proto = %.env.has('HTTPS', :true) ?? 'https' !! 'http';
has $.port = %.env.has('SERVER_PORT', :true, :return) // 0;
has $.host = %.env.has('HTTP_HOST', :return) 
    // %*ENV.has('HOSTNAME', :return);
has $.debug = %*ENV.has('DEBUG', :return);
has $.mlext = 'wtml';
has $.dlext = 'wtdl';
has $.datadir = './';
has %.metadata is rw = {
    :plugins( [ 'Example' ] ),
    :root( [ '' ] ),
    'request' => {
        :host($.host),
        :proto($.proto),
        :path($.path),
        :type($.req.type),
        :method($.req.method),
        :query($.req.query),
        :params($.req.params),
        :userip($.req.remoteAddr),
        :browser($.req.userAgent),
        :uri($.uri),
        :url($.proto ~ '://' ~ $.host);
        :urlhttp('http://' ~ $.host);
        :urlhttps('https://' ~ $.host);
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

## Does NOT support appending. Use addHeader for special cases.
method addHeaders (%headers) {
    for %headers.kv -> $name, $value {
        self.addHeader($name, $value);
    }
}

method delHeader ($name) {
    if %!headers.exists($name) {
        return %!headers.delete($name);
    }
    else {
        return;
    }
}

method delHeaders (@headers) {
    for @headers -> $name {
        self.delHeader($name);
    }
}

method redirect ($url is copy, $status=302, :$nostop) {
    if not $url ~~ /^\w+\:\/\// {
        $url = $.proto ~ '://' ~ $.host ~ '/' ~ $url;
    }
    self.addHeader('Status', $status);
    self.addHeader('Location', $url);
    if !$nostop {
        %.metadata<plugins>.splice;
    }
}

## To force 'https', you can use redirectProto('https');
method redirectProto ($proto, $status=302, :$nostop) {
    if $.proto eq $proto { return; }
    my $url = $proto ~ '://' ~ $.host ~ $.uri;
    self.redirect($url, :status($status), :nostop($nostop));
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

method findFile ($file, :@path=%.metadata<root>, :$ext=$.dlext) {
    for @path -> $path {
        my $config = $.datadir ~ '/' ~ $path ~ '/' ~ $file ~ '.' ~ $ext;
        if $config ~~ :f {
            return $config;
        }
    }
    return;
}

