package PostgreSQL::SecureMonitoring::Checks::CRUDCount;

=head1 NAME

 PostgreSQL::SecureMonitoring::Checks::CRUDCount -- statistics about read/inserted/updated/deleted rows

=head1 SYNOPSIS

=head1 DESCRIPTION

This check returns a list of databases with fetched/returned/inserted/updated/deleted rows.


=head2 SQL/Result

The SQL generates a result like this:


   >  SELECT * FROM crud_count();
     database  | rows_returned | rows_fetched | rows_inserted | rows_updated | rows_deleted 
   ------------+---------------+--------------+---------------+--------------+--------------
    $TOTAL     |    4319036903 |    815248355 |       3015595 |      6440502 |        75179
    monitoring |      62921444 |     13044164 |         18996 |          668 |        18293
    my_cms     |    2175313445 |    710610692 |       2777476 |      5871634 |         4494
    my_webapp  |    1481707499 |      7525438 |            18 |           27 |            8
    postgres   |      78751513 |     30510312 |             2 |            7 |            2
   (5 rows)



=head3 Filter by database name

Results may be filtered with parameter C<skip_db_re>, which is a regular expression filtering the databases. 
Default Filter is C<^template[01]$>, which excludes <template0> and <template1> databases.


=cut


use PostgreSQL::SecureMonitoring::ChecksHelper;
extends "PostgreSQL::SecureMonitoring::Checks";

has skip_db_re => ( is => "ro", isa => "Str", );



check_has
   name                 => "CRUD Count",
   description          => 'Rows fetched, returned, inserted, updated and deleted',
   has_multiline_result => 1,
   result_is_counter    => 1,
   result_unit          => "",
   result_type          => "bigint",
   arguments            => [ [ skip_db_re => 'TEXT', '^template[01]$' ], ],

   # complex return type
   return_type => q{
      database          VARCHAR(64), 
      rows_returned     BIGINT, 
      rows_fetched      BIGINT,
      rows_inserted     BIGINT,
      rows_updated      BIGINT,
      rows_deleted      BIGINT
      },

   code => q{
      WITH rows AS 
         (
         SELECT datname::VARCHAR(64) AS database, 
                tup_returned AS rows_returned,
                tup_fetched  AS rows_fetched,
                tup_inserted AS rows_inserted,
                tup_updated  AS rows_updated,
                tup_deleted  AS rows_deleted
           FROM pg_stat_database 
          WHERE ( CASE WHEN length(skip_db_re) > 0 THEN datname !~ skip_db_re ELSE true END )
       ORDER BY database
         )
       SELECT '$TOTAL', 
               sum(rows_returned)::BIGINT,
               sum(rows_fetched)::BIGINT, 
               sum(rows_inserted)::BIGINT, 
               sum(rows_updated)::BIGINT, 
               sum(rows_deleted)::BIGINT 
         FROM rows
       UNION ALL
       SELECT * FROM rows;
      };


1;



