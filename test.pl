# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::Simple tests => 11;
use SQLite::Abstract;

ok(1); # If we made it this far, we're ok.

my @file  	= <DATA>;
my $table_name 	= "sometown";
my $dbname 	= "phones.db";

open FH, ">$dbname" and close FH;

$SQLite::Abstract::glob->{'default_table'} = $table_name;

my $sql = SQLite::Abstract->new($dbname);

ok($sql);

my $table = {
        'struct', [
	        'phone',  [qw(INTEGER(32) NOT NULL)],
		'name',   [qw(VARCHAR(512) NOT NULL)],
		'address',[qw(VARCHAR(1024) NOT NULL)]
	]
};

ok($sql->create($table));

my ($phone, $name, $address, $data, %unique);

for( @file ){
	/^\s*$/ and next;
        ($name, $phone, $address) = split ';',$_ and
	$address =~ s/\n// and
        push @$data, [$phone, $name, $address];
}

ok($sql->delete_insert($data));
ok(3 == scalar@{$sql->search( { 'where','where phone like %1% and name like %some_man%' } )});
ok(1 == $sql->update( { 'phone', '34234 where address like %sorrow%' } ));
ok(1 == $sql->insert($data));
ok(6 == scalar@{$sql->select({})});
ok(2 == $sql->delete( { 'where', 'where address like %dragon%' } ));
ok(1 == $sql->delete_insert($data));
ok(1 == $sql->drop($table_name));



__DATA__

some_man_from_here;	017610810520;	city-of-the-sleepy-dragons
some_man_from_the_past; 020310251000; 	city-of-the-sorrowful-men
some_man_from_nowhere; 	189102501005;	city-of-the-beautyful 

