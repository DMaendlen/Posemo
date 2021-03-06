#!/usr/bin/env perl 

use strict;
use warnings;

use FindBin qw($Bin);

use Test::More;
use Test::Exception;
use Test::Deep;
use Test::Differences;

use File::Temp qw(tempdir);
use JSON;
use IO::All;


my $dir = tempdir( CLEANUP => 1 );
$SIG{INT} = $SIG{TERM} = sub { undef $dir; };      # remove temp dir on Ctrl-C or kill


use_ok( "PostgreSQL::SecureMonitoring::Run", output => "CheckMK" );


ok !-f "$dir/t-702-simple.json", "result file does NOT exist";

my $posemo;

lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                     configfile   => "$Bin/conf/run-default-checks.conf",
                                                     outfile      => "$dir/t-702-simple.json",
                                                     pretty       => 1,
                                                     service_type => "global",
                                                   );
}, "Object for simple";

lives_ok
   sub { $posemo->run; },
   "Run simple";

ok -f "$dir/t-702-simple.json", "result file exists";

my $result = io("$dir/t-702-simple.json")->all;


# diag $result;


# <<<posemo>>>

( my $host_data = $result ) =~ s{(^.*<<<posemo>>>)}{}sx;

my $data;

lives_ok sub { $data = decode_json($host_data); }, "no exception at decoding hosts JSON data";



# diag "TODO: analyse result ...";


is $data->{hostgroup}, "_GLOBAL",   "Hostgroup in JSON";
is $data->{host},      "localhost", "Host in JSON";
is $data->{name},      "localhost", "Name of Host in JSON";

is ref $data->{check_mk_data},      "ARRAY", "check_mk_data is Arrayref";
is ref $data->{check_mk_inventory}, "ARRAY", "check_mk_inventory is Arrayref";

my $non_null_count = grep { defined } map { $_[1] } @{ $data->{check_mk_inventory} };
is $non_null_count, 0, "Params in inventory are always undef";

my $error_count = grep { $_ != 0 } map { $_[1] } @{ $data->{check_mk_data} };
is $error_count, 0, "No error state in data";


is $data->{check_mk_inventory}[0][0], 'PostgreSQL check Activity of $TOTAL', "First service name in inventory";

is $data->{check_mk_data}[0][1],
   'Total: 1, Active: 1, Idle: 0, Idle in transaction: 0, Idle in transaction (aborted): 0, Fastpath function call: 0, Disabled: 0',
   "First message in data";
is $data->{check_mk_data}[0][2][0][0], "posemo__activity__total",                         "Column total";
is $data->{check_mk_data}[0][2][1][0], "posemo__activity__active",                        "Column active";
is $data->{check_mk_data}[0][2][2][0], "posemo__activity__idle",                          "Column idle";
is $data->{check_mk_data}[0][2][3][0], "posemo__activity__idle_in_transaction",           "Column idle in transaction";
is $data->{check_mk_data}[0][2][4][0], "posemo__activity__idle_in_transaction__aborted_", "Column idle in transaction (aborted)";
is $data->{check_mk_data}[0][2][5][0], "posemo__activity__fastpath_function_call",        "Column fastpath function call";
is $data->{check_mk_data}[0][2][6][0], "posemo__activity__disabled",                      "Column disbled";

# Removed, because metric/graph infos will not created here anymore
#
# cmp_deeply( $data->{check_mk_metric_info}{writeable__write_time},
#             { title => "Write time", unit => "s", },
#             "Metrics Info for Writeable" );
# cmp_deeply( $data->{check_mk_metric_info}{checkpoint_time__write_time},
#             { title => "Write time", unit => "s", },
#             "Metrics Info for CheckpointTime, write_time" );
# cmp_deeply( $data->{check_mk_metric_info}{checkpoint_time__sync_time},
#             { title => "Sync time", unit => "s", },
#             "Metrics Info for CheckpointTime, sync_time" );
# cmp_deeply( $data->{check_mk_metric_info}{connection_limit__connection_limit},
#             { title => "Connection limit", unit => "%", },
#             "Metrics Info for ConnectionLimit" );
# 
# cmp_deeply( $data->{check_mk_metric_info}{activity__total},
#             { title => "Total", unit => "", },
#             "Metrics Info for Activity, total" );
# 
# 
# eq_or_diff(
#             $data->{check_mk_graph_info}{activity},
#             {
#                title   => "Running and idling connections",
#                metrics => [
#                             [ activity__total                         => "area" ],
#                             [ activity__active                        => "stack" ],
#                             [ activity__idle                          => "stack" ],
#                             [ activity__idle_in_transaction           => "stack" ],
#                             [ activity__idle_in_transaction__aborted_ => "stack" ],
#                             [ activity__fastpath_function_call        => "stack" ],
#                             [ activity__disabled                      => "stack" ],
#                           ]
#             },
#             "Graph Info for Activity (global)"
#           );



