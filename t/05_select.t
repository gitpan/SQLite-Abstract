# -*- perl -*-

# t/06_select.t - select tests

use Test::More tests => 10;
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

my @data = ();

my $sql = SQLite::Abstract->new($database);

$sql->table($tablename);

is(local$_ = $sql->select_name(q/limit 100, 1/), 'guest', "select test 1");
is(local$_ = $sql->select(q/all limit 100, 10/)->[1], 'guest', "select test 2");
is(local$_ = $sql->select_name(q/where name = 'aa'/), 'aa', "select test 3");
is(local$_ = $sql->select(q/all where name = 'aa'/)->[1], 'aa', "select test 4");
is((local@_ = $sql->select_name(q/where name = 'aa'/))[0], 'aa', "select test 5");
is((local@_ = $sql->select(q/all where name = 'aa'/))[0]->[1], 'aa', "select test 6");
is(local$_ = $sql->select->[0], 1, "select test 7");
is(local$_ = $sql->select('*')->[0], 1, "select test 8");
is(local$_ = $sql->last->[0], 1, "select test 9");
is(local$_ = $sql->count, 1404, "select test 9");
	 
