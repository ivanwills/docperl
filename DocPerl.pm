package DocPerl;

=head1 NAME

DocPerl - Module for DocPerl stuff

=head1 VERSION

This documentation refers to DocPerl version 0.3.

=head1 SYNOPSIS

   use DocPerl;
   
   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


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

=cut

# Created on: 2006-01-31 19:59:04
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use Template;
use DocPerl::Cached;
use base qw/Exporter/;

our $VERSION = version->new('0.3.0');
our @EXPORT = qw//;
our @EXPORT_OK = qw/find/;


=head3 C<new ( %param )>

Param: C<%param> - The for use of docperl

C<cgi> - CGI - the cgi object.

C<conf> - Config::Std - The configuration object

Return: DocPerl - A new DocPerl object.

Description: Creates a new DocPerl object with the template file name and mime
type defined.

=cut

sub new {
	my $caller = shift;
	my $class  = (ref $caller) ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	carp "Need cgi parameters"	unless $self->{cgi};
	carp "Need conf parameters"	unless $self->{conf};
	
	bless $self, $class;
	
	# initialise the object
	$self->init();
	
	return $self;
}

=head3 C<init ( )>

Return: void

Description: Initialises the DocPerl object processing the requested
cgi parameters.

=cut

sub init {
	my $self	= shift;
	my $q		= $self->{cgi};
	my $conf	= $self->{conf};
	my $page	= $q->{page};
	
	# initialise the template name and mime type
	if ( $page ) {
		my $template = $page;
		if ( $template =~ /\.(\w+)$/ ) {
			$self->{template}	= $template;
			my $type			= $1 eq 'css' ? 'css'
								: $1 eq 'js'  ? 'javascript'
								:               $1;
			$self->{mime}		= "text/$type";
		}
		else {
			$self->{template}	= "$template.html";
			$self->{mime}		= "text/html";
		}
	}
	else {
		# if no page is given the default template is to create the frames page
		$self->{template}	= "frames.html";
		$self->{mime}		= "text/html";
	}
	
	# check if a module has been passed as a CGI parameter
	if ( $q->{module} ) {
		# check if the module starts with a double underscore which means that
		# it came from the module list page
		if ( $q->{module} =~ /__/ ) {
			# module came from the front page so need to get the actual module
			# name from the module parameter
			my $module = $self->{tag} = $q->{module};
			
			# remove the location start parts
			$module =~ s{^([^_]+)__[^_]+__}{}xs;
			
			# store the location
			$self->{current_location} = $1;
			
			# store the perl module name
			$self->{module}		 = $module;
			$self->{module_file} = $module;
			
			# store the module file name
			$self->{module}		 =~ s{__}{::}gxs;
			$self->{module_file} =~ s{__}{/}gxs;
		}
		elsif ( $q->{module} =~ m{^link/(.+)(?:[.]html)$} ) {
			$self->{current_location}	= $q->{location};
			$self->{module}				= $1;
			$self->{module_file}		= $1;
			
			$self->{module} =~ s{/}{::}gxs;
		}
		else {
			# extract the cgi parameters
			$self->{current_location}	= $q->{location};
			$self->{module}				= $q->{module};
			$self->{module_file}		= $q->{module};
			
			# Convert the module_file parameter to a more file like name
			# ie convert double colons to forward slashes (:: -> /)
			$self->{module_file} =~ s{::}{/}gxs;
			if ( $self->{current_location} eq 'perl' ) {
				$self->{module_file} = "pod/$self->{module_file}";
			}
		}
		
		# Check after all that we still have a module, file and a location
		die "Module went!"      unless $self->{module};
		die "Module file went!" unless $self->{module_file};
		die "Location went!"    unless $self->{current_location};
		
		# 
		my $file = $self->{module_file};
		my @files;
		my @folders;
		my @suffixes;
		
		# Get the folder locations and file name suffixes for the current
		# location.
		if ( $self->{current_location} eq 'local' ) {
			@folders  = split /:/, $conf->{LocalFolders}{Path};
			@suffixes = @{ $conf->{LocalFolders}{suffixes} };
		}
		else {
			@folders = @INC;
			push @folders, split /:/, $conf->{IncFolders}{Path};
			@suffixes = @{ $conf->{LocalFolders}{suffixes} };
		}
		
		# Get the location of the file
		for my $dir ( @folders ) {
			for my $suffix ( @suffixes ) {
				#warn "trying $dir/$file.$suffix";
				if ( -f "$dir/$file.$suffix" ) {
					push @files, { file => "$dir/$file.$suffix", suffix => $suffix };
				}
			}
		}
		
		# store all the calculated paramteres
		$self->{folders}  = \@folders;
		$self->{suffixes} = \@suffixes;
		$self->{sources}  = \@files;		# all files that match the module name
		$self->{source}	  = $q->{source} || $files[0]{file};
		#warn Dumper $self;
	}
}

