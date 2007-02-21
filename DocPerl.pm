package DocPerl;

# Created on: 2006-01-31 19:59:04
# Create by:  Ivan Wills

use strict;
use warnings;
use version;
use Carp qw/carp croak confess cluck/;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use Template;
use DocPerl::Cached;
use base qw/Exporter/;

our $VERSION   = version->new('0.6.0');
our @EXPORT_OK = qw/find/;

sub new {
	my $caller = shift;
	my $class  = ( ref $caller ) ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	carp 'Need cgi parameters'  if !$self->{cgi};
	carp 'Need conf parameters' if !$self->{conf};

	bless $self, $class;

	# initialise the object
	$self->init();

	return $self;
}

sub init {
	my $self = shift;
	my $q    = $self->{cgi};
	my $conf = $self->{conf};
	my $page = $q->{page};

	# initialise the template name and mime type
	if ($page) {
		my $template = $page;
		if ( $template =~ /\.(\w+)$/xms ) {
			$self->{template} = $template;
			my $type =
				  $1 eq 'css' ? 'css'
				: $1 eq 'js'  ? 'javascript'
				:               $1;
			$self->{mime} = "text/$type";
		}
		else {
			$self->{template} = "$template.html";
			$self->{mime}     = 'text/html';
		}
	}
	else {

		# if no page is given the default template is to create the frames page
		$self->{template} = 'frames.html';
		$self->{mime}     = 'text/html';
	}

	# check if a module has been passed as a CGI parameter
	if ( $q->{module} ) {
		$self->init_module();
	}

	return;
}


sub init_module {
	my $self = shift;
	my $q    = $self->{cgi};
	my $conf = $self->{conf};
	my $page = $q->{page};

	# check if the module starts with a double underscore which means that
	# it came from the module list page
	if ( $q->{module} =~ /__/xms ) {

		# module came from the front page so need to get the actual module
		# name from the module parameter
		my $module = $self->{tag} = $q->{module};

		# remove the location start parts
		$module =~ s{^([^_]+)__[^_]+__}{}xms;

		# store the location
		$self->{current_location} = $1;

		# store the perl module name
		$self->{module}      = $module;
		$self->{module_file} = $module;

		# store the module file name
		$self->{module}      =~ s{__}{::}gxms;
		$self->{module_file} =~ s{__}{/}gxms;
		if ( $self->{current_location} eq 'perl' ) {
			$self->{module_file} = "pod/$self->{module_file}";
		}
	}
	elsif ( $q->{module} =~ m{^link/(.+)(?:[.]html)$}xms ) {
		$self->{current_location} = $q->{location};
		$self->{module}           = $1;
		$self->{module_file}      = $1;

		$self->{module} =~ s{/}{::}gxms;
	}
	else {

		# extract the cgi parameters
		$self->{current_location} = $q->{location};
		$self->{module}           = $q->{module};
		$self->{module_file}      = $q->{module};

		# Convert the module_file parameter to a more file like name
		# ie convert double colons to forward slashes (:: -> /)
		$self->{module_file} =~ s{::}{/}gxms;
		if ( $self->{current_location} eq 'perl' ) {
			$self->{module_file} = "pod/$self->{module_file}";
		}
	}

	# Check after all that we still have a module, file and a location
	croak 'Module went!'      if !$self->{module};
	croak 'Module file went!' if !$self->{module_file};
	croak 'Location went!'    if !$self->{current_location};

	# Find all files that match the module
	$self->find_matches();

	return;
}

sub find_matches {
	my $self = shift;
	my $q    = $self->{cgi};
	my $conf = $self->{conf};

	my $file = $self->{module_file};
	my @files;
	my @folders;
	my @suffixes;

	# Get the folder locations and file name suffixes for the current
	# location.
	if ( $self->{current_location} eq 'local' ) {
		@folders  = split /:/xms, $conf->{LocalFolders}{Path};
		@suffixes = @{ $conf->{LocalFolders}{suffixes} };
	}
	else {
		@folders = @INC;
		push @folders, split /:/xms, $conf->{IncFolders}{Path};
		@suffixes = @{ $conf->{LocalFolders}{suffixes} };
	}

	# Get the location of the file
	for my $dir (@folders) {
		for my $suffix (@suffixes) {
			if ( -f "$dir/$file.$suffix" ) {
				push @files, { file => "$dir/$file.$suffix", suffix => $suffix };
			}
		}
	}

	# store all the calculated paramteres
	$self->{folders}  = \@folders;
	$self->{suffixes} = \@suffixes;
	$self->{sources}  = \@files;                           # all files that match the module name
	$self->{source}   = $q->{source} || $files[0]{file};

	#warn "$self->{current_location}: $self->{source}\nfolders = ".(join ', ', @folders);

	if ( ( !$self->{source} || !-e $self->{source} )
		&& $self->{current_location} eq 'local' ) {
		$self->{current_location} = 'inc';
		$self->find_matches();
	}

	return;
}

