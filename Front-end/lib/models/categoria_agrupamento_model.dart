class CategoriaAgrupamentoModel {
  final int idCategoria;
  final String nome;
  final String? nomeRelatorio;

  CategoriaAgrupamentoModel({
    required this.idCategoria,
    required this.nome,
    required this.nomeRelatorio,
  });

  factory CategoriaAgrupamentoModel.fromJson(Map<String, dynamic> json) {
    return CategoriaAgrupamentoModel(
      idCategoria: json['idCategoria'] ?? 0,
      nome: json['nome'] ?? 'Categoria não identificada',
      nomeRelatorio: json['nomeRelatorio'],
    );
  }
}