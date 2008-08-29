package DocPerl::Search;

# Created on: 2007-02-10 20:22:55
# Create by:  Ivan  Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('1.1.0');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub new {
	my $caller = shift;
	my $class  = ref $caller ? ref $caller : $caller;
	my %param  = @_;
	my $self   = \%param;

	if ( !$param{conf} ) {
		croak 'No configuration object passed!';
	}

	bless $self, $class;
	$self->init();

	return $self;
}

sub init   { return; }
sub search { return; }

1;

__END__

=head1 NAME

DocPerl::Search - The base module for performing searches in DocPerl

=head1 VERSION

This documentation refers to DocPerl::Search version 1.1.0.


=head1 SYNOPSIS

   use DocPerl::Search;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

=head3 C<new ( %args )>

Arg C<conf> - Config::Std - A DocPerl configuration hash ref

Return: DocPerl::Search - new search object

Description: Creates a new search object

=head3 C<init ( )>

Return: none

Description: Initialisation method to be overridden by modules that derive from this module

=head3 C<search ( %args )>

Arg C<terms> - string - The terms to search for in the pod

Return: array - An array of the modules that had the most occurrences of the terms

Description: Performs the actual searching. Should be overridden by derived modules.

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

Copyright (c) 2007 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
