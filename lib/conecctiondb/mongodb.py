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
    data = request.get_json()

    conta_origem = data.get('conta_origem')
    conta_destino = data.get('conta_destino')
    valor = data.get('valor')

    if not conta_origem or not conta_destino or not valor:
        return jsonify({'error': 'Dados incompletos para realizar a transferência'}), 400

    # Verifica se as contas existem no banco de dados
    if conta_origem_existe(conta_origem) and conta_destino_existe(conta_destino):
        # Realiza a transferência
        transferir_valor(conta_origem, conta_destino, valor)
        return jsonify({'message': 'Transferência realizada com sucesso'}), 200
    else:
        return jsonify({'error': 'Uma ou ambas as contas não existem'}), 404

def conta_origem_existe(conta_origem):
    # Aqui você implementa a lógica para verificar se a conta de origem existe no banco de dados
    # Por exemplo, pode ser uma consulta ao banco de dados para verificar a existência da conta
    return True  # Simulando que a conta existe

def conta_destino_existe(conta_destino):
    # Aqui você implementa a lógica para verificar se a conta de destino existe no banco de dados
    return True  # Simulando que a conta existe

def transferir_valor(conta_origem, conta_destino, valor):
    # Aqui você implementa a lógica para transferir o valor da conta de origem para a conta de destino
    # Por exemplo, pode ser uma atualização dos saldos das contas no banco de dados
    # Neste exemplo, apenas simulamos a transferência imprimindo as informações
    print(f"Transferindo {valor} da conta {conta_origem} para a conta {conta_destino}")

if __name__ == '__main__':
    app.run(debug=True)