# checkpoint_time__sync_time

# use Data::Dumper;
# diag Dumper $data->{check_mk_graph_info};
# #diag Dumper $data;

#############################################################################
#
# service type local
#
# will be removed later!
#
#############################################################################

undef $posemo;

lives_ok sub {
   $posemo = PostgreSQL::SecureMonitoring::Run->new(
                                                     configfile   => "$Bin/conf/run-default-checks.conf",
                                                     outfile      => "$dir/t-702-simple-local.json",
                                                     pretty       => 1,
                                                     service_type => "local",
                                                   );
}, "Object for simple";

lives_ok
   sub { $posemo->run; },
   "Run simple";

ok -f "$dir/t-702-simple-local.json", "result file exists";

$result = io("$dir/t-702-simple-local.json")->all;


# diag $result;


# <<<posemo>>>

( $host_data = $result ) =~ s{(^.*<<<posemo>>>)}{}sx;

undef $data;

lives_ok sub { $data = decode_json($host_data); }, "no exception at decoding hosts JSON data";



# diag "TODO: analyse result ...";


is $data->{hostgroup}, "_GLOBAL",   "Hostgroup in JSON";
is $data->{host},      "localhost", "Host in JSON";
is $data->{name},      "localhost", "Name of Host in JSON";

is ref $data->{check_mk_data},      "ARRAY", "check_mk_data is Arrayref";
is ref $data->{check_mk_inventory}, "ARRAY", "check_mk_inventory is Arrayref";

$non_null_count = grep { defined } map { $_[1] } @{ $data->{check_mk_inventory} };
is $non_null_count, 0, "Params in inventory are always undef";

$error_count = grep { $_ != 0 } map { $_[1] } @{ $data->{check_mk_data} };
is $error_count, 0, "No error state in data";


is $data->{check_mk_inventory}[0][0], 'PostgreSQL check Activity', "First service name in inventory (local)";

is $data->{check_mk_data}[0][1],
   'Total: 1, Active: 1, Idle: 0, Idle in transaction: 0, Idle in transaction (aborted): 0, Fastpath function call: 0, Disabled: 0',
   "First message in data";

my $prefix = "activity___TOTAL__";
is $data->{check_mk_data}[0][2][0][0], $prefix . "total",                         "Column total (local)";
is $data->{check_mk_data}[0][2][1][0], $prefix . "active",                        "Column active (local)";
is $data->{check_mk_data}[0][2][2][0], $prefix . "idle",                          "Column idle (local)";
is $data->{check_mk_data}[0][2][3][0], $prefix . "idle_in_transaction",           "Column idle in transaction (local)";
is $data->{check_mk_data}[0][2][4][0], $prefix . "idle_in_transaction__aborted_", "Column idle in transaction (aborted) (local)";
is $data->{check_mk_data}[0][2][5][0], $prefix . "fastpath_function_call",        "Column fastpath function call (local)";
is $data->{check_mk_data}[0][2][6][0], $prefix . "disabled",                      "Column disbled (local)";

# Removed, because metric/graph infos will not created here anymore
#
# cmp_deeply( $data->{check_mk_metric_info}{writeable__write_time},
#             { title => "Write time", unit => "s", },
#             "Metrics Info for Writeable" );
# cmp_deeply( $data->{check_mk_metric_info}{checkpoint_time__write_time},
#             { title => "Write time", unit => "s", },
#             "Metrics Info for CheckpointTime, write_time" );
# cmp_deeply( $data->{check_mk_metric_info}{checkpoint_time__sync_time},
#             { title => "Sync time", unit => "s", },
#             "Metrics Info for CheckpointTime, sync_time" );
# cmp_deeply( $data->{check_mk_metric_info}{connection_limit__connection_limit},
#             { title => "Connection limit", unit => "%", },
#             "Metrics Info for ConnectionLimit" );
# 
# cmp_deeply( $data->{check_mk_metric_info}{activity__postgres__total},
#             { title => "Total", unit => "", },
#             "Metrics Info for Activity, total (local!)" );
# 
# 
# eq_or_diff(
#             $data->{check_mk_graph_info}{activity__postgres},
#             {
#                title   => "Running and idling connections of postgres",
#                metrics => [
#                             [ activity__postgres__total                         => "area" ],
#                             [ activity__postgres__active                        => "stack" ],
#                             [ activity__postgres__idle                          => "stack" ],
#                             [ activity__postgres__idle_in_transaction           => "stack" ],
#                             [ activity__postgres__idle_in_transaction__aborted_ => "stack" ],
#                             [ activity__postgres__fastpath_function_call        => "stack" ],
#                             [ activity__postgres__disabled                      => "stack" ],
#                           ]
#             },
#             "Graph Info for Activity (global)"
#           );



# use Data::Dumper;
# diag Dumper $data->{check_mk_graph_info};



done_testing;
