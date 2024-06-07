PostgreSQL Database Management System
=====================================

This directory contains the source code distribution of the PostgreSQL
database management system.

PostgreSQL is an advanced object-relational database management system
that supports an extended subset of the SQL standard, including
transactions, foreign keys, subqueries, triggers, user-defined types
and functions.  This distribution also contains C language bindings.

Copyright and license information can be found in the file COPYRIGHT.

General documentation about this version of PostgreSQL can be found at
<https://www.postgresql.org/docs/devel/>.  In particular, information
about building PostgreSQL from the source code can be found at
<https://www.postgresql.org/docs/devel/installation.html>.

The latest version of this software, and related software, may be
obtained at <https://www.postgresql.org/download/>.  For more information
look at our web site located at <https://www.postgresql.org/>.

Example of memleak
------------------

```
./build/bin/initdb test-db
./build/bin/postgres --config-file=$(pwd)/test-db/postgresql.conf -D $(pwd)/test-db -k $(pwd)/test-db
./build/bin/psql -h localhost postgres

$ sudo memleak -p 1403478

[18:57:34] Top 10 stacks with outstanding allocations:
        98304 bytes in 2 allocations from stack
                0x0000000000a1d53c      AllocSetAllocFromNewBlock+0x142 [postgres]
                0x0000000000a1da62      AllocSetAlloc+0x164 [postgres]
                0x0000000000a271ee      palloc+0x5c [postgres]
                0x00000000008af709      PostgresMain+0x206 [postgres]
                0x00000000008a9140      BackendMain+0x59 [postgres]
                0x00000000007ffdd7      pgarch_die+0x0 [postgres]
                0x00000000008045aa      BackendStartup+0x9a [postgres]
                0x0000000000804833      ServerLoop+0x79 [postgres]
                0x0000000000805f69      BackgroundWorkerInitializeConnection+0x0 [postgres]
                0x0000000000720c27      main+0x216 [postgres]
                0x00007f1b0b993ace      __libc_start_call_main+0x7e [libc.so.6]
```

References
----------

- https://www.enterprisedb.com/blog/finding-memory-leaks-postgres-c-code
- https://news.ycombinator.com/item?id=39844439
