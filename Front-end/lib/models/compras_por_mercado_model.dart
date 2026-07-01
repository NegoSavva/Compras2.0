class ComprasPorMercadoModel {
  final String mercadoNome;
  final int quantidadeCompras;
  final double totalGasto;

  ComprasPorMercadoModel({
    required this.mercadoNome,
    required this.quantidadeCompras,
    required this.totalGasto,
  });

  factory ComprasPorMercadoModel.fromJson(Map<String, dynamic> json) {
    return ComprasPorMercadoModel(
      mercadoNome: json['mercadoNome'] ?? 'Mercado não identificado',
      quantidadeCompras: json['quantidadeCompras'] ?? 0,
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