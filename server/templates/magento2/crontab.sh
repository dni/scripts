#!/bin/sh
for f in $(ls /var/www/); do
  if [ ! "$f" == "html" ]; then
    /usr/bin/flock -n /var/www/$f/.cron.flag test ! -e /var/www/$f/var/.maintenance.flag \
      && /usr/bin/php /var/www/$f/bin/magento cron:run | \
      grep -v 'Ran jobs by schedule' >> /var/www/$f/var/log/magento.cron.log
  fi
done
