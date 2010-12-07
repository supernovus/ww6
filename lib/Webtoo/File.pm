## The last remnant from Perlite6, returns home to ww6 where it originated.

module Webtoo::File;

## A function to find a file or directory.
our sub findFile ($file, :$root='.', :@subdirs=[''], :$ext='', :$dir) is export(:DEFAULT) {
    for @subdirs -> $path {
        my $config = $root ~ '/' ~ $path ~ '/' ~ $file ~ $ext;
        if $dir {
          if $config.IO ~~ :d {
            return $config;
          }
        }
        else {
          if $config.IO ~~ :f {
              return $config;
          }
        }
    }
    return;
}

