use Websight;
use Perlite::Parser;

class Websight::Index does Websight;

method processPlugin (%opts?) {
    my $debug = 1; #$.parent.debug;
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
    my $keys = $config.has('keys', :defined, :type(Array), :return);
    my $reqkeys = $.parent.req.get('key','keys');
    if $reqkeys {
        $keys = $reqkeys.split(',');
    }
    my $author = $.parent.req.get('author');
    my $show = $.parent.req.get(
        :default($config.has('show', :notempty, :return)),
        'show',
    );
    my @slice;
    my $count = +@($data);
    if $show && $count > $show {
        my $page = $.parent.req.get(:default(1), 'page');
        if $page < 1 { $page = 1; }
        my $start = $show*($page-1);
        if $start > $count { $start = $count - $show; }
        my $end   = ($show*$page)-1;
        if $end > $count { $end = $count; }
        my $pages = ( $count / $show ).ceiling;
        $config<pager> = 1..$pages;
        @slice = $data[$start..$end];
    }
    else {
        @slice = @($data);
    }
    if $keys || $author {
        for @slice -> $def {
            if $author {
                if $def<author> ne $author {
                    next;
                }
            }
            if $keys {
                my $matched = 0;
                for @($keys) -> $wantkey {
                    for @($def<keys>) -> $haskey {
                        $haskey.=subst('^+', '');
                        if $haskey eq $wantkey {
                            $matched = 1;
                            last;
                        }
                    }
                    if $matched {
                        @showdata.push: $def;
                        last;
                    }
                }
            }
            else {
                @showdata.push: $def;
            }
        }
    }
    else {
        @showdata = @slice;
    }
    $config<pages> = @showdata;
    self.saveConfig($config);
    # You must use WTML to parse the index tags.
    # index.pages is the actual list of pages.
    # index.pager is an array of numbers, representing pages of the list.
}


