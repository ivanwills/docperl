package DocPerl::Cached;

=head1 NAME

DocPerl::Cached - Parent object for pages that cache their results.

=head1 VERSION

This documentation refers to DocPerl::Cached version 0.6.0.


=head1 SYNOPSIS

   use DocPerl::Cached;

   # create a new object
   my $cached = DocPerl::Cached->new( conf => { General => { Data => '/path/to/data' }, );

   # clear the cached files
   $cached->clear( '' );

=head1 DESCRIPTION

DocPerl::Cached provides a base for DocPerl classses that produce complex html
pages that need to be cached for performance.

=head1 METHODS

=cut

# Created on: 2006-03-19 20:28:44
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util qw/tainted/;
use File::stat;
use File::Path;
use base qw/Exporter/;

our $VERSION   = version->new('0.6.0');
our @EXPORT_OK = qw//;

=head3 C<new ( %args )>

Arg: C<$search> - type (detail) - description

Return: DocPerl::Cached - A new DocPerl::Cached object

Description: Creates and initialises a new DocPerl::Cached or inherited object

=cut

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

=head3 C<init (  )>

Description: Does nothing in its self but shold be overridden by inheriting
packages for any initialisation that they need.

=cut

sub init {
	my $self = shift;

	return;
}

sub process {
	return carp 'process should not be called directly from DocPerl::Cached is should be called from a drived object';
}

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
	my $self   = shift;
	my %arg    = @_;
	my $conf   = $self->{conf};
	my $source = $arg{source};
	my $cache  = $arg{cache};

	return '' if $conf->{General}{Cache} && $conf->{General}{Cache} eq 'off';

	# check that the arguments are supplied
	croak 'Missing required argument - source, file'    if !$source;
	croak 'Missing required argument - cache, location' if !$cache;
	if ( $source =~ /[.][.]/xms || $cache =~ /[.][.]/xms ) {
		carp "possible hack attempt with $source or $cache";
		return '';
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
	return '' if !-f $file;

	# get the file stats for the source and cached files
	my $source_stat = $source ne '1' ? stat $source : undef;
	my $cache_stat  = stat $file;

	# check that the last modified times of both files are the same
	return '' if $source ne '1' && $source_stat->mtime != $cache_stat->mtime;

	# read the contents of the cached file
	open my $cache_fh, '<', $file or carp "Could not read the cache file $file: $!" and return '';
	my $data;
	{
		local $/ = undef;
		$data = <$cache_fh>;
	}
	close $cache_fh;

	# return the cached contents
	return $data;
}

=head3 C<_save_cache ( %arg )>

Arg: C<source> - string - The file name that a cached file is baised on

Arg: C<cache> - string - The relative file name for a cached version of a file

Description: Saves some calculated data to a cache file

=cut

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

	# split up the directory parts of the cache
	my @parts = split m{/}xms, $cache;
	my $file  = pop @parts;
	my $dir   = $self->{cache_dir};

	carp "The cache file '$dir/$file' does not have a suffix" if $file !~ /\./xms;

	#carp "dir = $dir, ".join ' ', @parts;
	# make sure that we have all the directories up to the cached file
	$dir .= '/' . join '/', @parts;
	return if $dir !~ m{^ ( [\w\-\./]+ ) $}xms;
	eval { mkpath $1 };
	if ($@) {
		carp "Could not create the path $dir: $@";
		return;
	}

	# check that the file is OK
	return if $file !~ /\A([\w\-\.]+)\Z/xms;
	$file = $1;

	# open the cache file and write the contents
	#carp "Saving cache file '$dir/$file'\n";
	my %full = ( "$dir/$file" => 1 );
	my ($full) = %full;
	open my $cache_fh, '>', $full or carp "Unable to create the cache file '$full': $!" and return;
	print {$cache_fh} $arg{content} or carp "No content was able to be added to '$full': $!" and return;
	close $cache_fh;

	# touch the file using the source file's time stamps
	if ( $source ne '1' && $source =~ m{\A ( [\w\-\./]+ ) \Z}xms ) {
		my $stat = stat $1;
		my ($atime) = $stat->atime =~ m{\A (\d+) \Z}xms;
		my ($mtime) = $stat->mtime =~ m{\A (\d+) \Z}xms;
		my ($full)  = "$dir/$file" =~ m{\A ([\w\-\./]+) \Z}xms;
		utime $atime, $mtime, $full;
	}

	return;
}

=head3 C<clear_cache ( [$dir] )>

Param: C<$dir> - string (detail) - The cache directory to clear

Description: Clears all the cache files.

=cut

sub clear_cache {
	my $self = shift;
	my $dir  = shift || $self->{cache_dir};

	system "rm -rf $dir/*";

	return;
}

sub DESTROY {

	return;
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
