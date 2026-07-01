import 'package:flutter/material.dart';

import '../models/compras_por_mercado_model.dart';
import '../models/gastos_por_categoria_model.dart';
import '../services/api_service.dart';

enum TipoAnalisePeriodo {
  categorias,
  mercados,
}

class AnalisePeriodoPage extends StatefulWidget {
  final int? ano;
  final int? mes;
  final int? idMercado;
  final String? dataInicio;
  final String? dataFim;
  final String periodoTitulo;

  const AnalisePeriodoPage({
    super.key,
    this.ano,
    this.mes,
    this.idMercado,
    this.dataInicio,
    this.dataFim,
    required this.periodoTitulo,
  });

  @override
  State<AnalisePeriodoPage> createState() => _AnalisePeriodoPageState();
}

class _AnalisePeriodoPageState extends State<AnalisePeriodoPage> {
  final ApiService _apiService = ApiService();

  TipoAnalisePeriodo _tipoSelecionado = TipoAnalisePeriodo.categorias;

  List<GastosPorCategoriaModel> _categorias = [];
  List<ComprasPorMercadoModel> _mercados = [];

  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final categorias = await _apiService.buscarGastosPorCategoria(
        ano: widget.ano,
        mes: widget.mes,
        idMercado: widget.idMercado,
        dataInicio: widget.dataInicio,
        dataFim: widget.dataFim,
      );

      final mercados = await _apiService.buscarComprasPorMercado(
        ano: widget.ano,
        mes: widget.mes,
        idMercado: widget.idMercado,
        dataInicio: widget.dataInicio,
        dataFim: widget.dataFim,
      );

      if (!mounted) return;

      setState(() {
        _categorias = categorias;
        _mercados = mercados;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    }
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double _totalCategorias() {
    return _categorias.fold<double>(
      0,
      (total, item) => total + item.totalGasto,
    );
  }

  double _totalMercados() {
    return _mercados.fold<double>(
      0,
      (total, item) => total + item.totalGasto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final analisandoCategorias =
        _tipoSelecionado == TipoAnalisePeriodo.categorias;

    final itens = analisandoCategorias
        ? _categorias
            .map(
              (item) => _ItemAnalise(
                nome: item.categoriaNome,
                subtitulo:
                    '${item.quantidadeItens} item(ns) • ${item.quantidadeTotalProdutos.toStringAsFixed(3)} unidade(s)',
                valor: item.totalGasto,
              ),
            )
            .toList()
        : _mercados
            .map(
              (item) => _ItemAnalise(
                nome: item.mercadoNome,
                subtitulo: '${item.quantidadeCompras} compra(s)',
                valor: item.totalGasto,
              ),
            )
            .toList();

    final total = analisandoCategorias ? _totalCategorias() : _totalMercados();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise do período'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _carregarDados,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Análise do período',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.periodoTitulo.isEmpty
                              ? 'Período selecionado'
                              : widget.periodoTitulo,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatarMoeda(total),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SegmentedButton<TipoAnalisePeriodo>(
                  segments: const [
                    ButtonSegment(
                      value: TipoAnalisePeriodo.categorias,
                      icon: Icon(Icons.category_outlined),
                      label: Text('Categorias'),
                    ),
                    ButtonSegment(
                      value: TipoAnalisePeriodo.mercados,
                      icon: Icon(Icons.store_outlined),
                      label: Text('Mercados'),
                    ),
                  ],
                  selected: {_tipoSelecionado},
                  onSelectionChanged: (value) {
                    setState(() {
                      _tipoSelecionado = value.first;
                    });
                  },
                ),

                const SizedBox(height: 16),

                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_erro != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _erro!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  )
                else
                  _GraficoBarrasHorizontaisCard(
                    titulo: analisandoCategorias
                        ? 'Gastos por categoria'
                        : 'Gastos por mercado',
                    subtitulo: analisandoCategorias
                        ? 'Categorias com maior gasto no período.'
                        : 'Mercados onde você mais gastou no período.',
                    itens: itens,
                    formatarMoeda: _formatarMoeda,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemAnalise {
  final String nome;
  final String subtitulo;
  final double valor;

  _ItemAnalise({
    required this.nome,
    required this.subtitulo,
    required this.valor,
  });
}

class _GraficoBarrasHorizontaisCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<_ItemAnalise> itens;
  final String Function(double valor) formatarMoeda;

  const _GraficoBarrasHorizontaisCard({
    required this.titulo,
    required this.subtitulo,
    required this.itens,
    required this.formatarMoeda,
  });

  double _maiorValor() {
    if (itens.isEmpty) return 0;

    return itens.map((item) => item.valor).reduce((a, b) => a > b ? a : b);
  }

  double _total() {
    return itens.fold<double>(
      0,
      (total, item) => total + item.valor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maiorValor = _maiorValor();
    final total = _total();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(subtitulo),

            const SizedBox(height: 18),

            if (itens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nenhum dado encontrado para este período.'),
                ),
              )
            else
              ...itens.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                final proporcao =
                    maiorValor <= 0 ? 0.0 : item.valor / maiorValor;

                final percentual =
                    total <= 0 ? 0.0 : (item.valor / total) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _LinhaBarraAnalise(
                    posicao: index + 1,
                    item: item,
                    proporcao: proporcao,
                    percentual: percentual,
                    formatarMoeda: formatarMoeda,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _LinhaBarraAnalise extends StatelessWidget {
  final int posicao;
  final _ItemAnalise item;
  final double proporcao;
  final double percentual;
  final String Function(double valor) formatarMoeda;

  const _LinhaBarraAnalise({
    required this.posicao,
    required this.item,
    required this.proporcao,
    required this.percentual,
    required this.formatarMoeda,
  });

  @override
  Widget build(BuildContext context) {
    final larguraBarra = proporcao.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              child: Text(
                '$posicao',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatarMoeda(item.valor),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: Text(
            '${item.subtitulo} • ${percentual.toStringAsFixed(1).replaceAll('.', ',')}%',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      height: 14,
                      width: constraints.maxWidth * larguraBarra,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}