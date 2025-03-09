set +x
zola build -u ""
cp public/ /var/www/static-site -r

sudo chown -R $USER:$USER /var/www/static-site
sudo chown -R www-data:www-data /var/www/static-site
sudo chmod -R 755 /var/www/static-site

sudo nginx -t && sudo systemctl reload nginx
