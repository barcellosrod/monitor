#!/bin/bash

iniciarInstalacao(){
	echo "Instalacao ambiente hyperledger fabric"
}
updateSources() {
	if ! apt update
	then
		echo "Nao foi possivel atualizar os repositorios"
		exit 1
	fi
	echo "Fontes atualizados com sucesso"
}

instalacaoCurl(){
	echo "Instalacao do Curl"
	if ! apt install curl -y
	then 
		echo "Nao foi possivel instalar o Curl"
		exit 1
	fi
	echo "Curl instalado com sucesso!"
}

instalacaoDeps(){
	echo "Instalacao do GCC Make e Wget"
	if ! apt install python gcc make wget g++ -y
	then 
		echo "Nao foi possivel instalar o python gcc make e wget"
		exit 1
	fi
	echo "Python Gcc Make e Wget instalados com sucesso!"
}

removeOldDocker(){
	echo "Remocao de versoes antigas do docker"
	if ! apt remove docker docker-engine docker.io containerd runc
	then 
		echo "Nao foi possivel remover versoes antigas do docker"
		exit 1
	fi
	echo "Docker removido com sucesso!"
}

instalacaoHttps(){
	echo "Instalacao de pacotes para permitir o uso de repositorio sobre HTTPS"
	if ! apt install \
			apt-transport-https \
			ca-certificates \
		curl \
			gnupg-agent \
			software-properties-common -y
	then 
		echo "Nao foi possivel instalar pacotes para HTTPS"
		exit 1
	fi
	echo "Pacotes para repositorio HTTPS instalados com sucesso!"
}

adicaoChaveDocker(){
	echo "Adicao de chave oficial GPG Docker"
	if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	then 
		echo "Erro na instalacao da chave oficial Docker"
		exit 1
	fi
	echo "Chave oficial docker GPG adicionada com sucesso!"
}

validacaoChaveDocker(){
	echo "Validacao da chave oficial Docker instalada"
	if ! apt-key fingerprint 0EBFCD88
	then 
		echo "Erro na validacao da chave docker"
		exit 1
	fi
	echo "Chave oficial docker validada com sucesso!"
}

adicaoReposDocker(){
	echo "Adicionar repositorio Docker"
	if ! add-apt-repository \
		"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
	then 
		echo "Erro na adicao do repositorio docker"
		exit 1
	fi
	echo "Repositorio Docker adicionado com sucesso!"
}

updateRepositorios(){
	echo "Atualizar repositorios!"
	if ! apt update
	then
		echo "Nao foi possivel atualizar os repositorios"
		exit 1
	fi
	echo "Repositorios atualizados com sucesso!"
}

instalacaoDocker(){
	echo "Instalar Docker!"
	if ! apt install docker-ce docker-ce-cli containerd.io -y
	then
		echo "Nao foi possivel instalar o Docker"
		exit 1
	fi
	echo "Docker instalado com sucesso!"
}

instalacaoDockerCompose(){
	echo "Instalar Docker-compose"
	if ! curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	then
		echo "Nao foi possivel instalar o Docker-Compose"
		exit 1
	fi
	echo "Docker-compose instalado com sucesso!"
}

alterarPropsDockerCompose(){
	echo "Alterar propriedades do arquivo docker-compose"
	if ! chmod +x /usr/local/bin/docker-compose
	then
		echo "Nao foi possivel alterar as propriedades do arquivo Docker-Compose"
		exit 1
	fi
	echo "Propriedades Docker-compose alteradas com sucesso!"
}

iniciarDocker(){
	echo "Iniciar Docker"
	if ! systemctl start docker
	then
		echo "Nao foi possivel iniciar o docker"
		exit 1
	fi
	echo "Docker iniciado com sucesso!"
}

adicionarUserGrupoDocker(){
	echo "Adicionar usuario atual ao grupo docker"
	if ! usermod -aG docker ubuntu
	then
		echo "Nao foi possivel adicionar o usuario padrao ao grupo docker"
		exit 1
	fi
	echo "Usuario padrao adicionado ao grupi docker com sucesso!"
}

