#!/usr/bin/perl

use strict;
use SQLite::Abstract;

my $data_file  = "sometown.txt";
my $table_name = "sometown";

$SQLite::Abstract::glob->{'default_table'} = $table_name;

my $dbname = "phones.db";
open FH, ">$dbname" and close FH;

my $sql = SQLite::Abstract->new($dbname);

my $table = {
	'struct', [
		'phone',  [qw(INTEGER(32) NOT NULL)],
		'name',	  [qw(VARCHAR(512) NOT NULL)],
		'address',[qw(VARCHAR(1024) NOT NULL)]
	]
};

$sql->create($table);

my ($phone, $name, $address, $data, %unique, $file);
open FH, $data_file or die "can't open $file $!";

while (<FH>){
	($name, $phone, $address) = split ';',$_ and 
	push @$data, [$phone, $name, $address];
}

$sql->insert($data);

		



