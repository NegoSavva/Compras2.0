class ProdutoAgrupamentoModel {
  final int idProduto;
  final String nome;
  final String? nomeRelatorio;
  final String categoria;

  ProdutoAgrupamentoModel({
    required this.idProduto,
    required this.nome,
    required this.nomeRelatorio,
    required this.categoria,
  });

  factory ProdutoAgrupamentoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoAgrupamentoModel(
      idProduto: json['idProduto'] ?? 0,
      nome: json['nome'] ?? 'Produto não identificado',
      nomeRelatorio: json['nomeRelatorio'],
      categoria: json['categoria'] ?? 'Sem categoria',
    );
  }
}