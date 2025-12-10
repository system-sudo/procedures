### 🛠️ STEP 1 — Server-Side Admin Guide for Managing SFTP Users

#### SFTP User Management — Admin Guide

This guide explains how to create, configure, and manage SFTP-only users using a secure chroot environment.

#### 1. Server Requirements

* Ubuntu or Debian Linux
* OpenSSH server installed and running
* SFTP-only group: sftpusers

If not created:
```sh
sudo groupadd sftpusers
```
#### 2. sshd_config Settings
Edit:
```sh
sudo nano /etc/ssh/sshd_config
```
Ensure these lines exist:
```sh
Subsystem sftp internal-sftp

Match Group sftpusers
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTcpForwarding no
```
Restart SSH after editing:
```sh
sudo systemctl restart sshd
```
3. Create Chroot Directory Structure
```sh
/srv/sftp/<username>       (root-owned)
└── uploads                (user-owned)
```
Commands:
```sh
sudo mkdir -p /srv/sftp/<username>/uploads

sudo chown root:root /srv/sftp/<username>
sudo chmod 755 /srv/sftp/<username>

sudo chown <username>:sftpusers /srv/sftp/<username>/uploads
sudo chmod 700 /srv/sftp/<username>/uploads
```
#### 4. Create a New SFTP User

Create the user (no shell) - Replace <username> with the actual username.
```sh
sudo useradd -m -d /home/<username> -s /usr/sbin/nologin -G sftpusers <username>
sudo passwd <username>
```

#### 5. Validate Permissions

Correct output should be:
```sh
/srv/sftp/<username>        → root:root, 755
/srv/sftp/<username>/uploads → <username>:sftpusers, 700
```

This is critical — incorrect ownership will break SFTP login.

#### 6. Test Login

From a client:
```sh
sftp <username>@server_ip
```

If the user logs in and sees:
```sh
sftp>
```

The setup is correct.

#### 7. Remove a User
```sh
sudo userdel -r <username>
sudo rm -rf /srv/sftp/<username>
```
### 📄 STEP 2 — Client Instructions for SFTP Access

#### SFTP Access Instructions

You have been granted secure SFTP (SSH File Transfer Protocol) access to your server.  
Use the details below to log in, upload files, download files, and manage your content.

#### 1. Connection Details

* Server IP	13.204.86.73
* Protocol	SFTP
* Port	22
* Username	Provided to you separately
* Password	Provided to you separately

#### 2. How to Connect from Windows (No additional software required)

Windows 10 and Windows 11 include a built-in SFTP client.

Step-by-step:

1. Open PowerShell
2. Run:
```sh
sftp your_username@13.204.86.73
```
3. Enter your password when prompted
4. You will see an interactive SFTP prompt:
```sh
sftp>
```
This confirms a successful connection.

#### 3. Basic SFTP Commands
List files
```sh
ls
```
Change directory
```sh
cd foldername
```
Change your local download location
```sh
lcd C:\Users\YourName\Downloads
```
Download a single file
```sh
get filename.txt
```
Upload a file
```sh
put localfile.txt
```
#### 4. Downloading an Entire Folder (With All Contents)

To download the complete folder:
```sh
get -r folder_name
```
This will download the folder recursively into your current local directory.

#### 5. Allowed Upload Location

You can upload files only inside the uploads folder:
```sh
cd uploads
put yourfile.txt
```
Files placed here will be available to the server.

#### 6. Security Notes

* Access is restricted to your assigned directory only.

* You cannot access or browse system files.

* All transfers are encrypted.

* If you need additional users or expanded access, please contact support.
