class GastoMensalModel {
  final int ano;
  final int mes;
  final String periodo;
  final double totalGasto;
  final int quantidadeCompras;

  GastoMensalModel({
    required this.ano,
    required this.mes,
    required this.periodo,
    required this.totalGasto,
    required this.quantidadeCompras,
  });

  factory GastoMensalModel.fromJson(Map<String, dynamic> json) {
    return GastoMensalModel(
      ano: json['ano'] ?? 0,
      mes: json['mes'] ?? 0,
      periodo: json['periodo'] ?? '',
      totalGasto: _toDouble(json['totalGasto']),
      quantidadeCompras: json['quantidadeCompras'] ?? 0,
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