#!/bin/sh

set -ex

TARGETHOST=antti@hackchat.net
NAME=hackchat

cd $(dirname $0)/..

ssh $TARGETHOST mkdir -p /opt/apps/$NAME
rsync -r --exclude .git --exclude-from=.gitignore . $TARGETHOST:/opt/apps/$NAME
ssh $TARGETHOST sudo cp /opt/apps/$NAME/deploy/$NAME.conf /etc/init/
ssh $TARGETHOST "cd /opt/apps/$NAME && npm install"
ssh $TARGETHOST "sudo stop $NAME; sudo start $NAME"

