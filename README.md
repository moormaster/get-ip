# GetIp
Bash script to query the current external IPv4 or IPv6.
  
To be used with [ddclient](https://github.com/ddclient/ddclient)

## Example
```
$ ./get-ip.sh -4
12.34.56.78

$ ./get-ip.sh -6
1:2:3:4::2

$ ./get-ip.sh -4 -6
12.34.56.78,1:2:3:4::2
```
