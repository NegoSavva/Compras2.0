class HistoricoPrecoProdutoModel {
  final int idCompra;
  final String produtoNome;
  final String mercadoNome;
  final String? dataCompra;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final double valorTotal;
  final double quantidadeNormalizada;
  final String unidadeNormalizada;
  final double precoPorUnidade;

  HistoricoPrecoProdutoModel({
    required this.idCompra,
    required this.produtoNome,
    required this.mercadoNome,
    required this.dataCompra,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.quantidadeNormalizada,
    required this.unidadeNormalizada,
    required this.precoPorUnidade,
  });

  factory HistoricoPrecoProdutoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoPrecoProdutoModel(
      idCompra: json['idCompra'] ?? 0,
      produtoNome: json['produtoNome'] ?? 'Produto não identificado',
      mercadoNome: json['mercadoNome'] ?? 'Mercado não identificado',
      dataCompra: json['dataCompra'],
      quantidade: _toDouble(json['quantidade']),
      unidade: json['unidade'] ?? '',
      valorUnitario: _toDouble(json['valorUnitario']),
      valorTotal: _toDouble(json['valorTotal']),
      quantidadeNormalizada: _toDouble(json['quantidadeNormalizada']),
      unidadeNormalizada: json['unidadeNormalizada'] ?? '',
      precoPorUnidade: _toDouble(json['precoPorUnidade']),
    );
  }

  double get melhorPrecoComparacao {
    if (precoPorUnidade > 0) return precoPorUnidade;
    return valorUnitario;
  }

  String get unidadeComparacao {
    if (unidadeNormalizada.trim().isNotEmpty) return unidadeNormalizada;
    return unidade;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
