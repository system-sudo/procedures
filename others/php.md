#### Identify PHP version in use
```sh
php -v
```
#### Locate PHP-FPM pool configuration
```sh
cd /etc/php/8.1/fpm/pool.d/
ls
```
You should see: www.conf
#### Edit the pool configuration
```sh
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
```
#### Validate PHP-FPM config
```sh
sudo php-fpm8.1 -t
```
Output: NOTICE: configuration file ... test is successful
#### Restart PHP-FPM
```sh
sudo systemctl restart php8.1-fpm
```
Verify:
```sh
sudo systemctl status php8.1-fpm
```
#### PHP-FPM sizing rule:
```sh
pm.max_children × avg PHP process memory < 70% of RAM
```
List actual PHP-FPM processes:
```sh
ps aux | grep php-fpm | grep -v grep
```
Check:
```sh
ps -ylC php-fpm8.1 --sort:rss
```
If each process is ~80MB:
```sh
12 × 80MB = ~960MB
```
