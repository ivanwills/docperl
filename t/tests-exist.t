#!perl

use strict;
use warnings;
use Test::More;
use File::Find;
use FindBin qw/$Bin/;

my @modules;
find(
	sub {
		return if !/[.]pm$/;
		my ($module) = $File::Find::name =~ m{^ $Bin/../lib/ (.*) $ }xms;
		push @modules, $module;
	},
	"$Bin/../lib"
);

plan tests => scalar @modules;
for my $module (@modules) {
	$module =~ s{ [.]pm }{}gxms;

	my $file = "$module.t";
	$file   =~ s{ / }{-}gxms;
	$module =~ s{ / }{::}gxms;

	ok( -f "$Bin/$file", "Have test for $module - t/$file" );
}
