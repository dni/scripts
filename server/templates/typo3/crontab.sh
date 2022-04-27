#!/bin/bash
if [ "$(hostname)" = "typo3-prod1" ]
then
  for f in $(ls /var/www/); do
    if [ "$f" = "html" ]
    then
      continue
    fi
    php /var/www/$f/public/typo3/sysext/core/bin/typo3 scheduler:run
  done
fi
