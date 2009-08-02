use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'DocPerl',
	license           => 'perl',
	dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version_from => 'lib/DocPerl.pm',
	requires          => {
		'perl'                         => 5.008,
		'Template'                     => '2.14',
		'Template::Provider::FromDATA' => '0.08',
		'Class::Date'                  => '1.1.7',
		'Clone'                        => '0.17',
		'Data::Merger'                 => 0,
		'List::MoreUtils'              => 0,
		'Readonly'                     => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	add_to_cleanup     => [ 'DocPerl-*' ],
	create_makefile_pl => 'traditional',
	create_license     => 1,
);

$builder->create_build_script();
