%% name of module must match file name
-module(mod_add_timestamp).
 
-author("trepa").
 
%% Every ejabberd module implements the gen_mod behavior
%% The gen_mod behavior requires two functions: start/2 and stop/1
-behaviour(gen_mod).
 
%% public methods for this module
-export([start/2, stop/1, on_filter_packet/1]).
 
%% included for writing to ejabberd log file
-include("ejabberd.hrl").
-include("logger.hrl").
-include("jlib.hrl").

start(_Host, _Opt) -> 
    error_logger:info_msg("starting mod_add_timestamp", []),
    ejabberd_hooks:add(filter_packet, global, ?MODULE, on_filter_packet, 120).

stop(_Host) -> 
    error_logger:info_msg("stopping mod_add_timestamp", []),
    ejabberd_hooks:delete(filter_packet, global, ?MODULE, on_filter_packet, 120).

on_filter_packet({ _, _, #xmlel{name = <<"message">>, attrs = [{<<"type">>,<<"normal">>}], children = _} } = Packet) -> Packet;
on_filter_packet({ From, To, #xmlel{name = <<"message">>, attrs = _Attrs, children = _SubEl} = Xml} = Packet) ->
    case xml:get_subtag(Xml, <<"data">>) of
        false ->
            Timestamp = get_timestamp(),
            XMLTag = #xmlel{ name = <<"data">>, attrs = [{<<"timestamp">>, list_to_binary([Timestamp])}]},
            NewXml = xml:append_subtags(Xml, [XMLTag]),
            NewPacket = {From, To, NewXml},
            NewPacket;
        _ ->
            Packet
    end;
    
on_filter_packet(FullPacket) -> FullPacket.
    
get_timestamp()->
    {Mega, Secs, Micro} = now(),
    io_lib:format("~p", [(Mega*1000000 + Secs)*1000000 + Micro]).

