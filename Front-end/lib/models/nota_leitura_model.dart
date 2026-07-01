import 'item_extraido_model.dart';

class NotaLeituraModel {
  final String mercadoNome;
  final String mercadoCnpj;
  final String mercadoEndereco;

  final String? chaveAcesso;
  final String urlNota;
  final String? dataCompra;
  final double valorTotal;
  final String formaPagamento;
  final String statusProcessamento;

  final List<ItemExtraidoModel> itens;

  NotaLeituraModel({
    required this.mercadoNome,
    required this.mercadoCnpj,
    required this.mercadoEndereco,
    required this.chaveAcesso,
    required this.urlNota,
    required this.dataCompra,
    required this.valorTotal,
    required this.formaPagamento,
    required this.statusProcessamento,
    required this.itens,
  });

  factory NotaLeituraModel.fromJson(Map<String, dynamic> json) {
    return NotaLeituraModel(
      mercadoNome: json['mercadoNome'] ?? '',
      mercadoCnpj: json['mercadoCnpj'] ?? '',
      mercadoEndereco: json['mercadoEndereco'] ?? '',
      chaveAcesso: json['chaveAcesso'],
      urlNota: json['urlNota'] ?? '',
      dataCompra: json['dataCompra'],
      valorTotal: _toDouble(json['valorTotal']),
      formaPagamento: json['formaPagamento'] ?? '',
      statusProcessamento: json['statusProcessamento'] ?? '',
      itens: (json['itens'] as List<dynamic>? ?? [])
          .map((item) => ItemExtraidoModel.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJsonSalvar() {
    return {
      'mercadoNome': mercadoNome,
      'mercadoCnpj': mercadoCnpj,
      'mercadoEndereco': mercadoEndereco,
      'chaveAcesso': chaveAcesso,
      'urlNota': urlNota,
      'dataCompra': dataCompra,
      'valorTotal': valorTotal,
      'formaPagamento': formaPagamento,
      'statusProcessamento': 'PROCESSADO',
      'itens': itens.map((item) => item.toJson()).toList(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}