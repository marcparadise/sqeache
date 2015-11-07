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

init(Ref, Socket, Transport, _Opts ) ->
	ok = proc_lib:init_ack({ok, self()}),
	ok = ranch:accept_ack(Ref),
    ok = Transport:setopts(Socket, [{active, once}, {packet, raw}]),
	gen_server:enter_loop(?MODULE, [],
                          #state{socket=Socket, transport=Transport},
                          ?TIMEOUT).

handle_info({tcp, Socket, <<Length:32/integer,Data/binary>>},
            State=#state{ socket=Socket, transport=Transport}) ->
    FullMessage = recv_loop(Transport, Socket, Length - byte_size(Data), Data),
    Result = execute_request(FullMessage),
    ResultSize = byte_size(Result),
	Transport:send(Socket, <<ResultSize:32/integer,Result/binary>>),
    Transport:setopts(Socket, [{active, once}]),
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

recv_loop(_Transport, _Socket, 0, Data) ->
    Data;
recv_loop(Transport, Socket, RemainingLength, Data) ->
    case Transport:recv(Socket, RemainingLength, infinity) of
        {ok, MoreData} ->
            recv_loop(Transport, Socket, RemainingLength - byte_size(MoreData),
                      <<Data/binary,MoreData/binary>>);
        {error, What} ->
            {tcp_error, What};
        Unknown ->
            {tcp_error, {unexpected_response, Unknown}}
    end.



execute_request(B) when is_binary(B) ->
    Result = execute_request(binary_to_term(B)),
    term_to_binary(Result);
execute_request({_, select, Statement, Args, XForm, XFormArgs}) ->
    sqerl:select(Statement, Args, XForm, XFormArgs);
execute_request({_, statement, Statement, Args, XForm, XFormArgs}) ->
    sqerl:statement(Statement, Args, XForm, XFormArgs);
execute_request({_, execute, Statement, Args}) ->
    sqerl:execute(Statement, Args ).
