sqeache
=====

Pronunciation: "squeesh"
Alternative pronunciation: There is only one way to pronounche 'sqeache'.

A postgresql proxy via sqerl with persistent connection and prepared statement support.
Currently this is a basic raw tcp proxy that converts binaries to terms and vice-versa.
It simply passes any request through to sqerl and ships it off any response to the
requestor.

It will eventual support caching, authorization, encrpytion, and other
goodies.  But for now it's a PoC that I'm having some fun with.

What's being used, you ask?
 * sqerl + pooler - for the DB
 * ranch - tcp acceptor pooling
 * sync - for easy rapid iteration



Next Steps and/or Random Thoughts
---------------------------------

* Auth Considerations - simple first pass:
  * disterl to establisha  valid session with permitted remote nodes -
    that will have its own auth mechanishm, and is only done once per
    node.
  * A token is associated with that auth. Each request via the TCP
    interface must include that token (and the token must map to an
    authenticated session w/ matching IP + MAC)
  * Probably doesn't protect against  spoofing where the attacker
    knows the token and the originating IP associated with it, but it
    does prevent the current ability for anyone to connect and run
    anything they want if they know the (very simple) protocol.
  * Will this work for disterl/rpc over NAT, where multiple will get the
    same IP?
* Encryption
  * Yep we'll need this, but for the moment it's all a PoC anyway
* Caching
  * Allow statements to be tagged with a cache key, and others to be tagged
    as invalidating a list of known cache keys.
* sqerl : this project should support multiple databases. However, there
  are two options for that:
  * modify sqerl to support multi-connection
  * run one instance of sqeache per back end DB, on the same
    or different nodes.
  * Two approaches here.  - sqerl's going to need multi-pool support for this one. Coming
  soon in my sqerl fork.
* Pooler enhancements -
    * the app.confuig has a number of meaningless pooler config entries that I'd
      like to make mean something.  The comments there explain them. The
      TL;DR is:
      * worker health check on checkin
      * pruning workers to a threshold based on utilization
* Aggressive connection pooling via sqerl/pooler. Default settings to
  allow a significnat backlog and perf test that with variable load.
* Speaking of perf testing...


Build
-----

    $ rebar3 compile

Tests
-----

Coming Real Soon Now. You'll need postgresql installed.


REPL and Doing Stuff By Hand
-----------------------------
Take a look at sys.config  and make a DB and user that matches on
your local postgresql. You'll also need to make a table as follows, and make sure that the user
from app.config has full access to all sequences and tables in the DB:

     create table users (id serial, name varchar(255), email varchar(255), flag1 boolean, created_at timestamp, CONSTRAINT "users_pkey" PRIMARY KEY ("id"))

Now build `sqeache` and start it in a console. If you did everything right, there won't be errors.  If there are, it's totally not my fault:

    $ rebar3 release
    $ _build/default/rel/sqeache/bin/sqeache console

Separately, grab `sqeache_client` and bring it up:

    sqeache_client$ make

Create some data:

    sqeache_client:statement(testdb, add_user, [<<"Jiminy">>, <<"home@somewhere.com">>, true]).
    sqeache_client:statement(testdb, add_user, [<<"Bob">>, <<"bob@somewhere.com">>, false]).
    sqeache_client:statement(testdb, add_user, [<<"Englebert">>, <<"englebert@somewhere.com">>, true]).

Do a query on the fly:

    sqeache_client:statement(testdb, <<"SELECT COUNT(*) FROM users">>, [],  first_as_scalar, [count]).

Or just execute something for some raw output:
    sqeache_client:execute(testdb, <<"SELECT COUNT(*) FROM users">>, []).

Do something bad that will crash the remote connection (the default
xform for 'id'  isn't correct for this):

    sqeache_client:statement(testdb, <<"SELECT COUNT(*) FROM users">>, []).

Run something else and see that you didn't really break anything:

    sqeache_client:statement(testdb, <<"SELECT COUNT(*) FROM users">>, [],  first_as_slcalar, [count]).

Look ma, more transforms:

    sqeache_client:select(testdb, fetch_users, [], first_as_scalar, [name]).
    sqeache_client:select(testdb, fetch_users, [], rows_as_scalars, [name]).
    sqeache_client:select(testdb, fetch_users, [], first).
    sqeache_client:select(testdb, fetch_users).

Even more transforms - these showing that we can pass in any record
definition we care about, and sqeache is oblivious as long as it's
semantically correct (just like sqerl, which is the intent):

    sqeache_client:select(testdb, fetch_users, [], first_as_record, [user, [id, name, email, flag1, created_at]]).
    sqeache_client:select(testdb, fetch_users, [], rows_as_records, [dweeb, [id, name, email, flag1, created_at]]).
