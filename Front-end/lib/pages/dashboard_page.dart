import 'package:flutter/material.dart';

import '../app_theme_controller.dart';

import '../models/compras_por_mercado_model.dart';
import '../models/gasto_mensal_model.dart';
import '../models/gastos_por_categoria_model.dart';
import '../models/historico_gasto_mensal_model.dart';
import '../models/produto_mais_comprado_model.dart';
import '../services/api_service.dart';


import 'conferencia_compra_page.dart';
import 'qr_scanner_page.dart';

import '../models/nota_leitura_model.dart';
import '../services/api_service.dart';


import 'historico_page.dart';
import 'relatorios_page.dart';
import 'regras_categoria_page.dart';
import 'agrupamento_produtos_page.dart';
import 'agrupamento_categorias_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _urlController = TextEditingController();

  final ApiService _apiService = ApiService();
NotaLeituraModel? _nota;

bool _carregandoLeitura = false;

String? _erroLeitura;

  GastoMensalModel? _gastoMensal;
  List<HistoricoGastoMensalModel> _historicoMensal = [];
  List<ComprasPorMercadoModel> _mercados = [];
  List<GastosPorCategoriaModel> _categorias = [];
  List<ProdutoMaisCompradoModel> _produtos = [];

  bool _carregando = false;
  String? _erro;

  final int _anoAtual = DateTime.now().year;
  final int _mesAtual = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }
