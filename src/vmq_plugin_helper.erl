%% Copyright 2014 Erlio GmbH Basel Switzerland (http://erl.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(vmq_plugin_helper).
-export([all/2,
         all_till_ok/2]).

all(Hooks, Params) ->
    all(Hooks, Params, []).
all([{Module, Fun}|Rest], Params, Acc) ->
    Res = apply(Module, Fun, Params),
    all(Rest, Params, [Res|Acc]);
all([], _, Acc) -> lists:reverse(Acc).

all_till_ok(Hooks, Params) ->
    all_till_ok(Hooks, Params, []).
all_till_ok([{Module, Fun}|Rest], Params, ErrAcc) ->
    case apply(Module, Fun, Params) of
        ok -> ok;
        {ok, V} -> {ok, V};
        next ->
            all_till_ok(Rest, Params, ErrAcc);
        {next, Aux} ->
            all_till_aux_ok(Rest, Params, Aux, ErrAcc);
        E -> all_till_ok(Rest, Params, [E|ErrAcc])
    end;
all_till_ok([], _, []) ->
    {error, no_matching_hook_found};
all_till_ok([], _, ErrAcc) ->
    {error, ErrAcc}.

all_till_aux_ok([{Module, Fun}|Rest] = Hooks, Params, Aux, ErrAcc) ->
    Arity = length(Params),
    case lists:keyfind(Fun, 1, Module:module_info(exports)) of
        {Fun, Arity} -> all_till_ok(Hooks, Params, ErrAcc);
        {Fun, NewArity} when NewArity =:= (Arity + 1) ->
            case apply(Module, Fun, Params ++ [Aux]) of
                ok -> ok;
                {ok, V} -> {ok, V};
                next ->
                    all_till_ok(Rest, Params, ErrAcc);
                {next, Aux} ->
                    all_till_aux_ok(Rest, Params, Aux, ErrAcc);
                E -> all_till_ok(Rest, Params, [E|ErrAcc])
            end
    end;
all_till_aux_ok([], _, _, []) ->
    {error, no_matching_hook_found};
all_till_aux_ok([], _, _, ErrAcc) ->
    {error, ErrAcc}.
