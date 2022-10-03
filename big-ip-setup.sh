####################################################
## IF BIG-IP is newly deployed in UDF, enable AVR ##
####################################################

tmsh modify sys provision avr level nominal

######################
## SET UP VARIABLES ##
######################

MGMT_IP='127.0.0.1' #this is because we will run this setup script on the BIG-IP itself.
EXT_SELF_IP='10.1.10.10'
EXT_VIP_IP1='10.1.10.11'
EXT_VIP_IP2='10.1.10.12'
INT_SELF_IP='10.1.20.10'
LINUX_VM_IP='10.1.20.20'
GW_IP='10.1.10.1'
TS_VERSION=v1.31.0
TS_FN=f5-telemetry-1.31.0-2.noarch.rpm
AS3_VERSION=v3.39.0
AS3_FN=f5-appsvcs-3.39.0-7.noarch.rpm
CREDS='admin:DefaultPass12345!'

#######################################################
## BIG-IP setup VLANs and Self IPs and Default Route ##
#######################################################

tmsh create /net vlan external interfaces add { 1.1 }
tmsh create /net vlan internal interfaces add { 1.2 }

tmsh create net self external_self address $EXT_SELF_IP/24 vlan external
tmsh create net self internal_self address $INT_SELF_IP/24 vlan internal

tmsh create net route default gw $GW_IP

tmsh save sys config

###############################
## BIG-IP setup TS AND AS3   ##
###############################

#TS
curl -LOJ https://github.com/F5Networks/f5-telemetry-streaming/releases/download/$TS_VERSION/$TS_FN --output $TS_FN

LEN=$(wc -c $TS_FN | cut -f 1 -d ' ')
curl -kvu $CREDS https://$MGMT_IP/mgmt/shared/file-transfer/uploads/$TS_FN -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((LEN - 1))/$LEN" -H "Content-Length: $LEN" -H 'Connection: keep-alive' --data-binary @$TS_FN

DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$TS_FN\"}"
curl -kvu $CREDS "https://$MGMT_IP/mgmt/shared/iapp/package-management-tasks" -H "Origin: https://$MGMT_IP" -H 'Content-Type: application/json;charset=UTF-8' --data $DATA

curl -u $CREDS -X POST http://$MGMT_IP/mgmt/shared/telemetry/declare -d @/tmp/ts-declaration.json -H 'Content-Type: application/json'

#AS3
curl -LOJ https://github.com/F5Networks/f5-appsvcs-extension/releases/download/$AS3_VERSION/$AS3_FN --output $AS3_FN

LEN=$(wc -c $AS3_FN | cut -f 1 -d ' ')
curl -kvu $CREDS https://$MGMT_IP/mgmt/shared/file-transfer/uploads/$AS3_FN -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((LEN - 1))/$LEN" -H "Content-Length: $LEN" -H 'Connection: keep-alive' --data-binary @$AS3_FN

DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$TS_FN\"}"
curl -kvu $CREDS "https://$MGMT_IP/mgmt/shared/iapp/package-management-tasks" -H "Origin: https://$MGMT_IP" -H 'Content-Type: application/json;charset=UTF-8' --data $DATA

############################
## BIG-IP setup AVR LOGGING#
############################

	######################################################################
	## THIS PART MUST BE DONE IN INTERACTIVE CLI MODE, NOT COPY/PASTED ###
	######################################################################

## Configure Event Listener
tmsh 
create ltm rule telemetry_local_rule

##now put this text in the editor and save:
when CLIENT_ACCEPTED {
    node 127.0.0.1 6514
}

## back to bash AND REMEMBER TO SAVE YOUR VARIABLES AGAIN!
bash

	######################################################################
	## FROM HERE ON CAN BE COPY/PASTED AGAIN                           ###
	######################################################################
	
tmsh create ltm virtual telemetry_local destination 255.255.255.254:6514 rules { telemetry_local_rule } profiles replace-all-with { f5-tcp-progressive } source-address-translation { type automap } persist replace-all-with { source_addr { default yes }}

tmsh create ltm pool telemetry monitor tcp members replace-all-with { 255.255.255.254:6514 }

# create unformatted log destination
tmsh create sys log-config destination remote-high-speed-log telemetry_hsl protocol tcp pool-name telemetry

# create formatted log destination
tmsh create sys log-config destination splunk telemetry_formatted forward-to telemetry_hsl 

# create log publisher
tmsh create sys log-config publisher telemetry_publisher destinations replace-all-with { telemetry_formatted  }

#Create HTTP Analytics logging profile which will attach to our demo app VIP's.
tmsh create ltm profile analytics telemetry-http-analytics { collect-geo enabled collect-http-timing-metrics enabled collect-ip enabled collect-max-tps-and-throughput enabled collect-methods enabled collect-page-load-time enabled collect-response-codes enabled collect-subnets enabled collect-url enabled collect-user-agent enabled collect-user-sessions enabled publish-irule-statistics enabled }

#Create TCP Analytics profile which we will attache to our demo app VIP's.
#tmsh create ltm profile tcp-analytics telemetry-tcp-analytics { collect-city enabled collect-continent enabled collect-country enabled collect-nexthop enabled collect-post-code enabled collect-region enabled collect-remote-host-ip enabled collect-remote-host-subnet enabled collected-by-server-side enabled }

#modify the AVR logging configuration to point to the existing Log Publisher to get global AVR stats sento offbox
#tmsh modify analytics global-settings { external-logging-publisher /Common/telemetry_publisher offbox-protocol hsl use-offbox enabled  }

######################################################################
## NOW SET UP VIRTUAL SERVERS FOR DEMO APPS                        ###
######################################################################

HTTP_PROFILE="/Common/telemetry-http-analytics"
#TCP_PROFILE="/Common/telemetry-tcp-analytics"

#HTTP_PROFILE="/Common/shared/telemetry_http_analytics_profile"
#TCP_PROFILE="/Common/shared/telemetry_tcp_analytics_profile"

tmsh create ltm pool demo_pool monitor tcp load-balancing-mode round-robin members add { ubuntu:81 { address $LINUX_VM_IP } }
tmsh create ltm virtual demo_vs { destination $EXT_VIP_IP1:80 persist replace-all-with {source_addr} pool demo_pool source-address-translation { type automap } profiles add { http $HTTP_PROFILE { context all } } }
tmsh create ltm virtual demo_vs_https { destination $EXT_VIP_IP1:443 persist replace-all-with {source_addr} pool demo_pool source-address-translation { type automap } profiles add { clientssl http $HTTP_PROFILE { context all } } }

tmsh create ltm pool demo2_pool monitor tcp load-balancing-mode round-robin members add { ubuntu:8081 { address $LINUX_VM_IP } }
tmsh create ltm virtual demo2_vs { destination $EXT_VIP_IP2:80 persist replace-all-with {source_addr} pool demo2_pool source-address-translation { type automap } profiles add { http $HTTP_PROFILE { context all } } }
tmsh create ltm virtual demo2_vs_https { destination $EXT_VIP_IP2:443 persist replace-all-with {source_addr} pool demo2_pool source-address-translation { type automap } profiles add { clientssl http $HTTP_PROFILE { context all } } }

tmsh save sys config


