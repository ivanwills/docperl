package DocPerl::Cached;

=head1 NAME

DocPerl::Cached - Parent object for pages that cache their results.

=head1 VERSION

This documentation refers to DocPerl::Cached version 0.1.


=head1 SYNOPSIS

   use DocPerl::Cached;

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

# Created on: 2006-03-19 20:28:44
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

Return: DocPerl::Cached - 

Description: 

=cut

sub new {
	my $caller = shift;
	my $class  = (ref $caller) ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;
	
	croak "Missing parameter conf" unless $param{conf};
	my $conf = $param{conf};
	$self->{cache_dir} = "$conf->{General}{Data}/cache";
	
	bless $self, $class;
	$self->init();
	
	return $self;
}

=head3 C<init (  )>

Description: Does nothing in its self but shold be overridden by inheriting
packages for any initialisation that they need.

=cut

sub init {
	my $self	= shift;
	
	return;
}

sub process { carp "process should not be called directly from DocPerl::Cached is should be called from a drived object" }

=head3 C<_check_cache ( %args )>

Arg: C<source> - string - The file name that a cached file is baised on

Arg: C<cache> - string - The relative file name for a cached version of a file

Return: string - The cached file's contents if the source and cache file's
modiffied times match or an empty string if there is no cache file or the files
modification time is different to that of the source file.

Description: Checks a source file against the cached version to see if their
modified times are different. Returning the cache contents if they match.

=cut

sub _check_cache {
	my $self	= shift;
	my %arg		= @_;
	my $conf	= $self->{conf};
	
	return '' if $conf->{General}{Cache} && $conf->{General}{Cache} eq 'off';
	
	# check that the arguments are supplied
	croak "Missing required argument - source, file" unless $arg{source};
	croak "Missing required argument - cache, location" unless $arg{cache};
	
	# check if the cache file has a suffix
	if ( $arg{cache} !~ /\.\w+$/ && $arg{source} ne 1 ) {
		# add the sources suffix
		my ( $suffix ) = $arg{source} =~ /(\.\w+)$/xs;
		$arg{cache} .= $suffix;
	}
	
	# get the cached file's full name
	my $file	= "$self->{cache_dir}/$arg{cache}";
	
	# check that there is a cache file
	return '' unless -f $file;
	
	# get the file stats for the source and cached files
	my @source	= stat $arg{source} if $arg{source} ne 1;
	my @cache	= stat $file;
	
	# check that the last modified times of both files are the same
	return '' if $arg{source} ne 1 && $source[9] != $cache[9];
	
	# read the contents of the cached file
	open my $cache, '<', $file or warn "Could not read the cache file $file: $!" and return '';
	my $data;
	{
		local $/;
		$data = <$cache>;
	}
	close $cache;
	
	# return the cached contents
	return $data;
}

=head3 C<_save_cache ( %arg )>

Arg: C<source> - string - The file name that a cached file is baised on

Arg: C<cache> - string - The relative file name for a cached version of a file

Description: Saves some calculated data to a cache file

=cut

sub _save_cache {
	my $self	= shift;
	my $conf	= $self->{conf};
	my $touch	= $conf->{General}{Touch};
	my %arg		= @_;
	
	return if $conf->{General}{Cache} && $conf->{General}{Cache} eq 'off';
	
	# check that the arguments are supplied
	croak "Missing required argument - source, file" unless $arg{source};
	croak "Missing required argument - cache, location" unless $arg{cache};
	carp "No cache content to save!" && return unless $arg{content};
	
	# check if the cache file has a suffix
	if ( $arg{cache} !~ /\.\w+$/ && $arg{source} ne 1 ) {
		# add the sources suffix
		my ( $suffix ) = $arg{source} =~ /(\.\w+)$/xs;
		$arg{cache} .= $suffix;
	}
	
	# split up the directory parts of the cache
	my @parts	= split m{/}, $arg{cache};
	my $file	= pop @parts;
	my $dir		= $self->{cache_dir};
	
	#warn "dir = $dir, ".join ' ', @parts;
	# make sure that we have all the directories up to the cached file
	for my $part ( @parts ) {
		$dir .= "/$part";
		mkdir $dir or die "Could not create the directory '$dir': $!"
			unless -d $dir;
	}
	
	# open the cache file and write the contents
	open my $cache, '>', "$dir/$file" or warn "Unable to create the cache file '$dir/$file': $!" and return;
	print {$cache} $arg{content} or warn "No content was able to be added to '$dir/$file': $!" and return;
	close $cache;
	
	# touch the file using the source file's time stamps
	if ( -x $touch && $arg{source} ne 1 ) {
		system( "$touch --reference=$arg{source} $dir/$file" );
	}
	#warn( "$touch --reference=$arg{source} $dir/$file" );
	
	return;
}

=head3 C<clear_cache ( [$dir] )>

Param: C<$dir> - string (detail) - The cache directory to clear

Return:  - 

Description: 

=cut

sub clear_cache {
	my $self	= shift;
	my $dir		= shift || $self->{cache_dir};
	
	system( "rm -rf $dir/*" );
}

1;

__END__
