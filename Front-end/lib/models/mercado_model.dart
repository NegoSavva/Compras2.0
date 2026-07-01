class MercadoModel {
  final int idMercado;
  final String nome;
  final String? cnpj;
  final String? endereco;

  MercadoModel({
    required this.idMercado,
    required this.nome,
    required this.cnpj,
    required this.endereco,
  });

  factory MercadoModel.fromJson(Map<String, dynamic> json) {
    return MercadoModel(
      idMercado: json['idMercado'] ?? 0,
      nome: json['nome'] ?? 'Mercado não identificado',
      cnpj: json['cnpj'],
      endereco: json['endereco'],
    );
  }
}