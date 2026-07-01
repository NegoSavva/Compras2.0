class ItemCompraModel {
  final int idItem;
  final String produtoNome;
  final String categoriaNome;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final double valorTotal;
  final double quantidadeNormalizada;
  final String unidadeNormalizada;
  final double precoPorUnidade;

  ItemCompraModel({
    required this.idItem,
    required this.produtoNome,
    required this.categoriaNome,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.quantidadeNormalizada,
    required this.unidadeNormalizada,
    required this.precoPorUnidade,
  });

  factory ItemCompraModel.fromJson(Map<String, dynamic> json) {
    return ItemCompraModel(
      idItem: json['idItem'] ?? 0,
      produtoNome: json['produtoNome'] ?? 'Produto não identificado',
      categoriaNome: json['categoriaNome'] ?? 'Sem categoria',
      quantidade: _toDouble(json['quantidade']),
      unidade: json['unidade'] ?? '',
      valorUnitario: _toDouble(json['valorUnitario']),
      valorTotal: _toDouble(json['valorTotal']),
      quantidadeNormalizada: _toDouble(json['quantidadeNormalizada']),
      unidadeNormalizada: json['unidadeNormalizada'] ?? '',
      precoPorUnidade: _toDouble(json['precoPorUnidade']),
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
