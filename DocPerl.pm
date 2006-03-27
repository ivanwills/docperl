package DocPerl;

=head1 NAME

DocPerl - Module for DocPerl stuff

=head1 VERSION

This documentation refers to DocPerl version 0.1.


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
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

# Created on: 2006-01-31 19:59:04
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use base qw/Exporter/;

our $VERSION = version->new('0.0.1');
our @EXPORT = qw//;
our @EXPORT_OK = qw//;


=head3 C<sub ( $search,  )>

Param: C<$search> - type (detail) - description

Return: DocPerl - 

Description: 

=cut

sub new {
	my $caller = shift;
	my $class  = (ref $caller) ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	carp "Need cgi parameters"	unless $self->{cgi};
	carp "Need conf parameters"	unless $self->{conf};
	
	bless $self, $class;
	
	if ( $self->{cgi}{page} ) {
		my $template = $self->{cgi}{page};
		if ( $template =~ /\.(\w+)$/ ) {
			$self->{template}	= $template;
			$self->{mime}		= "text/$1";
		}
		else {
			$self->{template}	= "$template.html";
			$self->{mime}		= "text/html";
		}
	}
	
	return $self;
}

=head3 C<process ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub process {
	my $self	= shift;
	my $q		= $self->{cgi};
	my $conf	= $self->{conf};
	my $page	= $q->{page};
	my %vars;

	if ( $q->{module} ) {
		if ( $q->{module} =~ /__/ ) {
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
		else {
			$self->{current_location}	= $q->{location};
			$self->{module}				= $q->{module};
			$self->{module_file}		= $q->{module};
			
			$self->{module_file} =~ s{::}{/}gxs;
			$self->{module_file} = "pod/$self->{module_file}" if $self->{current_location} eq 'perl';
		}
		die "Module went!" unless $self->{module};
		die "Module file went!" unless $self->{module_file};
		die "Location went!" unless $self->{current_location};
		
		my $file	= $self->{module_file};
		my @files;
		my @folders;
		my @suffixes;
		if ( $self->{current_location} eq 'local' ) {
			@folders = split /:/, $conf->{LocalFolders}{Path};
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
					push @files, "$dir/$file.$suffix";
				}
			}
		}
		$self->{folders} = \@folders;
		$self->{suffixes} = \@suffixes;
		$self->{sources} = \@files;
		$self->{source}	 = $q->{source} || $files[0];
		#warn Dumper $self;
	}
	
	if ( $page ) {
		if ( $page !~ /^_/xs && $self->can( $page ) ) {
			%vars = $self->$page();
		}
		elsif ( $page =~ /^[a-zA-Z]\w+$/ ) {
			my $module = 'DocPerl::Cached::'.uc $page;
			eval( "require $module" );
			unless ( $@ ) {
				my $cache = $module->new( %$self );
				%vars = $cache->process();
			}
		}
	}
	
	return (
		DUMP	=> Dumper( \%vars ),
		module	=> $self->{module},
		file	=> $self->{module_file},
		location=> $self->{current_location},
		sources	=> $self->{sources},
		source	=> $self->{source},
		%vars,
	);
}

=head3 C<template ( )>

Return:  - 

Description: 

=cut

sub template {
	my $self	= shift;
	return $self->{template};
}

=head3 C<mime ( )>

Return:  - 

Description: 

=cut

sub mime {
	my $self	= shift;
	return $self->{mime};
}

=head3 C<list ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub list {
	my $self	= shift;
	my $q		= $self->{cgi};
	my $conf	= $self->{conf};
	my %vars;
	
	# find all the modules in the compined paths
	$vars{INC} ||= {};
	$self->get_files(
		[ @INC, split /:/, $conf->{IncFolders}{Path}, ],
		$conf->{IncFolders}{Match},
		$vars{INC},
	);
	
	$vars{PERL} = $vars{INC}{P}{pod};
	$vars{perl} = $self->create_js( 'perl', { POD => $vars{PERL} } );
	delete $vars{INC}{P}{pod};
	$vars{inc} = $self->create_js( 'inc', $vars{INC} );
	
	# find all the programs in the LocalFolders path
	$vars{LOCAL} ||= {};
	$self->get_files(
		[ split /:/, $conf->{LocalFolders}{Path}, ],
		$conf->{LocalFolders}{Match},
		$vars{LOCAL},
	);
	$vars{local} = $self->create_js( 'local', $vars{LOCAL} );
	
	$vars{inc_path}		= join "<br/>", ( @INC, split /:/, $conf->{IncFolders}{Path}, );
	$vars{local_path}	= join "<br/>", split /:/, $conf->{IncFolders}{Path};
	
	unless ( $self->{save_data} ) {
		delete $vars{INC};
		delete $vars{PERL};
		delete $vars{LOCAL};
	}
	$vars{sidebar} = $q->{sidebar};
	
	return %vars;
}

=head3 C<get_files ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub get_files {
	my $self	= shift;
	my $cgi_module = $self->{cgi}{module};
	my ( $path_ref, $match, $vars ) = @_;
	
	for my $path ( @$path_ref ) {
		$vars->{$path} = 1;
		find(
			$path,
			$match,
			sub {
				my ( $full ) = @_;
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

=head3 C<create_js ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  - 

Description: 

=cut

sub create_js {
	my $self	= shift;
	#my $dbh	= $self->{-dbh};
	#my $q		= $self->{-cgi};
	#my $set	= $self->{-set};
	my ( $name, $vars,  ) = @_;
	my $js = "var $name = {";
	
	for my $module ( sort keys %{ $vars } ) {
		my $result = $self->_blah( $module, $vars->{ $module } );
		$js .= $result . ',' if $result;
	}
	$js =~ s/,$//;
	
	return "$js};"
}


# struggling for a good name for this method
sub _blah {
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
		$js .= $self->_blah( $module, $vars->{$module} ) . ',';
	}
	$js =~ s/,$//;
	
	return "$js}"
}


1;

__END__
