#!perl

use Test::More tests => 12 ;
use autodie;
use FindBin;

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

my $temp = <<EOD;
  {
    "Listen": "127.0.0.1:$tport",
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

my $cfg = "[$static,$temp,$manage]";

my $server = Dandelions->new( config_handle => $cfg );
$server->run_child;

my $file = "1.txt";

open my $file_in, "<", $FindBin::Bin . "/" . $path . $file;
my $content = do { local $/; <$file_in> };

my $mech = Test::WWW::Mechanize->new;
$mech->timeout(1);

$mech->get("http://127.0.0.1:$port/");
is( $mech->status(), 404, "A proper 404 was returned" );

$mech->get("http://127.0.0.1:$port/$file");
is( $mech->status(), 404, "A proper 404 was returned" );

$mech->get("http://127.0.0.1:$tport/");
is( $mech->status(), 404, "A proper 404 was returned on the tmp port" );

my $tmp_open = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$tport");
$tmp_open->blocking(0);
my $buff = "";

$tmp_open->read($buff, 1);
ok( $tmp_open->eof, "Able to open a connection to the tmp port");

$cfg = "[$static,$manage]";
$cfg =~ s[/404][]g;

$mech->post("http://127.0.0.1:$mport/api/v1", Content => { config => "[$static,a]" });
is($mech->status, 500, "Invalid JSON produces an error");

$mech->get("http://127.0.0.1:$tport/$file");
is( $mech->status, 404, "Invalid JSON didn't change the config" );

$tmp_open->read($buff, 1);
ok( $tmp_open->eof, "The temp port is still ok");

$mech->post("http://127.0.0.1:$mport/api/v1", Content => { config => $cfg });
ok($mech->success, "Can post to the API");

$mech->get_ok("http://127.0.0.1:$port/$file");
$mech->content_is( $content, "File is now sent correctly" );

$mech->get("http://127.0.0.1:$tport/");
is( $mech->status(), 500, "tmp port is closed" );

$tmp_open->read($buff, 1);
ok( $tmp_open->eof, "The temp port was not closed");

1;
