## Webtoo: The Core Engine for ww6.

use v6;

class Webtoo;

#use Perlite::Data;
use Perlite::WebRequest;
use Perlite::Hash;

has $!NS = "Websight::";  ## Namespce for plugins. Defaults to Websight::
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

