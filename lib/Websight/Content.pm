use Websight;

class Websight::Content does Websight;

use Perlite::Hash;

has $.config is rw;
has $.cache is rw = 0;
has $.static is rw = 0;
has $.append is rw = '';

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    say "We're in Content" if $debug;
    $.config   = self.getConfig(:type(Hash)) // {};
    my $cacheExt = hash-has($.config, 'cache-ext', :notempty, :return) || '.cache';
    my $handler  = hash-has($.config, 'handler',   :notempty, :return) || 'handler.xml';
    my $cache = hash-has($.config, 'use-cache', :true, :return) || 0;
    say "Cache = $cache" if $debug;

    my $cachetail = '';
    if $cache == 2 {
        my %reqs = $.parent.req.params;
        %reqs.delete('REBUILD');
        my $ignorekeys = hash-has($.config, 'ignore-keys', :type(Array), :return);
        if $ignorekeys && $ignorekeys ~~ Array {
            for @($ignorekeys) -> $ignore {
                %reqs.delete($ignore);
            }
        }
        if +%reqs.keys {
            $cachetail = %reqs.Array.sort>>.fmt("~%s+%s");
        }
    }

    if not defined $.parent.req.get('REBUILD', 'NOCACHE') {
        $.cache = $cache;
        $.append = $cachetail;
        $.static = hash-has($.config, 'cache-only', :true, :return) || 0;
        say "Append: $.append" if $debug;
        say "Static: $.static" if $debug;
    }

    say "We made it past all those settings" if $debug;

    my $file;

    say "We should do the loop {$.cache+1} time(s)." if $debug;

    for $.static..$.cache {
        say "Doing the loop, iteration: {$.cache+1}" if $debug;
        my $page = $.parent.path;
        if $.cache { 
            $page ~= $cacheExt;
        }
        if $page ~~ /\/$/ {
            say "Page ended in a slash" if $debug;
            $file = self!findFolder($page) // self!findPage($page, :slash);
        }
        else {
            say "Page didn't end in a slash" if $debug;
            $file = self!findPage($page) // self!findFolder($page, :slash);
        }
        if $file && $.cache {
            say "We found a cache file: $file\n" if $debug;
            $.parent.clearPlugins;
            $.parent.noheaders = 1;
            last;
        }
        $.append = ''; # After parsing, reset again.
        $.cache-- if $.cache; # Lower the static.
    }
    ## If all other combinations have failed, use the handler.
    if !$file {
        if $cache && not defined $.parent.req.get('NOCACHE') {
            $.ext = $cacheExt;
            $file = self!findPage($handler);
            if $file {
                $.parent.metadata<plugins>.splice;
                $.parent.noheaders = 1;
            }
            else {
                $.ext = $pageExt;
                $file = self!findPage($handler);
            }
        }
        else {
            $file = self!findPage($handler);
        }
    }
    ## Finally, if we found a page, show it!
    if $file {
        $.config<path>;
        self.saveConfig($.config);
        my $content = slurp $file;
        $.parent.content = $content;
        if defined $.parent.req.get('REBUILD') {
            say "Setting the cache file to be saved." if $debug;
            my $cachefile = $file ~= $cachetail ~ $cacheExt;
            $.parent.savefile = $cachefile;
        }
    }
    else {
        $.parent.err: "No page found for {$.parent.path}";
        $.parent.setStatus(404);
    }
}

method !findFolder ($page is copy, :$slash) {
    my $debug = $.parent.debug;
    my $default = hash-has($.config, 'default', :notempty, :return) || 'default';
    if $slash {
        $page ~= '/';
    }
    my $find = $page ~ $default ~ $.append;
    return $.parent.findFile($find, :ext($.ext));
}

method !findPage ($page is copy, :$slash) {
    my $debug = $.parent.debug;
    if $slash {
        $page.=subst(/\/$/,'');
    }
    my $find = $page ~ $.append;
    return $.parent.findFile($find, :ext($.ext));
}

