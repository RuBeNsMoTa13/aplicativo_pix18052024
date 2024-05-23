import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 

class TransferirScreen extends StatelessWidget {
  final String contaOrigem;
  final List<dynamic> dados;

  TransferirScreen({required this.contaOrigem, required this.dados});

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
        _exibirComprovante(
          widget.contaOrigem,
          _contaDestino!,
          valorDigitado,
          _obterDataHoraAtual(), 
          _contasDestino
                  .firstWhere((element) => element['conta'] == _contaDestino)[
              'chave_pix'], 
        );
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

  void _mostrarSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _exibirComprovante(String contaOrigem, String contaDestino,
      String valorTransferido, String dataHora, String chavePix) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Comprovante de Transferência'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Conta de Origem: $contaOrigem'),
                Text('Conta de Destino: $contaDestino'),
                Text('Valor Transferido: R\$ $valorTransferido'),
                Text('Data e Hora: $dataHora'),
                Text('Chave PIX: $chavePix'), 
                Text(
                    'Saldo: R\$ ${widget.dados.firstWhere((element) => element['conta'] == widget.contaOrigem)['saldo']}'),
                Text(
                    'Nome: ${widget.dados.firstWhere((element) => element['conta'] == widget.contaOrigem)['nome']}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  String _obterDataHoraAtual() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
    return formattedDate;
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
                Text(
                  'Nome: ${widget.dados.firstWhere((element) => element['conta'] == widget.contaOrigem)['nome']}\n'
                  'Conta: ${widget.contaOrigem}\n'
                  'Saldo: R\$ ${widget.dados.firstWhere((element) => element['conta'] == widget.contaOrigem)['saldo']}',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
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
