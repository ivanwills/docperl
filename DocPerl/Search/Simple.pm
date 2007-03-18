package DocPerl::Search::Simple;

# Created on: 2006-07-02 06:11:02
# Create by:  ivan
# $Id$
# # $Revision$, $HeadURL$, $Date$
# # $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English '-no_match_vars';
use base qw/DocPerl::Search/;

our $VERSION   = version->new('0.9.0');
our @EXPORT_OK = qw//;

sub new {
	my $caller = shift;
	my $class  = ( ref $caller ) ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	if ( !$param{conf} ) {
		croak 'No configuration object passed!';
	}

	bless $self, $class;
	$self->init();

	return $self;
}

sub init {
	my $self = shift;
	my $conf  = $self->{conf};
	my $data  = $conf->{General}{Data};
	my $cache = "$data/cache";
	my $pod   = "$cache/pod";


	my %files = ( $self->find("$pod/inc"), $self->find("$pod/perl"), $self->find("$pod/local") );
	for my $file ( keys %files ) {
		my ( $type, $module, $extension ) = $file =~ m{$pod/(\w+)/(.*)([.]\w+)$}xms;
		$module =~ s{/}{::}gxms;
		$self->{modules}{$module} += $files{$file};
	}

	return;
}

sub search {
	my $self    = shift;
	my %args    = @_;
	my %files   = %{ $self->{files} };
	my %modules = %{ $self->{modules} };

	if ( $args{regex} ) {
		$self->{regex} = $args{regex} !~ /\((?![?]:)/xms ? "($self->{regex})" : $self->{regex};
	}
	elsif ( $args{terms} ) {
		my $re = join ')|(', split /\s+/xms, $args{terms};
		$self->{regex} = qr/($re)/;
	}
	else {
		croak 'No search term or search regular expression passed!';
	}

	return (
		map {
			{ $_ => $modules{$_} }
			} reverse sort { $modules{$a} <=> $modules{$b} } keys %modules
	)[ 0 .. 10 ];
}

sub find {
	my $self = shift;
	my ($dir) = @_;
	my %files;

	opendir DIR, $dir or carp "Unable to open the directory $dir: $OS_ERROR\n" and return;
	my @files = readdir DIR;
	close DIR;

FILE:
	for my $file (
		sort { -d "$dir/$a" && -d "$dir/$b" || -f "$dir/$a" && -f "$dir/$b" ? $a cmp $b : -f "$dir/$a" ? 1 : -1 }
		@files ) {
		next FILE if $file eq '.' || $file eq '..';

		if ( -d "$dir/$file" ) {
			%files = ( %files, $self->find("$dir/$file") );
		}
		else {
			my $count = $self->process_file("$dir/$file");
			if ( $count ) {
				$files{"$dir/$file"} = $count;
			}
		}
	}
	return %files;
}

sub process_file {
	my $self   = shift;
	my $re     = $self->{regex};
	my ($file) = @_;
	my $count  = 0;

	open my $fh, '<', $file or carp "Could not open the file '$file' for reading: $!\n" and return;
	{
		undef $INPUT_RECORD_SEPARATOR;
		my @count = <$fh> =~ /$re/gxms;
		$count = @count;
	}

	return $count;
}

1;

__END__

=head1 NAME

DocPerl::Search::Simple - Initial quick and dirty search engin till I find an
easily installable and working better solution.

=head1 VERSION

This documentation refers to DocPerl::Search::Simple version 0.9.0.


=head1 SYNOPSIS

   use DocPerl::Search::Simple;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Performs a simple text search for a list of words in the cached documentation
files. (Hopefully this will be replaced by something like KinoSearch or
VectorSearch)

=head1 SUBROUTINES/METHODS

=head3 C<new ( %params )>

Param: C<conf> - hashref - Standard DocPerl Configuration hash

Param: C<terms> - string - space seperated string of search tearms

Param: C<regex> - string (regex) - A regular expression for the terms to be searched

Return: DocPerl::Search::Simple -

Description:

=head3 C<init ( $var1, $var2,  )>

Param: C<$var1> - type (detail) - description

Param: C<$var2> - type (detail) - description

Return:  -

Description:

=head3 C<search ( )>

Return:  -

Description:

=head3 C<find_files ( $dir )>

Param: C<$dir> - type (detail) - description

Return:  -

Description:

=head3 C<process_file ( $file )>

Param: C<$file> - string (file name) - The file to check

Return:  -

Description:

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



=cut
