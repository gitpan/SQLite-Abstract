#!/usr/bin/perl

use SQLite::Abstract;
use strict;

my $dbname = "phones.db";
my $table_name = "sometown";

$SQLite::Abstract::glob->{'default_table'} = $table_name;

my $sql	= SQLite::Abstract->new($dbname);

$sql->drop

