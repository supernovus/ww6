##
## A shared role for the Content and Cache plugins.
##
role WW::Cache;

use Hash::Has;

has $.cacheconf is rw;

method query-cache() {
  my $cachetail = '';
  my %reqs = $.parent.req.params;
  %reqs.delete('REBUILD');
  my $ignorekeys = hash-has($.cacheconf, 'ignore-keys', :type(Array), :return);
  if $ignorekeys && $ignorekeys ~~ Array {
    for @($ignorekeys) -> $ignore {
    %reqs.delete($ignore);
    }
  }
  if +%reqs.keys {
    $cachetail = %reqs.Array.sort>>.fmt("~%s+%s");
  }
  return $cachetail;
}

method cache-config() {
  hash-has($.parent.metadata, 'cache', :type(Hash), :default({}), :return);
}

