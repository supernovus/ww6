#!/usr/bin/perl
package WW6;

# A Perl 5 library offering limited support of ww6 features.
# You can set up redirection and header rules, and parse
# ww6 static page caches (includng the Autoroot functionality.)

use strict;
use warnings;
use v5.10;

use base 'SimpleClass';

use YAML::XS;

## init()
#
#  Set up the class structure.
#

sub init {
    my $self = shift;
    my $struct = {
        'env'     => { ro => 1, default => \%ENV },
        'headers' => {},
        'cgi'     => { ro => 1, default => CGI::Simple->new },
        'path'    => { ro => 1 },
        'uri'     => { ro => 1 },
        'proto'   => { ro => 1 },
        'port'    => { ro => 1 },
        'host'    => { ro => 1 },
        'config'  => { ro => 1, required => 1 },
    };
    $self->_init_class($struct, @_);
    $self->{path}  = $self->{env}{'PATH_IFO'};
    $self->{uri}   = $self->{env}{'REQUEST_URI'};
    $self->{proto} = $self->{env}{'HTTPS'} ? 'https' : 'http'; 
    $self->{host}  = $self->{env}{'HTTP_HOST'};
    $self->{port}  = $self->{env}{'SERVER_PORT'};

    ## A bit of magic. You must specify the config file in the script
    #  The config attribute will be replaced by a YAML tree.
    $self->{config} = LoadFile($self->{config});
}

