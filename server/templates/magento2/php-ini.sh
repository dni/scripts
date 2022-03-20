php_version=$1
if [ -z $php_version ]; then
  echo "no php version specified"
  exit 1
fi

php_ini=/etc/php/$php_version/apache2/php.ini
sed -i $php_ini
  -e '/date.timezone/c\date.timezone = "Europe/Vienna"' \
  -e "/memory_limit/c\memory_limit = 1G" \
  -e "/realpath_cache_ttl/c\realpath_cache_ttl = 7200" \
  -e "/realpath_cache_size/c\realpath_cache_size = 10M"
  -e "/opcache.enable/c\opcache.enable=1" \
  -e "/opcache.enable_cli/c\opcache.enable_cli=1" \
  -e "/opcache.save_comments/c\opcache.save_comments=1" \
  -e "/opcache.memory_consumption/c\opcache.memory_consumption=512" \
  -e "/opcache.max_accelerated_files/c\opcache.max_accelerated_files=60000" \
  -e "/opcache.consistency_checks/c\opcache.consistency_checks=0" \
  -e "/opcache.validate_timestamps/c\opcache.validate_timestamps=0"

cat <<EOF > $php_ini
apc.enabled = 1
apc.shm_size=256M
;apc.mmap_file_mask=/srv/apc.shm.XXXXXX
apc.include_once_override=0
apc.ttl=7200
apc.user_ttl=7200
apc.user_entries_hint=10000
apc.stat=0
apc.enable_cli=1
apc.max_file_size=5M
apc.slam_defense=0
EOF

