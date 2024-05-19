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
    collection = db[f'{banco}_ag{agencia}']  # Usando f-string para criar o nome da coleção dinamicamente

    # Obter dados da coleção selecionada
    dados = list(collection.find())

    # Converter ObjectId para strings
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

    # Verifica se as informações necessárias foram fornecidas
    if not conta_origem or not conta_destino or not valor:
        return jsonify({'error': 'Dados incompletos para realizar a transferência'}), 400

    # Aqui você implementa a lógica para transferir o valor da conta de origem para a conta de destino
    # Por exemplo, você pode buscar as informações das contas no banco de dados e realizar as operações necessárias

    return jsonify({'message': 'Transferência realizada com sucesso'}), 200

if __name__ == '__main__':
    app.run(debug=True)
