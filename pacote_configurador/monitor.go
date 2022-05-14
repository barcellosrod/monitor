package main
// Dependencias
import (
	"fmt"
    "time"
	"bytes"
	"sort"
	"encoding/json"
	"strconv"
	"strings"
	"github.com/hyperledger/fabric-chaincode-go/shim"
    pb "github.com/hyperledger/fabric-protos-go/peer"
)
//Formato da estrutura que armazena os dados de desempenho
type Nodo struct {
	Cpu int `json:"CPU"`
	Mem int `json:"MEM"`
	Stg float64 `json:"STG"`
	Dat time.Time `json:"DAT"`
}

type EstruturaOrdenacao []Nodo

//Monitor implements a simple chaincode to manage an asset
type Monitor struct {
}
// Funcao de inicializacao do chaincode
func (t *Monitor) Init(stub shim.ChaincodeStubInterface) pb.Response {
	// Obtem os argumentos da transacao
	args := stub.GetStringArgs()
	if len(args) != 2 {
		return shim.Error("Argumentos incorretos, aguardando um par chave e valor")
	}
	// Armazenar o par chave valor no ledger
	err := stub.PutState(args[0], []byte(args[1]))
	if err != nil {
		return shim.Error(fmt.Sprintf("Falhou ao criar o nodo: %s", args[0]))
	}
	return shim.Success(nil)
}
// Cria um novo indicador de performance para o nodo, baseado no par chave e valor.
func (t *Monitor) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	// Extrai a funcao e os argumentos
	fn, args := stub.GetFunctionAndParameters()
	var result string
	var err error
 	if fn == "set" {
		result, err = set(stub, args)
	} else if fn == "obterDadosMonitoradosEquip" {
		result, err = obterDadosMonitoradosEquip(stub, args)
	} else if fn == "obterDadosMonitoradosTotais" {
		result, err = obterDadosMonitoradosTotais(stub)
	} else if fn == "obterEquipamentosDados" {
                result, err = obterEquipamentosDados(stub,args)
        } else if fn == "obterUltimosEstadosEquip" {
		result, err = obterUltimosEstadosEquip(stub,args)
	}

	if err != nil {
		return shim.Error(err.Error())
	}
	// Retorna o resultado
	return shim.Success([]byte(result))
}
// Armazena a identificacao do nodo e o respectivo desempenho, se o mesmo existir.
// Se ja existir, sobreescreve 
func set(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("Argumentos incorretos. Aguardando identificacao do nodo e valor")
	}
	var dataCorrente = time.Now().UTC().Format(("2006-01-02T15:04:05.000Z"))
	var retorno = strings.Replace(args[1], "???", dataCorrente, -1)
	err := stub.PutState(args[0], []byte(retorno))
	if err != nil {
		return "", fmt.Errorf("Falhou ao setar o desempenho: %s", args[0])
	}
	return retorno, nil
}

// Funcao responsavel pela recuperacao dos dados de desempenho de todos os nodos da rede.
func obterDadosMonitoradosTotais(APIstub shim.ChaincodeStubInterface) (string, error) {
	chavesTotais, err := APIstub.GetStateByRange("","")
	if err != nil {
		return "", fmt.Errorf("Operacao para busca de chaves falhou. Erro accessando estado: %s", err)
	}

	defer chavesTotais.Close()
	var jsonRetorno string
	for chavesTotais.HasNext() {
		objeto, err := chavesTotais.Next()
		if err != nil {
			return "", fmt.Errorf("Iteracoes de chaves falhou. Erro acessando estado: %s", err)
		}
		jsonRetorno +=  "{\"" + objeto.Key + "\":" + string(objeto.Value) + "}"
	}

	return jsonRetorno,nil
}

// Funcao responsavel pela recuperacao dos dados de desempenho de um nodo especifico da rede.
func obterDadosMonitoradosEquip(APIstub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 1 {
                return "", fmt.Errorf("Argumentos incorretos. Aguardando a identificacao do nodo")
        }
        value, err := APIstub.GetState(args[0])
        if err != nil {
                return "", fmt.Errorf("Falha ao obter o nodo: %s with error: %s", args[0], err)
        }
        if value == nil {
                return "", fmt.Errorf("Nodo nÃ£o encontrado: %s", args[0])
        }
        return string(value), nil
}

