from flask import Flask, jsonify
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

if __name__ == '__main__':
    app.run(debug=True)
