package DocPerl::View::API;

# Created on: 2006-03-19 20:32:12
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Readonly;
use Symbol qw/delete_package/;
use Data::Dumper qw/Dumper/;
use Scalar::Util;
use English '-no_match_vars';
use base qw/DocPerl::View/;

our $VERSION   = version->new('0.9.2');
our @EXPORT_OK = qw//;

Readonly my $QW       => qr/qw[^\w\s;] ( [\w:\s]+ ) [^\w\s;]/xms;
Readonly my $LIST     => qr/[(] ( [\w:\s'"]+ ) [)]/xms;
Readonly my $LIST_ALL => qr/(?: $QW | $LIST )/xms;

sub process {
	my $self     = shift;
	my $conf     = $self->{conf};
	my $location = $self->{current_location};
	my $source   = $self->{source};
	my $file     = $source;

	return if !$file || !-f $file;

	# open the file
	open my $fh, '<', $file or carp "Cannot open $file: $!\n" and return;
	my %api = ( pod => 0, parents => [] );
	my $i   = 0;
	my $pod = 0;
	my $end = 0;

	# loop through the file line by line
LINE:
	while ( my $line = <$fh> ) {
		$i++;

		if ( $line =~ /\A=(\w*)/xms || $pod ) {
			$api{pod}++;
			my $pod_cmd = $1;
			$pod = $pod && $pod_cmd && $pod_cmd eq 'cut' ? 0 : 1;
			next LINE;
		}

		# ignore lines starting with a {, } or #
		next LINE if $line =~ /^\s* (?: (?: (?: [{] | [}] ) \s* $ ) | [#] )/xms;

		# check if we have reached the end of the file
		if ( $line =~ /^__(END|DATA)__/xms ) {
			$end = 1;
		}

		# lines after the end/data can only add to POD stat
		next LINE if $end;

		if (   $self->check_package( $line, \%api )
			|| $self->check_base_parents( $line, \%api )
			|| $self->check_isa_parents( $line, \%api )
			|| $self->check_use( $line, \%api )
			|| $self->check_require( $line, \%api )
			|| $self->check_package_vars( $line, \%api )

			#|| $self->check_( $line, \%api )
			) {
		}

		# check for sub directives
		elsif ( my ($func) = $line =~ /^\s*sub\s+(\w+)/xms ) {
			my $method     = 0;
			my $found_line = $i;
			my $line;
			my $sub_line_no = 0;
			while ( $sub_line_no < 10 && ( $line = <$fh> ) ) {
				$i++;
				if ( my ($require) = $line =~ /require\s+([\w:]*)/xms ) {
					$api{required}{$require}++;
				}

				# if the line is of the from $self = shift then assume sub is a method
				if ( $line =~ /}/xms ) {
					$sub_line_no = 11;
				}

				# if the line is of the form $class = shift or $caller = shift assume sub is a class method
				elsif ( $line =~ /\$(class|caller)\s*=\s*shift;/xms ) {
					$api{class}{$func} = $found_line;
					$method = 1;
				}

				# stop if we come accross a closing bracket
				elsif ( $line =~ /\$(self|this)\s*=\s*shift;/xms ) {
					$api{object}{$func} = $found_line;
					$method = 1;
				}

				# alternate object opener $this = shift form
				elsif ( $line =~ /my\s*\(\s*\$(self|this)[^\)]*\)\s*=\s*\@_;/xms ) {
					$api{object}{$func} = $found_line;
					$method = 1;
				}

				$sub_line_no++;
			}

			# if no a class or object method add to functions
			if ( !$method ) {
				$api{func}{$func} = $found_line;
			}
		}
	}
	close $fh or carp "Problem closing filehandle: $OS_ERROR\n";

	if ( !@{ $api{parents} } ) {
		delete $api{parents};
	}
	my @paths = split /:/xms, $location eq 'local' ? $conf->{LocalFolders}{Path} : $conf->{IncFolders}{Path};
	my $inc_path_size = @INC - 1;
	push @INC, @paths;

	if ( $api{package} ) {
		$api{version} = load_package( $api{package}, $file );
		carp $EVAL_ERROR if $EVAL_ERROR;
		eval { $api{hirachy} = [ get_hirachy( $api{package} ) ]; };
		if ($EVAL_ERROR) {
			carp $EVAL_ERROR;
			$api{hirachy} = $api{parents};
		}
		elsif ( !@{ $api{hirachy}[0]{hirachy} } && $api{parents} ) {
			carp "Found parents of $api{package} (" . ( join q{,}, @{ $api{parents} } ) . ') but not hirachy!';
			$api{hirachy}[0]{hirachy} = [ map { { class => $_ } } @{ $api{parents} } ];
		}

		# clean up if we did not already have the symbol table
		unload_package( $api{package} );
	}

	if ( ref $api{modules} ) {
		$api{modules} = [ sort keys %{ $api{modules} } ];
	}
	for my $type (qw/class object func vars/) {
		if ( ref $api{$type} ) {
			$api{$type} = [ map { { name => $_, line => $api{$type}{$_} } } sort keys %{ $api{$type} } ];
		}
	}
	@INC = @INC[ 0 .. $inc_path_size ];

	$api{lines} = $i;
	$api{size}  = int -s $file;

	return ( api => \%api );
}

sub check_package {
	my ( $self, $line, $api ) = @_;

	# if the line starts with the package directive
	my ($package) = $line =~ /^ \s* package \s+ ( [\w:]+ );/xms;

	if ($package) {
		if ( $api->{package} ) {
			push @{ $api->{packages} }, $package;
		}
		else {
			$api->{package} = $package;
		}
		return 1;
	}

	return 0;
}

sub check_base_parents {
	my ( $self, $line, $api ) = @_;

	# check if the line starts with 'use base' to indicate inhereted packages
	my ($parents) = $line =~ m{\A \s* use \s+ base \s+ $LIST_ALL }xms;
	if ($parents) {
		my @parents = split /\s+/xms, $parents;
		push @{ $api->{parents} }, @parents;
		return 1;
	}

	return 0;
}

sub check_isa_parents {
	my ( $self, $line, $api ) = @_;

	# check if the line starts with '@ISA' to indicate inhereted packages
	my ($parents) = $line =~ / \@ISA \s* = \s* $LIST_ALL  /xms;
	if ($parents) {
		my @parents = split /,\s*/xms, $parents;
		for my $parent (@parents) {
			$parent =~ s/'|\s//gxms;    #'
		}
		push @{ $api->{parents} }, @parents;
		return 1;
	}
	$parents = $line =~ / push \s* [(]? \s* \@ISA \s* , \s* (?:['"])? ([\w:]+) (?:['"])? /xms;
	if ($parents) {
		my $parents = $1;
		my @parents = split /,\s*/xms, $parents;
		push @{ $api->{parents} }, @parents;
		return 1;
	}
	return 0;
}

sub check_use {
	my ( $self, $line, $api ) = @_;

	# check for generic module 'use'
	if ( my ($module) = $line =~ /^ \s* use \s+ ( [\w:]* ) /xms ) {
		$api->{modules}{$module}++;
		return 1;
	}

	return 0;
}

sub check_require {
	my ( $self, $line, $api ) = @_;

	# check for generic module 'require'
	if ( my ($require) = $line =~ /^ \s* require \s+ ( [\w:]* ) /xms ) {
		$api->{required}{$require}++;
		return 1;
	}

	return 0;
}

sub check_package_vars {
	my ( $self, $line, $api ) = @_;

	# check for package variables
	if ( my ($var) = $line =~ /^ \s* our \s+ ( [\$\%\@] \w+ ) /xms ) {
		$api->{vars}{$var} = $INPUT_LINE_NUMBER;
		return 1;
	}

	return 0;
}

sub get_hirachy {
	my ($object) = @_;
	my @hirachy;
	my @parents;
	{
		no strict qw/refs/;    ## no critic
		@parents = @{"$object\:\:ISA"};
	}
	carp $EVAL_ERROR if $EVAL_ERROR;

	foreach my $parent (@parents) {
		load_package($parent);
		if ( !$EVAL_ERROR ) {
			push @hirachy, get_hirachy($parent);
		}
		else {
			push @hirachy, { class => $parent };
		}
	}

	return { class => $object, hirachy => \@hirachy };
}

{
	my %loaded = (
		'DocPerl'        => 1,
		'UNIVERSAL::can' => 1,
	);

	sub load_package {
		my ( $package, $file ) = @_;
		my $sym = $package;
		my ($sub_sym) = $sym =~ /::(\w+)$/xms;
		my $version  = $package . '::VERSION';
		my $have_sym = 0;
		$sym =~ s/::(\w+)$/::/xms;
		if ($sub_sym) {
			$sub_sym .= q{::};
		}
		else {
			$sym .= q{::};
		}

		if ( !$file ) {
			$file = $package;
			$file =~ s{/}{::}gxms;
			$file .= '.pm';
		}

		{
			no strict qw/refs/;    ## no critic
			if ( ( $sub_sym && !exists ${$sym}{$sub_sym} ) || ( !$sub_sym && !%{$sym} ) ) {
				my $warn = $SIG{__WARN__};
				$SIG{__WARN__} = sub { };
				eval { require $file };
				$SIG{__WARN__} = $warn;
			}
			else {
				$loaded{$package} = 1;
			}
			return ${$version};
		}

		return;
	}

	sub unload_package {
		my ($package) = @_;
		if ( !$loaded{$package} ) {
			delete_package($package);
		}

		return;
	}
}

1;

__END__

=head1 NAME

DocPerl::View::API - Inspects a perl file to find what functions are defined
modules used/inherited etc

=head1 VERSION

This documentation refers to DocPerl::View::API version 0.9.2.


=head1 SYNOPSIS

  use DocPerl::View::API;

  # Create a new API variable
  my $api = DocPerl::View::API->new(
      conf    => {
          General      => {
              Data     => '/tmp/',
          },
          IncFolders   => {
              Path     => '',
          },
      },
      source => $file,
      current_location => '',
  );

  # get a hash ref with the information about the API found
  my $description = $api->process();

  # $description will contain something like
  # {
  #   api => {
  #      modules   => [a list of modules used],
  #      parents   => [a list of modules directly inhreited from],
  #      required  => [a list of modules required],
  #      vars      => [a list of package variable defined],
  #      version   => 'File version number',
  #      class     => [
  #          { name => 'class method', line => 'line no method defined on' }, ...
  #      ],
  #      object    => [
  #          { name => 'method', line => 'line no method defined on' }, ...
  #      ],
  #      func      => [
  #          { name => 'function', line => 'line no defined' }, ...
  #      ],
  #      hirachy   => [ inverted definition of class hirachy ],
  #   }
  # };

=head1 DESCRIPTION

This module inspects perl files and tries to determine what subroutines/
object methods/class methods and package variables are defined as well as
the module use()ed, require()d and inherited from.

=head1 SUBROUTINES/METHODS

=head3 C<display ( )>

Return: HASHREF - The files API

Description: Processes a file to find out what modules it uses, what subs it
declares (and weather they are class or object methods or plain subs) and the
inheritance tree if any of the module.

=head3 C<get_hirachy ( $object )>

Param: C<$object> - The name of the module who's hirachy is desired

Return: HASHREF - That describes the object hirachy of $object

Description: This function finds out the object hirachy of the passed object
$object by using the object (use $object) and looking at it's ISA array. (it
then cascades down to the next level etc).

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
