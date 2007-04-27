#!/usr/bin/perl

# Created on: 2006-05-24 20:25:32
# Create by:  ivan
# $Id$
# # $Revision$, $HeadURL$, $Date$
# # $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Scalar::Util;
use List::Util;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use Term::ANSIColor qw/:constants/;
use FindBin;
use lib qw/$FindBin::Bin/;
use English qw/ -no_match_vars /;

use DocPerl::View::API;
use DocPerl qw/find/;

sub colour_line;
our $VERSION = version->new('0.9.2');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
	columns => 2,
	colour  => 0,
	verbose => 0,
	man     => 0,
	help    => 0,
	VERSION => 0,
);
my %colours = (
	headding => 'bold blue',
	file     => 'green on_white',
	module   => 'bold',
	content  => q//,
);

if ( !@ARGV ) {
	pod2usage( -verbose => 1 );
}

main();
exit 0;

sub main {

	Getopt::Long::Configure('bundling');
	GetOptions(
		\%option,
		'columns|c=i',
		'verbose|v!',
		'man',
		'help',
		'version'
	) or pod2usage(2);

	my $file = pop @ARGV;
	my $module;

	if ( $option{VERSION} ) {
		print "$name Version = $VERSION";
		exit 1;
	}
	elsif ( $option{man} ) {
		pod2usage( -verbose => 2 );
	}
	elsif ( $option{help} ) {
		pod2usage( -verbose => 1 );
	}

	# check if the file is actually a module (and find its real file)
	if ( !-f $file ) {

		# assume file is a module
		$module = $file;
		$module =~ s{::}{/}gxms;
		undef $file;

		for my $path (@INC) {
			find(
				$path,
				$module,
				sub {
					my $full = shift;
					return if $full =~ m{^\./data}xms || $full =~ m{.svn|/t/}xms;
					if ( $full =~ m{^ (?:$path) /? (?:$module) ([.]p(?:m|l)) $}xms ) {
						$file ||= $full;
					}
				}
			);
			last if $file;
		}
	}

	# Get the API for the file
	my $api = DocPerl::View::API->new(
		conf => {
			General    => { Data => '/tmp/', },
			IncFolders => { Path => q//, },
		},
		source           => $file,
		current_location => q//,
	);
	my %data = $api->process();
	$api = $data{api};

	# print out the API
	if ($module) {
		colour_line 'module', $module;
		colour_line 'file',   $file;
	}
	if ( $api->{modules} ) {
		colour_line 'heading', "Modules Used:\n";
		display( $api->{modules}, %option );
		print "\n";
	}
	if ( $api->{class} ) {
		colour_line 'heading', "Class Methods:\n";
		display( $api->{class}, %option );
		print "\n";
	}
	if ( $api->{object} ) {
		colour_line 'heading', "Object Methods:\n";
		display( $api->{object}, %option );
		print "\n";
	}
	if ( $api->{func} ) {
		colour_line 'heading', "General Functions:\n";
		display( $api->{func}, %option );
		print "\n";
	}

	return;
}

sub display {
	my ( $list, %option ) = @_;
	my $max = 10;
	if ( ref $list eq 'HASH' ) {
		$list = [ sort keys %{$list} ];
	}

	map {
		if ( ref $_ ) {
			if ( length $_->{name} > $max ) {
				$max = length $_->{name};
			}
		}
		elsif ( length $_ > $max ) {
			$max = length $_;
		}
	} @{$list};

	for ( my $i = 0; $i < @$list; $i += $option{columns} ) {    ## no critic
		my $out = q//;
		for my $j ( 0 .. $option{columns} - 1 ) {
			next if !$list->[ $i + $j ];
			if ( ref $list->[ $i + $j ] ) {
				$out .= $list->[ $i + $j ]->{name} . q/ / x ( $max - length( $list->[ $i + $j ]->{name} ) + 1 );
			}
			else {
				$out .= $list->[ $i + $j ] . q/ / x ( $max - length( $list->[ $i + $j ] ) + 1 );
			}
		}
		colour_line( 'content', $out );
	}

	return;
}

sub colour_line {
	my ( $type, @line ) = @_;
	my $line = join q//, @line;
	if ( $line !~ /\n\Z/xms ) {
		$line .= "\n";
	}

	if ( $option{colour} ) {
		print Term::ANSIColor::colored( $line, $colours{$type} );
	}
	else {
		print $line;
	}

	return;
}

__DATA__

=head1 NAME

get-api - Displays a summary of the API used by the file or module passed

=head1 VERSION

This documentation refers to get-api version 0.9.2.

=head1 SYNOPSIS

   get-api [options] file | module
   get-api [ --version | --help | --man ]

 OPTIONS:
  -c --columns  The number of columns to format the out put into (Default 2)
     --nocolor  Turns off the colouring of the output

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for get-api

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<display ( $list )>

Param: C<$list> - type (detail) - description

Return:  -

Description:

=head3 C<colour_line ( $type, @line )>

Param: C<$type> - string (detail) - The type of line to print

Param: C<@line> - strings (detail) - the data to print

Return: none -

Description: Prints colourised lines

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
