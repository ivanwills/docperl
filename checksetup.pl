#!/usr/bin/perl

# Created on: 2006-03-24 05:48:19
# Create by:  ivan

use strict;
use warnings;
use FindBin;
use Scalar::Util;
use List::Util;
use Config::Std;
use Readonly;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;

our $VERSION = 0.1;

use lib ($FindBin::Bin);
Readonly my $CONFIG => "$FindBin::Bin/data/docperl.conf";

my %option = (
	compile			=> [],
	verbose 		=> 0,
	man				=> 0,
	help			=> 0,
	VERSION			=> 0,
);

main();
exit(0);

sub main {

	Getopt::Long::Configure("bundling");
	GetOptions(
		\%option,
		'compile|c=s@',
		'verbose|v!',
		'man',
		'help',
		'version'
	) or pod2usage( 2 );
	
	print "checksetup.pl Version = $VERSION\n" and exit(1) if $option{version};
	pod2usage( -verbose => 2 ) if $option{man};
	pod2usage( -verbose => 1 ) if $option{help};

	# Check module existance
	eval("require Readonly");
	if ( $@ ) {
		print "Readonly", ' 'x15, "Missing\n";
	}
	else {
		print "Readonly", ' 'x15, "$Readonly::VERSION",' 'x5,"OK\n";
	}
	eval("require Template");
	if ( $@ ) {
		print "Template", ' 'x15, "Missing\n";
	}
	else {
		print "Template", ' 'x15, "$Template::VERSION",' 'x5,"OK\n";
	}
	eval("require Config::Std");
	if ( $@ ) {
		print "Config::Std", ' 'x15, "Missing\n";
	}
	else {
		print "Config::Std", ' 'x12, "$Config::Std::VERSION",' 'x3,"OK\n";
	}
	print "\n";
	
	if ( ref $option{compile} && @{ $option{compile} } ) {
		read_config $CONFIG, my %config;
		use DocPerl;
		my $dp = DocPerl->new( cgi => { page => 'list', }, conf => \%config, save_data => 1 );
		my %data = $dp->process();
		
		for my $options ( @{ $option{compile} } ) {
			for my $option ( split /,/, $options ) {
				compile( lc $option, \%data, $dp );
			}
		}
		`chmod o+w -R $FindBin::Bin/data/cache`;
	}
}

sub compile {
	my ( $type, $data, $dp ) = @_;
	
	if ( $type eq 'pod' ) {
		use DocPerl::Cached::POD;
		#for my $location ( qw/LOCAL / ) {
		for my $location ( qw/PERL LOCAL INC/ ) {
			print "Create $location POD\n";
			pod( $data->{$location}, $dp, lc $location );
			#die Dumper $data->{$location};
		}
	}
}

sub pod {
	my ( $data, $dp, $location, $parent ) = @_;
	$parent ||= '';
	$parent .= '::' if $parent;
	#die Dumper $data if $location eq 'local';
	
	for my $module ( keys %{ $data } ) {
		next if $module eq '*';
		next if $module =~ m{/};
		
		#warn "$parent$module\n";
		$dp->{cgi} = { page => 'pod', module => "$parent$module", location => $location };
		$dp->process();
		
		if ( ref $data->{$module} && keys %{ $data->{$module} } > ($parent?1:0) ) {
			for my $sub ( keys %{ $data->{$module} } ) {
				next if $sub =~ /\*/;
				my $super = ( !$parent && length $module > 1 ) ? "$parent$module" : '';
				pod( $data->{$module}{$sub}, $dp, $location, $super );
			}
		}
	}
}

__DATA__

=head1 NAME

checksetup.pl - <One-line description of commands purpose>

=head1 VERSION

This documentation refers to checksetup.pl version 0.1.

=head1 SYNOPSIS

   checksetup.pl [option] 
   
 OPTIONS:
  -c --compile=opt   Pre compile the pod/api/code (seperate with commas to
                     compile more than one option)

  -v --verbose       Show more detailed option
     --version       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for checksetup.pl



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
