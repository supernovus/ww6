## Webtoo: The Core Engine for ww6.

use v6;

class Webtoo;

use WebRequest;
use Hash::Has;
use HashConfig::Magic;
use Webtoo::File;

has %.env = %*ENV; # Override this if using SCGI or FastCGI.
has %.headers = { Status => 200, 'Content-Type' => 'text/html' };
has $.content is rw = '';
has $.req = WebRequest.new( :env(%.env) );
has $.path is rw = hash-has(%.env, 'PATH_INFO', :notempty, :return) 
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
has $!NS = "Websight::";  ## Namespce for plugins. Defaults to Websight::
has $.defCommand = 'processPlugin'; ## Default command.
has $.datadir = '.';
has HashConfig::Magic $.metadata is rw = HashConfig::Magic.make(
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

## Similar to the findFile for metadata, but for use elsewhere.
## Also supports the optional :$ext parameter. Unlike before, you must
## put a dot in the extension.
method findFile($file, :$ext='', :$dir) {
  findFile($file, :root($.datadir), :subdirs($.metadata<root>), :$ext, :$dir);
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

    my $loaded = self.loadPlugin($plugin, :$namespace);
    if ($loaded) {
      $loaded."$command"($opts);
    }
}

## Note loadPlugin and it's helpers will modify the namespace passed to it.
method loadPlugin ($plug, :$namespace is rw, :$prefix=$!NS, :$noload, :$try) {
  my $plugin;
  if ($plug ~~ Str) {
    $plugin = self!loadDynamicPlugin(
      $plug, :$namespace, :$prefix, :$noload, :$try
    );
  }
  else {
    $plugin = self!loadStaticPlugin($plug, :$namespace, :$prefix);
  }
  if $plugin && !$noload {
    $plugin.parent = self;
    $plugin.namespace = $namespace;
  }
  return $plugin;
}

## Dynamic plugins. Loads by class name.
method !loadDynamicPlugin (
  $plugin is copy, :$namespace is rw, :$prefix, :$noload, :$try
) {

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
        $plugin = $prefix ~ $plugin;
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
    #require $classfile; ## Oh, how I wish.

    my $eval = "use $plugin; ";
    if ($noload) {
      $eval ~= '$plugin = '~$plugin;
    }
    else {
      $eval ~= $plugin~'.new()';
    }
    say "We're going to eval: $eval" if $.debug;
    my $plug = eval($eval);
    if defined $! && !$try { die "eval failed: $!"; }

#    eval("use $plugin"); # Evil hack to replace 'require'.
#    if defined $! && !$try { die "eval use failed: $!"; }
#    say "We got past require" if $.debug;
#    if ($noload) {
#      eval('$plugin = '~$plugin); ## Convert string into Type object.
#      if defined $! && !$try { die "eval type assignment failed: $!"; }
#      return $plugin;
#    }
#    else {
#      my $plug = eval($plugin~".new()"); # More needed hackery.
#      if defined $! && !$try { die "eval new() failed: $!"; }
#
#      return $plug;
#    }

    return $plug;

}

## Static plugins, loads by initialized object.
method !loadStaticPlugin ($plugin, :$namespace is rw, :$prefix) {
    say "Entered callStaticPlugin..." if $.debug;

    my regex nsSep    { \: \: }

    if (!$namespace) { 
        $namespace = ~$plugin.WHAT.perl;
        $namespace.=subst($prefix, '', :global); # Strip the prefix.
        $namespace.=subst(/<&nsSep>/, '-', :global); # Convert :: to - for NS.
        $namespace.=lc; # Change to lowercase.
    }

    say "<class> "~$plugin.WHAT if $.debug;
    say "<namespace> $namespace" if $.debug;
    return $plugin;
}

method err ($message) {
    $*ERR.say: $message;
    return;
}

method setStatus ($code?) {
    if $code {
        %.headers<Status> = $code;
    }
    else {
        return %.headers<Status>;
    }
}

method mimeType ($type?) {
    if $type {
        %.headers<Content-Type> = $type;
    }
    else {
        return %.headers<Content-Type>;
    }
}

method addHeader ($name, $value, Bool $append=False) {
    if $append && %.headers{$name} {
        if %.headers{$name} ~~ Array {
            %.headers{$name}.push: $value;
        }
        else {
            my @array = %.headers{$name};
            @array.push: $value;
            %.headers{$name} = @array;
        }
    }
    else {
        %.headers{$name} = $value;
    }
}

## Does NOT support appending. Use addHeader for special cases.
method addHeaders (%headers) {
    for %headers.kv -> $name, $value {
        self.addHeader($name, $value);
    }
}

method delHeader ($name) {
    if %.headers.exists($name) {
        return %.headers.delete($name);
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
method redirect ($url is copy, $status=302, :$nohooks, :$noclear) {
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
    if !$nohooks {
        self!callHooks('redirect');
    }
    if !$noclear {
      self.clearPlugins;
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
    my $status = %.headers.delete: 'Status';
    if $status == 204 | 304 { %!header.delete: 'Content-Type'; }
    my $headers = "Status: " ~ $status ~ $eol;
    for %.headers.kv -> $key, $value {
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