instalarGolang(){
	echo "Baixar linguagem GO"
	cd ~/Downloads
	if ! wget https://dl.google.com/go/go1.15.7.linux-amd64.tar.gz
	then
		echo "Nao foi possivel baixar a linguagem golang"
		exit 1
	fi
	echo "Linguagem golang baixada com sucesso!"
	echo "Instalar linguagem GO"
	if ! tar -C /usr/local -xzf go1.15.7.linux-amd64.tar.gz
	then
		echo "Nao foi possivel instalar a linguagem golang"
		exit 1
	fi
	echo "Linguagem golang instalada com sucesso!"
	echo "Variaveis de ambiente linguagem GO"
	echo "#Variaveis de ambiente linguagem golang" >> ~/.bashrc
	echo "export GOPATH=/usr/local/go/bin" >> ~/.bashrc
	echo "export GOROOT=/usr/local/go" >> ~/.bashrc
	source ~/.bashrc
	echo "Variaveis de ambiente golang configuradas com sucesso!"
}

instalarNodeJs(){
	echo "Baixar nodejs"
	if ! curl -fsSL https://deb.nodesource.com/setup_10.x | sudo -E bash -
	then
		echo "Nao foi possivel baixar o nodejs"
		exit 1
	fi
	if ! apt install -y nodejs
	then
		echo "Erro instalação Nodejs"
		exit 1
	fi
	echo "Nodejs instalado com sucesso!"
}

instalarNpm(){
	echo "Instalar Npm"
	if ! apt install npm -y
	then
		echo "Nao foi possivel instalar o npm"
		exit 1
	fi
	if !npm install -g npm
	then	
		echo "Erro ao atualizar o npm"
		exit 1
	fi
	echo "Npm instalado com sucesso!"
}

instalarNodeGyp(){
	export OLDPWD="/usr/lib/node_modules/npm/bin"
	if ! npm install -g node-gyp -y
	then
		echo "Erro instalação node-gyp"
		exit 1
	fi
	echo "Node-gyp instalado com sucesso!"
}

versaoPython(){
	echo "Versao python"
	python --version
}

installJQ(){
	echo "Instalação JQ"
	if ! apt install jq -y
	then
		echo "Nao foi possivel instalar o jq"
		exit 1
	fi
}

instalacaoHyperledger(){
	echo "Instalar imagens docker hyperledger"
	echo "Criar diretorio de instalacao"
	mkdir ~/fabric
	cd ~/fabric
	if ! curl -sSL http://bit.ly/2ysbOFE | bash -s 2.3.0
	then
		echo "Nao foi possivel baixar as imagens hyperledger"
		exit 1
	fi
	echo "Hyperledger instalado com sucesso!"
	echo "Ajustar permissões e propriedades do diretorio Hyperledger Fabric"
	cd ~
	if ! chown -R ubuntu fabric 
	then
			echo "Nao foi possivel ajustar o proprietario de fabric para ubuntu"
		exit 1
	fi

	if ! chgrp -R ubuntu fabric 
	then
			echo "Nao foi possivel ajustar o grupo de fabric para ubuntu"
		exit 1
	fi
	if ! chmod -R 755 fabric 
	then
			echo "Nao foi possivel ajustar o grupo de fabric para ubuntu"
		exit 1
	fi
	echo "Propriedades ajustadas com sucesso!"
}

prepararChaincode(){
	echo "Criar diretorio de armazenamento do chaincode"
	mkdir ~/fabric/fabric-samples/chaincode/monitor
	if ! cp ~/pacote_configurador/monitor.go ~/fabric/fabric-samples/chaincode/monitor/
	then
			echo "Nao foi possivel mover o chaincode para o diretorio destino"
		exit 1
	fi
	echo "Chaincode movido com sucesso!"
}

