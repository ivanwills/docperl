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

our $VERSION     = version->new('1.1.0');
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

DocPerl::Search::Perl - Searches module paths for requested keywords

=head1 VERSION

This documentation refers to DocPerl::Search::Perl version 1.1.0.


=head1 SYNOPSIS

   use DocPerl::Search::Perl;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<search ( %args )>

Arg: C<area> - string - the area of the cache to search

Arg: C<tearms> - string - The term to search for

Return: ARRAY - A list of modules found to contain the search term

Description: Searches the cache for files containing the search term using
File::Find and regular expressions.

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

Copyright (c) 2007 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
