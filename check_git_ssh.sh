#!/bin/bash

set -e

if [[ $(ssh -T git@github.com 2>&1) != *"You've successfully authenticated"* ]]; then
	echo "==> Could not connect to Github"
fi

if [[ $(ssh -T git@bitbucket.org 2>&1) != *"logged in as"* ]]; then
	echo "==> Could not connect to Bitbucket"
fi

echo "--> finished git ssh check"