instalacaoCaliper(){
	echo "Instalacao Caliper"
	cd ~
	mkdir caliper 
	cd caliper
	git clone https://github.com/hyperledger/caliper/
	git clone https://github.com/hyperledger/caliper-benchmarks
	chown -R ubuntu caliper
	chgrp -R ubuntu caliper
	chown -R ubuntu node_modules
	chgrp -R ubuntu node_modules
	npm init -y
	cd /home/ubuntu/caliper/caliper-benchmarks
	cp -R /home/ubuntu/pacote_configurador/caliper-monitor .
	chown -R ubuntu caliper-monitor
	chgrp -R ubuntu caliper-monitor
	cd caliper-monitor
	chmod 755 *.sh
}

instalacaoVariaveisAmbiente(){
	echo "#Variaveis de ambiente hyperledger" >> ~/.bashrc
	echo "Declaração de variaveis globais HLF"
	echo "declare -x CHANNEL_NAME=channelall"  >> ~/.bashrc
	echo "declare -x VERSION=1"  >> ~/.bashrc
	echo "declare -x CC_NAME=monitor"  >> ~/.bashrc
	echo "declare -x FABRIC_CFG_PATH=~/fabric/fabric-samples/config"  >> ~/.bashrc
	echo "declare -x PATH=$PATH:/usr/local/go/bin:/usr/local/go:~/fabric/fabric-samples/bin"  >> ~/.bashrc
	echo "declare -x CORE_PEER_ADDRESS=localhost:7051"  >> ~/.bashrc
	echo "declare -x PEER0_ORG{NUM_NODO}_CA=~/fabric/fabric-samples/sharedchannel/crypto-config/peerOrganizations/org{NUM_NODO}.example.com/peers/peer0.org{NUM_NODO}.example.com/tls/ca.crt"  >> ~/.bashrc
	echo "declare -x CORE_PEER_LOCALMSPID=Org{NUM_NODO}MSP"  >> ~/.bashrc
	echo "declare -x CORE_PEER_TLS_ROOTCERT_FILE=~/fabric/fabric-samples/sharedchannel/crypto-config/peerOrganizations/org{NUM_NODO}.example.com/peers/peer0.org{NUM_NODO}.example.com/tls/ca.crt"  >> ~/.bashrc
	echo "declare -x CORE_PEER_MSPCONFIGPATH=~/fabric/fabric-samples/sharedchannel/crypto-config/peerOrganizations/org{NUM_NODO}.example.com/users/Admin@org{NUM_NODO}.example.com/msp"  >> ~/.bashrc
	# endorsement policy defaults to "NA". This would allow chaincodes to use the majority default policy.
	echo "declare -x CC_END_POLICY=NA"  >> ~/.bashrc
	# collection configuration defaults to "NA"
	echo "declare -x CC_COLL_CONFIG=NA"  >> ~/.bashrc
	source ~/.bashrc
	echo "Variaveis de ambiente hyperledger configuradas com sucesso!"
}

reiniciarAmbiente(){
	echo "Reiniciando ambiente"
	for i in 5 4 3 2 1 ; do sleep 1 echo $i; done
	shutdown -r now
}

echo "============================================================================="
iniciarInstalacao
echo "============================================================================="
updateSources
echo "============================================================================="
instalacaoCurl
echo "============================================================================="
instalacaoDeps
echo "============================================================================="
removeOldDocker
echo "============================================================================="
instalacaoHttps
echo "============================================================================="
adicaoChaveDocker
echo "============================================================================="
validacaoChaveDocker
echo "============================================================================="
adicaoReposDocker
echo "============================================================================="
updateRepositorios
echo "============================================================================="
instalacaoDocker
echo "============================================================================="
instalacaoDockerCompose
echo "============================================================================="
alterarPropsDockerCompose
echo "============================================================================="
iniciarDocker
echo "============================================================================="
adicionarUserGrupoDocker
echo "============================================================================="
instalarGolang
echo "============================================================================="
instalarNodeJs
echo "============================================================================="
#instalarNpm
echo "============================================================================="
instalarNodeGyp
echo "============================================================================="
versaoPython
echo "============================================================================="
installJQ
echo "============================================================================="
instalacaoHyperledger
echo "============================================================================="
prepararChaincode
echo "============================================================================="
instalacaoCaliper
echo "============================================================================="
instalacaoVariaveisAmbiente
echo "============================================================================="
reiniciarAmbiente