=head3 C<process ( )>

Return: HASH - Parameters for use in the templates

Description: Processes the page that is to be displaied and returns the
parameters that contain the information to be used by the template system.

=cut

sub process {
	my $self	= shift;
	my $conf	= $self->{conf};
	my $q		= $self->{cgi};
	my $page	= $q->{page};
	my %vars;
	my $out;
	my $cache   = DocPerl::Cached->new( %$self );
	
	# check if we are meant to clear the cache (and the we are allowed to)
	$cache->clear_cache() if $conf->{Templates}{ClearCache} && $q->{clearcache};
	
	# create a cache object
	my $cache_path = $page || '';
	if ( $self->{current_location} ) {
		$cache_path .= "/$self->{current_location}";
	}
	if ( $self->{module_file} ) {
		$cache_path .= "/$self->{module_file}";
	}
	
	# Check if there is a page to view specified
	if ( $page ) {
		# check the cache for the page
		$out = $cache->_check_cache( cache => $cache_path, source => $self->{source} || 1 );
		
		# return the cached output
		return $out if $out;
		
		# Check that the page is OK to execute (ie if a method of this module
		# and is not a hidden method)
		if ( $page !~ /^_/xs && $self->can( $page ) ) {
			%vars = $self->$page();
		}
		elsif ( $page =~ /^(pod|api|code)$/i ) {
			# try to see if the method is a cached module
			my $module = 'DocPerl::Cached::'.uc $1;
			eval( "require $module" );
			if ( $@ ) {
				warn $@;
			}
			else {
				# use the cached object to get the data
				my $cache = $module->new( %$self );
				%vars = $cache->process();
			}
		}
	}
	else {
		# this only occurs when showing frames page
		$self->{module} = $q->{module} || 'perl__pod__perlfunc';
	}
	
	# set up other required params
	$vars{DUMP}		= Dumper( \%vars );
	$vars{module}	= $self->{module};
	$vars{file}		= $self->{module_file};
	$vars{location}	= $self->{current_location};
	$vars{sources}	= $self->{sources};
	$vars{source}	= $self->{source};
	
	# get the template object
	my $tmpl = $self->get_templ_object();
	
	# process the template
	$conf->{Template} ||= {};
	$tmpl->process( $self->template(), { %$q, %{ $conf->{Template} }, %vars }, \$out )
		or error( $tmpl->error );
	die 'The processed template "'.$self->template().'" contains not data!'.Dumper \%vars if $out =~ /^\s+$/;
	
	if ( $page && (!$self->{source} || -f $self->{source}) ) {
		#warn "Saving cache of $self->{source}\t$cache_path\n";
		$cache->_save_cache( cache => $cache_path, source => $self->{source} || 1, content => $out );
	}
	
	return $out;
}

=head3 C<template ( )>

Return: string - The file name of the current template.

Description: Gets the template file for the current page

=cut

sub template {
	my $self	= shift;
	return $self->{template};
}

=head3 C<get_templ_object ( )>

Return: Template - Returns the stored template object

Description: Gets (or creates then gets) the template toolkit object.

=cut

sub get_templ_object {
	my $self	= shift;
	my $conf	= $self->{conf};
	
	return $self->{templ} if $self->{templ};
	
	$self->{templ} = Template->new( INCLUDE_PATH => $conf->{Templates}{Path}, EVAL_PERL => 1 );
	die "Could not create the template object!" unless $self->{templ};
	
	return $self->{templ};
}

=head3 C<mime ( )>

Return: string - A HTTP MIME type string

Description: Gets the mime type of the current template file

=cut

sub mime {
	my $self	= shift;
	return $self->{mime} || 'text/html';
}

=head3 C<list ( )>

Return: HASH - The parameters for displaying the module/file list page.

Description: Finds all modules in the three specified locations (perl,local
and inc) and returns the parameters for the list page to display that
information.

=cut

