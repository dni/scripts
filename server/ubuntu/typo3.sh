#!/bin/sh
sh ~/scripts/server/install.sh
sh ~/scripts/server/php.sh "typo3"
touch /root/.setup_done