sub process {
	my $self = shift;
	my $conf = $self->{conf};
	my $q    = $self->{cgi};
	my $page = $q->{page};
	my %vars;
	my $out;
	my $cache = DocPerl::Cached->new( %{$self} );

	# check if we are meant to clear the cache (and the we are allowed to)
	if ( $conf->{Templates}{ClearCache} && $q->{clearcache} ) {
		$cache->clear_cache();
	}

	# create a cache object
	my $cache_path = $page || '';
	if ( $self->{current_location} ) {
		$cache_path .= "/$self->{current_location}";
	}
	if ( $self->{module_file} ) {
		$cache_path .= "/$self->{module_file}";
	}

	# Check if there is a page to view specified
	if ($page) {

		# check the cache for the page
		$out = $cache->_check_cache( cache => $cache_path, source => $self->{source} || 1 );

		# return the cached output
		return $out if $out;

		# Check that the page is OK to execute (ie if a method of this module
		# and is not a hidden method)
		if ( $page !~ /^_/xms && $self->can($page) ) {
			%vars = $self->$page();
		}
		elsif ( $page =~ /^(pod|text|api|code)$/xmsi ) {

			# try to see if the method is a cached module
			my $module = 'DocPerl::Cached::' . uc $1;
			warn $module;
			eval("require $module");
			if ($@) {
				carp $@;
			}
			else {

				# use the cached object to get the data
				my $cache = $module->new( %{$self} );
				%vars = $cache->process();
			}
		}
	}
	else {

		# this only occurs when showing frames page
		$self->{module} = $q->{module} || $conf->{General}{DefaultModule} || 'perl__pod__perlfunc';
	}

	# set up other required params
	$vars{DUMP}     = Dumper( \%vars );
	$vars{module}   = $self->{module};
	$vars{file}     = $self->{module_file};
	$vars{location} = $self->{current_location};
	$vars{sources}  = $self->{sources};
	$vars{source}   = $self->{source};

	# get the template object
	my $tmpl = $self->get_templ_object();

	# process the template
	$conf->{Template} ||= {};
	$tmpl->process( $self->template(), { %{$q}, %{ $conf->{Template} }, %vars }, \$out )
		or error( $tmpl->error );
		warn $self->template();
		warn length $out;
		warn scalar keys %vars;

	if ( $out =~ /\A\s+\Z/xms ) {
		croak 'The processed template "' . $self->template() . '" contains not data!' . Dumper \%vars, $out;
	}

	if ( $page && ( !$self->{source} || -f $self->{source} ) ) {
		$cache->_save_cache( cache => $cache_path, source => $self->{source} || 1, content => $out );
	}

	return $out;
}

sub error {
	my ($message) = @_;
	carp $message;

	return;
}

sub template {
	my $self = shift;
	return $self->{template} . '.tmpl';
}

sub get_templ_object {
	my $self = shift;
	my $conf = $self->{conf};

	return $self->{templ} if $self->{templ};

	my $data = $conf->{General}{Data};
	my $path = "$conf->{Templates}{Path}:$data/templates/local:$data/templates/default";
	$self->{templ} = Template->new( INCLUDE_PATH => $path, EVAL_PERL => 1 );
	croak "Could not create the template object!" if !$self->{templ};

	return $self->{templ};
}

sub mime {
	my $self = shift;
	return $self->{mime} || 'text/html';
}

