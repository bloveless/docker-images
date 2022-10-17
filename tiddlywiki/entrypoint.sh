#! /usr/bin/env bash
wikiname=${WIKINAME:-wiki}
listen_host=${LISTENHOST:-0.0.0.0}
listen_port=${LISTENPORT:-8080}

echo "Using wiki /tiddlywiki/$wikiname"

[ ! -d "/tiddlywiki/$wikiname" ] && tiddlywiki $wikiname --init server

exec /usr/bin/tini -- tiddlywiki $wikiname --listen host=$listen_host port=$listen_port

