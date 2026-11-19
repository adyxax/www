#!/usr/bin/env perl
use v5.36;
use FindBin qw($RealBin);
chdir $RealBin or die "chdir $RealBin: $!\n";

BEGIN {
    $ENV{PERL_LIBRARY_VERSION} = 'v1';
    $ENV{PERL_LIBRARY_DIR} = "$ENV{HOME}/.cache/adyxax.org/perl-library-$ENV{PERL_LIBRARY_VERSION}";
    unless (grep { /\A(?:--no-update\z|-[hv]*n)/ } @ARGV) {
        require File::Temp;
        my $url = "https://git.adyxax.org/api/v1/repos/adyxax.org/perl-library/raw/init.pl?ref=$ENV{PERL_LIBRARY_VERSION}";
        my $init = File::Temp->new(SUFFIX => '.pl');
        system('curl', '-fsSL', '-o', "$init", $url) == 0
            or die "perl library bootstrap: failed to download $url\n";
        system($^X, "$init") == 0 or die "perl library bootstrap failed\n";
    }
}
use lib "$ENV{PERL_LIBRARY_DIR}/lib";
use AdyxaxOrg::CLI::Ansible qw(ansible_main);
ansible_main(@ARGV);
