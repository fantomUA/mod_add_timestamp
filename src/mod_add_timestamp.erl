%% name of module must match file name
-module(mod_add_timestamp).
 
-author("Johan Vorster").
 
%% Every ejabberd module implements the gen_mod behavior
%% The gen_mod behavior requires two functions: start/2 and stop/1
-behaviour(gen_mod).
 
%% public methods for this module
-export([start/2, stop/1, on_filter_packet/1]).
 
%% included for writing to ejabberd log file
-include("ejabberd.hrl").

start(_Host, _Opt) -> 
    ?INFO_MSG("starting mod_add_timestamp", []),
    ejabberd_hooks:add(filter_packet, global, ?MODULE, on_filter_packet, 120).

stop(_Host) -> 
    ?INFO_MSG("stopping mod_add_timestamp", []),
    ejabberd_hooks:delete(filter_packet, global, ?MODULE, on_filter_packet, 120).

on_filter_packet({From, To, XML} = Packet) ->
    Type = xml:get_tag_attr_s("type", XML),
    DataTag = xml:get_subtag(XML, "data"), 
    %% Add timestamp to chat message and where no DataTag exist 
    case Type =:= "groupchat" andalso DataTag =:= false of
        true -> 
            Timestamp = now_to_seconds(erlang:now()),
            FlatTimeStamp = lists:flatten(io_lib:format("~p", [Timestamp])),
            XMLTag = {xmlelement,"data", [{"timestamp", FlatTimeStamp}], []}, 
            TimeStampedPacket = xml:append_subtags(XML, [XMLTag]),
            ReturnPacket = {From, To, TimeStampedPacket},
            Return = ReturnPacket;
        false ->
            Return = Packet
    end,
    Return.
    
now_to_seconds({Mega, Sec, _Micro}) ->
    %%Epoch time in milliseconds from 1 Jan 1970
    (Mega*1000000 + Sec). 
