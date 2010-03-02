use Websight;

class Websight::Content does Websight;

has $.config is rw;

method processPlugin (%opts?) {
    my $.config = self.getConfig(:type(Hash));
    my $handler = $.config.has('handler', :notempty, :return) || 'handler';
    my $page = $.parent.page;
    my $file;
    if $page ~~ /\/$/ {
        $file = self!findFolder($page) // self!findPage($page, :slash) // self!findPage($handler);
    }
    else {
        $file = self!findPage($page) // self!findFolder($page, :slash) // self!findPage($handler);
    }
    if $file {
        $content = lines $file;
        $.parent.content = $content;
    }
}

method !findFolder ($page is copy, :$slash) {
    my $default = $.config.has('default', :notempty, :return) || 'default';
    if $slash {
        $page ~= '/';
    }
    return $.parent.findFile($page ~ $default, $.mlext);
}

method !findPage ($page is copy, :$slash) {
    if $slash {
        $page.=subst(/\/$/,'');
    }
    return $.parent.findFile($page, $.mlext);
}

