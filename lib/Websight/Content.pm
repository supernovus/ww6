use Websight;

class Websight::Content does Websight;

has $.config is rw;
has $.cache is rw = 0;
has $.ext is rw;
has $.append is rw = '';

method processPlugin (%opts?) {
    $.config   = self.getConfig(:type(Hash)) // {};
    my $pageExt  = $.config.has('page-ext',  :notempty, :return) || 'wtml';
    my $cacheExt = $.config.has('cache-ext', :notempty, :return) || 'cache';
    my $handler  = $.config.has('handler',   :notempty, :return) || 'handler';
    if not defined $.parent.req.get('REBUILD', 'NOCACHE') {
        $.cache = $.config.has('use-cache', :true, :return) || 0;
        if $.cache == 2 {
            my %reqs = $.parent.req.params;
            if +%reqs.keys {
                $.append = '~' ~ %reqs.keys.sort.join('+');
            }
        }
    }

    my $file;

    for 0..$.cache {
        my $page = $.parent.page;
        if $.cache { 
            $.ext = $cacheExt;
        }
        else {
            $.ext = $pageExt;
        }
        if $page ~~ /\/$/ {
            $file = self!findFolder($page) // self!findPage($page, :slash);   
        }
        else {
            $file = self!findPage($page) // self!findFolder($page, :slash);
        }
        if $file && $.cache {
            $.parent.plugins.splice;
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
        my $content = lines $file;
        $.parent.content = $content;
    }
}

method !findFolder ($page is copy, :$slash) {
    my $default = $.config.has('default', :notempty, :return) || 'default';
    if $slash {
        $page ~= '/';
    }
    return $.parent.findFile($page ~ $default ~ $.append, $.ext);
}

method !findPage ($page is copy, :$slash) {
    if $slash {
        $page.=subst(/\/$/,'');
    }
    return $.parent.findFile($page ~ $.append, $.ext);
}

