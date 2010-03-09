use Websight;

class Websight::Content does Websight;

has $.config is rw;
has $.cache is rw = 0;
has $.static is rw = 0;
has $.ext is rw;
has $.append is rw = '';

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    say "We're in Content" if $debug;
    $.config   = self.getConfig(:type(Hash)) // {};
    my $pageExt  = $.config.has('page-ext',  :notempty, :return) || 'wtml';
    my $cacheExt = $.config.has('cache-ext', :notempty, :return) || 'html';
    my $handler  = $.config.has('handler',   :notempty, :return) || 'handler';
    my $cache = $config.has('use-cache', :true, :return) || 0;

    my %reqs = $.parent.req.params;
    my $cachetail;
    if +%reqs.keys {
        $cachetail = %reqs.Array.sort>>fmt('~%s+%s');
    }

    if not defined $.parent.req.get('REBUILD', 'NOCACHE') {
        $.cache = $cache;
        if $.cache == 2 {
            $.append = $cachetail;
        }
        $.static = $.config.has('cache-only', :true, :return) || 0;
    }

    say "We made it past all those settings" if $debug;

    my $file;

    say "We should do the loop {$.cache+1} time(s)." if $debug;

    for $.static..$.cache {
        say "Doing the loop, iteration: {$.cache+1}" if $debug;
        my $page = $.parent.path;
        if $.cache { 
            $.ext = $cacheExt;
        }
        else {
            $.ext = $pageExt;
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
            $.parent.plugins.splice;
            $.parent.noheaders = 1;
            last;
        }
        $.append = ''; # After parsing, reset again.
        $.cache-- if $.cache; # Lower the static.
    }
    ## If all other combinations have failed, use the handler.
    if !$file {
        $file = self!findPage($handler);
    }
    ## Finally, if we found a page, show it!
    if $file {
        $.config<path>;
        self.saveConfig($.config);
        my $content = slurp $file;
        $.parent.content = $content;
        if $.parent.req.get('REBUILD') {
            my $rep = matcher("\\.$pageExt");
            my $cachefile = $file.subst($rep, "$cachetail.$cacheExt");
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
    my $default = $.config.has('default', :notempty, :return) || 'default';
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