sub list {
	my $self = shift;
	my $q    = $self->{cgi};
	my $conf = $self->{conf};
	my %vars;

	if ( !$conf->{Template}{LocalOnly} ) {

		# find all the installed modules in the combined paths
		$vars{INC} ||= {};
		$self->_get_files( [ @INC, split /:/xms, $conf->{IncFolders}{Path}, ], $conf->{IncFolders}{Match}, $vars{INC} );

		# Move any module found in the pod name space to the PERL
		# location and create the javascript for the list page
		$vars{PERL} = $vars{INC}{P}{pod};
		my $perl    = _organise_perl( $vars{INC}{P}{pod} );
		$vars{perl} = $self->_create_js( 'perl', $perl );

		# delete the pod documentation and reate the INC javascript
		delete $vars{INC}{P}{pod};
		$vars{inc}      = $self->_create_js( 'inc', $vars{INC} );
		$vars{inc_path} = join '<br/>', ( @INC, split /:/xms, $conf->{IncFolders}{Path}, );
	}

	# find all the programs in the LocalFolders path and create its javascript
	$vars{LOCAL} ||= {};
	my @local_folders = split /:/xms, $conf->{LocalFolders}{Path};
	$self->_get_files( \@local_folders, $conf->{LocalFolders}{Match}, $vars{LOCAL}, );
	$vars{'local'} = $self->_create_js( 'local', $vars{LOCAL} );

	# create the path info for the list page
	$vars{local_path} = join '<br/>', @local_folders;

	# remove all unnessesery data
	if ( !$self->{save_data} ) {
		delete $vars{INC};
		delete $vars{PERL};
		delete $vars{LOCAL};
	}
	$vars{sidebar} = $q->{sidebar};

	# return parameters
	return %vars;
}

# gets the files listed in a specified path
sub _get_files {
	my $self       = shift;
	my $conf       = $self->{conf};
	my $cgi_module = $self->{cgi}{module};
	my ( $path_ref, $match, $vars ) = @_;

	# for each path find the all files files that match.
	for my $path ( @{$path_ref} ) {
		$vars->{$path} = 1;
		find(
			$path, $match,
			sub {
				my ($full) = @_;

				# ignore any file in the data directory
				return if $full =~ /^$conf->{General}{Data}/xms || $full =~ m{^\./data}xms;

				my ( $inc, $module, $first_letter ) = $full =~ m{^ ($path) / ((.).*) \. \w+ $}xms;

				if ($cgi_module) {
					my $mod = $module;
					$mod =~ s{/}{_}gxms;
					if ( $mod eq $cgi_module ) {
						$self->{template} = $module;
					}
				}

				$first_letter = uc $first_letter;

				# storage eg
				# {I}{Ivan}{*}[0] = '/home/ivan/lib/Ivan.pm';
				# {I}{Ivan}{Find}{*}[0] = '/home/ivan/lib/Ivan/Find/pm';
				# {I}{Ivan}{Find}{*}[1] = '/homw/ivan/src/home/lib/Ivan/Find.pm'

				if ( !$vars->{$first_letter} || !ref $vars->{$first_letter} eq 'HASH' ) {
					$vars->{$first_letter} = {};
				}
				my $tmp = $vars->{$first_letter};

				for my $part ( split m{/}xms, $module ) {
					$tmp->{$part} ||= {};
					$tmp = $tmp->{$part};
				}

				# now should have a deep ref to the last part of the modules name
				$tmp->{'*'} ||= [];
				push @{ $tmp->{'*'} }, $full;
			},
		);
	}

	return;
}

# recursivly finds files
sub find {
	my ( $path, $match, $action ) = @_;

	opendir DIR, $path or return;
	my @files = readdir DIR;
	close DIR;

	for my $file (@files) {
		next if $file eq '.' || $file eq '..' || $file =~ /^\d+$/xms;
		my $full = "$path/$file";
		if ( -d $full ) {
			find( $full, $match, $action );
		}
		elsif ( $full =~ /$match/xms ) {
			&$action($full);
		}
	}

	return;
}

# creates the javascript to contain the information provided in $vars
# ie converts $vars to a javascript object syntax (the closest thing to
# a perl hash in javascript).
sub _create_js {
	my $self = shift;
	my ( $name, $vars, ) = @_;

	my $js = "var $name = {";

	for my $module ( sort keys %{$vars} ) {
		my $result = $self->_create_js_object( $module, $vars->{$module} );
		if ($result) {
			$js .= $result . ',';
		}
	}
	$js =~ s/,$//xms;

	return "$js};";
}

# Recursivly creates a javascript object form a perl hash reference
sub _create_js_object {
	my $self = shift;
	my ( $name, $vars, ) = @_;

	return '' if !ref $vars;

	my $js = "'$name':{'*':new Array(";

	if ( $vars->{'*'} and ref $vars->{'*'} eq 'ARRAY' ) {
		$js .= "'" . join( "','", @{ $vars->{'*'} } ) . "'";
	}
	$js .= '),';

	for my $module ( sort keys %{$vars} ) {
		next if $module eq '*' or not ref $vars->{$module};
		$js .= $self->_create_js_object( $module, $vars->{$module} ) . ',';
	}
	$js =~ s/,$//xms;

	return "$js}";
}

