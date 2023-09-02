# install mongodb on a sidecar machine

sudo apt-get install gnupg curl

curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /etc/apt/trusted.gpg.d/mongodb-server-7.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update

sudo apt-get install -y mongodb-org

# systemctl enable mongod.service
# sudo systemctl daemon-reload
sudo systemctl enable mongod # enable mongod service
sudo systemctl start mongod # start mongod service


# if connection fails, try:
# sudo systemctl restart mongod
# if still fails, try:
# sudo nano /etc/mongod.conf
# change bindIp:
# bindIp: 127.0.0.1,[ip_address]
# sudo systemctl restart mongod
# sudo systemctl status mongod
# sudo netstat -tuln | grep 27017



