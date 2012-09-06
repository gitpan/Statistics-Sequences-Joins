use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Sequences::Joins',
    license             => 'perl',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_abstract   => 'lib/Statistics/Sequences/Joins.pm',
    dist_version_from   => 'lib/Statistics/Sequences/Joins.pm',
    build_requires => {
            'Test::More' => 0,
    },
    requires => {
            'Statistics::Sequences' => '0.051',
            'List::AllUtils' => '0.03',
    },
    add_to_cleanup      => [ 'Statistics-Sequences-Joins-0.06-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
