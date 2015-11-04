-module(sqeache_app).

-behaviour(application).

-export([start/2,stop/1]).

start(_StartType, _StartArgs) ->
    {ok, Port} = application:get_env(sqeache, listen_port),
    {ok, _} = ranch:start_listener(sqeache_handler, 10,
		ranch_tcp, [{port, Port}], sqeache_handler, []),
    sqeache_sup:start_link().

stop(_State) ->
    ok.

