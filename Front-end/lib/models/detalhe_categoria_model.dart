class DetalheCategoriaModel {
  final int idCompra;
  final String produtoNome;
  final String categoriaNome;
  final String mercadoNome;
  final String? dataCompra;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final double valorTotal;

  DetalheCategoriaModel({
    required this.idCompra,
    required this.produtoNome,
    required this.categoriaNome,
    required this.mercadoNome,
    required this.dataCompra,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  factory DetalheCategoriaModel.fromJson(Map<String, dynamic> json) {
    return DetalheCategoriaModel(
      idCompra: json['idCompra'] ?? 0,
      produtoNome: json['produtoNome'] ?? 'Produto não identificado',
      categoriaNome: json['categoriaNome'] ?? 'Sem categoria',
      mercadoNome: json['mercadoNome'] ?? 'Mercado não identificado',
      dataCompra: json['dataCompra'],
      quantidade: _toDouble(json['quantidade']),
      unidade: json['unidade'] ?? '',
      valorUnitario: _toDouble(json['valorUnitario']),
      valorTotal: _toDouble(json['valorTotal']),
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