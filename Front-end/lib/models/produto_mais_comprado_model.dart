  class ProdutoMaisCompradoModel {
  final String produtoNome;
  final String categoriaNome;
  final int frequenciaCompra;
  final double quantidadeTotal;
  final double totalGasto;

  ProdutoMaisCompradoModel({
    required this.produtoNome,
    required this.categoriaNome,
    required this.frequenciaCompra,
    required this.quantidadeTotal,
    required this.totalGasto,
  });

  factory ProdutoMaisCompradoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoMaisCompradoModel(
      produtoNome: json['produtoNome'] ?? 'Produto não identificado',
      categoriaNome: json['categoriaNome'] ?? 'Sem categoria',
      frequenciaCompra: json['frequenciaCompra'] ?? 0,
      quantidadeTotal: _toDouble(json['quantidadeTotal']),
      totalGasto: _toDouble(json['totalGasto']),
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