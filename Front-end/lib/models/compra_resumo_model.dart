class CompraResumoModel {
  final int idCompra;
  final String mercadoNome;
  final String? dataCompra;
  final double valorTotal;
  final String formaPagamento;
  final String statusProcessamento;
  final String? criadoEm;
  final List<String> nomesProdutos;
  final int quantidadeItens;

  CompraResumoModel({
    required this.idCompra,
    required this.mercadoNome,
    required this.dataCompra,
    required this.valorTotal,
    required this.formaPagamento,
    required this.statusProcessamento,
    required this.criadoEm,
    required this.nomesProdutos,
    required this.quantidadeItens,
  });

  factory CompraResumoModel.fromJson(Map<String, dynamic> json) {
    return CompraResumoModel(
      idCompra: json['idCompra'] ?? 0,
      mercadoNome: json['mercadoNome'] ?? 'Mercado não identificado',
      dataCompra: json['dataCompra'],
      valorTotal: _toDouble(json['valorTotal']),
      formaPagamento: json['formaPagamento'] ?? 'Não informado',
      statusProcessamento: json['statusProcessamento'] ?? '',
      criadoEm: json['criadoEm'],
      nomesProdutos: (json['nomesProdutos'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      quantidadeItens: json['quantidadeItens'] ?? 0,
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