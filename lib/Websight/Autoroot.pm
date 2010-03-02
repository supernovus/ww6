use Websight;

class Websight::Autoroot does Websight;

## Find a root based on a domain name.
#  Existing roots will be searched in.
#  By default, if this finds a path, that path
#  will REPLACE all other roots.
#  If you want to change this behavior,
#  specify 'merge: 1' in the 'autoroot' config.
#
#  Also, by default, the processing stops when
#  it finds the first matching directory.
#  You can add multiple roots, by specifying 'nest: 1'
#  That means you could have domains/my.test.com and domains/test.com
#  and files would be found in them in that order.

method processPlugin (%opts?) {
    my $config = self.getConfig(:type(Hash));
    my $replace = 1;
    my $nest    = 0;
    if $config && $config.has('merge', :true) {
        $replace = 0;
    }
    my @host = $.parent.host.split('.');
    my @roots;
    HUNT: while my $check = @host.join('.') {
        for $.parent.metadata<root> -> $root {
            my $path = $.parent.datadir ~ '/' ~ $root ~ '/' ~ $check;
            if $path ~~ :d {
                @roots.push: $root ~ '/' ~ $check;
                if !$nest { HUNT.last; }
            }
        }
        @host.shift;
    }
    if @roots {
        if $replace { 
            $.parent.metadata<root> = @roots;
        }
        $parent.metadata<root>.unshift: @roots;
    }
}