Future<void> _lerNota() async {
  final url = _urlController.text.trim();

  if (url.isEmpty) {
    setState(() {
      _erroLeitura = 'Cole a URL da NFC-e.';
    });

    return;
  }

  setState(() {
    _carregandoLeitura = true;
    _erroLeitura = null;
    _nota = null;
  });

  try {
    final nota = await _apiService.lerNota(url);

    setState(() {
      _nota = nota;
    });
  } catch (e) {
    setState(() {
      _erroLeitura =
          e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    setState(() {
      _carregandoLeitura = false;
    });
  }
}
  Future<void> _carregarDashboard() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final gastoMensal = await _apiService.buscarGastoMensal(
        ano: _anoAtual,
        mes: _mesAtual,
      );

      final historicoMensal = await _apiService.buscarHistoricoGastosMensais(
        ano: _anoAtual,
      );

      final mercados = await _apiService.buscarComprasPorMercado(
        ano: _anoAtual,
        mes: _mesAtual,
      );

      final categorias = await _apiService.buscarGastosPorCategoria(
        ano: _anoAtual,
        mes: _mesAtual,
      );

      final produtos = await _apiService.buscarProdutosMaisComprados(
        ano: _anoAtual,
        mes: _mesAtual,
      );

      if (!mounted) return;

      setState(() {
        _gastoMensal = gastoMensal;
        _historicoMensal = historicoMensal;
        _mercados = mercados;
        _categorias = categorias;
        _produtos = produtos;
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

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return meses[mes - 1];
  }

  ComprasPorMercadoModel? get _mercadoMaiorGasto {
    if (_mercados.isEmpty) return null;
    return _mercados.first;
  }

  GastosPorCategoriaModel? get _categoriaMaiorGasto {
    if (_categorias.isEmpty) return null;
    return _categorias.first;
  }

  ProdutoMaisCompradoModel? get _produtoMaisComprado {
    if (_produtos.isEmpty) return null;
    return _produtos.first;
  }

  double _maiorGastoMensal() {
    if (_historicoMensal.isEmpty) return 0;

    return _historicoMensal
        .map((item) => item.totalGasto)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final gasto = _gastoMensal;
    final mercado = _mercadoMaiorGasto;
    final categoria = _categoriaMaiorGasto;
    final produto = _produtoMaisComprado;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.pushNamed(
      context,
      '/ler-nota',
    );
  },
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text('Ler Nota'),
),
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppThemeController.themeMode,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return IconButton(
                onPressed: AppThemeController.toggleTheme,
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: isDark ? 'Usar tema claro' : 'Usar tema escuro',
              );
            },
          ),
          IconButton(
            onPressed: _carregando ? null : _carregarDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dashboard',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _carregarDashboard,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _DashboardHeroCard(
                  mes: _nomeMes(_mesAtual),
                  ano: _anoAtual,
                  total: gasto == null ? 'R\$ 0,00' : _formatarMoeda(gasto.totalGasto),
                  compras: gasto?.quantidadeCompras ?? 0,
                  categoria: categoria?.categoriaNome ?? 'Sem categoria',
                ),

                const SizedBox(height: 24),

                if (_erro != null)
                Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leitura de NFC-e',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'URL da NFC-e',
            hintText:
                'https://www.fazenda.sp.gov.br/nfce/qrcode?p=...',
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 3,
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _carregandoLeitura ? null : _lerNota,
                icon: _carregandoLeitura
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _carregandoLeitura
                      ? 'Lendo...'
                      : 'Ler nota',
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final urlLida =
                      await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const QrScannerPage(),
                    ),
                  );

                  if (!mounted) return;

                  if (urlLida == null ||
                      urlLida.trim().isEmpty) {
                    return;
                  }

                  _urlController.text = urlLida.trim();

                  await _lerNota();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR Code'),
              ),
            ),
          ],
        ),

        if (_erroLeitura != null) ...[
          const SizedBox(height: 16),

          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _erroLeitura!,
                style: TextStyle(
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  ),
),
if (_nota != null) ...[
  const SizedBox(height: 16),

  _ResumoNotaCard(nota: _nota!),

  const SizedBox(height: 16),

  _ItensNotaCard(nota: _nota!),

  const SizedBox(height: 16),

  FilledButton.icon(
    onPressed: () async {
      final salvou = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ConferenciaCompraPage(nota: _nota!),
        ),
      );

      if (!mounted) return;

      if (salvou == true) {
        setState(() {
          _nota = null;
          _urlController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compra cadastrada com sucesso.',
            ),
          ),
        );
      }
    },
    icon: const Icon(Icons.save),
    label: const Text('Conferir e salvar'),
  ),
],
                if (_erro != null)
  Card(
    color: Colors.red.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        _erro!,
        style: TextStyle(
          color: Colors.red.shade900,
        ),
      ),
    ),
  ),

                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _DashboardInfoCard(
                        titulo: 'Total gasto no mês',
                        valor: gasto == null
                            ? 'R\$ 0,00'
                            : _formatarMoeda(gasto.totalGasto),
                        subtitulo: gasto == null
                            ? 'Nenhuma compra'
                            : '${gasto.quantidadeCompras} compra(s)',
                        icone: Icons.payments_outlined,
                      ),
                      _DashboardInfoCard(
                        titulo: 'Categoria destaque',
                        valor: categoria?.categoriaNome ?? 'Sem dados',
                        subtitulo: categoria == null
                            ? 'Nenhuma categoria'
                            : _formatarMoeda(categoria.totalGasto),
                        icone: Icons.category_outlined,
                      ),
                      _DashboardInfoCard(
                        titulo: 'Mercado destaque',
                        valor: mercado?.mercadoNome ?? 'Sem dados',
                        subtitulo: mercado == null
                            ? 'Nenhum mercado'
                            : _formatarMoeda(mercado.totalGasto),
                        icone: Icons.store_outlined,
                      ),
                      _DashboardInfoCard(
                        titulo: 'Produto mais comprado',
                        valor: produto?.produtoNome ?? 'Sem dados',
                        subtitulo: produto == null
                            ? 'Nenhum produto'
                            : '${produto.quantidadeTotal.toStringAsFixed(3)} unid. • ${_formatarMoeda(produto.totalGasto)}',
                        icone: Icons.shopping_basket_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _DashboardGraficoMensalCard(
                    historico: _historicoMensal,
                    maiorValor: _maiorGastoMensal(),
                    formatarMoeda: _formatarMoeda,
                  ),

                  const SizedBox(height: 24),

                  _DashboardRankingsCard(
                    categorias: _categorias.take(5).toList(),
                    mercados: _mercados.take(5).toList(),
                    produtos: _produtos.take(5).toList(),
                    formatarMoeda: _formatarMoeda,
                  ),

                  const SizedBox(height: 24),

                  _AtalhosDashboardCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _DashboardHeroCard extends StatelessWidget {
  final String mes;
  final int ano;
  final String total;
  final int compras;
  final String categoria;

  const _DashboardHeroCard({
    required this.mes,
    required this.ano,
    required this.total,
    required this.compras,
    required this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF14532D), const Color(0xFF0F172A)]
              : [scheme.primaryContainer, Colors.white],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( isDark ? 0.18 : 0.07),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usarColuna = constraints.maxWidth < 720;

          final resumo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo de $mes de $ano',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Acompanhe suas compras, categorias, mercados e evolução dos gastos em um painel mais limpo.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity( 0.78),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroChip(icon: Icons.receipt_long_outlined, text: '$compras compra(s)'),
                  _HeroChip(icon: Icons.category_outlined, text: categoria),
                ],
              ),
            ],
          );

          final valor = Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity( 0.08) : Colors.white.withOpacity( 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity( 0.10) : Colors.white,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total gasto no mês'),
                const SizedBox(height: 8),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Atualizado com suas compras salvas',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity( 0.72),
                  ),
                ),
              ],
            ),
          );

          if (usarColuna) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [resumo, const SizedBox(height: 18), valor],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: resumo),
              const SizedBox(width: 20),
              SizedBox(width: 320, child: valor),
            ],
          );
        },
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity( 0.08) : Colors.white.withOpacity( 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DashboardInfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;

  const _DashboardInfoCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  icone,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                valor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _DashboardGraficoMensalCard extends StatelessWidget {
  final List<HistoricoGastoMensalModel> historico;
  final double maiorValor;
  final String Function(double valor) formatarMoeda;

  const _DashboardGraficoMensalCard({
    required this.historico,
    required this.maiorValor,
    required this.formatarMoeda,
  });

  String _nomeMesCurto(int mes) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos ao longo do ano',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Veja como seus gastos estão distribuídos mês a mês.',
            ),

            const SizedBox(height: 22),

            if (historico.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum dado mensal encontrado.'),
              )
            else
              SizedBox(
                height: 230,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: historico.map((item) {
                    final temGasto = item.totalGasto > 0;
                    final proporcao = maiorValor <= 0
                        ? 0.0
                        : item.totalGasto / maiorValor;

                    final altura = temGasto
                        ? (150 * proporcao).clamp(6.0, 150.0)
                        : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Tooltip(
                          message:
                              '${item.periodo}\n${formatarMoeda(item.totalGasto)}\n${item.quantidadeCompras} compra(s)',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                formatarMoeda(item.totalGasto),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: altura,
                                width: 24,
                                decoration: BoxDecoration(
                                  color: temGasto
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _nomeMesCurto(item.mes),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRankingsCard extends StatelessWidget {
  final List<GastosPorCategoriaModel> categorias;
  final List<ComprasPorMercadoModel> mercados;
  final List<ProdutoMaisCompradoModel> produtos;
  final String Function(double valor) formatarMoeda;

  const _DashboardRankingsCard({
    required this.categorias,
    required this.mercados,
    required this.produtos,
    required this.formatarMoeda,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rankings do mês',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final usarColuna = constraints.maxWidth < 760;

                final children = [
                  _RankingColuna(
                    titulo: 'Categorias',
                    itens: categorias
                        .map(
                          (item) => _RankingItem(
                            nome: item.categoriaNome,
                            valor: formatarMoeda(item.totalGasto),
                          ),
                        )
                        .toList(),
                  ),
                  _RankingColuna(
                    titulo: 'Mercados',
                    itens: mercados
                        .map(
                          (item) => _RankingItem(
                            nome: item.mercadoNome,
                            valor: formatarMoeda(item.totalGasto),
                          ),
                        )
                        .toList(),
                  ),
                  _RankingColuna(
                    titulo: 'Produtos',
                    itens: produtos
                        .map(
                          (item) => _RankingItem(
                            nome: item.produtoNome,
                            valor: formatarMoeda(item.totalGasto),
                          ),
                        )
                        .toList(),
                  ),
                ];

                if (usarColuna) {
                  return Column(
                    children: children
                        .map(
                          (child) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: child,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .map(
                        (child) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: child,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingColuna extends StatelessWidget {
  final String titulo;
  final List<_RankingItem> itens;

  const _RankingColuna({
    required this.titulo,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (itens.isEmpty)
          const Text('Sem dados.')
        else
          ...itens.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                child: Text('${index + 1}'),
              ),
              title: Text(
                item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                item.valor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
      ],
    );
  }
}

class _RankingItem {
  final String nome;
  final String valor;

  _RankingItem({
    required this.nome,
    required this.valor,
  });
}

class _AtalhosDashboardCard extends StatelessWidget {
  const _AtalhosDashboardCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atalhos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AtalhoDashboardButton(
                  texto: 'Relatórios',
                  icone: Icons.analytics_outlined,
                  page: const RelatoriosPage(),
                ),
                _AtalhoDashboardButton(
                  texto: 'Histórico',
                  icone: Icons.history,
                  page: const HistoricoPage(),
                ),
                _AtalhoDashboardButton(
                  texto: 'Regras de categoria',
                  icone: Icons.rule,
                  page: const RegrasCategoriaPage(),
                ),
                _AtalhoDashboardButton(
                  texto: 'Agrupar produtos',
                  icone: Icons.inventory_2_outlined,
                  page: const AgrupamentoProdutosPage(),
                ),
                _AtalhoDashboardButton(
                  texto: 'Agrupar categorias',
                  icone: Icons.category_outlined,
                  page: const AgrupamentoCategoriasPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _ResumoNotaCard extends StatelessWidget {
  final NotaLeituraModel nota;

  const _ResumoNotaCard({required this.nota});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados da compra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _LinhaResumo(label: 'Mercado', valor: nota.mercadoNome),
            _LinhaResumo(label: 'CNPJ', valor: nota.mercadoCnpj),
            _LinhaResumo(label: 'Endereço', valor: nota.mercadoEndereco),
            _LinhaResumo(label: 'Chave de acesso', valor: nota.chaveAcesso ?? 'Não identificada'),
            _LinhaResumo(label: 'Forma de pagamento', valor: nota.formaPagamento),
            _LinhaResumo(label: 'Status', valor: nota.statusProcessamento),

            const Divider(height: 32),

            Text(
              'Total: R\$ ${nota.valorTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItensNotaCard extends StatelessWidget {
  final NotaLeituraModel nota;

  const _ItensNotaCard({required this.nota});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Produtos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nota.itens.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = nota.itens[index];

                return ListTile(
                  title: Text(item.nome),
                  subtitle: Text(
                    '${item.quantidade.toStringAsFixed(3)} ${item.unidade} • ${item.categoria}',
                  ),
                  trailing: Text(
                    'R\$ ${item.valorTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
class _LinhaResumo extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaResumo({
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}
class _AtalhoDashboardButton extends StatelessWidget {
  final String texto;
  final IconData icone;
  final Widget page;

  const _AtalhoDashboardButton({
    required this.texto,
    required this.icone,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      icon: Icon(icone),
      label: Text(texto),
    );
  }
}
