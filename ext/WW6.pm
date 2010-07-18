#!/usr/bin/perl
package WW6;

# A Perl 5 library offering limited support of ww6 features.
# You can set up redirection and header rules, and parse
# ww6 static page caches (includng the Autoroot functionality.)

use Mouse;
use v5.10;

use YAML::Syck 'LoadFile'; # Would normally use YAML::XS.
use CGI::Simple;
use Carp;

has 'file',    is => 'ro', required => 1;
has 'env',     is => 'ro', default => sub { \%ENV };
has 'cgi',     is => 'ro', default => sub { CGI::Simple->new };
has 'headers', is => 'ro';
has 'path',    is => 'ro', lazy_build => 1;
has 'uri',     is => 'ro', lazy_build => 1;
has 'proto',   is => 'ro', lazy_build => 1;
has 'port',    is => 'ro', lazy_build => 1;
has 'host',    is => 'ro', lazy_build => 1;
has 'conf',    is => 'ro', lazy_build => 1;

sub _build_path {
    my $self = shift;
    return $self->env->{'PATH_INFO'};
}

sub _build_uri {
    my $self = shift;
    return $self->env->{'REQUEST_URI'};
}

sub _build_proto {
    my $self = shift;
    return $self->env->{'HTTPS'} ? 'https' : 'http';
}

sub _build_host {
    my $self = shift;
    return $self->env->{'HTTP_HOST'};
}

sub _build_port {
    my $self = shift;
    return $self->env->{'SERVER_PORT'};
}

sub _build_conf {
    my $self = shift;
    my $file = LoadFile($self->file) or croak "Could not load config";
    return $file;
}


