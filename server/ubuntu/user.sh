username=$1
if [ ! -z $username ] && [ ! "$username" = "typo3" ] && [ ! "$username" = "magento2" ]; then
  echo "not a valid username: $username"
  exit 1
fi

useradd -G www-data $username
mkdir -p /home/#{username}/.composer

mkdir -p /home/$username/.ssh

echo "Host $git_server
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa" > /home/$username/.ssh/config

chmod 600 /home/$username/.ssh/config

chown -R $username /home/$username/
chown -R $username:www-data /var/www

# echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
