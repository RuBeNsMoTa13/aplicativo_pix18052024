import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transferência',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: TransferirScreen(
        contaOrigem: '123456789',
        dados: [],
      ),
    );
  }
}

class TransferirScreen extends StatelessWidget {
  final String contaOrigem;

  TransferirScreen(
      {required this.contaOrigem, required List<Map<String, dynamic>> dados});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transferência'),
        backgroundColor: Colors.deepPurple,
      ),
      body: TransferenciaForm(contaOrigem: contaOrigem),
    );
  }
}

class TransferenciaForm extends StatefulWidget {
  final String contaOrigem;

  const TransferenciaForm({required this.contaOrigem});

  @override
  State<TransferenciaForm> createState() => _TransferenciaFormState();
}

class _TransferenciaFormState extends State<TransferenciaForm> {
  late final TextEditingController _valorController = TextEditingController();
  late final TextEditingController _pesquisaController =
      TextEditingController();
  String? _contaDestino;
  bool _isLoading = false;
  List<dynamic> _contasDestino = [];
  List<dynamic> _contasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarContasDestino();
    _pesquisaController.addListener(_filtrarContas);
  }

  // Carrega as contas de destino
  Future<void> _carregarContasDestino() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/contas_destino'));

      if (response.statusCode == 200) {
        setState(() {
          _contasDestino = json.decode(response.body);
          _contasFiltradas = _contasDestino;
        });
      } else {
        throw Exception('Erro ao carregar contas de destino');
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao carregar contas de destino');
    }
  }

  // Realiza a transferência
  Future<void> _realizarTransferencia() async {
    final valorDigitado = _valorController.text;

    if (_contaDestino == null) {
      _mostrarSnackBar('Selecione a conta de destino');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/realizar_transferencia'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conta_origem': widget.contaOrigem,
          'conta_destino': _contaDestino!,
          'valor': valorDigitado,
        }),
      );

      if (response.statusCode == 200) {
        _mostrarSnackBar('Transferência realizada com sucesso!');
      } else {
        throw Exception('Erro ao realizar a transferência');
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao realizar a transferência');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filtra as contas de destino
  void _filtrarContas() {
    final keyword = _pesquisaController.text.toLowerCase();
    setState(() {
      _contasFiltradas = _contasDestino.where((item) {
        final nomeConta = item['nome'].toString().toLowerCase();
        final conta = item['conta'].toString().toLowerCase();
        final chavePix = item['chave_pix']?.toString().toLowerCase() ?? '';
        return nomeConta.contains(keyword) ||
            conta.contains(keyword) ||
            chavePix.contains(keyword);
      }).toList();
    });
  }

  // Mostra um SnackBar com a mensagem especificada
  void _mostrarSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sua Conta:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center),
                SizedBox(height: 8),
                Text('Conta: ${widget.contaOrigem}',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.center),
                SizedBox(height: 20),
                TextFormField(
                  controller: _pesquisaController,
                  onChanged: (_) => _filtrarContas(),
                  decoration: InputDecoration(
                    labelText: 'Pesquisar Conta Destino',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                  ),
                ),
                SizedBox(height: 20),
                _contasFiltradas.isNotEmpty
                    ? DropdownButtonFormField<String>(
                        value: _contaDestino,
                        items: _contasFiltradas.map((dynamic item) {
                          return DropdownMenuItem<String>(
                            value: item['conta'],
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item['nome']} - ${item['conta']}',
                                    style: TextStyle(color: Colors.black)),
                                SizedBox(width: 30),
                                Text(
                                    'Banco: ${item['banco']}, Agência: ${item['agencia']}',
                                    style:
                                        TextStyle(color: Colors.purple[900])),
                                if (item['chave_pix'] != null)
                                  Text('  Chave PIX: ${item['chave_pix']}',
                                      style: TextStyle(color: Colors.amber)),
                              ],
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
                              borderSide: BorderSide(color: Colors.black)),
                        ),
                      )
                    : Text('Nenhuma conta encontrada'),
                SizedBox(height: 20),
                TextFormField(
                  controller: _valorController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _realizarTransferencia,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text(
                          'Transferir',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
