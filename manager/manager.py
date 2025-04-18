import json
import os
import sys

def limpar_tela():
    os.system('clear' if os.name == 'posix' else 'cls')

def esperar_usuario():
    input("\nPressione Enter para continuar...")

def erro():
    limpar_tela()
    print("Erro! Entrada inválida.")
    esperar_usuario()

def sair_programa():
    limpar_tela()
    print("Saindo do programa...")
    sys.exit()

def menu():
    limpar_tela()
    print("\nGerenciador de Contas")
    print("1 - Contas Fixas")
    print("2 - Contas Começo do Mês")
    print("3 - Contas Fim do Mês")
    print("4 - Calcular")
    print("5 - Apagar Conta")
    print("6 - Listar Contas")
    print("7 - Remover Conta")
    print("8 - Sair")
    return input("Escolha uma opção: ") or erro()

def salvar_dados():
    with open("contas.json", "w") as f:
        json.dump({"fixas": contas_fixas, "comeco": contas_comeco, "fim": contas_fim}, f)

def carregar_dados():
    global contas_fixas, contas_comeco, contas_fim
    try:
        with open("contas.json", "r") as f:
            dados = json.load(f)
            contas_fixas = dados.get("fixas", [])
            contas_comeco = dados.get("comeco", [])
            contas_fim = dados.get("fim", [])
    except FileNotFoundError:
        pass

contas_fixas = []
contas_comeco = []
contas_fim = []
carregar_dados()

def adicionar_conta_fixa():
    descricao = input("Digite a descrição da conta fixa: ") or erro()
    try:
        valor = float(input("Digite o valor da conta fixa: "))
    except ValueError:
        erro()
        return
    destino = input("Essa conta é para o começo (1) ou fim (2) do mês? ") or erro()
    
    contas_fixas.append((descricao, valor))
    if destino == '1':
        contas_comeco.append((descricao, valor))
    elif destino == '2':
        contas_fim.append((descricao, valor))
    else:
        print("Opção inválida! Conta adicionada apenas às fixas.")
    
    salvar_dados()
    print("Conta fixa adicionada com sucesso!")
    esperar_usuario()

def adicionar_conta(lista, nome):
    descricao = input(f"Digite a descrição da conta {nome}: ") or erro()
    try:
        valor = float(input(f"Digite o valor da conta {nome}: "))
    except ValueError:
        erro()
        return
    lista.append((descricao, valor))
    salvar_dados()
    print("Conta adicionada com sucesso!")
    esperar_usuario()

def apagar_conta():
    print("\nEscolha a categoria da conta para apagar:")
    print("1 - Contas Fixas")
    print("2 - Contas Começo do Mês")
    print("3 - Contas Fim do Mês")
    opcao = input("Escolha uma opção: ") or erro()
    
    if opcao == '1':
        lista = contas_fixas
        nome = "fixas"
    elif opcao == '2':
        lista = contas_comeco
        nome = "do começo do mês"
    elif opcao == '3':
        lista = contas_fim
        nome = "do fim do mês"
    else:
        erro()
        return
    
    if not lista:
        print(f"Nenhuma conta {nome} para apagar.")
        esperar_usuario()
        return
    
    print(f"Contas {nome}:")
    for i, (desc, valor) in enumerate(lista):
        print(f"{i + 1} - {desc}: R$ {valor:.2f}")
    
    indice = input("Digite o número da conta que deseja apagar: ") or erro()
    if indice.isdigit():
        indice = int(indice) - 1
        if 0 <= indice < len(lista):
            lista.pop(indice)
            salvar_dados()
            print("Conta apagada com sucesso!")
        else:
            erro()
    else:
        erro()
    esperar_usuario()

def remover_conta():
    apagar_conta()

def listar_contas():
    print("\nContas Fixas:")
    for desc, valor in contas_fixas:
        print(f"- {desc}: R$ {valor:.2f}")
    print("\nContas do Começo do Mês:")
    for desc, valor in contas_comeco:
        print(f"- {desc}: R$ {valor:.2f}")
    print("\nContas do Fim do Mês:")
    for desc, valor in contas_fim:
        print(f"- {desc}: R$ {valor:.2f}")
    esperar_usuario()

def calcular():
    limpar_tela()
    total_comeco = sum(valor for _, valor in contas_comeco)
    total_fim = sum(valor for _, valor in contas_fim)
    total_geral = total_comeco + total_fim

    print("Resumo de Gastos:")
    print(f"Total do Começo do Mês: R$ {total_comeco:.2f}")
    print(f"Total do Fim do Mês: R$ {total_fim:.2f}")
    print(f"Total Geral: R$ {total_geral:.2f}")
    esperar_usuario()

try:
    while True:
        opcao = menu()
        if opcao == '1':
            adicionar_conta_fixa()
        elif opcao == '2':
            adicionar_conta(contas_comeco, "do Começo do Mês")
        elif opcao == '3':
            adicionar_conta(contas_fim, "do Fim do Mês")
        elif opcao == '4':
            calcular()
        elif opcao == '5':
            apagar_conta()
        elif opcao == '6':
            listar_contas()
        elif opcao == '7':
            remover_conta()
        elif opcao == '8':
            sair_programa()
        else:
            erro()
except KeyboardInterrupt:
    sair_programa()

