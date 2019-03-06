#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Hyperledger-Fabric automatic end-to-end demo"
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="demochannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME
echo
# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	    done
	done

	#joinChannelWithRetry 1 7
}

## Create channel
printf "\E[0;33;m"
echo "Creating channel..."
printf "\E[0m"
createChannel

## Join all the peers to the channel
printf "\E[0;33;40m"
echo "Having all peers join the channel..."
printf "\E[0m"

joinChannel

## Set the anchor peers for each org in the channel
printf "\E[0;33;40m"
echo "Updating anchor peers for org1..."
printf "\E[0m"
updateAnchorPeers 0 1
printf "\E[0;33;40m"
echo "Updating anchor peers for org2..."
printf "\E[0m"
updateAnchorPeers 0 2

## Install chaincode on peer0.org1 and peer0.org2
printf "\E[0;33;40m"
echo "Installing chaincode on peer0.org1..."
printf "\E[0m"
installChaincode 0 1
printf "\E[0;33;40m"
echo "Install chaincode on peer0.org2..."
printf "\E[0m"
installChaincode 0 2

# Instantiate chaincode on peer0.org2
printf "\E[0;33;40m"
echo "Instantiating chaincode on peer0.org2..."
printf "\E[0m"

instantiateChaincode 0 2

# Query chaincode on peer0.org1
printf "\E[0;33;40m"
echo "Querying chaincode on peer0.org1..."
printf "\E[0m"
chaincodeQuery 0 1 100

# Invoke chaincode on peer0.org1
printf "\E[0;33;40m"
echo "Sending invoke transaction on peer0.org1..."
printf "\E[0m"
chaincodeInvoke 0 1

# Query on chaincode on peer0.org1, check if the result is 210
printf "\E[0;33;40m"
echo "Quarying B on peer0.org1..."
printf "\E[0m"
chaincodeQueryB 0 1 210


## Install chaincode on peer1.org2
printf "\E[0;33;40m"
echo "Installing chaincode on peer1.org2..."
printf "\E[0m"
installChaincode 1 2


# Query on chaincode on peer1.org2, check if the result is 90
printf "\E[0;33;40m"
echo "Querying chaincode on peer1.org2..."
printf "\E[0m"
chaincodeQuery 1 2 90

# Invoke chaincode on peer1.org2
printf "\E[0;33;40m"
echo "Sending invoke transaction on peer1.org2..."
printf "\E[0m"
chaincodeInvoke 1 2 

# Query on chaincode on peer0.org1, check if the result is 80
printf "\E[0;33;40m"
echo "Querying chaincode on peer0.org1..." 
printf "\E[0m"

chaincodeQuery 0 1 80

echo
echo "========= All GOOD, Hyperledger-Fabric Automatic execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
