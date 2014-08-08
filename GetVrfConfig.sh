#!/bin/bash

vrf="$1"
ConfigFile="$2"

echo "Vrf name: $vrf"
echo "Config File: $ConfigFile"

if [[ "$ConfigFile" == "" ]]
then 
    ConfigFile="pod2-pe1"
fi
VRFPart() {
cat $ConfigFile | sed -n "/^vrf\ $vrf$/,/^!/p"
}
BGPPart() {
BGPConfig="$(cat $ConfigFile | sed -n "/^router bgp 15688/,/^!/p" | sed -n "/^\ vrf\ "$vrf"$/,/^\ !/p")"
if [[ -z "$BGPConfig" ]] 
then
echo "!"
else 
cat $ConfigFile | grep "router bgp 15688"
cat $ConfigFile | sed -n "/^router bgp 15688/,/^!/p" | sed -n "/^\ vrf\ "$vrf"/,/^\ !/p"
fi
}
StaticRoutePart() {
StaticRouteConfig="$(cat $ConfigFile | sed -n "/^router static/,/^!/p" | sed -n "/^\ vrf\ "$vrf"$/,/^\ !/p")"
if [[ -z "$StaticRouteConfig" ]] 
then
echo "!"
else
cat $ConfigFile | grep "router static"
cat $ConfigFile | sed -n "/^router static/,/^!/p" | sed -n "/^\ vrf\ "$vrf"$/,/^\ !/p"
fi
}
InterfacePart() {
IFNAME="$(cat "$ConfigFile" | sed -n "/^interface/,/^!/p" | sed -n "/^\ vrf\ "$vrf"$/,/^!/p" | grep encapsulation | awk '{print $NF}')"
for i in $IFNAME 
 do cat $ConfigFile | sed -n "/^interface\ .*\."$i"$/,/^!/p" 
done
}
RoutePolicyPrefixSetPart() {
RoutePolicy="$(cat $ConfigFile | sed -n "/^vrf\ $vrf$/,/^!/p" | grep "import route-policy" | awk '{print $NF}')"
if [[ -z "$RoutePolicy" ]]      
then 
echo "!"
else
PrefixSet="$(cat $ConfigFile | sed -n "/^route-policy\ "$RoutePolicy"/,/^!/p" | sed -n '/if\ destination\ in\ [a-zA-Z0-9\-\_]/p' | awk '{print $4}' | uniq)"
if [[ -z "$PrefixSet" ]]         
then 
echo "!"
else
for i in $PrefixSet
do cat $ConfigFile | sed -n "/^prefix-set\ "$i"/,/^!/p" 
done
fi
cat $ConfigFile | sed -n "/^route-policy\ "$RoutePolicy"/,/^!/p"
fi
}
DHCPPart() {
DHCPIPv4Profile="$(cat $ConfigFile | sed -n "/^dhcp ipv4/,/^!/p" | grep -B 1 "helper-address vrf "$vrf"" | grep profile | awk '{print $2}')"
if [[ -z "$DHCPIPv4Profile" ]]
then
echo "!"
else
cat $ConfigFile | sed -n "/^dhcp ipv4/,/^!/p" | grep '^dhcp ipv4'
cat $ConfigFile | sed -n "/^dhcp ipv4/,/^!/p" | sed -n "/^\ profile\ "$DHCPIPv4Profile"/,/^\ !/p"
cat $ConfigFile | sed -n "/^dhcp ipv4/,/^!/p" | grep "interface\ .*relay\ profile\ "$DHCPIPv4Profile""
fi

DHCPIPv6Profile="$(cat $ConfigFile | sed -n "/^dhcp ipv6/,/^!/p" | grep -B 1 "helper-address vrf "$vrf"" | grep profile | awk '{print $2}')"
if [[ -z "$DHCPIPv6Profile" ]]
then
echo "!"
else
cat $ConfigFile | sed -n "/^dhcp ipv6/,/^!/p" | grep '^dhcp ipv6'
cat $ConfigFile | sed -n "/^dhcp ipv6/,/^!/p" | sed -n "/^\ profile\ "$DHCPIPv6Profile"/,/^\ !/p"
cat $ConfigFile | sed -n "/^dhcp ipv6/,/^!/p" | grep "interface\ .*relay\ profile\ "$DHCPIPv6Profile""
fi
}
VRFPart
DHCPPart
InterfacePart
RoutePolicyPrefixSetPart
StaticRoutePart
BGPPart

