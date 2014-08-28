apt-get update
apt-get -y install git curl redis-server libxslt-dev libxml2-dev libyaml-dev build-essential bison openssl zlib1g libxslt1.1 libssl-dev libxslt1-dev libxml2 libffi-dev libxslt-dev autoconf libc6-dev libreadline6-dev zlib1g-dev libtool libsqlite3-dev libcurl3 libmagickcore-dev libmagickwand-dev imagemagick
sudo aptitude purge ruby

wget -O - https://get.rvm.io | bash
rvm requirements
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
rvm install ruby-2.1.2
rvm use 2.1.2
rvm rubygems current

gem install bundler --no-ri --no-rdoc
gem install rails -v 4.0.9  --no-ri --no-rdoc
gem install sidekiq --no-ri --no-rdoc


cd /vagrant
git clone https://github.com/Netflix/Scumblr.git
cd Scumblr
bundle install
rake db:create
rake db:schema:load

redis-server &
bundle exec rails s &

echo '----------------------------------------------' >> /etc/motd
echo 'Welcome! We have already set up a base box for' >> /etc/motd
echo 'you, but there is still config yet to be done.' >> /etc/motd
echo 'You need to go into /vagrant/Scrumblr and make' >> /etc/motd
echo 'an admin user. See http://bit.ly/1oqdwFU      ' >> /etc/motd
echo '----------------------------------------------' >> /etc/motd

cat /etc/motd


# user = User.new
# user.email = "admin@localhost.com"
# user.password = "root"
# user.password_confirmation = "root"
# user.admin = true
# user.save
