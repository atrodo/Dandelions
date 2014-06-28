#!perl

use Test::More tests => 5;
use autodie;
use FindBin;
use File::Temp qw/tempfile/;

use Dandelions;
use Try::Tiny;
use Test::WWW::Mechanize;

my $port = "63021";
my $mport = "63022";
my $tport = "63023";
my $path = "test_static/";

my $static = <<EOD;
  {
    "Listen": "127.0.0.1:$port",
    "Protocol": "PSGI",
    "Handler": "Static",
    "Options": {
      "Path": "$path/404"
    }
  }
EOD

my $manage = <<EOD;
  {
    "Listen": "127.0.0.1:$mport",
    "Protocol": "PSGI",
    "Handler": "Manage",
    "Options": { }
  }
EOD

my ($cfg, $cfg_file) = tempfile();
$cfg->print("[$static,$manage]");
$cfg->seek(0,0);

my $server = Dandelions->new( config_handle => $cfg );
$server->run_child;

my $file = "1.txt";

open my $file_in, "<", $FindBin::Bin . "/" . $path . $file;
my $content = do { local $/; <$file_in> };

my $mech = Test::WWW::Mechanize->new;
$mech->timeout(1);

$mech->get("http://127.0.0.1:$port/");
is( $mech->status(), 404, "A proper 404 was returned" );

my $new_cfg = "[$static,$manage]";
$new_cfg =~ s[/404][]g;
$new_cfg =~ s[\n][]g;

$mech->post("http://127.0.0.1:$mport/api/v1", Content => { config => $new_cfg });
ok($mech->success, "Can post to the API");

$mech->get_ok("http://127.0.0.1:$port/$file");
$mech->content_is( $content, "File is now sent correctly" );

undef $server;

$cfg->seek(0,0);
is( do { local $/; <$cfg> }, $new_cfg, "Config file was written" );

1;