# moves the various perl documentation .pod files into their best categories
sub _organise_perl {
	my ($perl) = @_;
	my %pod;
	my %areas = (
		'Commands'              => { map { 'perl'.$_ => 1, $_ => 1 } qw/a2p doc perl run / },
		'OS'                    => { map { 'perl'.$_ => 1 } qw/aix amiga apollo beos bs2000 ce cygwin dgux dos ebcdic epoc freebsd hpux hurd irix machten macos macosx mint mpeix netware openbsd os2 os390 os400 plan9 qnx solaris tru64 uts vmesa vms vos win32/ },
		'Languages'             => { map { 'perl'.$_ => 1 } qw/cn tw ko jp / },
		'Tutorials'             => { map { 'perl'.$_ => 1 } qw/book boot bot cheat dsc tooc toot trap / },
		'Internals'             => { map { 'perl'.$_ => 1 } qw/api apio call clib compile filter guts hack iol debguts intern / },
		'Regular Expressions'   => { map { 'perl'.$_ => 1 } qw/re reref requick re / },
		'Debug'                 => { map { 'perl'.$_ => 1 } qw/debug diag/ },
		'Licence'               => { map { 'perl'.$_ => 1 } qw/artistic gpl / },
		'Processes and Threads' => { map { 'perl'.$_ => 1 } qw/fork ipc thrtut / },
		'Programming'           => { map { 'perl'.$_ => 1 } qw/data form func lol number obj op pod podspec port ref sec style sub syn tie unicode unintro var xs/ },
	);

	for my $module ( keys %{$perl} ) {
		my $found = 0;
		for my $area ( keys %areas ) {
			if ( $areas{$area}{$module} ) {
				$pod{$area}{$module} = $perl->{$module};
				$found = 1;
			}
		}
		my $area =
			  $module =~ /delta$/xms ? 'Changes'
			: $module =~ /faq/xms    ? 'FAQ'
			: $module =~ /tut/xms    ? 'Tutorials'
			: $module =~ /mod/xms    ? 'Modules'
			: $found                 ? undef
			:                          'Unsorted';

		if ($area) {
			$pod{$area}{$module} = $perl->{$module};
		}
	}
	return \%pod;
}

1;

__END__

=head1 NAME

DocPerl - Module for DocPerl stuff

=head1 VERSION

This documentation refers to DocPerl version 0.6.0.

=head1 SYNOPSIS

   # Load the DocPerl module
   use DocPerl;

   # create a new DocPerl Object
   my $docperl = DocPerl->new(
       cgi       => $cgi_params,
       conf      => $config_params,
       save_data => 0,
   );

   # print CGI headders
   print $cgi->headder( $docperl->mime() );

   # print the DocPerl document
   print $docperl->process();

=head1 DESCRIPTION

This module provides the basic controll of DocPerl.

=head1 METHODS

=head3 C<new ( %param )>

Param: C<%param> - The for use of docperl

C<cgi> - CGI - the cgi object.

C<conf> - Config::Std - The configuration object

C<save_data> - bool - Flags that the data built up in the list function should be kept because this object will be reused other wise it will be removed to save on the passing arround unnessesary data.

Return: DocPerl - A new DocPerl object.

Description: Creates a new DocPerl object with the template file name and mime
type defined.

=head3 C<init ( )>

Return: void

Description: Initialises the DocPerl object processing the requested
cgi parameters.

=head3 C<process ( )>

Return: HASH - Parameters for use in the templates

Description: Processes the page that is to be displaied and returns the
parameters that contain the information to be used by the template system.

=head3 C<template ( )>

Return: string - The file name of the current template.

Description: Gets the template file for the current page

=head3 C<get_templ_object ( )>

Return: Template - Returns the stored template object

Description: Gets (or creates then gets) the template toolkit object.

=head3 C<mime ( )>

Return: string - A HTTP MIME type string

Description: Gets the mime type of the current template file

=head3 C<list ( )>

Return: HASH - The parameters for displaying the module/file list page.

Description: Finds all modules in the three specified locations (perl,local
and inc) and returns the parameters for the list page to display that
information.

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

The following modules are required by DocPerl:
warnings (included with perl 5.6)
Carp (included with perl 5.6)
Scalar::Util (included with perl 5.8)
version
Template (any)
DocPerl::Cached (included in DocPerl installation)
DocPerl::Cached::POD (included in DocPerl installation)
DocPerl::Cached::API (included in DocPerl installation)
DocPerl::Cached::CODE (included in DocPerl installation)

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
