#!/usr/bin/perl

use strict;
use SQLite::Abstract;

my $dbname = "phones.db";
my $table_name = "sometown";

$SQLite::Abstract::glob->{'default_table'} = $table_name;
$SQLite::Abstract::glob->{'where'} = 'remove';

my $sql	   = SQLite::Abstract->new($dbname);
my $delete = { 'remove', 'where 1=1' };
my $result = $sql->delete( $delete );

print $result, " records deleted\n";


