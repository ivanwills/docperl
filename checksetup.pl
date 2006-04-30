#!/usr/bin/perl

# Created on: 2006-03-24 05:48:19
# Create by:  ivan

use strict;
use warnings;
use FindBin;
use File::Copy qw/copy/;
use Scalar::Util;
use List::Util;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;

our $VERSION = 0.1;

use lib ($FindBin::Bin);
my $CONFIG = "$FindBin::Bin/data/docperl.conf";

my %option = (
	compile			=> [],
	purge			=> 0,
	verbose 		=> 0,
	man				=> 0,
	help			=> 0,
	VERSION			=> 0,
);

my %required_modules = (
	Readonly		=> { },
	Template		=> { },
	'Config::Std'	=> { },
	'Pod::Html'		=> { },
	version			=> { },
);

main();
exit(0);

sub main {

	Getopt::Long::Configure("bundling");
	GetOptions(
		\%option,
		'compile|c=s@',
		'purge|p!',
		'verbose|v!',
		'man',
		'help',
		'version'
	) or pod2usage( 2 );
	
	print "checksetup.pl Version = $VERSION\n" and exit(1) if $option{version};
	pod2usage( -verbose => 2 ) if $option{man};
	pod2usage( -verbose => 1 ) if $option{help};

	# Check module existance
	my @missing;
	for my $module ( sort keys %required_modules ) {
		print $module, (' 'x(24 - length $module) );
		eval("require $module");
		if ( $@ ) {
			print "Missing\n";
			push @missing, $module;
		}
		else {
			my $version = eval("\$${module}::VERSION");
			print "OK    $version\n";
		}
	}
	if ( @missing ) {
		print "\n\nTo install all missing modules try the following commands:\n\n";
		print '$ cpan '.join(' ', @missing)."\nor\n";
		print "\$ perl -MCPAN -e 'install ", join( "'\n\$ perl -MCPAN -e 'install ", @missing ), "'\n\n";
		print "Windows/ActivePerl users try useing ppm\n";
	}
	
	print "\n";
	my $conf = "$FindBin::Bin/data/docperl.conf";
	unless ( -f $conf ) {
		my $eg = "$FindBin::Bin/data/docperl.conf.expample";
		die "Serious problem trying to set up config '$conf': Missing $eg\n"
			unless -f $eg;
		print "Setting default config. Please check the settings in $conf\n";
		copy $eg, $conf;
	}
	else {
		print "Config Exists\n";
	}
	
	# set up the local directory
	my $data  = "$FindBin::Bin/data";
	my $local = "$data/templates/local";
	unless ( -d $local ) {
		mkdir $local or warn "Could not create the local template directory '$local': $!\n";
	}
	print "\n";
	
	if ( $option{purge} ) {
		print "Clearing old cache files\n";
		system "rm -rf $FindBin::Bin/data/cache/*";
	}
	
	if ( ref $option{compile} && @{ $option{compile} } ) {
		use Config::Std;
		use Readonly;
		read_config $CONFIG, my %config;
		use DocPerl;
		my $dp = DocPerl->new( cgi => { page => 'list', }, conf => \%config, save_data => 1, data => $data, );
		my %data = $dp->list();
		
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
		$dp->init();
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

checksetup.pl - Program to check the setup of a DocPerl installation

=head1 VERSION

This documentation refers to checksetup.pl version 0.1.

=head1 SYNOPSIS

   checksetup.pl [option] 
   
 OPTIONS:
  -c --compile=opt   Pre compile the pod/api/code (seperate with commas to
                     compile more than one option)
  -p --purge         Purge the current cache files.
  
  -v --verbose       Show more detailed option
     --version       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for checksetup.pl



=head1 DESCRIPTION

This program checks to see if everything is ok with an install of DocPerl.
It checks that the required modules are installed, that there is a config
file and the security settings on the file system are setup correctly
(still to be fully completed). Also checksetup.pl can precompile all templates
for all pages to improve performance (at the expence of diskspace). Note that
in the future the compiled templates will be searchable.

=head1 DIAGNOSTICS

Known problems:

=over 4

=item POD Documentation

Generating of POD documentation requires permission to write temporary files
to the file system. This may not be possible by default with some web servers/
operating systems combinations (eg Linux with extra security enabled by default
in Fedora).

=back

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script.

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

