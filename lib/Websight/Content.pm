use Websight;
use WW::Cache;

class Websight::Content does Websight does WW::Cache;

use Hash::Has;

has $.config is rw;
has $.ext is rw;
has $.append is rw = '';

method processPlugin ($opts?) {
  my $debug = $.parent.debug;
  say "We're in Content" if $debug;
  $.config  = self.getConfig(:type(Hash), :default({}));
  $.cacheconf = self.cache-config();
  $.ext       = hash-has($.config, 'extension', :notempty, 
      :default('.xml'), :return);

  my $cache   = hash-has($.config, 'cache', :true, :return);
  ## fallthrough defaults to true if cache is true.
  my $fall    = hash-has($.config, 'fallthrough', :true, 
      :default($cache), :return);
  my $handler = hash-has($.config, 'handler', :notempty, 
      :default('handler'), :return);

  if $cache {
    $.append = self.query-cache();
  }

  my $file;

  my $page = $.parent.path;
  if $page ~~ /\/$/ {
    say "Page ended in a slash" if $debug;
    $file = self!findFolder($page) // self!findPage($page, :slash);
  }
  else {
    say "Page didn't end in a slash" if $debug;
    $file = self!findPage($page) // self!findFolder($page, :slash);
  }

  say "After search file is $file" if $debug;

  ## If all other combinations have failed, and we're not falling through,
  ## use the handler.
  if !$file && !$fall {
    $file = self!findPage($handler);
  }

  ## Finally, if we found a page, show it!
  if $file {
    say "Found $file" if $debug;
    $.config<path>;
    self.saveConfig($.config);
    my $content = slurp $file;
    $.parent.content = $content;
    say "Found Content is: "~$content if $debug;
  }
  elsif !$fall {
    $.parent.err: "No page found for {$.parent.path}";
    $.parent.setStatus(404);
  }
}

method !findFolder ($page is copy, :$slash) {
  my $debug = $.parent.debug;
  say "We're in findFolder" if $debug;
  my $index = hash-has($.config, 'index', :notempty, :return) || 'index';
  if $slash {
    $page ~= '/';
  }
  my $find = $page ~ $index ~ $.append;
  return $.parent.findFile($find, :ext($.ext));
}

method !findPage ($page is copy, :$slash) {
  my $debug = $.parent.debug;
  say "We're in findPage" if $debug;
  if $slash {
    $page.=subst(/\/$/,'');
  }
  my $find = $page ~ $.append;
  return $.parent.findFile($find, :ext($.ext));
}

