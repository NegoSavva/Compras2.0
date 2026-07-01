class GastosPorCategoriaModel {
  final String categoriaNome;
  final int quantidadeItens;
  final double quantidadeTotalProdutos;
  final double totalGasto;

  GastosPorCategoriaModel({
    required this.categoriaNome,
    required this.quantidadeItens,
    required this.quantidadeTotalProdutos,
    required this.totalGasto,
  });

  factory GastosPorCategoriaModel.fromJson(Map<String, dynamic> json) {
    return GastosPorCategoriaModel(
      categoriaNome: json['categoriaNome'] ?? 'Sem categoria',
      quantidadeItens: json['quantidadeItens'] ?? 0,
      quantidadeTotalProdutos: _toDouble(json['quantidadeTotalProdutos']),
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