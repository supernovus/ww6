class Webtoo::File;

has $.dlext = 'wtdl';
has $.datadir = './';
has @.roots = [ '' ];

method find ($file, :@path=@.roots, :$ext=$.dlext) {
    say "We're in File::find" if $.debug;
    for @path -> $path {
        my $config = $.datadir ~ '/' ~ $path ~ '/' ~ $file ~ '.' ~ $ext;
        say "Looking for $config" if $.debug;
        if $config.IO ~~ :f {
            return $config;
        }
    }
    return;
}

