from flask import Flask, jsonify, request
from pymongo import MongoClient

app = Flask(__name__)
client = MongoClient('mongodb://localhost:27017/')
dbs = {
    'itau': client['itau'],
    'bradesco': client['bradesco'],
    'caixa': client['caixa'],
    'santander': client['santander'],
    'sicoob': client['sicoob']
}

def conta_existe(conta):
    # Verifica se a conta existe em todas as agências de todos os bancos
    for db_name, db in dbs.items():
        for agencia in range(1, 6):  # Considerando agências de 1 a 5
            colecao = f'{db_name}_ag{agencia}'
            contas = db[colecao]
            if contas.find_one({'conta': conta}):
                return True
    return False


@app.route('/<string:banco>/<int:agencia>/dados', methods=['GET'])
def obter_dados(banco, agencia):
    if banco not in dbs:
        return jsonify({'error': 'Banco não encontrado'}), 404

    db = dbs[banco]
    collection = db[f'{banco}_ag{agencia}']

    dados = list(collection.find())

    for item in dados:
        if '_id' in item:
            item['_id'] = str(item['_id'])

    return jsonify(dados)

@app.route('/realizar_transferencia', methods=['POST'])
def realizar_transferencia():
    try:
        data = request.get_json()
        print("Dados recebidos:", data)

        conta_origem = data.get('conta_origem')
        conta_destino = data.get('conta_destino')
        valor = data.get('valor')
        print("Dados extraídos:", conta_origem, conta_destino, valor)

        if not conta_origem or not conta_destino or not valor:
            return jsonify({'error': 'Dados incompletos para realizar a transferência'}), 400

        # Verifica se as contas existem em qualquer banco de dados
        if conta_existe( conta_origem) and conta_existe(conta_destino):
            # Realiza a transferência
            if transferir_valor(conta_origem, conta_destino, valor):
                return jsonify({'message': 'Transferência realizada com sucesso'}), 200
            else:
                return jsonify({'error': 'Erro ao transferir valores ou atualizar saldos'}), 500
        else:
            return jsonify({'error': 'Uma ou ambas as contas não existem'}), 404
    except Exception as e:
        print(f"Erro no servidor Flask: {e}")
        return jsonify({'error': 'Erro interno no servidor'}), 500

def transferir_valor(conta_origem, conta_destino, valor):
    try:
        for db_name, db in dbs.items():
            for agencia in range(1, 6):  # Considerando agências de 1 a 5
                colecao = f'{db_name}_ag{agencia}'
                contas = db[colecao]

                # Convertendo o valor para float
                valor = float(valor)

                # Busca a conta de origem e a conta de destino
                conta_origem_doc = contas.find_one({'conta': conta_origem})
                conta_destino_doc = contas.find_one({'conta': conta_destino})

                if conta_origem_doc is not None and conta_destino_doc is not None:
                    saldo_origem = conta_origem_doc.get('saldo')
                    saldo_destino = conta_destino_doc.get('saldo')

                    if saldo_origem < valor:
                        print(f"Saldo insuficiente na conta de origem para o banco {db_name} agência {agencia}")
                        continue  # Passa para a próxima agência

                    # Atualiza o saldo da conta de origem
                    novo_saldo_origem = saldo_origem - valor
                    contas.update_one({'conta': conta_origem}, {'$set': {'saldo': novo_saldo_origem}})

                    # Atualiza o saldo da conta de destino
                    novo_saldo_destino = saldo_destino + valor
                    contas.update_one({'conta': conta_destino}, {'$set': {'saldo': novo_saldo_destino}})

                    print(f"Transferência de {valor} realizada com sucesso para o banco {db_name} agência {agencia}")
                    return True
                else:
                    print(f"Conta de origem ou destino não encontrada no banco {db_name} agência {agencia}")
        print("Erro: Conta de origem ou destino não encontrada em nenhum banco ou agência")
        return False
    except Exception as e:
        print(f"Erro ao transferir valores ou atualizar saldos no banco de dados: {e}")
        return False

if __name__ == '__main__':
    app.run(debug=True)

    
