# Remote endpoint used for your tunnel, HE calls this "Server IPv4 Address:" on tunnelbroker.net under Tunnel Details.
REMOTE_ENDPOINT=184.105.253.14

# Local IPV6 for tunnel, HE calls this "Client IPv6 Address:" on tunnelbroker.net under Tunnel Details
LOCAL_IPV6=2001:470:1f10:148::2/64  # Use your client IPv6 address

# Determine the local IPv4 address to use for the tunnel
LOCAL_ENDPOINT=`/sbin/ip route get $REMOTE_ENDPOINT | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'`

# Allow incoming IPv6 HTTP traffic
ip6tables -I UBIOS_WAN_IN_USER 3 -p tcp --dport 80 -j RETURN

# If you also want HTTPS
ip6tables -I UBIOS_WAN_IN_USER 3 -p tcp --dport 443 -j RETURN

ip6tables -I UBIOS_WAN_IN_USER 3 -p tcp --dport 25 -j RETURN   # SMTP
ip6tables -I UBIOS_WAN_IN_USER 3 -p tcp --dport 465 -j RETURN  # SMTPS
ip6tables -I UBIOS_WAN_IN_USER 3 -p tcp --dport 587 -j RETURN  # Submission
ip6tables -I UBIOS_WAN_IN_USER 3 -p tcp --dport 993 -j RETURN  # IMAPS

# Create the tunnel interface
/sbin/ip tunnel add he-ipv6 mode sit remote $REMOTE_ENDPOINT local $LOCAL_ENDPOINT ttl 255
/sbin/ip link set he-ipv6 up

# Assign the client IPv6 address to the tunnel interface
/sbin/ip addr add $LOCAL_IPV6 dev he-ipv6

# Add the default IPv6 route via the tunnel interface
/sbin/ip route add ::/0 dev he-ipv6

### NEW
#ip tunnel add he-ipv6 mode sit remote 184.105.253.14 local 152.117.116.178 ttl 255
#ip link set he-ipv6 up
#ip addr add 2001:470:1f10:148::2/64 dev he-ipv6
#ip -6 route add ::/0 dev he-ipv6
