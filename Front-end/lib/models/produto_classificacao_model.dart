class ProdutoClassificacaoModel {
  final int idProduto;
  final String nome;
  final String categoria;
  final int? idRegra;
  final String? palavraChaveRegra;
  final String? categoriaRegra;

  ProdutoClassificacaoModel({
    required this.idProduto,
    required this.nome,
    required this.categoria,
    required this.idRegra,
    required this.palavraChaveRegra,
    required this.categoriaRegra,
  });

  factory ProdutoClassificacaoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoClassificacaoModel(
      idProduto: json['idProduto'] ?? 0,
      nome: json['nome'] ?? 'Produto não identificado',
      categoria: json['categoria'] ?? 'Sem categoria',
      idRegra: json['idRegra'],
      palavraChaveRegra: json['palavraChaveRegra'],
      categoriaRegra: json['categoriaRegra'],
    );
  }
}