[connection]
id=${id}
type=ethernet
autoconnect-priority=-999
interface-name=eth0
permissions=

[ethernet]
mac-address-blacklist=

[ipv4]
dns=1.1.1.1;1.0.0.1;
dns-search=${domain}
method=auto

[ipv6]
addr-gen-mode=eui64
dns-search=
method=auto

[proxy]
