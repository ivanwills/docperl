package DocPerl::View::FUNCTION;

# Created on: 2007-02-13 19:14:27
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

# Created on: 2007-02-13 19:14:27
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/DocPerl::View/;

our $VERSION     = version->new('1.1.0');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

sub process {
	my $self    = shift;
	my $conf    = $self->{conf};
	my $module  = $self->{module};
	my $file    = $self->{source} || '';
	my @folders = $self->{folders};

	croak 'No location supplied' if !$self->{current_location};

	# check that we found the proper file
	return ( pod => "Could not find $self->{module_file} " . ( !$file ? 'no file' : 'in ' . join ', ', @folders ) )
		if !$file || $file eq $self->{module_file};

	# check $file (for tainting)
	($file)   = $file   =~ m{\A ( [\w\-./]+ ) \Z}xms;
	($module) = $module =~ m{\A ( [\w\:]+ ) \Z}xms;

	return ( pod => "File contains dodgy characters ($file)" ) if !$file;

	my $text;
	open my $fh, '<', $file or carp "Could not open the file '$file': $OS_ERROR\n" and return ( func => 'none' );
	{
		local $/;
		$text = <$fh>;
	}
	my @functions = $text =~ /(?:^|\W)sub \s+ (\w+)/gxms;

	return ( functions => \@functions );
}

1;

__END__

=head1 NAME

DocPerl::View::FUNCTION - Generates a list of functions defined in a perl script/module

=head1 VERSION

This documentation refers to DocPerl::View::FUNCTION version 1.1.0.


=head1 SYNOPSIS

   use DocPerl::View::FUNCTION;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<process ( %args )>

Param: see L<DocPerl::View>

Return: HASH - the functions key contains the list of functions

Description: Processes a perl script or module to find all the functions that
are declared.

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
