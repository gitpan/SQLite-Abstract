#!/usr/bin/perl

use SQLite::Abstract;

my $table_name = "sometown";

$SQLite::Abstract::glob->{'default_table'} = $table_name;

my $dbname = "phones.db";

my $sql = SQLite::Abstract->new($dbname);

push my @$data, [("010010", "Tester", "st._one_test_1")];

$sql->delete_insert($data);

		



