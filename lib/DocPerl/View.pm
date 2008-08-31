package DocPerl::View;

# Created on: 2006-03-19 20:28:44
# Create by:  Ivan  Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util qw/tainted/;
use File::stat;
use File::Path;
use English qw/ -no_match_vars /;
use Readonly;
use base qw/Exporter/;

our $VERSION   = version->new('1.1.0');
our @EXPORT_OK = qw//;

Readonly my $SAFE_FILE => qr{\A ( [\w\-./]+ ) \Z}xms;

sub new {
	my $caller = shift;
	my $class  = ( ref $caller ) ? ref $caller : $caller;
	my %args   = @_;
	my $self   = \%args;

	croak 'Missing args conf' if !$args{conf};
	my $conf = $args{conf};
	$self->{cache_dir} = "$conf->{General}{Data}/cache";

	bless $self, $class;
	$self->init();

	return $self;
}

sub init {
	my $self = shift;

	return;
}

sub process {
	return carp 'process should not be called directly from DocPerl::View is should be called from a derived object';
}

sub _check_cache {
	my ($self, %arg) = @_;
	my $conf   = $self->{conf};
	my $suffix = $self->{suffix};
	my $source = $arg{source};
	my $cache  = $arg{cache};

	return q{} if $conf->{General}{Cache} && $conf->{General}{Cache} eq 'off';

	# check that the arguments are supplied
	croak 'Missing required argument - source, file'    if !$source;
	croak 'Missing required argument - cache, location' if !$cache;
	if ( $source =~ /[.][.]/xms || $cache =~ /[.][.]/xms ) {
		carp "possible hack attempt with $source or $cache";
		return q{};
	}

	# check if the cache file has a suffix
	if ( $cache !~ /\.\w+$/xms && $source ne '1' ) {

		# add the sources suffix
		my ($suffix) = $source =~ /(\.\w+)$/xms;
		$cache .= $suffix;
	}

	# get the cached file's full name
	my $file = "$self->{cache_dir}/$cache";

	# check that there is a cache file
	return q{} if !-f $file;

	# get the file stats for the source and cached files
	my $source_stat = $source ne '1' ? stat $source : undef;
	my $cache_stat = stat $file;

	# check that the last modified times of both files are the same
	return q{} if $source ne '1' && $source_stat->mtime != $cache_stat->mtime;

	# read the contents of the cached file
	open my $cache_fh, '<', $file or carp "Could not read the cache file $file: $!" and return q{};
	my $data;
	{
		local $INPUT_RECORD_SEPARATOR = undef;
		$data = <$cache_fh>;
	}
	if ( !close $cache_fh ) {
		warn "Error in closing file handle for $file: $OS_ERROR\n";    ## no critic
	}

	# return the cached contents
	return $data;
}

sub _save_cache {
	my $self   = shift;
	my %arg    = @_;
	my $conf   = $self->{conf};
	my $source = $arg{source};
	my $cache  = $arg{cache};

	return if $conf->{General}{Cache} && $conf->{General}{Cache} eq 'off';

	# check that the arguments are supplied
	croak 'Missing required argument - source, file'    if !$source;
	croak "Source file does not exist '$source'"        if $source ne '1' && !-f $source;
	croak 'Missing required argument - cache, location' if !$cache;
	carp 'No cache content to save!' && return if !$arg{content};

	# check if the cache file has a suffix
	if ( $cache !~ /\.\w+$/xms && $source ne '1' ) {

		# add the sources suffix
		my ($suffix) = $source =~ /(\.\w+)$/xms;
		$cache .= $suffix;
	}

	# set up the full cache file name
	$cache = "$conf->{General}{Data}/cache/$cache";

	# create the path up to the cache file (if missing)
	my $full = eval { $self->make_path($cache) };
	if ($EVAL_ERROR || !$full) {
		carp "Could not create the path $cache: $EVAL_ERROR";
		return;
	}

	# open the cache file and write the contents
	open my $cache_fh, '>', $full or carp "Unable to create the cache file '$full': $!" and return;
	print {$cache_fh} $arg{content} or carp "No content was able to be added to '$full': $!" and return;
	if ( !close $cache_fh ) {
		warn "Error in closing file handle for $full: $OS_ERROR\n";    ## no critic
	}

	# touch the file using the source file's time stamps
	if ( $source ne '1' ) {
		$self->touch($source, $full);
	}

	return;
}

sub make_path {
	my ($self, $file) = @_;

	# do taint checking of file name
	my ($safe) = $file =~ m{$SAFE_FILE}xms;
	warn "Unsafe file $file" if !$safe;

	# split the file name into its directory parts
	my @dir = split m{/}, $safe;

	# remove the actual file name
	pop @dir;

	# reconstruct the directory
	my $dir = join '/', @dir;

	# try to make the full path
	eval{ mkpath $dir };

	die "Could not make path '$dir': $EVAL_ERROR" if $EVAL_ERROR;

	return $safe;
}

sub touch {
	my ($self, $source, $dest) = @_;

	my ($safe) = $source =~ m{$SAFE_FILE}xms;
	my $stat   = stat $safe;

	my ($atime) = $stat->atime =~ m{\A (\d+) \Z}xms;
	my ($mtime) = $stat->mtime =~ m{\A (\d+) \Z}xms;

	utime $atime, $mtime, $dest;

	return;
}

sub clear_cache {
	my $self = shift;
	my $dir = shift || $self->{cache_dir};

	system "rm -rf $dir/*";

	return;
}

sub pom {

	my $self = shift;

	# return the cached object if it exists
	return $self->{pom} if $self->{pom};

	# create and cache a new Pod::POM object
	return $self->{pom} = Pod::POM->new( { warn => 0, } );
}

sub DESTROY {

	return;
}

1;

__END__

=head1 NAME

DocPerl::View - Parent object for pages that cache their results.

=head1 VERSION

This documentation refers to DocPerl::View version 1.1.0.


=head1 SYNOPSIS

   use DocPerl::View;

   # create a new object
   my $cached = DocPerl::View->new( conf => { General => { Data => '/path/to/data' }, );

   # clear the cached files
   $cached->clear( '' );

=head1 DESCRIPTION

DocPerl::View provides a base for DocPerl classes that produce complex html
pages that need to be cached for performance.

=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg: C<$search> - type (detail) - description

Return: DocPerl::View - A new DocPerl::View object

Description: Creates and initialises a new DocPerl::View or inherited object

=head3 C<init (  )>

Description: Does nothing in its self but should be overridden by inheriting
packages for any initialisation that they need.

=head2 C<process ()>

Return: HASH - The parameters to be passed on to the template

Description: This method should be overwritten by an actual view. Its results
are passed on to the template used to display the view.

=head3 C<_check_cache ( %args )>

Arg: C<source> - string - The file name that a cached file is based on

Arg: C<cache> - string - The relative file name for a cached version of a file

Return: string - The cached file's contents if the source and cache file's
modified times match or an empty string if there is no cache file or the files
modification time is different to that of the source file.

Description: Checks a source file against the cached version to see if their
modified times are different. Returning the cache contents if they match.

=head3 C<_save_cache ( %arg )>

Arg: C<source> - string - The file name that a cached file is based on

Arg: C<cache> - string - The relative file name for a cached version of a file

Description: Saves some calculated data to a cache file

=head3 C<clear_cache ( [$dir] )>

Param: C<$dir> - string (detail) - The cache directory to clear

Description: Clears all the cache files.

=head2 C<pom ()>

Return: Pod::POM - a new or cached Pod::POM object

Description: Caches the internal Pod::POM object

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

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
