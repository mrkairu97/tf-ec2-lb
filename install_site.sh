#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
yum update -y
yum install -y mod_ssl
sudo /etc/pki/tls/certs/make-dummy-cert localhost.crt
sed 's/SSLCertificateKeyFile/# SSLCertificateKeyFile/g' /etc/httpd/conf.d/ssl.conf
systemctl restart httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
