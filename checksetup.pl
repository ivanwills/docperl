#!/usr/bin/perl

# Created on: 2006-03-24 05:48:19
# Create by:  ivan

use strict;
use warnings;
use FindBin;
use File::Copy qw/copy/;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;

our $VERSION = 0.6;

use lib ($FindBin::Bin);
my $CONFIG = "$FindBin::Bin/docperl.conf";

my %option = (
	compile => [],
	shrink  => 0,
	purge   => 0,
	verbose => 0,
	man     => 0,
	help    => 0,
	VERSION => 0,
);

my %required_modules = (
	Readonly      => { },
	Template      => { },
	'Config::Std' => { },
	'Pod::Html'   => { },
	version       => { },
	'File::stat'  => { },
	'File::Path'  => { },
);

main();
exit(0);

sub main {

	Getopt::Long::Configure("bundling");
	GetOptions(
		\%option,
		'compile|c=s@',
		'purge|p!',
		'shrink|s!',
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
			$required_modules{$module}{missing} = 1;
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

	# check if we have Config::Std before continuing
	exit 20 if $required_modules{'Config::Std'}{missing};

	# read the config file
	eval('use Config::Std qw/read_config/');
	my %config;
	read_config( $CONFIG, \%config );

	# get the data directory
	my $data  = $config{General}{Data};
	unless ( -d $data ) {
		warn "Cannot find the data directory at '$data' please update docperl.conf to point to the correct location\n";
		exit 30;
	}

	# set up the cache directory
	my $cache = "$data/cache";
	unless ( -d $cache ) {
		print "Creating cache directory, '$cache'\n";
		mkdir $cache or warn "Could not create the cache directory '$cache': $!\n";
	}

	# set up the local directory
	my $local = "$data/templates/local";
	unless ( -d $local ) {
		print "Creating local template directory, '$local'\n";
		mkdir $local or warn "Could not create the local template directory '$local': $!\n";
	}
	print "\n";

	# purge the cache files (if requested)
	if ( $option{purge} ) {
		print "Clearing old cache files\n";
		system "rm -rf $FindBin::Bin/data/cache/*";
	}

	# create shrunken versions of files
	if ( $option{shrink} ) {
		print "Shrinking CSS and Javascript files ...\n";
		shrink_file($data, 'list.js.tmpl', 'js');
		shrink_file($data, 'css.css.tmpl', 'css');
	}

	# compile the cache files (if requrested)
	if ( ref $option{compile} && @{ $option{compile} } ) {
		$config{Templates}{ClearCache} = 'on';
		eval('use DocPerl');
		my $dp = DocPerl->new( cgi => { page => 'list', }, conf => \%config, save_data => 1, );
		my %data = $dp->list();

		my @compile = map { split /,/ } @{ $option{compile} };
		compile( \%data, $dp, \@compile );
		system("chmod o+w -R $FindBin::Bin/data/cache");
	}
}

sub shrink_file {
	my ( $data, $template, $type ) = @_;

	# shrink the JS template
	my $js = "$data/templates/default/$template";
	open my $fh, '<', $js;

	if ( !$fh ) {
		warn "Could not open the javascript template file $js! $!\n";
	}
	else {
		my $text;
		{
			local $/ = undef;
			$text = <$fh>;
		}
		close $fh;

		$text = $type eq 'js' ? shrink_js($text) : shrink_css($text);

		## save the template to the local template dir
		$js = "$data/templates/local/$template";
		if ( length $text && open $fh, '>', $js ) {
			print {$fh} $text;
			close $fh;
		}
	}

}

sub shrink_js {
	my ( $text ) = @_;

	## remove the unnessesary text
	# multi line comments
	$text =~ s{/[*][*] .*? [*]/\n*}{}gxms;
	# end of line comments
	$text =~ s{\s*//[^\n]*\n}{\n}gxms;
	# multiple new lines
	$text =~ s/\n\n+/\n/gxms;
	# new line after statements
	$text =~ s/;\n\s+/;/gxms;
	# white space arround brackets
	$text =~ s/\s* ( [(){] ) \s*/$1/gxms;
	$text =~ s/\s*{\n/{/gxms;
	$text =~ s/\s* ( [^\w\s'] ) \s*/$1/gxms;
	$text =~ s/\n}/}/gxms;
	$text =~ s/}\n([^f])/}$1/gxms;
	# multiple white space
	$text =~ s/\s\s+/ /gxms;
	$text =~ s/;}/}/gxms;

	my %replace = (
		'document.getElementById' => '$',
		'document.createTextNode' => '$ct',
		'document.createElement'  => '$ce',
	);
	my $func = join '', map { "function $replace{$_}(a){return $_(a)}" } keys %replace;
	my $list = join '|', keys %replace;

	$text =~ s/($list)/$replace{$1}/gxms;
	$text .= $func;

	%replace = (
		'add_count'         => 'ac',
		'clear_cookie'      => 'cc',
		'cookie_number'     => 'cn',
		'create_module'     => 'Cm',
		'create_plus'       => 'Cp',
		'create_tree'       => 'Ct',
		'container_id'      => 'ci',
		'count'             => 'C',
		'count_tree'        => 'ct',
		'counter'           => 'c',
		'counter_span'      => 'cs',
		'counter_value'     => 'cv',
		'display_recent'    => 'dr',
		'end_of_cookie'     => 'eoc',
		'exists_cookie'     => 'ec',
		'expiry_date'       => 'ed',
		'expiry_string'     => 'es',
		'found'             => 'f',
		'find_in'           => 'fi',
		'files_sort'        => 'fs',
		'debug_div'         => 'dd',
		'debug_found'       => 'df',
		'domain_string'     => 'ds',
		'get_cookie'        => 'gc',
		'get_cookie_count'  => 'gcc',
		'get_cookie_number' => 'gcn',
		'head'              => 'h',
		'lable'             => 'L',
		'link'              => 'l',
		'list'              => 'l',
		'list_toggle'       => 'lt',
		'li_sub'            => 'ls',
		'module'            => 'm',
		'my_cookie'         => 'mc',
		'name'              => 'c',
		'name_length'       => 'nl',
		'path_string'       => 'ps',
		'path_to_module'    => 'ptm',
		'plus'              => 'l',
		'result'            => 'r',
		'search_name'       => 'sn',
		'sect'              => 'S',
		'section'           => 's',
		'set_cookie'        => 'sc',
		'secure_string'     => 'ss',
		'show_found'        => 'sf',
		'start_of_cookie'   => 'soc',
		'term'              => 't',
		'terms'             => 'T',
		'three_days'        => 't',
		'tree_holder'       => 'th',
		'ul_sub'            => 'us',
	);
	$list = join '|', keys %replace;

	$text =~ s/(?<!\w)($list)(?!\w)/$replace{$1}/gxms;

	return $text;
}

sub shrink_css {
	my ( $text ) = @_;

	## remove the unnessesary text
	# multi line comments
	$text =~ s{/[*] .*? [*]/\n*}{}gxms;
	# end of line comments
	$text =~ s{\s*//[^\n]*\n}{\n}gxms;
	# multiple new lines
	$text =~ s/\n\n+/\n/gxms;
	# new line after statements
	$text =~ s/;\n\s+/;/gxms;
	# white space arround brackets
	$text =~ s/\s* ( [(){] ) \s*/$1/gxms;
	$text =~ s/\s*{\n/{/gxms;
	$text =~ s/\s* ( [^\w\s'] ) \s*/$1/gxms;
	$text =~ s/\n}/}/gxms;
	$text =~ s/}\n([^f])/$1/gxms;
	# multiple white space
	$text =~ s/\s\s+/ /gxms;
	$text =~ s/;}/}/gxms;

	return $text;
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

This documentation refers to checksetup.pl version 0.6.0.

=head1 SYNOPSIS

   checksetup.pl [ --version | --help | --man ]
   checksetup.pl [ -v ] [ -p ] [ -c [ pod||,api||,code ]

 OPTIONS:
  -c --compile=opt Pre compile the pod/api/code (seperate with commas to
                   compile more than one option eg -c pod,code)
  -p --purge       Purge the current cache files.
  -s --shrink      Shrink the size of the js & css files (makes them less
                   readable but smaller)

  -v --verbose     Show more detailed option
     --version     Prints the version information
     --help        Prints this help information
     --man         Prints the full documentation for checksetup.pl

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

