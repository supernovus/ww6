## Webtoo: The Core Engine for ww6.

use v6;

class Webtoo;

use Perlite::WebRequest;
use Perlite::Hash;
use Perlite::Data;
use Perlite::File;

has %.env = %*ENV; # Override this if using SCGI or FastCGI.
has %!headers = { Status => 200, 'Content-Type' => 'text/html' };
has $.content is rw = '';
has $.req = Perlite::WebRequest.new( :env(%.env) );
has $.path = hash-has(%.env, 'PATH_INFO', :notempty, :return) 
    // hash-has(%.env, 'REQUEST_URI', :defined, :return) 
    // @*ARGS[0] // '';
has $.uri = hash-has(%.env, 'REQUEST_URI', :defined, :return)
    // $.path;
has $.proto = hash-has(%.env, 'HTTPS', :true) ?? 'https' !! 'http';
has $.port = hash-has(%.env, 'SERVER_PORT', :true, :return) // 0;
has $.host = hash-has(%.env, 'HTTP_HOST', :return) 
    // hash-has(%*ENV, 'HOSTNAME', :return) // 'localhost';
has $.debug = hash-has(%*ENV, 'DEBUG', :return);
has $.noheaders is rw = 0;
has $.savefile is rw;
has %.hooks is rw;
has Perlite::Data $.metadata is rw; ## Metadata object.
has $!NS = "Websight::";  ## Namespce for plugins. Defaults to Websight::
has $.defCommand = 'processPlugin'; ## Default command.
has $.datadir = '.';

## We would use BUILD to init the metadata, but unfortunately,
## the BUILD submethod currently makes all of the attribute settings
## go "poof". It's basically useless. I hope that gets fixed. :-P
method init-metadata() {
    if defined $.metadata {
        $.metadata = $.metadata.make(
          :data({
            :root( [ '' ] ),
            :plugins( ['Example'] ),
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
          }),
          :find(sub ($me, $file) {
            findFile($file, :root($.datadir), :subdirs($me<root>));
          }),
        );
    }
}

## Similar to the findFile for metadata, but for use elsewhere.
method findFile($file) {
  findFile($file, :root($.datadir), :subdirs($.metadata<root>));
}

method processPlugins {

    say "Entered processPlugins" if $.debug;

    while my $plugin = $.metadata<plugins>.shift {
        say "Processing $plugin" if $.debug;
        self.callPlugin($plugin);
    }

    say "Leaving processPlugins" if $.debug;

}

method clearPlugins {
  $.metadata<plugins>.splice;
}

## A Quick wrapper supporting both Dynamic and Static plugins.
method callPlugin ($spec, :$command is copy = $.defCommand, :$opts is copy, :$namespace is copy) {

    say "Entered callPlugin..." if $.debug;

    my $plugin;

    if $spec ~~ Hash {
        ## For Hash based specs, the 'plugin' value is required.
        if hash-has($spec, 'plugin', :notempty) {
            $plugin = $spec<plugin>;
        }
        else {
            return self.err: "No plugin specified.";
        }

        ## The others are optional, and just overide the defaults.
        if hash-has($spec, 'opts', :defined) {
            $opts = $spec<opts>;
        }
        if hash-has($spec, 'command', :notempty) {
            $command = $spec<command>;
        }
    }
    else {
      $plugin = $spec;
    }

    if ($plugin ~~ Str) {
        return self!callDynamicPlugin($plugin, :$command, :$opts, :$namespace);
    }
    else {
        return self!callStaticPlugin($plugin, :$command, :$opts, :$namespace);
    }

}

## Dynamic plugins. Either the name of the class to load, or a spec.
method !callDynamicPlugin ($plugin is copy, :$command = $.defCommand, :$opts, :$namespace is copy) {

    say "Entered callDynamicPlugin..." if $.debug;

    ## Okay, now continue processing.

    my regex nsSep    { \: \: }
    my regex nsStart  { ^^ <&nsSep> }

    say "<def> $plugin" if $.debug;
    if (!$namespace) { $namespace = $plugin.lc; }
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
    say "What the fuck: "~$plug.perl if $.debug;
    if $plug {
      $plug.parent = self;
      $plug.namespace = $namespace;
      $plug."$command"($opts);
    }
}

method !callStaticPlugin ($plugin, :$command = $.defCommand, :$opts, :$namespace is copy) {
    say "Entered callStaticPlugin..." if $.debug;

    my regex nsSep    { \: \: }

    if (!$namespace) { 
        $namespace = ~$plugin.WHAT.perl;
        $namespace.=subst($!NS, '', :global); # Strip the Namespace.
        $namespace.=subst(/<&nsSep>/, '-', :global); # Convert :: to - for NS.
        $namespace.=lc; # Change to lowercase.
    }

    say "<class> "~$plugin.WHAT if $.debug;
    say "<namespace> $namespace" if $.debug;
    $plugin.parent = self;
    $plugin.namespace = $namespace;
    $plugin."$command"($opts);
}

method err ($message) {
    $*ERR.say: $message;
    return;
}

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

method status ($status) {
    self.addHeader('Status', $status);
}

# redirect now supports protocol redirection. redirectProto has been removed.
method redirect ($url is copy, $status=302, :$nostop) {
    if not $url ~~ /^\w+\:\/\// {
        my $proto = $.proto;
        my $oldurl = '';
        if $url ~~ /^https?$/ {
            $proto = $url;
            $oldurl = $.uri;
        }
        else {
            if not $url ~~ /^\// { $oldurl = '/'; }
            $oldurl ~= $url;
        }
        $url = $proto ~ '://' ~ $.host;
        if $.port != 80 | 443 { $url ~= ':' ~ $.port }
        $url ~= $oldurl;
    }
    self.status($status);
    self.addHeader('Location', $url);
    if !$nostop {
        self!callHooks('redirect');
    }
}

method !callHooks($hook) {
  if %.hooks.exists($hook) {
    if %.hooks{$hook} ~~ Array {
      for %.hooks{$hook} -> &func {
        func();
      }
    }
    elsif %.hooks{$hook} ~~ Callable {
      %.hooks{$hook}();
    }
  }
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

method processContent (Bool :$noheaders) {
    if $noheaders { $.noheaders = 1; }
    say "Entered processContent" if $.debug;
    say "About to build headers" if $.debug;
    my $output = '';
    $output = self!buildHeaders if ! $.noheaders;
    say "About to add the content" if $.debug;
    $output ~= $.content;
    say "Built output" if $.debug;
    if $.savefile {
        my $file = open $.savefile, :w;
        $file.say: $output;
        $file.close;
    }
    return $output;
}