// Funcao responsavel pela recuperacao dos equipamentos de acordo com os dados repassados.
func obterEquipamentosDados(APIstub shim.ChaincodeStubInterface, args []string) (string, error) {
	//Valor recuperado da cadeia
        var intNumber int
        //Valor recebido como argumento
        var priInt int
        //Valor recebido como argumento
	var secInt int
        //Valor recuperado da cadeia
        var floatNumber float64
        //Valor recebido como argumento
        var priFloat float64
	//Valor recebido como argumento
        var secFloat float64

	chavesTotais, err := APIstub.GetStateByRange("","")
        if err != nil {
                return "", fmt.Errorf("Operacao para busca de chaves falhou. Erro accessando estado: %s", err)
        }

        defer chavesTotais.Close()
        var jsonRetorno string
	jsonRetorno += "["
        for chavesTotais.HasNext() {
                objeto, err := chavesTotais.Next()
                if err != nil {
                        return "", fmt.Errorf("Iteracoes de chaves falhou. Erro acessando estado: %s", err)
                }

		var nodoStruct Nodo
                err = json.Unmarshal(objeto.Value, &nodoStruct)
		if args[0] == "CPU" || args[0] == "MEM" {
			if args[0] == "CPU" {
				intNumber = nodoStruct.Cpu
			} else {
				intNumber = nodoStruct.Mem
			}
                        priInt, err = strconv.Atoi(args[1])
                        if err != nil {
                                return string("Primeiro inteiro informado invalido."), nil
                        }
			secInt, err = strconv.Atoi(args[2])
			if err != nil {
                                return string("Segundo inteiro informado invalido."), nil
                        }
                        //Procura o equipamento de acordo com os parametros passados
                        if intNumber >= priInt && intNumber <= secInt {
				if jsonRetorno != "[" {
					jsonRetorno += ", "
		                }
				jsonRetorno +=  "\"" + objeto.Key + "\""
                        }
                } else if args[0] == "STG" {
                        floatNumber = nodoStruct.Stg
                        priFloat, err = strconv.ParseFloat(args[1],32)
                        if err != nil {
                                return string("Primeiro flutuante informado invalido."), nil
			}
			secFloat, err = strconv.ParseFloat(args[2],32)
                        if err != nil {
                                return string("Segundo flutuante informado invalido."), nil
                        }
			//Procura o equipamento de acordo com os parametros passados
                        if floatNumber >= priFloat && floatNumber <= secFloat {
				if jsonRetorno != "[" {
		                        jsonRetorno += ", "
		                }
                                jsonRetorno +=  "\"" + objeto.Key + "\""
                        }
                }
        }
	jsonRetorno += "]"

        return jsonRetorno,nil
}

//Funcao responsavel pela recuperacao dos ultimos registros do equipamento pesquisado
func obterUltimosEstadosEquip(APIstub shim.ChaincodeStubInterface, args []string) (string, error) {

        if len(args) != 1 {
                return "", fmt.Errorf("Argumentos incorretos. Aguardando a identificacao do nodo")
        }
        historico, err := APIstub.GetHistoryForKey(args[0])
        if err != nil {
                return "", fmt.Errorf("Falha ao obter o nodo: %s with error: %s", args[0], err)
        }
        if historico == nil {
                return "", fmt.Errorf("Nodo nao encontrado: %s", args[0])
        }

        var listaHistorico = make([]Nodo, 0)
	for historico.HasNext() {
		resposta, err := historico.Next()
		fmt.Println(resposta)
		if err != nil {
			return "", fmt.Errorf("Falha na obtencao do historico: %s", err)
		}

		var nodoStruct Nodo
                err = json.Unmarshal(resposta.Value, &nodoStruct)
                listaHistorico = append(listaHistorico, nodoStruct)
	}

	sort.Slice(listaHistorico, func(i, j int) bool { return listaHistorico[i].Dat.After(listaHistorico[j].Dat) })

	var buffer bytes.Buffer
	var jsonStr string
	var contador int
	contador = 0

	for _, nodo := range listaHistorico {
		jsonBytes, _ := json.Marshal(nodo)
		jsonStr = string(jsonBytes[:])
		buffer.WriteString(jsonStr)
		if contador >= 9 {
			break;
		}
		contador += 1;
	}

        return buffer.String(), nil
}

//Funcoes que implementam a interface Sort
func (p EstruturaOrdenacao) Len() int {
    return len(p)
}

//Funcoes que implementam a interface Sort
func (p EstruturaOrdenacao) Less(i, j int) bool {
    return p[i].Dat.Before(p[j].Dat)
}

//Funcoes que implementam a interface Sort
func (p EstruturaOrdenacao) Swap(i, j int) {
    p[i], p[j] = p[j], p[i]
}

// Funcao principal que inicia o container durante o processo de instanciacao
func main() {
	if err := shim.Start(new(Monitor)); err != nil {
		fmt.Printf("Error starting Monitor chaincode: %s", err)
	}
}
