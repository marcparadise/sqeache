%% ex: ft=erlang ts=4 sw=4 et
%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-

-module(sqeache_data).
-export([statements/0]).
%
% create table users (id serial, name varchar(255), email varchar(255),
%                     flag1 boolean, created_at timestamp,
%                     CONSTRAINT "users_pkey" PRIMARY KEY ("id"));
statements() ->
   [ {fetch_users, <<"SELECT * FROM users">>},
     {add_user, <<"INSERT INTO USERS (name, email, flag1, created_at) VALUES ($1, $2, $3, CURRENT_TIMESTAMP) RETURNING id">>},
     {delete_user_by_name, <<"DELETE FROM USERS WHERE name = $1">>},
     {delete_user_by_id, <<"DELETE FROM USERS WHERE ID = $1">>} ].