sub list {
	my $self	= shift;
	my $q		= $self->{cgi};
	my $conf	= $self->{conf};
	my %vars;
	
	# find all the installed modules in the combined paths
	$vars{INC} ||= {};
	$self->_get_files(
		[ @INC, split /:/, $conf->{IncFolders}{Path}, ],
		$conf->{IncFolders}{Match},
		$vars{INC},
	);
	
	# Move any module found in the pod name space to the PERL
	# location and create the javascript for the list page
	$vars{PERL} = $vars{INC}{P}{pod};
	$vars{perl} = $self->_create_js( 'perl', { POD => $vars{PERL} } );
	
	# delete the pod documentation and reate the INC javascript
	delete $vars{INC}{P}{pod};
	$vars{inc} = $self->_create_js( 'inc', $vars{INC} );
	
	# find all the programs in the LocalFolders path and create its javascript
	$vars{LOCAL} ||= {};
	$self->_get_files(
		[ split /:/, $conf->{LocalFolders}{Path}, ],
		$conf->{LocalFolders}{Match},
		$vars{LOCAL},
	);
	$vars{local} = $self->_create_js( 'local', $vars{LOCAL} );
	
	# create the path info for the list page
	$vars{inc_path}		= join "<br/>", ( @INC, split /:/, $conf->{IncFolders}{Path}, );
	$vars{local_path}	= join "<br/>", split /:/, $conf->{IncFolders}{Path};
	
	# remove all unnessesery data
	unless ( $self->{save_data} ) {
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
	my $self	= shift;
	my $cgi_module = $self->{cgi}{module};
	my ( $path_ref, $match, $vars ) = @_;
	
	# for each path find the all files files that match.
	for my $path ( @$path_ref ) {
		$vars->{$path} = 1;
		find(
			$path,
			$match,
			sub {
				my ( $full ) = @_;
				
				# ignore any file in the data directory
				return if $full =~ /^$self->{data}/ || $full =~ m{^\./data};
				
				my ($inc, $module, $first_letter) = $full =~ m{^ ($path) / ((.).*) \. \w+ $}xs;
				
				if ( $cgi_module ) {
					my $mod = $module;
					$mod =~ s{/}{_}gxs;
					if ( $mod eq $cgi_module ) {
						$self->{template} = $module;
					}
				}
				
				$first_letter = uc $first_letter;
				# storage eg
				# {I}{Ivan}{*}[0] = '/home/ivan/lib/Ivan.pm';
				# {I}{Ivan}{Find}{*}[0] = '/home/ivan/lib/Ivan/Find/pm';
				# {I}{Ivan}{Find}{*}[1] = '/homw/ivan/src/home/lib/Ivan/Find.pm'
				
				$vars->{$first_letter} ||= {};
				my $tmp = $vars->{$first_letter};
				
				for my $part ( split m{/}, $module ) {
					$tmp->{$part} ||= {};
					$tmp = $tmp->{$part};
				}
				
				# now should have a deep ref to the last part of the modules name
				$tmp->{'*'} ||= [];
				push @{ $tmp->{'*'} }, $full;
			},
		);
	}
}

# recursivly finds files
sub find {
	my ( $path, $match, $action ) = @_;
	opendir DIR, $path or return;
	my @files = readdir DIR;
	close DIR;
	
	for my $file ( @files ) {
		next if $file eq '.' || $file eq '..' or $file =~ /^\d+$/;
		my $full = "$path/$file";
		if ( -d $full ) {
			find( $full, $match, $action );
		}
		elsif ( $full =~ /$match/ ) {
			&$action($full);
		}
	}
}

# creates the javascript to contain the information provided in $vars
# ie converts $vars to a javascript object syntax (the closest thing to
# a perl hash in javascript).
sub _create_js {
	my $self	= shift;
	#my $dbh	= $self->{-dbh};
	#my $q		= $self->{-cgi};
	#my $set	= $self->{-set};
	my ( $name, $vars,  ) = @_;
	my $js = "var $name = {";
	
	for my $module ( sort keys %{ $vars } ) {
		my $result = $self->_create_js_object( $module, $vars->{ $module } );
		$js .= $result . ',' if $result;
	}
	$js =~ s/,$//;
	
	return "$js};"
}


# Recursivly creates a javascript object form a perl hash reference
sub _create_js_object {
	my $self	= shift;
	my ( $name, $vars,  ) = @_;
	return '' unless ref $vars;
	
	my $js = "'$name':{'*':new Array(";
	
	if ( $vars->{'*'} and ref $vars->{'*'} eq 'ARRAY' ) {
		$js .= "'" . join( "','", @{ $vars->{'*'} } ) . "'";
	}
	$js .= "),";

	for my $module ( sort keys %{ $vars } ) {
		next if $module eq '*' or not ref $vars->{$module};
		$js .= $self->_create_js_object( $module, $vars->{$module} ) . ',';
	}
	$js =~ s/,$//;
	
	return "$js}"
}


1;

__END__

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
