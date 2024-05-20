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

def conta_existe(db, conta):
    # Verifica se a conta existe na coleção específica do Itaú com a agência 1
    colecao = 'itau_ag1'
    contas = db[colecao]
    return contas.find_one({'conta': conta}) is not None

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

        # Verifica se as contas existem no banco de dados
        db = dbs['itau']  # Usando o banco de dados do Itaú para a transferência
        if conta_existe(db, conta_origem) and conta_existe(db, conta_destino):
            # Realiza a transferência
            if transferir_valor(db, conta_origem, conta_destino, valor):
                return jsonify({'message': 'Transferência realizada com sucesso'}), 200
            else:
                return jsonify({'error': 'Erro ao transferir valores ou atualizar saldos'}), 500
        else:
            return jsonify({'error': 'Uma ou ambas as contas não existem'}), 404
    except Exception as e:
        print(f"Erro no servidor Flask: {e}")
        return jsonify({'error': 'Erro interno no servidor'}), 500

def transferir_valor(db, conta_origem, conta_destino, valor):
    try:
        colecao = 'itau_ag1'
        contas = db[colecao]

        # Convertendo o valor para float
        valor = float(valor)

        # Busca a conta de origem e a conta de destino
        conta_origem_doc = contas.find_one({'conta': conta_origem})
        conta_destino_doc = contas.find_one({'conta': conta_destino})

        if conta_origem_doc is None or conta_destino_doc is None:
            print("Conta de origem ou destino não encontrada")
            return False

        saldo_origem = conta_origem_doc.get('saldo')
        saldo_destino = conta_destino_doc.get('saldo')

        if saldo_origem < valor:
            print("Saldo insuficiente na conta de origem")
            return False

        # Atualiza o saldo da conta de origem
        novo_saldo_origem = saldo_origem - valor
        contas.update_one({'conta': conta_origem}, {'$set': {'saldo': novo_saldo_origem}})

        # Atualiza o saldo da conta de destino
        novo_saldo_destino = saldo_destino + valor
        contas.update_one({'conta': conta_destino}, {'$set': {'saldo': novo_saldo_destino}})

        print("Transferência realizada com sucesso")
        return True
    except Exception as e:
        print(f"Erro ao transferir valores ou atualizar saldos no banco de dados: {e}")
        return False

if __name__ == '__main__':
    app.run(debug=True)
