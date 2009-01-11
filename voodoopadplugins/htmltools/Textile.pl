#!/usr/bin/perl

$file = $ARGV[0] . ".html";

my $input = do { local $/; <> };

$me = `echo ${0}`;
$len = length($me);
$parentDir = substr($me, 0, $len - 12);

chdir($parentDir);

require Text::Textile;
#require Textile;

my $textile = new Text::Textile;
#my $textile = new Textile;

$textile->charset("UTF-8");

open( FILE, "> $file" ) or die "Can't open $file : $!";
print FILE $textile->textile($input);
close FILE;

#print $file . "\n";
