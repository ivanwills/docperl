#!/usr/bin/perl

# Created on: 2006-06-25 05:55:36
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use FindBin qw/$Bin/;
use Data::Dumper qw/Dumper/;
use CGI;
use Config::Std;
use Readonly;
use lib qw/./;
use DocPerl::Search::Grep;
use DocPerl::Search::Perl;

our $VERSION = version->new('0.9.2');

Readonly my $BASE   => $Bin;
Readonly my $CONFIG => "$BASE/docperl.conf";

# for taint saifty remove the environment's PATH;
delete $ENV{PATH};

main();
exit 0;

sub main {
	my $cgi = CGI->new();
	read_config $CONFIG, my %config;

	my $engine = $config{'Search'}{'Engine'} eq 'Grep'
		&& -x $config{'Search'}{'grep'} ? 'DocPerl::Search::Grep' : 'DocPerl::Search::Perl';
	my $terms = $cgi->param('terms') || $ARGV[0] || 'test';
	my $type  = $cgi->param('type')  || $ARGV[1] || 'xml';
	my $area  = $cgi->param('area')  || $ARGV[2] || 'text';

	# get the search engine object
	my $search = $engine->new( conf => \%config, );

	# find the files
	my @files = $search->search( terms => $terms, area => $area );

	if ( $type eq 'jason' ) {
		jason( $cgi, $terms, @files );
	}
	else {
		xml( $cgi, $terms, @files );
	}

	return;
}

sub jason {
	my ( $cgi, $terms, @files ) = @_;
	my $count = @files || 0;
	my %results;
	for my $result (@files) {
		push @{ $results{ $result->[1] } }, $result->[0];
	}
	print $cgi->header('text/jason');
	print "{'terms':'$terms','count':$count,'results':{";
	print join q{,}, map { "'$_':['" . ( join q{','}, @{ $results{$_} } ) . q{']} } keys %results;
	print "}}\n";

	return;
}

sub xml {
	my ( $cgi, $terms, @files ) = @_;
	print $cgi->header('text/xml');
	print "<search>\n\t<terms>$terms</terms>\n\t<results>\n";
	for my $file (@files) {
		print "\t\t<file area=\"$file->[1]\">$file->[0]</file>\n";
	}
	print "\t</results>\n</search>\n";

	return;
}

__DATA__

=head1 NAME

search.cgi - Searches the POD, API's and Code cached DocPerl files

=head1 VERSION

This documentation refers to search.cgi version 0.9.2.

=head1 SYNOPSIS

   search.cgi?type={pod|api|code}&?

  type   Specifys which type of cached files to search.



=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
