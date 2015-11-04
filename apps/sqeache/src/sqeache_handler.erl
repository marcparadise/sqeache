%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
-module(sqeache_handler).
-behaviour(gen_server).
-behaviour(ranch_protocol).

%% API.
-export([start_link/4]).

%% gen_server.
-export([init/1,
         init/4,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-define(TIMEOUT, 5000).

-record(state, {socket, transport}).

start_link(Ref, Socket, Transport, Opts) ->
	proc_lib:start_link(?MODULE, init, [Ref, Socket, Transport, Opts]).

%% This function is never called. We only define it so that
%% we can use the -behaviour(gen_server) attribute.
init([]) -> {ok, undefined}.

init(Ref, Socket, Transport, _Opts = []) ->
	ok = proc_lib:init_ack({ok, self()}),
	ok = ranch:accept_ack(Ref),
	ok = Transport:setopts(Socket, [{active, once}]),
	gen_server:enter_loop(?MODULE, [],
		#state{socket=Socket, transport=Transport},
		?TIMEOUT).

handle_info({tcp, Socket, Data}, State=#state{
		socket=Socket, transport=Transport}) ->
	Transport:setopts(Socket, [{active, once}]),
	Transport:send(Socket, execute_request(Data)),
	{noreply, State, ?TIMEOUT};
handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State};
handle_info({tcp_error, _, Reason}, State) ->
	{stop, Reason, State};
handle_info(timeout, State) ->
	{stop, normal, State};
handle_info(_Info, State) ->
	{stop, normal, State}.

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

execute_request(B) when is_binary(B) ->
    Result = execute_request(binary_to_term(B)),
    term_to_binary(Result);
execute_request({_, select, Statement, Args, XForm, XFormArgs}) ->
    sqerl:select(Statement, Args, XForm, XFormArgs);
execute_request({_, statement, Statement, Args, XForm, XFormArgs}) ->
    sqerl:statement(Statement, Args, XForm, XFormArgs);
execute_request({_, execute, Statement, Args}) ->
    sqerl:execute(Statement, Args ).
