#!/bin/bash

# Remote endpoint used for your tunnel
REMOTE_ENDPOINT=184.105.253.14
LOCAL_IPV6=2001:470:1f10:148::2/64
LOCAL_ENDPOINT=`/sbin/ip route get $REMOTE_ENDPOINT | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'`

# Clean up existing configuration...
echo "Cleaning up existing configuration..."
ip link set he-ipv6 down 2>/dev/null
ip tunnel del he-ipv6 2>/dev/null
ip6tables -F UBIOS_WAN_IN_USER

# Add basic security rules
echo "Adding basic security rules..."

# Allow established and related connections
ip6tables -I UBIOS_WAN_IN_USER 1 -m state --state ESTABLISHED,RELATED -j RETURN

# Allow ICMPv6 with rate limiting
ip6tables -I UBIOS_WAN_IN_USER 2 -p ipv6-icmp -m limit --limit 30/minute -j RETURN

# Allow DNS to nameservers
ip6tables -I UBIOS_WAN_IN_USER 3 -p udp --dport 53 -d 2001:470:c0b5:5::3 -j RETURN  # CoreDNS UDP
ip6tables -I UBIOS_WAN_IN_USER 4 -p tcp --dport 53 -d 2001:470:c0b5:5::3 -j RETURN  # CoreDNS TCP

# Web services for kratos
ip6tables -I UBIOS_WAN_IN_USER 5 -p tcp --dport 80 -d 2001:470:c0b5:5::1 -j RETURN  # kratos HTTP
ip6tables -I UBIOS_WAN_IN_USER 6 -p tcp --dport 443 -d 2001:470:c0b5:5::1 -j RETURN # kratos HTTPS

# Mail server rules
ip6tables -I UBIOS_WAN_IN_USER 7 -p tcp --dport 25 -d 2001:470:c0b5:4:8a8:c150:1491:190d -j RETURN   # SMTP
ip6tables -I UBIOS_WAN_IN_USER 8 -p tcp --dport 465 -d 2001:470:c0b5:4:8a8:c150:1491:190d -j RETURN # SMTPS
ip6tables -I UBIOS_WAN_IN_USER 9 -p tcp --dport 587 -d 2001:470:c0b5:4:8a8:c150:1491:190d -j RETURN # Submission
ip6tables -I UBIOS_WAN_IN_USER 10 -p tcp --dport 993 -d 2001:470:c0b5:4:8a8:c150:1491:190d -j RETURN # IMAPS

# DUSK Network rules
ip6tables -I UBIOS_WAN_IN_USER 11 -p tcp --dport 8080 -d 2001:470:c0b5:5::5 -j RETURN  # DUSK API
ip6tables -I UBIOS_WAN_IN_USER 12 -p tcp --dport 9000 -d 2001:470:c0b5:5::5 -j RETURN  # DUSK P2P

# Drop invalid packets
ip6tables -I UBIOS_WAN_IN_USER 13 -m state --state INVALID -j DROP

# Log and drop everything else
ip6tables -A UBIOS_WAN_IN_USER -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "IPv6_DENIED: " --log-level 7
ip6tables -A UBIOS_WAN_IN_USER -j DROP

# Create and configure tunnel interface
echo "Setting up tunnel interface..."
/sbin/ip tunnel add he-ipv6 mode sit remote $REMOTE_ENDPOINT local $LOCAL_ENDPOINT ttl 255
/sbin/ip link set he-ipv6 up
/sbin/ip addr add $LOCAL_IPV6 dev he-ipv6
/sbin/ip route add ::/0 dev he-ipv6

# Verify setup
echo "Verifying setup..."
ip link show he-ipv6
ip -6 addr show he-ipv6
ip -6 route show
echo -e "\nFirewall Rules:"
ip6tables -L UBIOS_WAN_IN_USER -n --line-numbers -v

echo "Setup complete!"
