import 'package:flutter/material.dart';

import '../models/compra_resumo_model.dart';
import '../models/mercado_model.dart';
import '../services/api_service.dart';
import 'detalhes_compra_page.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final ApiService _apiService = ApiService();

  final TextEditingController _valorMinimoController = TextEditingController();
  final TextEditingController _valorMaximoController = TextEditingController();
  final TextEditingController _formaPagamentoController =
      TextEditingController();
  final TextEditingController _buscaHistoricoController =
      TextEditingController();

  late Future<List<CompraResumoModel>> _futureCompras;

  List<MercadoModel> _mercados = [];
  int? _idMercadoSelecionado;
  int _paginaAtual = 0;
  final int _itensPorPagina = 10;

  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _futureCompras = _buscarCompras();
    _carregarMercados();
  }

  @override
  void dispose() {
    _valorMinimoController.dispose();
    _valorMaximoController.dispose();
    _formaPagamentoController.dispose();
    _buscaHistoricoController.dispose();
    super.dispose();
  }

  Future<void> _carregarMercados() async {
    try {
      final mercados = await _apiService.listarMercados();

      if (!mounted) return;

      setState(() {
        _mercados = mercados;
      });
    } catch (_) {
      // Se falhar, o histórico ainda funciona sem filtro de mercado.
    }
  }

  Future<List<CompraResumoModel>> _buscarCompras() {
    return _apiService.listarCompras(
      idMercado: _idMercadoSelecionado,
      dataInicio: _dataInicio == null ? null : _formatarDataIso(_dataInicio!),
      dataFim: _dataFim == null ? null : _formatarDataIso(_dataFim!),
      valorMinimo: _parseDoubleOuNull(_valorMinimoController.text),
      valorMaximo: _parseDoubleOuNull(_valorMaximoController.text),
      formaPagamento: _formaPagamentoController.text,
    );
  }

  Future<void> _recarregar() async {
    setState(() {
      _paginaAtual = 0;
      _futureCompras = _buscarCompras();
    });
  }

  void _aplicarFiltros() {
    setState(() {
      _paginaAtual = 0;
      _futureCompras = _buscarCompras();
    });
  }

  void _limparFiltros() {
    setState(() {
      _idMercadoSelecionado = null;
      _dataInicio = null;
      _dataFim = null;
      _valorMinimoController.clear();
      _valorMaximoController.clear();
      _formaPagamentoController.clear();
      _buscaHistoricoController.clear();
      _paginaAtual = 0;
      _futureCompras = _apiService.listarCompras();
    });
  }

  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data == null) return;

    setState(() {
      _dataInicio = data;
    });
  }

  Future<void> _selecionarDataFim() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data == null) return;

    setState(() {
      _dataFim = data;
    });
  }

  Future<void> _excluirCompra(CompraResumoModel compra) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir compra'),
          content: Text(
            'Deseja excluir a compra do mercado "${compra.mercadoNome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    try {
      await _apiService.excluirCompra(compra.idCompra);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra excluída com sucesso.'),
        ),
      );

      _recarregar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  double? _parseDoubleOuNull(String value) {
    final texto = value.trim().replaceAll(',', '.');

    if (texto.isEmpty) {
      return null;
    }

    return double.tryParse(texto);
  }

  String _formatarDataIso(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  String _formatarDataBr(DateTime? data) {
    if (data == null) {
      return 'Selecionar';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarDataCompra(String? data) {
    if (data == null || data.isEmpty) {
      return 'Data não informada';
    }

    try {
      final dateTime = DateTime.parse(data);

      final dia = dateTime.day.toString().padLeft(2, '0');
      final mes = dateTime.month.toString().padLeft(2, '0');
      final ano = dateTime.year.toString();

      final hora = dateTime.hour.toString().padLeft(2, '0');
      final minuto = dateTime.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$ano $hora:$minuto';
    } catch (_) {
      return data;
    }
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarProdutosHistorico(CompraResumoModel compra) {
    if (compra.nomesProdutos.isEmpty) {
      return '';
    }

    final produtosVisiveis = compra.nomesProdutos.take(4).join('\n- ');
    final restantes = compra.quantidadeItens - compra.nomesProdutos.take(4).length;
    final textoRestantes = restantes > 0 ? '\n+ $restantes produto(s)' : '';

    return '\n\nProdutos:\n- $produtosVisiveis$textoRestantes';
  }

  double _somarTotal(List<CompraResumoModel> compras) {
    return compras.fold<double>(
      0,
      (total, compra) => total + compra.valorTotal,
    );
  }


  List<CompraResumoModel> _filtrarPorBusca(List<CompraResumoModel> compras) {
    final busca = _normalizarTexto(_buscaHistoricoController.text);

    if (busca.isEmpty) {
      return compras;
    }

    return compras.where((compra) {
      final textoCompra = _normalizarTexto([
        compra.idCompra.toString(),
        compra.mercadoNome,
        compra.formaPagamento,
        compra.statusProcessamento,
        compra.dataCompra ?? '',
        ...compra.nomesProdutos,
      ].join(' '));

      return textoCompra.contains(busca);
    }).toList();
  }

  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de compras'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: RefreshIndicator(
            onRefresh: _recarregar,
            child: FutureBuilder<List<CompraResumoModel>>(
              future: _futureCompras,
              builder: (context, snapshot) {
                final compras = snapshot.data ?? [];
                final comprasFiltradas = _filtrarPorBusca(compras);
                final totalPaginas = comprasFiltradas.isEmpty
                    ? 1
                    : (comprasFiltradas.length / _itensPorPagina).ceil();
                if (_paginaAtual >= totalPaginas) {
                  _paginaAtual = totalPaginas - 1;
                }
                final inicioPagina = _paginaAtual * _itensPorPagina;
                final comprasPaginadas = comprasFiltradas
                    .skip(inicioPagina)
                    .take(_itensPorPagina)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _FiltrosHistoricoCard(
                      mercados: _mercados,
                      idMercadoSelecionado: _idMercadoSelecionado,
                      dataInicio: _dataInicio,
                      dataFim: _dataFim,
                      valorMinimoController: _valorMinimoController,
                      valorMaximoController: _valorMaximoController,
                      formaPagamentoController: _formaPagamentoController,
                      formatarDataBr: _formatarDataBr,
                      onMercadoChanged: (value) {
                        setState(() {
                          _idMercadoSelecionado = value;
                        });
                      },
                      onSelecionarDataInicio: _selecionarDataInicio,
                      onSelecionarDataFim: _selecionarDataFim,
                      onAplicar: _aplicarFiltros,
                      onLimpar: _limparFiltros,
                    ),

                    const SizedBox(height: 16),

                    _BuscaHistoricoCard(
                      controller: _buscaHistoricoController,
                      onChanged: (_) {
                        setState(() {
                          _paginaAtual = 0;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (snapshot.hasError)
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
                      )
                    else ...[
                      _ResumoHistoricoCard(
                        quantidadeCompras: comprasFiltradas.length,
                        total: _somarTotal(comprasFiltradas),
                        formatarMoeda: _formatarMoeda,
                      ),

                      const SizedBox(height: 16),

                      if (comprasFiltradas.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma compra encontrada com os filtros selecionados.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...comprasPaginadas.map((compra) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(compra.idCompra.toString()),
                                ),
                                title: Text(
                                  compra.mercadoNome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_formatarDataCompra(compra.dataCompra)}\n'
                                  '${compra.formaPagamento} • ${compra.statusProcessamento}'
                                  '${_formatarProdutosHistorico(compra)}',
                                ),
                                isThreeLine: false,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatarMoeda(compra.valorTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          _excluirCompra(compra),
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Excluir compra',
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalhesCompraPage(
                                        idCompra: compra.idCompra,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),

                      if (comprasFiltradas.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PaginacaoHistorico(
                          paginaAtual: _paginaAtual,
                          totalPaginas: totalPaginas,
                          totalItens: comprasFiltradas.length,
                          itensPorPagina: _itensPorPagina,
                          onAnterior: _paginaAtual == 0
                              ? null
                              : () {
                                  setState(() {
                                    _paginaAtual--;
                                  });
                                },
                          onProxima: _paginaAtual >= totalPaginas - 1
                              ? null
                              : () {
                                  setState(() {
                                    _paginaAtual++;
                                  });
                                },
                        ),
                      ],
                    ],
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


class _BuscaHistoricoCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BuscaHistoricoCard({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Buscar no histórico',
            hintText: 'Produto, mercado, forma de pagamento, data ou ID',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PaginacaoHistorico extends StatelessWidget {
  final int paginaAtual;
  final int totalPaginas;
  final int totalItens;
  final int itensPorPagina;
  final VoidCallback? onAnterior;
  final VoidCallback? onProxima;

  const _PaginacaoHistorico({
    required this.paginaAtual,
    required this.totalPaginas,
    required this.totalItens,
    required this.itensPorPagina,
    required this.onAnterior,
    required this.onProxima,
  });

  @override
  Widget build(BuildContext context) {
    final primeiroItem = totalItens == 0 ? 0 : paginaAtual * itensPorPagina + 1;
    final ultimoItem = (paginaAtual * itensPorPagina + itensPorPagina)
        .clamp(0, totalItens);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mostrando $primeiroItem-$ultimoItem de $totalItens compras • Página ${paginaAtual + 1} de $totalPaginas',
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAnterior,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onProxima,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Próxima'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltrosHistoricoCard extends StatelessWidget {
  final List<MercadoModel> mercados;
  final int? idMercadoSelecionado;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final TextEditingController valorMinimoController;
  final TextEditingController valorMaximoController;
  final TextEditingController formaPagamentoController;
  final String Function(DateTime? data) formatarDataBr;
  final void Function(int? value) onMercadoChanged;
  final VoidCallback onSelecionarDataInicio;
  final VoidCallback onSelecionarDataFim;
  final VoidCallback onAplicar;
  final VoidCallback onLimpar;

  const _FiltrosHistoricoCard({
    required this.mercados,
    required this.idMercadoSelecionado,
    required this.dataInicio,
    required this.dataFim,
    required this.valorMinimoController,
    required this.valorMaximoController,
    required this.formaPagamentoController,
    required this.formatarDataBr,
    required this.onMercadoChanged,
    required this.onSelecionarDataInicio,
    required this.onSelecionarDataFim,
    required this.onAplicar,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int?>(
              value: idMercadoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Mercado',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos os mercados'),
                ),
                ...mercados.map(
                  (mercado) => DropdownMenuItem<int?>(
                    value: mercado.idMercado,
                    child: Text(mercado.nome),
                  ),
                ),
              ],
              onChanged: onMercadoChanged,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSelecionarDataInicio,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('Início: ${formatarDataBr(dataInicio)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSelecionarDataFim,
                    icon: const Icon(Icons.event),
                    label: Text('Fim: ${formatarDataBr(dataFim)}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: valorMinimoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor mínimo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: valorMaximoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor máximo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: formaPagamentoController,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
                hintText: 'Ex: PIX, Cartão, Vale alimentação...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAplicar,
                    icon: const Icon(Icons.search),
                    label: const Text('Aplicar filtros'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onLimpar,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar filtros'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoHistoricoCard extends StatelessWidget {
  final int quantidadeCompras;
  final double total;
  final String Function(double valor) formatarMoeda;

  const _ResumoHistoricoCard({
    required this.quantidadeCompras,
    required this.total,
    required this.formatarMoeda,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            Text(
              'Compras encontradas: $quantidadeCompras',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total filtrado: ${formatarMoeda(total)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}