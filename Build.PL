use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'Statistics-Sequences-Joins-0.11-*' ],
    build_requires => {
        'Test::More' => 0,
        'Statistics::Zed' => '0.072',
        'Statistics::Sequences' => '0.10',
        'List::AllUtils' => '0.03',
        'Statistics::Data::Dichotomize' => '0.01',
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    create_makefile_pl => 'traditional',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_abstract   => 'lib/Statistics/Sequences/Joins.pm',
    dist_version_from   => 'lib/Statistics/Sequences/Joins.pm',
    license             => 'perl',
    module_name         => 'Statistics::Sequences::Joins',
    requires => {
            'Statistics::Sequences' => '0.10',
            'List::AllUtils' => '0.03',
            'Statistics::Zed' => '0.072',
    },
);

$builder->create_build_script();
