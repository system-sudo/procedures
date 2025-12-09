### To transfer file from one server to other server.
#### Set up SSH key-based authentication
On Server 1, generate a keypair (skip if already exists):
```sh
ssh-keygen -t ed25519
```
Copy the public key id_ed25519.pub from server 1 to Server 2's authorized_keys:
```sh
cd ~/.ssh
nano authorized_keys
```
paste the id_ed25519.pub from server 1 here

#### Use rsync to securely transfer files
Run from Server 1 (push model):
```sh
rsync -avz --progress --partial --append-verify \
    -e "ssh -o IdentitiesOnly=yes -i /home/ubuntu/.ssh/id_ed25519" \
    /home/ubuntu/trs ubuntu@15.207.14.245:/home/ubuntu/test
```
DRY RUN
```sh
rsync -avz --dry-run --progress --partial --append-verify \
    -e "ssh -o IdentitiesOnly=yes -i /home/ubuntu/.ssh/id_ed25519" \
    /home/ubuntu/trs ubuntu@15.207.14.245:/home/ubuntu/test
```
Dry Run to check what files will be transfered when we execute the cmd.

#### Step-by-Step Explanation:

##### 1. Core flags > rsync -avz --progress 
-a (archive mode)
* Preserves file attributes: permissions, ownership, timestamps, symlinks, directories, etc.

-v (verbose)
* Prints more information about what rsync is doing.

-z (compress)
* Compresses data during transfer to save bandwidth (helpful over WAN links).

--progress
* Shows progress per file (bytes, percentage, speed).

##### 2. Resilience / resume flags > --partial --append-verify
--partial
* Keeps partially transferred files if the connection breaks, so a retry can resume rather than start from scratch.

--append-verify
* When resuming transfers, rsync appends new data to the partial file and verifies the overlapped/unchanged part to ensure integrity.

##### 3. SSH transport > -e "ssh -o IdentitiesOnly=yes -i /home/ubuntu/.ssh/id_ed25519"
-e "ssh ..."
* Tells rsync to use SSH as the transport and lets you pass SSH options.

-o IdentitiesOnly=yes
* Forces SSH to use only the identities specified with -i, not whatever is loaded in your ssh-agent or other default keys.

-i /home/ubuntu/.ssh/id_ed25519
* Specifies the private key file to use for authentication.

##### 4. Source and destination paths > /home/ubuntu/trs ubuntu@15.207.14.245:/home/ubuntu/test
* Source: /home/ubuntu/trs
* Destination: ubuntu@15.207.14.245:/home/ubuntu/test
    - Remote server: 15.207.14.245
    - Remote user: ubuntu
    - Remote path: /home/ubuntu/test

✅ rsync is a fast and flexible file transfer/synchronization tool. It copies files from a source to a destination, efficiently transferring only what’s changed.
