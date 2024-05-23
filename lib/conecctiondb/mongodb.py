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
    for db_name, db in dbs.items():
        for agencia in range(1, 6):
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
        conta_origem = data.get('conta_origem')
        conta_destino = data.get('conta_destino')
        valor = data.get('valor')

        if not conta_origem or not conta_destino or not valor:
            print("Dados incompletos para realizar a transferência")
            return jsonify({'error': 'Dados incompletos para realizar a transferência'}), 400

        if conta_existe(conta_origem) and conta_existe(conta_destino):
            if transferir_valor(conta_origem, conta_destino, valor):
                print("Transferência realizada  com sucesso de R$",valor," para Conta ", conta_destino )
                return jsonify({'message': 'Transferência realizada com sucesso'}), 200
            else:
                print("Erro ao transferir valores ou atualizar saldos")
                return jsonify({'error': 'Erro ao transferir valores ou atualizar saldos'}), 500
        else:
            print("Uma ou ambas as contas não existem")
            return jsonify({'error': 'Uma ou ambas as contas não existem'}), 404
    except Exception as e:
        print(f"Erro interno no servidor: {str(e)}")
        return jsonify({'error': 'Erro interno no servidor'}), 500



def transferir_valor(conta_origem, conta_destino, valor):
    try:
        conta_origem_doc = None
        conta_destino_doc = None

        
        for db_name, db in dbs.items():
            for agencia in range(1, 6):
                colecao = f'{db_name}_ag{agencia}'
                contas = db[colecao]
                conta_origem_doc = contas.find_one({'conta': conta_origem})
                if conta_origem_doc:
                    break
            if conta_origem_doc:
                break

        
        for db_name, db in dbs.items():
            for agencia in range(1, 6):
                colecao = f'{db_name}_ag{agencia}'
                contas = db[colecao]
                conta_destino_doc = contas.find_one({'conta': conta_destino})
                if conta_destino_doc:
                    break
            if conta_destino_doc:
                break

        if conta_origem_doc is not None and conta_destino_doc is not None:
            saldo_origem = conta_origem_doc.get('saldo')
            saldo_destino = conta_destino_doc.get('saldo')

            valor = float(valor)
            if saldo_origem < valor:
                return False  

            novo_saldo_origem = saldo_origem - valor
            novo_saldo_destino = saldo_destino + valor

            
            contas.update_one({'conta': conta_origem}, {'$set': {'saldo': novo_saldo_origem}})

            
            contas.update_one({'conta': conta_destino}, {'$set': {'saldo': novo_saldo_destino}})

            return True  
        else:
            return False  
    except Exception as e:
        return False  


@app.route('/contas_destino', methods=['GET'])
def obter_contas_destino():
    contas_destino = []
    for db_name, db in dbs.items():
        for agencia in range(1, 6):
            colecao = f'{db_name}_ag{agencia}'
            contas = db[colecao]
            for conta in contas.find():
                conta['_id'] = str(conta['_id'])
                conta['banco'] = db_name
                conta['agencia'] = agencia
                conta['nome_banco'] = db_name.capitalize()  
                if 'chave_pix' in conta:
                    conta['chave_pix'] = conta['chave_pix']
                contas_destino.append(conta)
    return jsonify(contas_destino)



if __name__ == '__main__':
    app.run(debug=True)
