import json
import os

# Nome do arquivo para salvar a lista
darq = "lista_compras.json"

# Categorias disponíveis
CATEGORIAS = ["Higiene", "Limpeza", "Comida", "Bebida", "Frutas", "Verduras"]

# Carregar lista de compras do arquivo
if os.path.exists(darq):
    with open(darq, "r", encoding="utf-8") as f:
        lista_compras = json.load(f)
else:
    lista_compras = {categoria: [] for categoria in CATEGORIAS}

def salvar_lista():
    with open(darq, "w", encoding="utf-8") as f:
        json.dump(lista_compras, f, indent=4, ensure_ascii=False)

def adicionar_item():
    print("\nCategorias disponíveis:")
    for i, categoria in enumerate(CATEGORIAS, 1):
        print(f"{i}. {categoria}")
    
    try:
        escolha = int(input("Escolha uma categoria pelo número: ")) - 1
        if escolha not in range(len(CATEGORIAS)):
            print("Opção inválida!")
            return
        
        categoria = CATEGORIAS[escolha]
        item = input(f"Digite o item para adicionar em {categoria}: ").strip()
        if item:
            lista_compras[categoria].append(item)
            print(f"{item} adicionado à categoria {categoria}.")
    except ValueError:
        print("Entrada inválida! Digite um número válido.")

def remover_item():
    listar_itens()
    categoria = input("Digite a categoria do item a remover: ").strip()
    if categoria not in CATEGORIAS:
        print("Categoria inválida!")
        return
    
    if not lista_compras[categoria]:
        print("Nenhum item para remover nesta categoria.")
        return
    
    item = input("Digite o item a remover: ").strip()
    if item in lista_compras[categoria]:
        lista_compras[categoria].remove(item)
        print(f"{item} removido de {categoria}.")
    else:
        print("Item não encontrado!")

def listar_itens():
    print("\nLista de Compras:")
    for categoria, itens in lista_compras.items():
        print(f"\n{categoria}:")
        if itens:
            for item in itens:
                print(f" - {item}")
        else:
            print(" (vazio)")

def main():
    while True:
        print("\n=== Lista de Compras ===")
        print("1. Adicionar Item")
        print("2. Remover Item")
        print("3. Listar Itens")
        print("4. Sair")
        
        escolha = input("Escolha uma opção: ").strip()
        if escolha == "1":
            adicionar_item()
        elif escolha == "2":
            remover_item()
        elif escolha == "3":
            listar_itens()
        elif escolha == "4":
            salvar_lista()
            print("Lista salva! Saindo...")
            break
        else:
            print("Opção inválida! Tente novamente.")

if __name__ == "__main__":
    main()
