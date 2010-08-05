#!/usr/local/bin/perl6
#
# Using a Perl 6 script as a standard CGI is not really recommended.
# It's really slow. Use the SCGI interface in 'ww6.scgi' for production use.
#
# This is good for testing, and supports command line usage, like:
#
# ./ww6.cgi /virtual/path key1=value key2=value
#
# The virtual path will be used as the 'page' in Webtoo terms (normally
# this is defined as the PATH_INFO header for a live CGI script.)
#
# The keys=value settings will be joined by & characters and parsed instead of
# the QUERY_STRING environment variable.
#
# There is a magic command-line only parameter that allows you to simulate
# POST submissions, but a word of warning: if you don't have data in the
# STDIN, the script WILL fail. Usage:
#
# echo "postkey=value&key2=blah" | ./ww6.cgi /path FAKEPOST=1
#
# You can also use FAKEPOST=2 to emulate a POST with multipart/form-data
# content. Any other value for FAKEPOST will be used to set the mime-type
# of the POST content.

BEGIN {
    @*INC.push: './lib';
}

use Webtoo;

my $datadir = './data';
my $config  = 'config';

my $wt = Webtoo.new( :datadir($datadir) );
$wt.loadMetadataFile($config); # The global config.
say $wt.processContent;

