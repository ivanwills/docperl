package DocPerl::Search::Perl;

# Created on: 2007-02-16 20:28:48
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use File::Find qw/find/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/DocPerl::Search/;

our $VERSION     = version->new('1.0.0');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub search {
	my $self = shift;
	my %args = @_;
	my $conf = $self->{'conf'};
	my %rank;
	my @results;

	# check if the text is only strings and/or white space so that we can use the fast grep version
	my $location =
		  $args{'area'} eq 'function'                ? 'function'
		: $args{'area'} eq 'code'                    ? 'code'
		: -d "$conf->{'General'}{'Data'}/cache/text" ? 'text'
		:                                              'pod';

	my $dir = "$conf->{'General'}{'Data'}/cache/$location/";

	find sub {
		return if -d $_;
		open my $f, '<', $_ or return;
		local $INPUT_RECORD_SEPARATOR = undef;
		my $text = <$f>;
		my $count = $text =~ /$args{terms}/gisxm;
		return if not $count;
		my ( $area, $file ) = $File::Find::name =~ m{^ $dir (\w+) / (.+) $}xms;
		$file =~ s{/}{::}gxms;
		$file =~ s{[.]\w+$}{}xms;
		push @{ $rank{$count} }, [ $file => $area ];
	}, $dir;

	$conf->{Search}{result_size} ||= 100;

	# limit the returned results to the amount desired
RANK:
	for my $rank ( reverse sort keys %rank ) {
		push @results, @{ $rank{$rank} };
		last RANK if @results > $conf->{Search}{result_size};
	}

	# return the modules found
	return @results;
}

1;

__END__

=head1 NAME

DocPerl::Search::Perl - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to DocPerl::Search::Perl version 1.0.0.


=head1 SYNOPSIS

   use DocPerl::Search::Perl;

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


=head3 C<sub ( $search, )>

Param: C<$search> - type (detail) - description

Return: DocPerl::Search::Perl -

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

Copyright (c) 2007 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
