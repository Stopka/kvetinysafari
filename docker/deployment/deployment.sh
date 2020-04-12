#!/usr/bin/env bash
APPPATH="./deployment/";
PHPARGS="$APPPATH/app.phar $APPPATH/config.php";
php $PHPARGS -t;
echo "Is this ok?";
read -p "Press any key to continue, or ctrl+c to cancel";
php $PHPARGS;
