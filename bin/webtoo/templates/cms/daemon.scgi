#!/usr/bin/env perl6
#
# A skeleton application, set up to use dynamic metadata plugins.

BEGIN {
    @*INC.push: './lib';
    print "Initializing System... ";
}

use SCGI;
use Webtoo;

my $port = 8118; ## SCGI port
my $datadir = './data'; ## The directory our data is stored in.
my $config  = 'config.json'; ## Name of the configuration file, in datadir.

my $scgi = SCGI.new( :port($port), :strict ); ## Create an SCGI object.

## Now we're going to create a handler subroutine to handle page requests.
my $handler = sub (%env) {
    ## Create the Webtoo object.
    my $wt = Webtoo.new( 
        :env(%env), 
        :datadir($datadir),
    ); 
    $wt.metadata.loadFile($config); ## Load the config file.
    $wt.processPlugins; ## Process plugins in the 'plugins' metadata array.
    return $wt.processContent; ## Return processed content to web server.
}

say "done.";

$scgi.handle: $handler; ## Pass the handler to the SCGI object.

## End of script.

