### To get the number of requests per IP address, sorted in descending order.
Command:
```sh
awk '{print $1}' access.log | sort | uniq -c | sort -rn
```
If you still want to sort by IP:
```sh
awk '{print $1}' access.log | sort -t . -k1,1n -k2,2n -k3,3n -k4,4n | uniq -c
```
#### Step-by-Step Explanation:

##### 1. awk '{print $1}' access.log
* awk reads each line of access.log.
* {print $1} means: print the first field (column) of each line.
* In Apache logs, the first field is usually the client IP address.
* Result: A list of IP addresses (one per line).

##### 2. | sort
* Takes the list of IPs and sorts them alphabetically.
* Sorting is necessary because the next command (uniq) only works on consecutive duplicates.

##### 3. | uniq -c
* uniq removes duplicate consecutive lines.
* -c adds a count of how many times each unique IP appeared.
* Result: Each line now shows:
* [count] [IP]

##### 4. | sort -rn
* Sorts the output numerically (-n) and in reverse order (-r).
* So the IP with the highest request count appears first.
* Result: A descending list of IPs by number of requests.

##### 5. Final Output:  
41391 14.195.129.150  
40693 49.249.37.10  
36037 115.245.92.66  
...

✅ This is a quick way to find the most active IPs hitting your server.
