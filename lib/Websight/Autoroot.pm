use Websight;

class Websight::Autoroot does Websight;

use Perlite::Hash;

## Find a root based on a domain name.
#  Existing roots will be searched in.
#  By default, if this finds a path, that path
#  will REPLACE all other roots.
#  If you want to change this behavior,
#  specify 'keep: 1' in the 'autoroot' config.
#
#  Also, by default, the processing stops when
#  it finds the first matching directory.
#  You can add multiple roots, by specifying 'nest: 1'
#  That means you could have domains/my.test.com and domains/test.com
#  and files would be found in them in that order.

method processPlugin (%def_config) {
    my $debug = $.parent.debug;
    my %config = self.getConfig(:type(Hash)) // %def_config;
    my $replace = 1;
    my $nest    = 0;
    my $found   = 0;
    if hash-has(%config, 'keep', :true) {
        $replace = 0;
    }
    if hash-has(%config, 'nest', :true) {
        $nest = %config<nest>;
    }
    my @host = $.parent.host.split('.');
    say "Host: {@host}" if $debug;
    my @roots;
    while my $check = @host.join('.') {
        for @($.parent.metadata<root>) -> $root {
            say "Checking '$root' for '$check'." if $debug;
            my $path = $.parent.datadir ~ '/' ~ $root ~ '/' ~ $check;
            say "Lookng for $path" if $debug;
            if $path.IO ~~ :d {
                say "Found it!" if $debug;
                @roots.push: $root ~ '/' ~ $check;
                if $nest < 2 { $found = 1; last; }
            }
        }
        if ($found && !$nest) { last; }
        @host.shift;
    }
    if @roots {
        if $replace { 
            $.parent.metadata<root> = @roots;
        }
        else {
            $.parent.metadata<root>.unshift: @roots;
        }
    }
}

