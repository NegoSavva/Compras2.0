

import '../models/compra_detalhe_model.dart';
import '../models/categoria_agrupamento_model.dart';
import '../models/compra_resumo_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compras_por_mercado_model.dart';
import '../models/produto_mais_comprado_model.dart';
import '../models/gastos_por_categoria_model.dart';
import '../models/gasto_mensal_model.dart';
import '../models/regra_categoria_model.dart';
import '../models/mercado_model.dart';
import '../models/nota_leitura_model.dart';
import '../models/detalhe_categoria_model.dart';
import '../models/historico_preco_produto_model.dart';
import '../models/produto_classificacao_model.dart';
import '../models/produto_agrupamento_model.dart';
import '../models/historico_gasto_mensal_model.dart';
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  Future<List<HistoricoPrecoProdutoModel>> buscarHistoricoPrecoProduto({
  required String produtoNome,
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final params = <String, String>{
    'produtoNome': produtoNome,
  };

  if (dataInicio != null && dataFim != null) {
    params['dataInicio'] = dataInicio;
    params['dataFim'] = dataFim;
  } else {
    if (ano != null) params['ano'] = ano.toString();
    if (mes != null) params['mes'] = mes.toString();
  }

  if (idMercado != null) {
    params['idMercado'] = idMercado.toString();
  }

  final query = Uri(queryParameters: params).query;

  final response = await http.get(
    Uri.parse('$baseUrl/relatorios/produtos/historico-preco?$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => HistoricoPrecoProdutoModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<List<ProdutoAgrupamentoModel>> buscarProdutosAgrupamento({
  String? nome,
  String? nomeRelatorio,
  String? categoria,
  bool somenteSemGrupo = false,
}) async {
  final params = <String, String>{};

  if (nome != null && nome.trim().isNotEmpty) {
    params['nome'] = nome.trim();
  }

  if (nomeRelatorio != null && nomeRelatorio.trim().isNotEmpty) {
    params['nomeRelatorio'] = nomeRelatorio.trim();
  }

  if (categoria != null && categoria.trim().isNotEmpty) {
    params['categoria'] = categoria.trim();
  }

  if (somenteSemGrupo) {
    params['somenteSemGrupo'] = 'true';
  }

  final uri = Uri.parse('$baseUrl/produtos-agrupamento').replace(
    queryParameters: params.isEmpty ? null : params,
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => ProdutoAgrupamentoModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> atualizarAgrupamentoProduto({
  required int idProduto,
  required String nomeRelatorio,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/produtos-agrupamento/$idProduto'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nomeRelatorio': nomeRelatorio,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> removerAgrupamentoProduto(int idProduto) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/produtos-agrupamento/$idProduto'),
  );

  if (response.statusCode == 204) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<void> baixarRelatorioExcel({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final query = _montarQueryRelatorio(
    ano: ano,
    mes: mes,
    idMercado: idMercado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );

  final url = '$baseUrl/relatorios/exportar/excel?$query';

  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = 'relatorio-compras.xlsx';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
Future<void> baixarRelatorioCsv({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final query = _montarQueryRelatorio(
    ano: ano,
    mes: mes,
    idMercado: idMercado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );

  final url = '$baseUrl/relatorios/exportar/csv?$query';

  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = 'relatorio-compras.csv';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
Future<List<HistoricoGastoMensalModel>> buscarHistoricoGastosMensais({
  required int ano,
  int? idMercado,
}) async {
  final params = <String, String>{
    'ano': ano.toString(),
  };

  if (idMercado != null) {
    params['idMercado'] = idMercado.toString();
  }

  final query = Uri(queryParameters: params).query;

  final response = await http.get(
    Uri.parse('$baseUrl/relatorios/historico-gastos-mensais?$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => HistoricoGastoMensalModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<List<CategoriaAgrupamentoModel>> buscarCategoriasAgrupamento({
  String? nome,
  String? nomeRelatorio,
  bool somenteSemGrupo = false,
}) async {
  final params = <String, String>{};

  if (nome != null && nome.trim().isNotEmpty) {
    params['nome'] = nome.trim();
  }

  if (nomeRelatorio != null && nomeRelatorio.trim().isNotEmpty) {
    params['nomeRelatorio'] = nomeRelatorio.trim();
  }

  if (somenteSemGrupo) {
    params['somenteSemGrupo'] = 'true';
  }

  final uri = Uri.parse('$baseUrl/categorias-agrupamento').replace(
    queryParameters: params.isEmpty ? null : params,
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => CategoriaAgrupamentoModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> atualizarAgrupamentoCategoria({
  required int idCategoria,
  required String nomeRelatorio,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/categorias-agrupamento/$idCategoria'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nomeRelatorio': nomeRelatorio,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> removerAgrupamentoCategoria(int idCategoria) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/categorias-agrupamento/$idCategoria'),
  );

  if (response.statusCode == 204) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<List<DetalheCategoriaModel>> buscarDetalhesPorCategoria({
  required String categoria,
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final params = <String, String>{
    'categoria': categoria,
  };

  if (dataInicio != null && dataFim != null) {
    params['dataInicio'] = dataInicio;
    params['dataFim'] = dataFim;
  } else {
    if (ano != null) params['ano'] = ano.toString();
    if (mes != null) params['mes'] = mes.toString();
  }

  if (idMercado != null) {
    params['idMercado'] = idMercado.toString();
  }

  final query = Uri(queryParameters: params).query;

  final response = await http.get(
    Uri.parse('$baseUrl/relatorios/gastos-por-categoria/detalhes?$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => DetalheCategoriaModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<List<MercadoModel>> listarMercados() async {
  final response = await http.get(
    Uri.parse('$baseUrl/mercados'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) => MercadoModel.fromJson(item)).toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
String _montarQueryRelatorio({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) {
  final params = <String, String>{};

  if (dataInicio != null && dataFim != null) {
    params['dataInicio'] = dataInicio;
    params['dataFim'] = dataFim;
  } else {
    if (ano != null) params['ano'] = ano.toString();
    if (mes != null) params['mes'] = mes.toString();
  }

  if (idMercado != null) {
    params['idMercado'] = idMercado.toString();
  }

  return Uri(queryParameters: params).query;
}
Future<void> excluirCompra(int idCompra) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/compras/$idCompra'),
  );

  if (response.statusCode == 204) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<GastoMensalModel> buscarGastoMensal({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final query = _montarQueryRelatorio(
    ano: ano,
    mes: mes,
    idMercado: idMercado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );

  final response = await http.get(
    Uri.parse('$baseUrl/relatorios/gasto-mensal?$query'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return GastoMensalModel.fromJson(data);
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<List<ProdutoClassificacaoModel>> buscarProdutosClassificados({
  String? nome,
  String? categoria,
}) async {
  final params = <String, String>{};

  if (nome != null && nome.trim().isNotEmpty) {
    params['nome'] = nome.trim();
  }

  if (categoria != null && categoria.trim().isNotEmpty) {
    params['categoria'] = categoria.trim();
  }

  final query = Uri(queryParameters: params).query;

  final response = await http.get(
    Uri.parse('$baseUrl/produtos-classificacao?$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => ProdutoClassificacaoModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
  Future<List<RegraCategoriaModel>> listarRegrasCategoria() async {
  final response = await http.get(
    Uri.parse('$baseUrl/regras-categoria'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => RegraCategoriaModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> criarRegraCategoria({
  required String palavraChave,
  required String categoria,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/regras-categoria'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'palavraChave': palavraChave,
      'categoria': categoria,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> atualizarRegraCategoria({
  required int idRegra,
  required String palavraChave,
  required String categoria,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/regras-categoria/$idRegra'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'palavraChave': palavraChave,
      'categoria': categoria,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<void> desativarRegraCategoria(int idRegra) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/regras-categoria/$idRegra'),
  );

  if (response.statusCode == 204) {
    return;
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<List<GastosPorCategoriaModel>> buscarGastosPorCategoria({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final query = _montarQueryRelatorio(
    ano: ano,
    mes: mes,
    idMercado: idMercado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );

  final uri = Uri.parse('$baseUrl/relatorios/gastos-por-categoria?$query')
      .replace(queryParameters: {
    ...Uri.splitQueryString(query),
    // Evita qualquer cache do navegador/proxy e garante que o botão Atualizar
    // reflita categorias alteradas no banco imediatamente.
    '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
  });

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => GastosPorCategoriaModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
 Future<List<ProdutoMaisCompradoModel>> buscarProdutosMaisComprados({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final query = _montarQueryRelatorio(
    ano: ano,
    mes: mes,
    idMercado: idMercado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );

  final response = await http.get(
    Uri.parse('$baseUrl/relatorios/produtos-mais-comprados?$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => ProdutoMaisCompradoModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
Future<List<ComprasPorMercadoModel>> buscarComprasPorMercado({
  int? ano,
  int? mes,
  int? idMercado,
  String? dataInicio,
  String? dataFim,
}) async {
  final query = _montarQueryRelatorio(
    ano: ano,
    mes: mes,
    idMercado: idMercado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );

  final response = await http.get(
    Uri.parse('$baseUrl/relatorios/compras-por-mercado?$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => ComprasPorMercadoModel.fromJson(item))
        .toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}
  Future<NotaLeituraModel> lerNota(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notas/ler'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'url': url,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return NotaLeituraModel.fromJson(data);
    }

    throw Exception(_extrairMensagemErro(response.body));
  }

  Future<String> salvarCompra(NotaLeituraModel nota) async {
    final response = await http.post(
      Uri.parse('$baseUrl/compras'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(nota.toJsonSalvar()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['mensagem'] ?? 'Compra salva com sucesso.';
    }

    throw Exception(_extrairMensagemErro(response.body));
  }
Future<List<CompraResumoModel>> listarCompras({
  int? idMercado,
  String? dataInicio,
  String? dataFim,
  double? valorMinimo,
  double? valorMaximo,
  String? formaPagamento,
}) async {
  final params = <String, String>{};

  if (idMercado != null) {
    params['idMercado'] = idMercado.toString();
  }

  if (dataInicio != null && dataInicio.isNotEmpty) {
    params['dataInicio'] = dataInicio;
  }

  if (dataFim != null && dataFim.isNotEmpty) {
    params['dataFim'] = dataFim;
  }

  if (valorMinimo != null) {
    params['valorMinimo'] = valorMinimo.toString();
  }

  if (valorMaximo != null) {
    params['valorMaximo'] = valorMaximo.toString();
  }

  if (formaPagamento != null && formaPagamento.trim().isNotEmpty) {
    params['formaPagamento'] = formaPagamento.trim();
  }

  final uri = Uri.parse('$baseUrl/compras').replace(
    queryParameters: params.isEmpty ? null : params,
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) => CompraResumoModel.fromJson(item)).toList();
  }

  throw Exception(_extrairMensagemErro(response.body));
}

Future<CompraDetalheModel> buscarCompraPorId(int idCompra) async {
  final response = await http.get(
    Uri.parse('$baseUrl/compras/$idCompra'),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return CompraDetalheModel.fromJson(data);
  }

  throw Exception(_extrairMensagemErro(response.body));
}
  String _extrairMensagemErro(String body) {
    try {
      final data = jsonDecode(body);
      return data['mensagem'] ?? data['error'] ?? 'Erro inesperado.';
    } catch (_) {
      return 'Erro inesperado ao se comunicar com o servidor.';
    }
  }
}