class RegraCategoriaModel {
  final int idRegra;
  final String palavraChave;
  final String categoria;
  final bool ativo;

  RegraCategoriaModel({
    required this.idRegra,
    required this.palavraChave,
    required this.categoria,
    required this.ativo,
  });

  factory RegraCategoriaModel.fromJson(Map<String, dynamic> json) {
    return RegraCategoriaModel(
      idRegra: json['idRegra'] ?? 0,
      palavraChave: json['palavraChave'] ?? '',
      categoria: json['categoria'] ?? '',
      ativo: json['ativo'] ?? false,
    );
  }
}