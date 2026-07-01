class ItemExtraidoModel {
  final String nome;
  final double quantidade;
  final String unidade;
  final double valorUnitario;
  final double valorTotal;
  final String categoria;

  ItemExtraidoModel({
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.categoria,
  });

  factory ItemExtraidoModel.fromJson(Map<String, dynamic> json) {
    return ItemExtraidoModel(
      nome: json['nome'] ?? '',
      quantidade: _toDouble(json['quantidade']),
      unidade: json['unidade'] ?? '',
      valorUnitario: _toDouble(json['valorUnitario']),
      valorTotal: _toDouble(json['valorTotal']),
      categoria: json['categoria'] ?? 'Sem categoria',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'valorUnitario': valorUnitario,
      'valorTotal': valorTotal,
      'categoria': categoria,
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