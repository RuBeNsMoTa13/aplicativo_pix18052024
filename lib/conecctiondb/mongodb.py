from flask import Flask, jsonify
from pymongo import MongoClient

app = Flask(__name__)
client = MongoClient('mongodb://localhost:27017/')
db = client['itau']

@app.route('/<int:agencia>/dados', methods=['GET'])
def obter_dados(agencia):
    # Determinar a coleção com base na agência
    collection = db[f'itau_ag{agencia}']  # Usando f-string para criar o nome da coleção dinamicamente

    # Obter dados da coleção selecionada
    dados = list(collection.find())

    # Converter ObjectId para strings
    for item in dados:
        if '_id' in item:
            item['_id'] = str(item['_id'])

    return jsonify(dados)

if __name__ == '__main__':
    app.run(debug=True)
