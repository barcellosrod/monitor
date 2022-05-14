#!/bin/bash
echo "====================================================================="
echo "             CONFIGURACAO AMBIENTE MONITOR DE RECURSOS"
echo "====================================================================="

DIR_INSTALADOR=$(pwd)
DIR_WORK=~/fabric/fabric-samples/sharedchannel
ORG_NAME='org1'
ARQUIVO_ORGS=$DIR_INSTALADOR/orgs

ajusteVariaveisEDiretorios(){
	echo "Diretorio de trabalho:" $DIR_WORK
	if [ ! -d "$DIR_WORK" ] 
	then
		echo "Diretorio de trabalho nao existe"
		mkdir $DIR_WORK && cd $DIR_WORK
	else
		echo "Entrar no diretorio de trabalho"
		cd $DIR_WORK
		rm -R channel-artifacts
		rm -R crypto-config
		rm -R deployment
	fi
	echo "==============================================="
	echo "Definicao de variaveis de ambiente"
	echo "==============================================="
	export PATH=$PATH:${PWD}/../bin:${PWD}

	echo "==============================================="
	echo "Criacao do diretorio de artefatos"
	echo "==============================================="
	if ! mkdir channel-artifacts
	then
		echo "Erro ao criar o diretorio de artefatos"
		exit 1
	fi

	echo "==============================================="
	echo "Criacao do diretorio de material criptografico"
	echo "==============================================="
	if ! mkdir crypto-config
	then
		echo "Erro ao criar o diretorio de materia criptografico"
		exit 1
	fi

	echo "==============================================="
	echo "Criacao do diretorio de deployment"
	echo "==============================================="
	if ! mkdir deployment
	then
			echo "Erro ao criar o diretorio de deployment"
			exit 1
	fi

	echo "==============================================="
	echo "Copia arquivos para diretorio de instalacao"
	echo "==============================================="
	cd $DIR_INSTALADOR
	cp crypto-config.yaml $DIR_WORK
	cp configtx.yaml $DIR_WORK
	cp deployment/* $DIR_WORK/deployment/
}

criacaoMateriaCriptografico(){
	echo "==============================================="
	echo "Criacao do materia criptografico"
	echo "==============================================="
	cd $DIR_WORK
	if ! ../bin/cryptogen generate --config=crypto-config.yaml
	then
		echo "Erro na criacao do material criptografico"
		exit 1
	fi
}

criacaoBlocoGenesis(){
	echo "==============================================="
	echo "Criacao do bloco genesis"
	echo "==============================================="
	if ! ../bin/configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/channelall.block -channelID genesischannel
	then
			echo "Erro na criacao do bloco genesis"
			exit 1
	fi
}

configuracaoCanal(){
	echo "==============================================="
	echo "Configuracao das transacoes para o canal criado"
	echo "==============================================="
	if ! ../bin/configtxgen -profile ChannelAll -outputCreateChannelTx ./channel-artifacts/channelall.tx -channelID channelall
	then
			echo "Erro na configuracao da transacao para o canal"
			exit 1
	fi
}

compactarDiretorioTrabalho(){
	echo "==================================================="
	echo "Subir nivel e compactar diretorio para distribuicao"
	echo "==================================================="
	cd ..
	if ! tar cf sharedchannel.tar sharedchannel/
	then
			echo "Erro na compactacao do diretorio de trabalho"
		exit 1
	fi
}

alterarPropriedadesPastasArquivos(){
	echo "==================================================="
	echo "Alteracao das propriedades da pasta"
	echo "==================================================="

	if ! chown -R ubuntu sharedchannel
	then
			echo "Erro na definição do dono do diretorio de trabalho"
			exit 1
	fi

	echo "==================================================="
	echo "Alteracao das propriedades da pasta"
	echo "==================================================="

	if ! chgrp -R ubuntu sharedchannel
	then
			echo "Erro na definicao do grupo do diretorio de trabalho"
			exit 1
	fi

	echo "==================================================="
	echo "Alterar proprietario do arquivo"
	echo "==================================================="
	if ! chown ubuntu sharedchannel.tar
	then
			echo "Erro na alteracao do proprietario do arquivo"
			exit 1
	fi

	echo "==================================================="
	echo "Alterar grupo do arquivo"
	echo "==================================================="
	if ! chgrp ubuntu sharedchannel.tar
	then
			echo "Erro na alteracao do grupo do arquivo"
			exit 1
	fi

	echo "==================================================="
	echo "Alterar propriedades de acesso do arquivo"
	echo "==================================================="
	if ! chmod 777 sharedchannel.tar
	then
			echo "Erro na alteracao do acesso ao arquivo"
			exit 1
	fi
}

moverAmbienteParaVms(){
	echo "===================================================="
	echo "Movendo ambiente para outras vms"
	echo "===================================================="
	cd $DIR_WORK
	cd ..
	while IFS='=' read -r ORG IP
	do	
		echo "================================================================"
		echo "Levantando ambiente para equipamento" $ORG
		echo "================================================================"
		echo "Derrubando instancias ativas" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "cd ~/fabric/fabric-samples/sharedchannel/deployment; docker-compose -f docker-compose-\$(hostname).yml down; sleep 1; docker volume prune -f; docker rm \$(docker ps -aq); docker rmi \$(docker images net-* -q)"
		if [ $ORG != $ORG_NAME ]
		then	    
			echo "Removendo diretorios de trabalhos remotos" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "cd ~/fabric/fabric-samples/; sudo rm -R sharedchannel;"
			echo "Copiando diretorio compactado para "$IP
			cd ~/fabric/fabric-samples/
			cat sharedchannel.tar | ssh -i ~/.ssh/id_rsa ubuntu@$IP "cd ~/fabric/fabric-samples/; sudo tar xf -"
			sleep 1	
		fi
		echo "Levantando nodo" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "cd ~/fabric/fabric-samples/sharedchannel/deployment; docker-compose -f docker-compose-\$(hostname).yml up -d"
		
	done < "$ARQUIVO_ORGS"
}

criarCanal(){
	echo "===================================================="
	echo "Criar canal de comunicacao"
	echo "===================================================="
	docker exec -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG_NAME.example.com/msp" peer0.$ORG_NAME.example.com peer channel create -o orderer.example.com:7050 -c channelall -f /var/hyperledger/configs/channelall.tx
}

usufruirCanal(){
	echo "===================================================="
	echo "Usufruir canal de comunicacao"
	echo "===================================================="
	docker exec -e "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG_NAME.example.com/msp" peer0.$ORG_NAME.example.com peer channel join -b channelall.block
}

copiarCanalParaDocker(){
	cd $DIR_WORK/deployment
	echo "===================================================="
	echo "Copiar o canal para distribuicao do inteior do docker"
	echo "===================================================="
	docker cp peer0.$ORG_NAME.example.com:channelall.block .
}

movimentarCanaisParaOrgs(){
	echo "===================================================="
	echo "Realizacao de Join nos canais pelas orgs"
	echo "===================================================="
	while IFS='=' read -r ORG IP
	do
		if [ $ORG != $ORG_NAME ] && [ $ORG  != 'orderer' ]
		then	
			echo "================================================================"
			echo "Join Canal" $ORG
			echo "================================================================"
			echo "Ajustando permissoes diretorios" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "sudo chgrp ubuntu -R /home/ubuntu/fabric/fabric-samples/sharedchannel; sudo chown ubuntu -R /home/ubuntu/fabric/fabric-samples/sharedchannel;"
			scp -i ~/.ssh/id_rsa channelall.block ubuntu@$IP:$DIR_WORK/deployment
			echo "Copiando para o interior do docker" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "cd ~/fabric/fabric-samples/sharedchannel/deployment; docker cp channelall.block peer0.$ORG.example.com:/channelall.block"
			echo "Join Canal" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer channel join -b channelall.block"
		fi
	done < "$ARQUIVO_ORGS"
}

ajusteDependenciasEVariaveisPeers(){
	COUNTER=1
	echo "===================================================="
	echo "Ajuste de dependencias e Variaveis de Ambiente"
	echo "===================================================="
	while IFS='=' read -r ORG IP
	do
			if [ $ORG  != 'orderer' ]
			then
				echo "================================================================"
				echo "Instalando Dependencias" $ORG
				echo "================================================================"
				ORGMSP=Org$COUNTER
				ORGMSP+=MSP
				echo "Install shim" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "sudo $DIR_INSTALADOR/mtu.sh; docker exec -e CORE_PEER_LOCALMSPID=$ORGMSP -e CORE_PEER_ADDRESS=peer0.$ORG.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG.example.com/users/Admin@$ORG.example.com/msp cli go get github.com/hyperledger/fabric-chaincode-go/shim"

				echo "================================================================"
				echo "Setando variáveis de ambiente" $ORG
				echo "================================================================"
				echo "Setar" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "sed -i 's/{NUM_NODO}/$COUNTER/g' /home/ubuntu/.bashrc; source /home/ubuntu/.bashrc"

				echo "===================================================="
				echo "Exibicao do canal no" $ORG
				echo "===================================================="
				echo "Exibir Canal" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "/home/ubuntu/fabric/fabric-samples/bin/peer channel list >&/home/ubuntu/pacote_configurador/log.txt"
				echo "Incremento de Organizacao: $ORGMSP"
				((COUNTER++))
			fi
	done < "$ARQUIVO_ORGS"
}

instalacaoAnchorPeers(){
	declare -x CORE_PEER_ADDRESS=localhost:7051
 	declare -x PEER0_ORG1_CA=~/fabric/fabric-samples/sharedchannel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
	declare -x CORE_PEER_LOCALMSPID=Org1MSP
	declare -x CORE_PEER_TLS_ROOTCERT_FILE=~/fabric/fabric-samples/sharedchannel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
	declare -x CORE_PEER_MSPCONFIGPATH=~/fabric/fabric-samples/sharedchannel/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
	declare -x FABRIC_CFG_PATH=~/fabric/fabric-samples/config
	declare -x PATH=$PATH:/usr/local/go/bin:/usr/local/go:~/fabric/fabric-samples/bin

	COUNTER=1
	echo "===================================================="
	echo "Instalacao AncherPeers"
	echo "===================================================="
#	while IFS='=' read -r ORG IP
#	do
#		if [ $ORG  != 'orderer' ]
#		then
		#	echo "Install shim" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer channel fetch config config_block.pb -o orderer.example.com:7050 -c channelall;
		#	docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json;"
		#	jq '.channel_group.groups.Application.groups.Org${COUNTER}MSP.values += {\"AnchorPeers\":{\"mod_policy\": \"Admins\",\"value\":{\"anchor_peers\":[{\"host\": \"peer0.org${COUNTER}.example.com\",\"port\": 11051}]},\"versio\":\"0\"}}' config.json > modified_anchor_config.json;
		#	configtxlator proto_encode --input config.json --type common.Config --output config.pb;
		#	configtxlator proto_encode --input modified_anchor_config.json --type common.Config --output modified_anchor_config.pb;
		#	configtxlator compute_update --channel_id channelall --original config.pb --updated modified_anchor_config.pb --output anchor_update.pb;
		#	configtxlator proto_decode --input anchor_update.pb --type common.ConfigUpdate | jq . > anchor_update.json;
		#	echo '{"payload":{"header":{"channel_header":{"channel_id":"channelall", "type":2}},"data":{"config_update":'$(cat anchor_update.json)'}}}' | jq . > anchor_update_in_envelope.json;
		#	configtxlator proto_encode --input anchor_update_in_envelope.json --type common.Envelope --output anchor_update_in_envelope.pb"
		#	((COUNTER++))
#		fi
#	done < "$ARQUIVO_ORGS"

}

instalacaoChaincode(){
	echo "===================================================="
	echo "Instalacao chaincode"
	echo "===================================================="
	while IFS='=' read -r ORG IP
	do
		if [ $ORG  != 'orderer' ]
		then	
			echo "===================================================="
			echo "Instalacao do chaincode no" $ORG
			echo "===================================================="			
			echo "Instalar chaicode" |  ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker cp /home/ubuntu/pacote_configurador/monitor.tar.gz peer0.$ORG.example.com:monitor.tar.gz; docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode install monitor.tar.gz;"
			#echo "Instalar chaicode" |  ssh -i ~/.ssh/id_rsa ubuntu@$IP "export FABRIC_CFG_PATH=/home/ubuntu/fabric/fabric-samples/config;/home/ubuntu/fabric/fabric-samples/bin/peer lifecycle chaincode install /home/ubuntu/pacote_configurador/monitor.tar.gz;"
		fi
	done < "$ARQUIVO_ORGS"
}

pesquisaChaincode(){
	echo "===================================================="
	echo "Query chaincode"
	echo "===================================================="
	while IFS='=' read -r ORG IP
	do
		if [ $ORG  != 'orderer' ]
		then	
			echo "===================================================="
			echo "Query e approve do chaincode no" $ORG
			echo "===================================================="
			echo "Query chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode queryinstalled ; docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode approveformyorg -o 192.169.0.9:7050 --channelID channelall --name monitor --version 1 --init-required --package-id monitor_1.0:cc3d2282d825a1b2d8cf7bcc8928ca88fa5045c08e3c55c9a74b40e7ff9f01dd --sequence 1 >&/home/ubuntu/pacote_configurador/log.txt"
			#echo "Query chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode queryinstalled >&/home/ubuntu/pacote_configurador/log.txt;" # PACKAGE_ID=monitor_1.0:cc3d2282d825a1b2d8cf7bcc8928ca88fa5045c08e3c55c9a74b40e7ff9f01dd; docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode approveformyorg -o 192.169.0.9:7050 --channelID channelall --name monitor --version 1 --init-required --package-id monitor_1.0:cc3d2282d825a1b2d8cf7bcc8928ca88fa5045c08e3c55c9a74b40e7ff9f01dd --sequence 1"
			#echo "Query chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "/home/ubuntu/fabric/fabric-samples/bin/peer lifecycle chaincode queryinstalled >&/home/ubuntu/pacote_configurador/log.txt; PACKAGE_ID=$(sed -n /"${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" /home/ubuntu/pacote_configurador/log.txt); echo PackageID is ${PACKAGE_ID} >> /home/ubuntu/pacote_configurador/log.txt; docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode approveformyorg -o 192.169.0.9:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION}"
		fi
	done < "$ARQUIVO_ORGS"
}

checagemChaincode(){
	echo "===================================================="
	echo "Checkcommitreadiness chaincode"
	echo "===================================================="
	while IFS='=' read -r ORG IP
	do
		if [ $ORG  != 'orderer' ]
		then	
			echo "===================================================="
			echo "Checkcommitreadiness chaincode no " $ORG
			echo "===================================================="
			echo "Checkcommitreadiness chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@$ORG.example.com/msp\" peer0.$ORG.example.com peer lifecycle chaincode checkcommitreadiness --channelID channelall --name monitor --version 1 --sequence 1 --init-required NA NA --output json" #>&log.txt"
			#echo "Checkcommitreadiness chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --init-required ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt"
		fi
	done < "$ARQUIVO_ORGS"
}

commitChaincode(){
	echo "===================================================="
	echo "Commit chaincode"
	echo "===================================================="
	while IFS='=' read -r ORG IP
	do
		if [ $ORG  != 'orderer' ]
		then	
			echo "===================================================="
			echo "Commit chaincode no " $ORG
			echo "===================================================="
			echo "Commit chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer lifecycle chaincode commit -o 192.169.0.9:7050 --channelID channelall --name monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051  --version 1 --sequence 1 --init-required  NA NA"
			break
			#docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer lifecycle chaincode commit -o 192.169.0.9:7050 --channelID channelall --name monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051  --version 1 --sequence 1 --init-required  NA NA #>&/home/ubuntu/pacote_configurador/log.txt;"
			#echo "Commit chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@$IP "peer lifecycle chaincode commit -o 192.169.0.9:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051  --version ${VERSION} --sequence ${VERSION} --init-required  ${CC_END_POLICY} ${CC_COLL_CONFIG} >&/home/ubuntu/pacote_configurador/log.txt;"
		fi
	done < "$ARQUIVO_ORGS"
}

initChaincode(){
	echo "===================================================="
	echo "Inicialização do chaincode"
	echo "===================================================="
	echo "Inicializacao chaicode" | ssh -i ~/.ssh/id_rsa ubuntu@10.20.20.71 "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 --isInit -c '{\"Args\": [\"node1\", \"{CPU:70,MEM:55,STG:15.5,DAT:0001-01-01T00:00:00Z}\"]}'"
	sleep 3
	#docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 --isInit -c '{"Args": ["node1", "{\"CPU\":70,\"MEM\":55,\"STG\":15.5,\"DAT\":\"0001-01-01T00:00:00Z\"}"]}' 
	# >&init.txt
	#peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 --isInit -c '{"Args": ["node1", "{\"CPU\":70,\"MEM\":55,\"STG\":15.5,\"DAT\":\"0001-01-01T00:00:00Z\"}"]}' >&init.txt
	#cat init.txt
}

testesChaincode(){
	echo "===================================================="
	echo "Testando comandos nodo1"
	echo "===================================================="
	#Obter Equipamentos
	echo "Obter equipamento"
	echo "Obter equipamento" | ssh -i ~/.ssh/id_rsa ubuntu@10.20.20.71 "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{\"Args\":[\"obterEquipamentosDados\", \"CPU\",\"0\",\"99\"]}'"
	#peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{"Args":["obterEquipamentosDados", "CPU","0","99"]}' >&log.txt
	#cat log.txt
	#Obter Dados Equipamento
	echo "Obter dados equipamento"
	echo "Obter dados equipamento" | ssh -i ~/.ssh/id_rsa ubuntu@10.20.20.71 "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{\"Args\":[\"obterDadosMonitoradosEquip\", \"node1\"]}'"
	#peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{"Args":["obterDadosMonitoradosEquip", "node1"]}' >&log.txt
	#cat log.txt
	#Obter Dados Totais
	echo "Obter dados totais"
	echo "Obter dados totais" | ssh -i ~/.ssh/id_rsa ubuntu@10.20.20.71 "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{\"Args\":[\"obterDadosMonitoradosTotais\"]}'"
	#peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{"Args":["obterDadosMonitoradosTotais"]}' >&log.txt
	#cat log.txt
	#Obter Ultimos Estados Equipamento
	echo "Obter ultimos estados equipamento"
	echo "Obter ultimos estados equipamento" | ssh -i ~/.ssh/id_rsa ubuntu@10.20.20.71 "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{\"Args\":[\"obterUltimosEstadosEquip\", \"node1\"]}'"
	#peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{"Args":["obterUltimosEstadosEquip", "node1"]}' >&log.txt
	#cat log.txt
	#Set valores
	echo "Set valores"
	echo "Set valores" | ssh -i ~/.ssh/id_rsa ubuntu@10.20.20.71 "docker exec -e \"CORE_PEER_MSPCONFIGPATH=/var/hyperledger/users/Admin@org1.example.com/msp\" peer0.org1.example.com peer chaincode invoke -o 192.169.0.9:7050 -C channelall -n monitor --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{\"Args\":[\"set\",\"node3\", \"{CPU:50,MEM:50,STG:50.0,DAT:2020-11-17T00:10:00Z}\"]}'"
	#peer chaincode invoke -o 192.169.0.9:7050 -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --peerAddresses peer0.org3.example.com:7051 -c '{"Args":["set","node3", "{\"CPU\":50,\"MEM\":50,\"STG\":50.0,\"DAT\":\"2020-11-17T00:10:00Z\"}"]}'  >&log.txt
	#cat log.txt
}

ajusteVariaveisEDiretorios
criacaoMateriaCriptografico
criacaoBlocoGenesis
configuracaoCanal
compactarDiretorioTrabalho
alterarPropriedadesPastasArquivos
moverAmbienteParaVms
criarCanal
usufruirCanal
copiarCanalParaDocker
movimentarCanaisParaOrgs
ajusteDependenciasEVariaveisPeers
instalacaoChaincode
pesquisaChaincode
checagemChaincode
commitChaincode
initChaincode
testesChaincode
#instalacaoAnchorPeers
