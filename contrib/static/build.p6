#!/usr/local/bin/perl6

our $pdir = './src/pages/';
our $tdir = './src/templates/';
our $ext  = '.html';
our $ddir = './site/';

sub MAIN ( $page, $save? ) {
    if $pdir~$page~$ext ~~ :e {
        my $content = parsePage($page);
        if $save {
            my $filename = $ddir~$page~$ext;
            my $file = open $filename, :w;
            say "Regenerating $filename";
            $file.print($content);
            $file.close;
        }
        else {
            print $content;
        }
    }
    ## TODO: Parse an entire sub-directory.
}

sub parsePage ( $page ) {
    my %opts;
    %opts<content> = '';
    my @lines = lines($pdir~$page~$ext);
    for @lines -> $line {
        if $line ~~ / \< \% (\w+) \= \"(.*?)\" \% \> / {
            #say "Setting $0 to $1";
            %opts{$0} = $1;
        }
        else { 
            %opts<content> ~= $line ~ "\n";
        } 
    }
    my $template = 'default';
    if %opts<template> && %opts<template> ~~ :f {
        $template = delete %opts<template>;
    }
    return parseTemplate( $template, %opts );
}

sub parseTemplate ( $template, %opts ) {
    my $content = slurp($tdir~$template~$ext);
    $content.=subst( / \< \% (\w+) \% \> /, { %opts{$_[0] } // '' }, :global );
    return $content;
}


