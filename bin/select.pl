#!/usr/bin/perl

use strict;
use SQLite::Abstract;

my $dbname = "phones.db";
my $table_name = "sometown";

$SQLite::Abstract::glob->{'default_table'} = $table_name;

my $sql	   = SQLite::Abstract->new($dbname);
#my $what   = "where phone like %6% and name like %reni%";
#my $search = { 'where' => $what, 'col' => 'name, phone' };
my $result = $sql->search( {} );

print $_->[0], "\t", $_->[1], "\n" for @$result;


