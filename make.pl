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
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use File::Temp ();
use MIME::Base64 qw(decode_base64);
use Sys::Hostname qw(hostname);
use AdyxaxOrg::Assert qw(assert_commands);
use AdyxaxOrg::Check qw(check_go check_perl check_shell check_yaml);
use AdyxaxOrg::CLI qw(cli_main);
use AdyxaxOrg::Git qw(git_assert_clean);
use AdyxaxOrg::Go qw(go_build_static go_tidy go_update);
use AdyxaxOrg::Shell qw(run);

my $CACHE_DIR   = '/tmp/hugo-cache-' . ($ENV{USER} // scalar(getpwuid $<) // $<);
my $DESTINATION = "$RealBin/public";
my $HOST        = 'www_adyxax_org@myth.adyxax.org';
my $PORT        = 1313;
my $REMOTE_DIR  = '/srv/www';
my $SEARCH      = 'search';
my $SERVICE     = 'www-search';
my $DAEMON_PID  = "$REMOTE_DIR/$SERVICE.daemon.pid";
my $SEARCH_PID  = "$REMOTE_DIR/$SERVICE.pid";
my $START       = "cd $REMOTE_DIR && daemon -f -H -r -t $SERVICE -P $DAEMON_PID"
    . " -p $SEARCH_PID -o $REMOTE_DIR/$SERVICE.log $REMOTE_DIR/$SEARCH";
my $STOP        = "{ if [ -f $DAEMON_PID ]; then kill \$(cat $DAEMON_PID) 2>/dev/null; fi;"
    . " i=0; for f in $DAEMON_PID $SEARCH_PID; do"
    . " [ -f \$f ] || continue; pid=\$(cat \$f);"
    . " while kill -0 \$pid 2>/dev/null; do"
    . " i=\$((i + 1)); if [ \$i -gt 30 ]; then echo '$SERVICE did not stop' >&2; exit 1; fi;"
    . " sleep 1; done; done; }";
my %SEARCH_FILES = (
    'index.json' => 'index.json',
    'search/index.html' => 'index.html'
);
my @HUGO = ('hugo', '--cacheDir', $CACHE_DIR, '--buildFuture');

# _rsh_quote <argument>
#
# Quotes <argument> for the -e option of rsync, which splits it on spaces.
sub _rsh_quote($argument) {
    return $argument if $argument =~ /\A[\w.\/\@+:=,-]+\z/;
    die "cannot quote for rsync: $argument\n" if $argument =~ /'/;
    return "'$argument'";
}

# build
#
# Builds the website, then the search service.
sub build() {
    assert_commands('hugo');
    run(@HUGO, qw(--gc --minify --cleanDestinationDir -d), $DESTINATION);
    for my $file (sort keys %SEARCH_FILES) {
        copy("$DESTINATION/$file", "$SEARCH/$SEARCH_FILES{$file}")
            or die "failed to copy $DESTINATION/$file to $SEARCH/$SEARCH_FILES{$file}: $!\n";
    }
    {
        local $ENV{GOOS}   = 'freebsd';
        local $ENV{GOARCH} = 'amd64';
        go_build_static($SEARCH, $SEARCH);
    }
    return;
}

# deploy <fail_if_dirty>
#
# Deploys the website and the search service.
sub deploy($fail_if_dirty) {
    assert_commands(qw(rsync ssh));
    # An empty source would wipe the website because of --delete
    die "deploy: $DESTINATION/index.html not found, run the build action first\n"
        unless -f "$DESTINATION/index.html";
    die "deploy: $SEARCH/$SEARCH not found, run the build action first\n" unless -f "$SEARCH/$SEARCH";
    git_assert_clean() if $fail_if_dirty;

    my @ssh = ('ssh');
    my $key;
    if (($ENV{SSH_PRIVATE_KEY} // '') ne '') {
        $key = File::Temp->new(TMPDIR => 1);  # mode 0600
        binmode $key;
        print {$key} decode_base64($ENV{SSH_PRIVATE_KEY});
        close $key or die "close $key: $!\n";
        push @ssh, '-i', "$key", '-o', 'StrictHostKeyChecking=accept-new';
    }
    my $rsh = join ' ', map { _rsh_quote($_) } @ssh;

    run(qw(rsync -a --delete -e), $rsh, "$DESTINATION/", "$HOST:$REMOTE_DIR/public/");
    run('rsync', '-e', $rsh, "$SEARCH/$SEARCH", "$HOST:$REMOTE_DIR/");
    run(@ssh, $HOST, "chmod +x $REMOTE_DIR/$SEARCH && $STOP && $START");
    return;
}

cli_main({
    actions => {
        build => {
            code => sub (@) { build() },
            describe => 'build the website.',
        },
        check => {
            code => sub (@) {
                check_perl();
                check_shell();
                check_yaml();
                check_go($SEARCH);
            },
            describe => 'check and lint everything.',
        },
        clean => {
            code => sub (@) {
                remove_tree($DESTINATION, map { "$SEARCH/$_" } $SEARCH, values %SEARCH_FILES);
            },
            describe => 'clean the repository of build artifacts.',
        },
        deploy => {
            code => sub ($opts, @) { deploy($opts->{'fail-if-dirty'} // 1) },
            describe => 'deploy the website.',
            flags => '[--[no-]fail-if-dirty]',
            options => ['fail-if-dirty!'],
        },
        serve => {
            code => sub (@) {
                assert_commands('hugo');
                run(@HUGO, qw(serve --disableFastRender --noHTTPCache --navigateToChanged --bind 0.0.0.0),
                    '--port', $PORT, '--baseURL', 'http://' . hostname() . ":$PORT/");
            },
            describe => 'run a development web server.',
        },
        tidy => {
            code => sub ($opts, @) {
                go_tidy($SEARCH);
                git_assert_clean() if $opts->{'fail-if-dirty'};
            },
            describe => 'tidy up the code.',
            flags => '[--[no-]fail-if-dirty]',
            options => ['fail-if-dirty!'],
        },
        update => {
            code => sub (@) { go_update($SEARCH) },
            describe => 'update the go version and the dependencies.',
        },
    },
    help => [
        ['--[no-]fail-if-dirty', 'fail if the repository is dirty (default: yes for deploy, no for tidy)'],
    ],
}, @ARGV);
