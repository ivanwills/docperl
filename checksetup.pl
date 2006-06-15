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

our $VERSION = 0.3;

use lib ($FindBin::Bin);
my $CONFIG = "$FindBin::Bin/docperl.conf";

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
	unless ( -f $CONFIG ) {
		my $eg = "$CONFIG.example";
		die "Serious problem trying to set up config '$CONFIG': Missing $eg\n"
			unless -f $eg;
		print "Setting default config. Please check the settings in $CONFIG\n";
		copy $eg, $CONFIG;
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
		$config{Templates}{ClearCache} = 'on';
		use DocPerl;
		my $dp = DocPerl->new( cgi => { page => 'list', }, conf => \%config, save_data => 1, data => $data, );
		my %data = $dp->list();
		
		my @compile = map { split /,/ } @{ $option{compile} };
		compile( \%data, $dp, \@compile );
		system("chmod o+w -R $FindBin::Bin/data/cache");
	}
}

sub compile {
	my ( $data, $dp, $compile ) = @_;
	
		#for my $location ( qw/LOCAL / ) {
		for my $location ( qw/PERL LOCAL INC/ ) {
			print "Create $location Cache\n";
			cache( $data->{$location}, $dp, location => lc $location, top => 1, map {$_=>1} @$compile );
			#die Dumper $data->{$location};
		}
}

sub cache {
	my ( $data, $dp, %arg ) = @_;
	my $location = $arg{location};
	my $parent   = $arg{parent};
	$parent    ||= '';
	$arg{all}  ||= '';
	
	for my $module ( keys %{ $data } ) {
		next unless $module;
		next if $module eq '*';
		next if $data->{$module} == 1;
		
		# check that the module is not the numeral 1 (just an alphabetic place holder)	
		# and that there is an actual file for it (ie not just a name space prefix)
		if ( !$arg{top} && $data->{$module}{'*'}[0] ) {
			$dp->{cgi} = { page => 'pod', module => "$parent$module", location => $location, source => $data->{$module}{'*'}[0] };
			$dp->init();
			if ( $arg{pod} ) {
				$dp->process();
			}
			if ( $arg{api} ) {
				$dp->{cgi}{page} = 'api';
				$dp->{template}  = 'api.html';
				# Unfortunatly repeated processing of api's can be dangerous to this is now disabled
				#$dp->process();
			}
			if ( $arg{code} ) {
				$dp->{cgi}{page} = 'code';
				$dp->{template}  = 'code.html';
				$dp->process();
			}
		}
		
		my $super = !$arg{top} ? "$parent$module\:\:" : '';
		cache( $data->{$module}, $dp, %arg, parent => $super, top => 0, all => "$arg{all}/$module" );
	}
}

__DATA__

=head1 NAME

checksetup.pl - Program to check the setup of a DocPerl installation

=head1 VERSION

This documentation refers to checksetup.pl version 0.3.

=head1 SYNOPSIS

   checksetup.pl [ --version | --help | --man ]
   checksetup.pl [ -v ] [ -p ] [ -c [ pod||,api||,code ]
   
 OPTIONS:
  -c --compile=opt   Pre compile the pod/api/code (seperate with commas to
                     compile more than one option eg -c pod,code)
  -p --purge         Purge the current cache files.
  
  -v --verbose       Show more detailed option
     --version       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for checksetup.pl
  
  Note: Creating cached api files (-c api) can cause checksetup.pl to crash

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

=item API Cache

The generation of the API cache files will load those modules (with require Module)
to get the version number and the object hirachy. This is usually OK when
performed once if run from the through the web interface (or with get-api.pl)
but when run with this script more than one module with the same name may be
run. This may be due to being included both @INC and paths defined in
docperl.conf or being installed in more than one place etc. This can some
times cause checksetup.pl to crash. I am working on a solution for this, but
for the moment if this happens to you do not try to pre-compile the api files.

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<checksetup.pl> is controlled by it's command line options (see above) but
will use docperl.conf when creating cached files.

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

