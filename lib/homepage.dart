import 'package:flutter/material.dart';
import 'transferir.dart'; 

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> dados;
  final int agenciaSelecionada;

  const HomePage({
    Key? key,
    required this.dados,
    required this.agenciaSelecionada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Agência $agenciaSelecionada'),
      ),
      body: ListView.builder(
        itemCount: dados.length,
        itemBuilder: (context, index) {
          final agencia = dados[index];

          return Card(
            elevation: 4,
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes da Agência ${agencia['agencia']}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      _buildAgenciaDetails(agencia),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransferirScreen(
                            contaOrigem: agencia['conta'],
                            dados: dados,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      child: Text(
                        'Transferir',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgenciaDetails(Map<String, dynamic> agencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome: ${agencia['nome']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text('Idade: ${agencia['idade']}'),
        SizedBox(height: 4),
        Text('Conta: ${agencia['conta']}'),
        SizedBox(height: 4),
        Text('Agência: ${agencia['agencia']}'),
        SizedBox(height: 4),
        Text('Saldo: ${agencia['saldo']}'),
        SizedBox(height: 4),
        Text('PIX: ${agencia['chave_pix']}'),
      ],
    );
  }
}
