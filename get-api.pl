#!/usr/bin/perl

# Created on: 2006-05-24 20:25:32
# Create by:  ivan

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
use lib "$FindBin::Bin";

use DocPerl::Cached::API;
use DocPerl qw/find/;

sub say;
our $VERSION = version->new('0.1');

my %option = (
	columns			=> 2,
	colour			=> 0,
	verbose 		=> 0,
	man				=> 0,
	help			=> 0,
	VERSION			=> 0,
);
my %colours = (
	headding	=> 'bold blue',
	file		=> 'green on_white',
	module		=> 'bold',
	content		=> '',
);

pod2usage( -verbose => 1 ) unless @ARGV;

main();
exit(0);

sub main {

	Getopt::Long::Configure("bundling");
	GetOptions(
		\%option,
		'columns|c=i',
		'verbose|v!',
		'man',
		'help',
		'version'
	) or pod2usage( 2 );
	
	my $file = pop @ARGV;
	my $module;
	
	print "get-api Version = $VERSION\n" and exit(1) if $option{version};
	pod2usage( -verbose => 2 ) if $option{man};
	pod2usage( -verbose => 1 ) if $option{help};

	# check if the file is actually a module (and find its real file)
	unless ( -f $file ) {
		# assume file is a module
		$module = $file;
		$module =~ s{::}{/}gxs;
		undef $file;
		
		for my $path ( @INC ) {
			find(
				$path,
				$module,
				sub {
					my $full = shift;
					return if $full =~ m{^\./data}xs || $full =~ m{.svn|/t/}xs;
					if ( $full =~ m{^ (?:$path) /? (?:$module) ([.]p(?:m|l)) $}xs ) {
						$file ||= $full;
					}
				}
			);
			last if $file;
		}
	}
	
	# Get the API for the file
	my $api = DocPerl::Cached::API->new(
		conf			=> {
			General		=> {
				Data	=> '/tmp/',
			},
			IncFolders	=> {
				Path	=> '',
			},
		},
		source			=> $file,
		current_location=> '',
	);
	my %data = $api->process();
	$api = $data{api};
	
	# print out the API
	if ( $module ) {
		say 'module', $module;
		say 'file', $file;
	}
	if ( $api->{modules} ) {
		say 'headding', "Modules Used:\n";
		display( $api->{modules}, %option );
		print "\n";
	}
	if ( $api->{class} ) {
		say 'headding',  "Class Methods:\n";
		display( $api->{class}, %option );
		print "\n";
	}
	if ( $api->{object} ) {
		say 'headding',  "Object Methods:\n";
		display( $api->{object}, %option );
		print "\n";
	}
	if ( $api->{func} ) {
		say 'headding', "General Functions:";
		display( $api->{func}, %option );
		print "\n";
	}
}

=head3 C<display ( $list )>

Param: C<$list> - type (detail) - description

Return:  - 

Description: 

=cut

sub display {
	my ( $list, %option ) = @_;
	my $max = 10;
	$list = [ sort keys %$list ] if ref $list eq 'HASH';

	map {
		if ( ref $_ ) {
			$max = length $_->{name} if length $_->{name} > $max;
		}
		else {
			$max = length $_ if length $_ > $max;
		}
	} @$list;

	for ( my $i = 0; $i < @$list; $i += $option{columns} ) {
		my $out = '';
		for my $j ( 0 .. $option{columns} - 1 ) {
			next unless $list->[$i+$j];
			if ( ref $list->[$i+$j] ) {
				$out .= $list->[$i+$j]->{name}. ' ' x ( $max - length( $list->[$i+$j]->{name} ) + 1);
			}
			else {
				$out .= $list->[$i+$j]. ' ' x ( $max - length( $list->[$i+$j] ) + 1);
			}
		}
		say( 'content', $out );
	}
}

=head3 C<say ( $type, @line )>

Param: C<$type> - string (detail) - The type of line to print

Param: C<@line> - strings (detail) - the data to print

Return: none - 

Description: Prints colourised lines

=cut

sub say {
	my ( $type, @line ) = @_;
	my $line = join '', @line;
	$line .= "\n" unless $line =~ /\n$/;
	
	if ( $option{colour} ) {
		print Term::ANSIColor::colored( $line, $colours{$type} );
	}
	else {
		print $line;
	}
}


__DATA__

=head1 NAME

get-api - Displays a summary of the API used by the file or module passed

=head1 VERSION

This documentation refers to get-api version 0.1.

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

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)
<Author name(s)> - (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
