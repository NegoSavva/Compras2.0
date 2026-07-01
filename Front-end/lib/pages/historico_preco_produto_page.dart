import 'package:flutter/material.dart';

import '../models/historico_preco_produto_model.dart';
import '../services/api_service.dart';
import 'detalhes_compra_page.dart';

class HistoricoPrecoProdutoPage extends StatefulWidget {
  final String produtoNome;
  final int? ano;
  final int? mes;
  final int? idMercado;
  final String? dataInicio;
  final String? dataFim;

  const HistoricoPrecoProdutoPage({
    super.key,
    required this.produtoNome,
    this.ano,
    this.mes,
    this.idMercado,
    this.dataInicio,
    this.dataFim,
  });

  @override
  State<HistoricoPrecoProdutoPage> createState() =>
      _HistoricoPrecoProdutoPageState();
}

class _HistoricoPrecoProdutoPageState
    extends State<HistoricoPrecoProdutoPage> {
  final ApiService _apiService = ApiService();

  late Future<List<HistoricoPrecoProdutoModel>> _futureHistorico;

  @override
  void initState() {
    super.initState();
    _futureHistorico = _buscarHistorico();
  }

  Future<List<HistoricoPrecoProdutoModel>> _buscarHistorico() {
    return _apiService.buscarHistoricoPrecoProduto(
      produtoNome: widget.produtoNome,
      ano: widget.ano,
      mes: widget.mes,
      idMercado: widget.idMercado,
      dataInicio: widget.dataInicio,
      dataFim: widget.dataFim,
    );
  }

  Future<void> _recarregar() async {
    setState(() {
      _futureHistorico = _buscarHistorico();
    });
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarData(String? data) {
    if (data == null || data.isEmpty) {
      return 'Data não informada';
    }

    try {
      final dateTime = DateTime.parse(data);

      final dia = dateTime.day.toString().padLeft(2, '0');
      final mes = dateTime.month.toString().padLeft(2, '0');
      final ano = dateTime.year.toString();

      return '$dia/$mes/$ano';
    } catch (_) {
      return data;
    }
  }

  double _menorPreco(List<HistoricoPrecoProdutoModel> historico) {
    if (historico.isEmpty) return 0;

    return historico
        .map((item) => item.melhorPrecoComparacao)
        .reduce((a, b) => a < b ? a : b);
  }

  double _maiorPreco(List<HistoricoPrecoProdutoModel> historico) {
    if (historico.isEmpty) return 0;

    return historico
        .map((item) => item.melhorPrecoComparacao)
        .reduce((a, b) => a > b ? a : b);
  }

  double _precoMedio(List<HistoricoPrecoProdutoModel> historico) {
    if (historico.isEmpty) return 0;

    final total = historico.fold<double>(
      0,
      (soma, item) => soma + item.melhorPrecoComparacao,
    );

    return total / historico.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de preço'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _recarregar,
            child: FutureBuilder<List<HistoricoPrecoProdutoModel>>(
              future: _futureHistorico,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            snapshot.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final historico = snapshot.data ?? [];

                if (historico.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nenhum histórico encontrado para "${widget.produtoNome}" no período selecionado.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final menorPreco = _menorPreco(historico);
                final maiorPreco = _maiorPreco(historico);
                final precoMedio = _precoMedio(historico);

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.produtoNome,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Registros encontrados: ${historico.length}',
                              style: const TextStyle(fontSize: 16),
                            ),

                            const SizedBox(height: 16),

                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _ResumoPrecoChip(
                                  label: 'Menor preço',
                                  valor: _formatarMoeda(menorPreco),
                                ),
                                _ResumoPrecoChip(
                                  label: 'Maior preço',
                                  valor: _formatarMoeda(maiorPreco),
                                ),
                                _ResumoPrecoChip(
                                  label: 'Preço médio',
                                  valor: _formatarMoeda(precoMedio),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evolução do preço normalizado/unitário',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                           _GraficoHistoricoPrecoInterativo(
  historico: historico,
  formatarMoeda: _formatarMoeda,
  formatarData: _formatarData,
),
                        
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: historico.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = historico[index];

                        return Card(
                          child: ListTile(
                            title: Text(
                              item.produtoNome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item.mercadoNome}\n'
                              '${_formatarData(item.dataCompra)}\n'
                              'Unitário: ${_formatarMoeda(item.valorUnitario)} • '
                              '${item.precoPorUnidade > 0 ? 'Normalizado: ${_formatarMoeda(item.precoPorUnidade)} / ${item.unidadeNormalizada} • ' : ''}'
                              'Qtd.: ${item.quantidadeNormalizada > 0 ? item.quantidadeNormalizada.toStringAsFixed(3) : item.quantidade.toStringAsFixed(3)} ${item.unidadeNormalizada.isNotEmpty ? item.unidadeNormalizada : item.unidade} • '
                              'Total: ${_formatarMoeda(item.valorTotal)}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalhesCompraPage(
                                    idCompra: item.idCompra,
                                  produtoDestacado: item.produtoNome,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumoPrecoChip extends StatelessWidget {
  final String label;
  final String valor;

  const _ResumoPrecoChip({
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $valor'),
    );
  }
}

class _GraficoHistoricoPrecoInterativo extends StatefulWidget {
  final List<HistoricoPrecoProdutoModel> historico;
  final String Function(double valor) formatarMoeda;
  final String Function(String? data) formatarData;

  const _GraficoHistoricoPrecoInterativo({
    required this.historico,
    required this.formatarMoeda,
    required this.formatarData,
  });

  @override
  State<_GraficoHistoricoPrecoInterativo> createState() =>
      _GraficoHistoricoPrecoInterativoState();
}

class _GraficoHistoricoPrecoInterativoState
    extends State<_GraficoHistoricoPrecoInterativo> {
  int? _indiceSelecionado;

  @override
  void initState() {
    super.initState();

    if (widget.historico.isNotEmpty) {
      _indiceSelecionado = widget.historico.length - 1;
    }
  }

  void _selecionarPontoPorPosicao(
    Offset posicao,
    Size tamanho,
  ) {
    if (widget.historico.length < 2) return;

    const margemEsquerda = 56.0;
    const margemDireita = 20.0;

    final areaLargura = tamanho.width - margemEsquerda - margemDireita;

    if (areaLargura <= 0) return;

    final xRelativo = posicao.dx - margemEsquerda;
    final proporcao = (xRelativo / areaLargura).clamp(0.0, 1.0);

    final indice = (proporcao * (widget.historico.length - 1)).round();

    setState(() {
      _indiceSelecionado = indice.clamp(0, widget.historico.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historico = widget.historico;

    if (historico.length < 2) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'É necessário mais de um registro para formar o gráfico.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final indice = _indiceSelecionado ?? historico.length - 1;
    final itemSelecionado = historico[indice];

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tamanho = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return MouseRegion(
                onHover: (event) {
                  _selecionarPontoPorPosicao(
                    event.localPosition,
                    tamanho,
                  );
                },
                child: GestureDetector(
                  onTapDown: (details) {
                    _selecionarPontoPorPosicao(
                      details.localPosition,
                      tamanho,
                    );
                  },
                  onPanUpdate: (details) {
                    _selecionarPontoPorPosicao(
                      details.localPosition,
                      tamanho,
                    );
                  },
                  child: CustomPaint(
                    painter: _GraficoHistoricoPrecoPainterMelhorado(
                      historico: historico,
                      indiceSelecionado: indice,
                      formatarMoeda: widget.formatarMoeda,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        _DetalhePontoPrecoCard(
          item: itemSelecionado,
          formatarMoeda: widget.formatarMoeda,
          formatarData: widget.formatarData,
        ),
      ],
    );
  }
}

class _DetalhePontoPrecoCard extends StatelessWidget {
  final HistoricoPrecoProdutoModel item;
  final String Function(double valor) formatarMoeda;
  final String Function(String? data) formatarData;

  const _DetalhePontoPrecoCard({
    required this.item,
    required this.formatarMoeda,
    required this.formatarData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _InfoPrecoGrafico(
            titulo: 'Produto',
            valor: item.produtoNome,
            largura: 260,
          ),
          _InfoPrecoGrafico(
            titulo: 'Mercado',
            valor: item.mercadoNome,
          ),
          _InfoPrecoGrafico(
            titulo: 'Data',
            valor: formatarData(item.dataCompra),
          ),
          _InfoPrecoGrafico(
            titulo: 'Unitário',
            valor: formatarMoeda(item.melhorPrecoComparacao),
          ),
          _InfoPrecoGrafico(
            titulo: 'Quantidade',
            valor: item.precoPorUnidade > 0
                ? '${item.quantidadeNormalizada.toStringAsFixed(3)} ${item.unidadeNormalizada}'
                : '${item.quantidade.toStringAsFixed(3)} ${item.unidade}',
          ),
          _InfoPrecoGrafico(
            titulo: 'Total',
            valor: formatarMoeda(item.valorTotal),
          ),
        ],
      ),
    );
  }
}

class _InfoPrecoGrafico extends StatelessWidget {
  final String titulo;
  final String valor;
  final double largura;

  const _InfoPrecoGrafico({
    required this.titulo,
    required this.valor,
    this.largura = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoHistoricoPrecoPainterMelhorado extends CustomPainter {
  final List<HistoricoPrecoProdutoModel> historico;
  final int indiceSelecionado;
  final String Function(double valor) formatarMoeda;

  _GraficoHistoricoPrecoPainterMelhorado({
    required this.historico,
    required this.indiceSelecionado,
    required this.formatarMoeda,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const margemEsquerda = 56.0;
    const margemDireita = 20.0;
    const margemTopo = 28.0;
    const margemBaixo = 42.0;

    final areaLargura = size.width - margemEsquerda - margemDireita;
    final areaAltura = size.height - margemTopo - margemBaixo;

    if (areaLargura <= 0 || areaAltura <= 0 || historico.length < 2) {
      return;
    }

    final precos = historico.map((item) => item.melhorPrecoComparacao).toList();

    final menor = precos.reduce((a, b) => a < b ? a : b);
    final maior = precos.reduce((a, b) => a > b ? a : b);

    final intervalo = maior - menor == 0 ? 1.0 : maior - menor;

    final eixoPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF9E9E9E);

    final gradePaint = Paint()
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFE0E0E0);

    final linhaPaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1976D2);

    final pontoPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1976D2);

    final pontoSelecionadoPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF9800);

    final linhaSelecionadaPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFFF9800);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 3; i++) {
      final y = margemTopo + (areaAltura / 3) * i;

      canvas.drawLine(
        Offset(margemEsquerda, y),
        Offset(margemEsquerda + areaLargura, y),
        gradePaint,
      );
    }

    canvas.drawLine(
      Offset(margemEsquerda, margemTopo),
      Offset(margemEsquerda, margemTopo + areaAltura),
      eixoPaint,
    );

    canvas.drawLine(
      Offset(margemEsquerda, margemTopo + areaAltura),
      Offset(margemEsquerda + areaLargura, margemTopo + areaAltura),
      eixoPaint,
    );

    final pontos = <Offset>[];

    for (int i = 0; i < historico.length; i++) {
      final item = historico[i];

      final x = margemEsquerda + (areaLargura / (historico.length - 1)) * i;
      final proporcao = (item.melhorPrecoComparacao - menor) / intervalo;
      final y = margemTopo + areaAltura - (proporcao * areaAltura);

      pontos.add(Offset(x, y));
    }

    final path = Path();

    for (int i = 0; i < pontos.length; i++) {
      if (i == 0) {
        path.moveTo(pontos[i].dx, pontos[i].dy);
      } else {
        path.lineTo(pontos[i].dx, pontos[i].dy);
      }
    }

    canvas.drawPath(path, linhaPaint);

    for (int i = 0; i < pontos.length; i++) {
      final ponto = pontos[i];

      canvas.drawCircle(
        ponto,
        i == indiceSelecionado ? 6 : 4,
        i == indiceSelecionado ? pontoSelecionadoPaint : pontoPaint,
      );
    }

    final pontoSelecionado = pontos[indiceSelecionado];
    final itemSelecionado = historico[indiceSelecionado];

    canvas.drawLine(
      Offset(pontoSelecionado.dx, margemTopo),
      Offset(pontoSelecionado.dx, margemTopo + areaAltura),
      linhaSelecionadaPaint,
    );

    textPainter.text = TextSpan(
      text: formatarMoeda(maior),
      style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      const Offset(0, margemTopo - 6),
    );

    textPainter.text = TextSpan(
      text: formatarMoeda(menor),
      style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(0, margemTopo + areaAltura - 8),
    );

    textPainter.text = TextSpan(
      text: formatarMoeda(itemSelecionado.melhorPrecoComparacao),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF9800),
      ),
    );
    textPainter.layout();

    double labelX = pontoSelecionado.dx - textPainter.width / 2;

    if (labelX < margemEsquerda) {
      labelX = margemEsquerda;
    }

    if (labelX + textPainter.width > size.width - margemDireita) {
      labelX = size.width - margemDireita - textPainter.width;
    }

    textPainter.paint(
      canvas,
      Offset(labelX, margemTopo + areaAltura + 10),
    );
  }

  @override
  bool shouldRepaint(
    covariant _GraficoHistoricoPrecoPainterMelhorado oldDelegate,
  ) {
    return oldDelegate.historico != historico ||
        oldDelegate.indiceSelecionado != indiceSelecionado;
  }
}