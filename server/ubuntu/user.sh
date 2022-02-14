username=$1
if [ ! -z $username ] && [ ! "$username" = "typo3" ] && [ ! "$username" = "magento2" ]; then
  echo "not a valid username: $username"
  exit 1
fi

useradd -G www-data $username
mkdir -p /home/#{username}/.composer
mkdir -p /home/#{username}/.aws
mkdir -p /home/$username/.ssh
chown -R $username /home/$username/
chown -R $username:www-data /var/www

# echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
