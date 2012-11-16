#!/bin/bash

RESULT=2

while [[ "$RESULT" == 2 ]]; do
	node_modules/coffee-script/bin/coffee start.coffee
	RESULT=$?
done

