package DocPerl::Cached::POD;

=head1 NAME

DocPerl::Cached::POD - Generates the HTML Documentation from a files POD

=head1 VERSION

This documentation refers to DocPerl::Cached::POD version 0.6.0.


=head1 SYNOPSIS

   use DocPerl::Cached::POD;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 METHODS

=cut

# Created on: 2006-03-19 20:31:36
# Create by:  ivan

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use Scalar::Util qw/tainted/;
use base qw/DocPerl::Cached/;
#use Pod::Html 1.0505;
use Pod::Html;

our $VERSION = version->new('0.6.0');
our @EXPORT = qw//;
our @EXPORT_OK = qw//;

=head3 C<process ( )>

Return: string - The POD documentation of the module passed in during
creation.

Description: Creates the html POD documentation of the file/module passed in
when this object was created.

=cut

sub process {
	my $self	= shift;
	my $conf	= $self->{conf};
	my $module	= $self->{module};
	my $file	= $self->{source} || '';
	my @folders	= $self->{folders};
	my @suffixes;
	
	croak "No location supplied" unless $self->{current_location};
	
	# check that we found the proper file
	return ( pod => "Could not find $self->{module_file} in ".join ", ", @folders )
		if !$file || $file eq $self->{module_file};
	
	# check $file (for tainting)
	($file) = $file =~ m{^ ( [\w\-./]+ ) $}xs;
	($module) = $module =~ m{^ ( [\w\:]+ ) $}xs;
	
	return (pod => "File contains dodgy craricters ($file)") unless $file;
	
	# construct the list of parameters
	my @params = (
		"--infile=$file",
		"--podroot=.",
		"--title=$module",
		"--index",
		"--cachedir=$conf->{General}{Data}/cache",
		"--css=?page=css.css",
	);
	
	# check if any values are tainted
	for ( @params ) {
		warn "Tainted $_" if tainted $_;
	}
	
	my $perl = $conf->{General}{Perl} || '/usr/bin/perl';
	my $cmd  = "$perl -MPod::Html -e \"pod2html('" . join( "', '", @params ) . "\')\"";
	
	# Pod::Html only appears to be able to print to STDOUT so have to call it
	# as an external program and capture STDOUT
	tie( *STDOUT, 'POD::STDOUT' );
	# Create the HTML POD
	eval{ pod2html( @params ); };
	my $pod = $POD::STDOUT::string;
	untie *STDOUT;
	
	# check for errors
	if ( $@ ) {
		warn "Error in creating POD: $@";
		return ( pod => "<html><head><title>Error</title></head><body><h1>Error</h1><p>Error in creating POD from $file</p></html>" );
	}
	
	# check that the html was created success fully
	if ( length $pod < 100 ) {
		return ( pod => "Could not create the POD for $module $!<br/><br/>\nGENERATED POD\n$pod\n<br/><br/>\n$cmd\n<br/><pre>". Dumper($conf)."</pre><br/>" );
	}
	
	# remove final number if one exists (bug with Pod::Html?)
	$pod =~ s/\d$//s if $pod =~ /\d$/s;
	# try to get rid of gaps between pre tags
	$pod =~ s{</pre>(\s*)<pre>}{$1}ixsg;
	# convert relative links to work with DocPerl structure
	my $location = $self->{current_location} || 'inc';
	$pod =~ s{href="/}{target="main" href="?page=module&location=$location&module=link/}gxs;
	
	# return the processed documentation
	return ( pod => $pod );
}

package POD::STDOUT;

use base qw/Tie::Handle/;
our $string = '';

sub TIEHANDLE { $string = ''; my $s; bless \$s, shift      }
sub PRINT     { shift; no warnings; $string .= join $,, @_ }
sub PRINTF    { shift; no warnings; $string .= sprintf @_  }
sub CLOSE     { }

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
