import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransferirScreen extends StatelessWidget {
  final String contaOrigem;
  final List<dynamic> dados;

  const TransferirScreen({required this.contaOrigem, required this.dados});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transferência'),
        backgroundColor: Colors.deepPurple,
      ),
      body: TransferenciaForm(contaOrigem: contaOrigem, dados: dados),
    );
  }
}

class TransferenciaForm extends StatefulWidget {
  final String contaOrigem;
  final List<dynamic> dados;

  const TransferenciaForm({required this.contaOrigem, required this.dados});

  @override
  State<TransferenciaForm> createState() => _TransferenciaFormState();
}

class _TransferenciaFormState extends State<TransferenciaForm> {
  final TextEditingController _valorController = TextEditingController();
  String? _contaDestino;
  bool _isLoading = false;

  Future<void> _realizarTransferencia() async {
    final valorDigitado = _valorController.text;

    if (_contaDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione a conta de destino')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://endereco_do_seu_servidor/realizar_transferencia'),
        body: {
          'conta_origem': widget.contaOrigem,
          'conta_destino': _contaDestino!,
          'valor': valorDigitado,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferência realizada com sucesso!')),
        );
        // Aqui você pode adicionar lógica adicional, como atualizar dados na interface do usuário.
      } else {
        throw Exception('Erro ao realizar a transferência');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao realizar a transferência')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Encontrando as informações da conta de origem
    Map<String, dynamic>? infoContaOrigem;
    for (var item in widget.dados) {
      if (item['conta'] == widget.contaOrigem) {
        infoContaOrigem = item;
        break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white, // Card branco
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sua Conta:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                if (infoContaOrigem != null) ...[
                  Text(
                    'Conta: ${infoContaOrigem!['conta']}\n'
                    'Nome: ${infoContaOrigem!['nome']}\n'
                    'Idade: ${infoContaOrigem!['idade']}\n'
                    'Saldo: ${infoContaOrigem!['saldo']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                ],
                DropdownButtonFormField<String>(
                  value: _contaDestino,
                  items: widget.dados.map((dynamic item) {
                    return DropdownMenuItem<String>(
                      value: item['conta'],
                      child: Text(
                        '${item['nome']} - ${item['conta']}',
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _contaDestino = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Conta Destino',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _valorController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _realizarTransferencia,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Transferir',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black, // Texto preto
                          )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // Botão roxo
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
