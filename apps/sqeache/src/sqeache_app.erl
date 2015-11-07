%% ex: ft=erlang ts=4 sw=4 et
%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
-module(sqeache_app).

-behaviour(application).

-export([start/2,stop/1, statements/0]).

start(_StartType, _StartArgs) ->
    {ok, Port} = application:get_env(sqeache, port),
    {ok, Acceptors} = application:get_env(sqeache, acceptor_count),
    {ok, _} = ranch:start_listener(sqeache,
                                   Acceptors, ranch_tcp,
                                   % TODO - this is a short-term hack, we'll want to use raw and handle split packets.
                                   [{ip, envy_parse:host_to_ip(sqeache, ip)}, {port, Port}], % {sndbuf,4194304},{recbuf,4194304}],
                                   sqeache_handler, []),
    sqeache_sup:start_link().

statements() ->
    {ok, Paths} = application:get_env(sqeache, prepared_statement_files),
    Loaded = [ file:consult(Path) || Path <- Paths],
    lists:flatten([ Statements || {ok, Statements} <- Loaded]).

stop(_State) ->
    ok.
