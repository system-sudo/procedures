### Install nginx
```sh
sudo apt update -y
sudo apt install -y nginx
sudo systemctl enable --now nginx
```
check status:
```sh
sudo systemctl status nginx
```
check nginx logs:
```sh
sudo journalctl -u nginx --no-pager -n 20
```
To Follow logs in real-time (like tail -f):
```sh
sudo journalctl -u nginx -f
```
