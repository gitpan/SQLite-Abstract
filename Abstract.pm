package SQLite::Abstract;

use strict;
use Carp;
use DBI;
require Exporter;

our @EXPORT =
  qw( search select insert update delete create drop delete_insert );

our $VERSION = '0.11';


our $glob = {
	'tablename',	'tablename', 
	'where',	'where',
	'col',		'col',       
	'set',		'set',
	'struct',	'struct',    
	'default_table',''
};

my $regex = {

	'sql', {
		'where', {
			'like',  qr{(\s+like\s+)(?!\')(\S+)(?<!\')}
		},
		'update',{
			'value', qr{^((?!\')(\S+)(?<!\'))},
			'col',	 qr{^set|set$}
		}
	}
};



sub new {

	my $class  = shift;
	my $dbname = shift;
    	my $dbtype = shift;

    	$dbtype ||= "dbi:SQLite:dbname";

    	-f $dbname or carp "ERR: no such database $dbname" and return 0;

    	my $dbh = DBI->connect(
        	"$dbtype=$dbname", "", "",
        	{
            		AutoCommit => 1,
            		PrintError => 1,
            		RaiseError => 1
        	}
      	)
      	or carp "ERR: connect $DBI::errstr\n"
      	and return 0;

    	my $self = { 'dbh', $dbh };

    	bless $self, $class;

    	$self

}

sub search {
	my $self   = shift;
	my $clause = shift;

    	$clause->{ $glob->{'tablename'} } ||= $glob->{'default_table'};
    	$clause->{ $glob->{'tablename'} } or carp "ERR: no tablename given\n" and return 0;
    	$clause->{ $glob->{'col'} } ||= '*';

    	my $stat = "SELECT $clause->{ $glob->{col} } FROM $clause->{ $glob->{tablename} }";

    	for ( keys %$clause ) {
        	next if /$glob->{'col'}/ or /$glob->{'tablename'}/;
        	/$glob->{'where'}/
		and 
		$clause->{ $glob->{'where'} } =~ s/$regex->{sql}{where}{like}/$1\'$2\'/gi;
        	$stat .= " $clause->{$_}";
    	}

    	$stat .= ';';
    
    	my $res = eval { $self->{'dbh'}->selectall_arrayref($stat) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0;
    	}

    	$res
}

sub select {
    	my $self = shift;
   	$self->search(@_);
}

sub update {
    	my $self   = shift;
    	my $clause = shift;

    	$clause->{ $glob->{'tablename'} } ||= $glob->{'default_table'};
    	$clause->{ $glob->{'tablename'} }
      		or carp "ERR: no tablename given\n"
      		and return 0;

    	my $stat = "UPDATE $clause->{$glob->{tablename}} SET";

    	for ( keys %$clause ) {
        	next if /$glob->{'tablename'}/;
		my $col = $_;
		$clause->{$_} =~ s/$regex->{sql}{update}{value}/\'$1\'/io;
        	$clause->{$_} =~ /$glob->{'where'}/io
		and $clause->{$_} =~ s/$regex->{sql}{where}{like}/$1\'$2\'/io;
		s/$regex->{sql}{update}{col}//io;
        	$stat .= " $_".'='."$clause->{$col}";
    	}

	$stat .= ';';
	
	$self->{'dbh'}->do("BEGIN;");

	my $res = eval { $self->{'dbh'}->do($stat) };

    	if ( $@ ) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0;
    	}

    	$self->{'dbh'}->do("COMMIT;");

    	$res
}

sub delete {
    	my $self   = shift;
    	my $clause = shift;

    	$clause->{ $glob->{'tablename'} } ||= $glob->{'default_table'};
    	$clause->{ $glob->{'tablename'} }
      		or carp "ERR: no tablename given\n"
      		and return 0;
    	my $stat = "DELETE FROM $clause->{$glob->{'tablename'}}";

    	for ( keys %$clause ) {
        	next if /$glob->{'tablename'}/;
        	/$glob->{'where'}/
          	and $clause->{ $glob->{'where'} } =~
          	s/$regex->{sql}{where}{like}/$1\'$2\'/gi;
        	$stat .= " $clause->{$_}";
    	}

    	$stat .= ';';
    
    	$self->{'dbh'}->do("BEGIN;");
    
    	my $res = eval { $self->{'dbh'}->do($stat) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
    	}

    	$self->{'dbh'}->do("COMMIT;");

    	$res
}

sub insert {
	my $self  = shift;
 	my $data  = shift;
    	my $table = shift;
    	my $len   = scalar @{ $data->[0] };
    	my $prep  = '?,' x $len;
    	my @exe;
    	$prep =~ s/,$//;

    	$table ||= $glob->{'default_table'};
    	$table or carp "ERR: no tablename given\n" and return 0;

    	my $stat = "INSERT INTO $table VALUES ($prep);";

    	$self->{'dbh'}->do("BEGIN;");

    	my $sth = eval { $self->{'dbh'}->prepare($stat) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
    	}

    	for my $h (@$data) {
        	for my $key (@$h) {
            		push @exe, $key
        	}
        	eval { $sth->execute(@exe) };
        	@exe = ();
       		if ($@) {
            		carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
        	}
    	}

    	$self->{'dbh'}->do("COMMIT;");

    	1

}

sub create {
    	my $self = shift;
    	my $sql  = shift;

    	$sql->{ $glob->{'tablename'} } ||= $glob->{'default_table'};
    	$sql->{ $glob->{'tablename'} }
      		or carp "ERR: no tablename given\n"
      		and return 0;

    	my $stat = "CREATE TABLE $sql->{$glob->{'tablename'}}\n";
    	my $c;

    	$stat .= "\n(\n";

    	for ( @{ $sql->{ $glob->{'struct'} } } ) {

        	if ( ref($_) eq "ARRAY" ) {
            		$stat .= "  @$_,\n"
        	}else{
            		$stat .= " $_"
        	}

    	}

    	$stat =~ s/,$//;
    	$stat .= "\n);\n";

    	$self->{'dbh'}->do("BEGIN;");

    	eval { $self->{'dbh'}->do($stat) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
    	}

    	$self->{'dbh'}->do("COMMIT;");

    	1
}

sub drop {
	my $self  = shift;
    	my $table = shift;

    	$table ||= $glob->{'default_table'};
    	$table or carp "ERR: no tablename given\n" and return 0;

    	my $stat = "DROP TABLE $table\n";

    	$self->{'dbh'}->do("BEGIN;");

    	eval { $self->{'dbh'}->do($stat) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
    	}

    	$self->{'dbh'}->do("COMMIT;");

    	1
}

sub delete_insert {
    	my $self  = shift;
    	my $data  = shift;
    	my $table = shift;
    	my $len   = scalar @{ $data->[0] };
    	my $prep  = '?,' x $len;
    	my @exe;
    	$prep =~ s/,$//;

    	$table ||= $glob->{'default_table'};
    	$table or carp "ERR: no tablename given\n" and return 0;

    	#	{
    	#		local $glob->{'default_table'} = $table; $self->delete
    	#		but not good for we need this in one transaction
    	#	}

    	my $delete = "DELETE FROM $table";

    	$self->{'dbh'}->do("BEGIN;");

    	eval { $self->{'dbh'}->do($delete) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
    	}

    	my $stat = "INSERT INTO $table VALUES ($prep);";

    	my $sth = eval { $self->{'dbh'}->prepare($stat) };

    	if ($@) {
        	carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
    	}

    	for my $h (@$data) {
        	for my $key (@$h) {
            		push @exe, $key
        	}
        	eval { $sth->execute(@exe) };
        	if ($@) {
            		carp $@ and eval { $self->{'dbh'}->do("ROLLBACK;") } and return 0
        	}
        	@exe = ();
    	}

    	$self->{'dbh'}->do("COMMIT;");

    	1

}

sub DESTROY {
    	my $self = shift;
    	$self->{'dbh'}->disconnect();
    	undef $self
}

1



__END__


=head1 NAME

SQLite::Abstract - Object oriented wrapper for SQLite

=head1 SYNOPSIS



 use SQLite::Abstract;

 
 my $sql = SQLite::Abstract->new($dbname);
 
 my $table_name = "smt";
 
 $SQLite::Abstract::glob->{'default_table'} = $table_name;
 
 $sql->create($table);
 
 $sql->insert($data);
 $sql->search($search);
 $sql->search({});
 
 #the same
 
 $sql->select({});
 $sql->update({$data});
 $sql->delete_insert($data);
 
 $sql->drop;
 
 
=head1 DESCRIPTION

SQLite::Abstract is just another try to wrap sql and to be more concrete - SQLite.
Primary goals are ease and speed in development of sql front-end with the excellent DBD::SQLite. 


=head1 METHODS

Each method works into a single transaction.

=head2 new

   $sql = SQLite::Abstract->new( $dbname );

Object creation expects database name in order to init DB connection.
Database name must ne existing file.

=head2 search

Where argument must be e hash reference, containing 'where' and 'col' keys
which are optional. Each key's name may be changed through the global %{$glob}:

=over

=item C<where>

specifies which rows you want

=item C<col>

specifies the columns you want

=back

   $SQLite::Abstract::glob->{'where'} = 'what';
   $what   = "where phone like %1% and name like %reni%";
   $search = { 'what' => $what, 'col' => 'name, phone' };
   $result = $sql->search($search);
   
   print "name: $_->[0]\tphone: $_->[1]\n" for @$result;

=head2 select

Synonym for search 

=head2 update

This method expects hash ref where the only one key is a column name 
and the value is WHERE clause. The key may be in comapy with 'set':

=over

=item C<name>

specifies which column you want to SET

=item C<where>

specifies the row(s) you want to SET

=back

   $update = { 'name set', 'Reni where name like %reni%' }; #or
   $update = { 'set name', 'Reni where name like %reni%' }; #or
   $update = { 'name', 'RENI where name like %reni%' };

   $result = $sql->update($update);

   print "$result rows updates\n";


=head2 delete

The same method arguments as insert method except that the key does not
have any special meaning - WHERE clause and value which contains the actual
sql code:

Again

=over

=item C<delete>

specifies symbolic word for the action DELETE

=item C<where>

specifies the row(s) you want to DELETE

=back

   #for more comfort
   $SQLite::Abstract::glob->{'where'} = 'remove';
   
   $delete = { 'remove', 'where name like %myself%' };
   $result = $sql->delete($delete);

   print "$result rows deleted\n";


=head2 insert
   
   push my @$data, [("010010", "Tester", "st._one_test_1")];
   $sql->insert( $data )

Where the array must contain the same number and order of columns as the table

=head2 delete_insert

   $sql->delete_insert( @$data )

The same method as 'insert' except that DELETE the table before INSERT
And because it's SQLite - speed is amazing.

=head2 create

This method needs table structure and eventually table name unless
another global var is not set (by default):

   $table_name = 'somewhere';
   $SQLite::Abstract::glob->{'default_table'} = $table_name;

Than the table structure where the key 'struct' is also modules' $glob value

   $SQLite::Abstract::glob->{'struct'} = 'structure';
   $table = {
   	'tablename', $table_name,
   	'structure', [
                'phone',  [qw(INTEGER(32) NOT NULL)],
                'name',   [qw(VARCHAR(512) NOT NULL)],
                'address',[qw(VARCHAR(1024) NOT NULL)]
	
	]
   };

   $sql->create($table);

=head2 drop

   $sql->drop( $table_name )

Pretty self explanatory

=head1 SEE ALSO

L<DBD::SQLite>

=head1 AUTHOR

Vidul Petrov, vidul@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Vidul Petrov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
