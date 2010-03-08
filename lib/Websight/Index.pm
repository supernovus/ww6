use Websight;
use Perlite::Parser;

class Websight::Index does Websight;

method processPlugin (%opts?) {
    my $debug = $.parent.debug;
    say "We're in Index::View" if $debug;
    my $config   = self.getConfig(:type(Hash));
    if !$config { return; } ## We must have a config.
    my $data  = $config.has('data',  :defined, :return);
    if !$data { return; }
    if $data ~~ Str {
        $data = $.parent.parseDataFile($data, []);
    }
    if not $data ~~ Array { return; } ## Data must be an array.
    my @showdata;
    my $tags  = $config.has('tags',  :defined, :type(Array), :return);
    my $match = $config.has('match', :defined, :type(Array), :return);
    my $reqtags = $.parent.req.get('tag','tags');
    if $reqtags {
        say "req tags: $reqtags";
        $tags = $reqtags.split(',');
    }
    my $show = $.parent.req.get(
        :default($config.has('show', :notempty, :return)),
        'show',
    );
    my @filter;
    if $tags || $match {
        for @($data) -> $def {
            if $match {
                my $failed = 0;
                for @($match) -> $key {
                    if $def{$key} ne $.parent.req.get($key) {
                        $failed = 1;
                        last;
                    }
                }
                if $failed {
                    next;
                }
            }
            if $tags {
                my $matched = 0;
                for @($tags) -> $wantkey {
                    for @($def<tags>) -> $haskey {
                        $haskey.=subst('^+', '');
                        if $haskey eq $wantkey {
                            $matched = 1;
                            last;
                        }
                    }
                    if $matched {
                        @filter.push: $def;
                        last;
                    }
                }
            }
            else {
                @filter.push: $def;
            }
        }
    }
    else {
        @filter = @($data);
    }

    my $count = +@filter;
    if $show && $count > $show {
        my $page = $.parent.req.get(:default(1), 'page');
        if $page < 1 { $page = 1; }
        my $start = $show*($page-1);
        if $start > $count { $start = $count - $show; }
        my $end   = ($show*$page)-1;
        if $end > $count { $end = $count; }
        my $pages = ( $count / $show ).ceiling;
        $config<pager> = 1..$pages;
        @showdata = @filter[$start..$end];
    }
    else {
        @showdata = @filter;
    }

    $config<pages> = @showdata;
    self.saveConfig($config);
    # You must use WTML to parse the index tags.
    # index.pages is the actual list of pages.
    # index.pager is an array of numbers, representing pages of the list.
}


