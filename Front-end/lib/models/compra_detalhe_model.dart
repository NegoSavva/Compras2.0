import 'item_compra_model.dart';

class CompraDetalheModel {
  final int idCompra;

  final String mercadoNome;
  final String mercadoCnpj;
  final String mercadoEndereco;

  final String? chaveAcesso;
  final String urlNota;
  final String? dataCompra;
  final double valorTotal;
  final String formaPagamento;
  final String statusProcessamento;
  final String? criadoEm;

  final List<ItemCompraModel> itens;

  CompraDetalheModel({
    required this.idCompra,
    required this.mercadoNome,
    required this.mercadoCnpj,
    required this.mercadoEndereco,
    required this.chaveAcesso,
    required this.urlNota,
    required this.dataCompra,
    required this.valorTotal,
    required this.formaPagamento,
    required this.statusProcessamento,
    required this.criadoEm,
    required this.itens,
  });

  factory CompraDetalheModel.fromJson(Map<String, dynamic> json) {
    return CompraDetalheModel(
      idCompra: json['idCompra'] ?? 0,
      mercadoNome: json['mercadoNome'] ?? 'Mercado não identificado',
      mercadoCnpj: json['mercadoCnpj'] ?? '',
      mercadoEndereco: json['mercadoEndereco'] ?? '',
      chaveAcesso: json['chaveAcesso'],
      urlNota: json['urlNota'] ?? '',
      dataCompra: json['dataCompra'],
      valorTotal: _toDouble(json['valorTotal']),
      formaPagamento: json['formaPagamento'] ?? 'Não informado',
      statusProcessamento: json['statusProcessamento'] ?? '',
      criadoEm: json['criadoEm'],
      itens: (json['itens'] as List<dynamic>? ?? [])
          .map((item) => ItemCompraModel.fromJson(item))
          .toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}