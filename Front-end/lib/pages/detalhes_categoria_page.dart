import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/detalhe_categoria_model.dart';
import '../services/api_service.dart';
import 'detalhes_compra_page.dart';

class DetalhesCategoriaPage extends StatefulWidget {
  final String categoria;
  final int? ano;
  final int? mes;
  final int? idMercado;
  final String? dataInicio;
  final String? dataFim;

  const DetalhesCategoriaPage({
    super.key,
    required this.categoria,
    this.ano,
    this.mes,
    this.idMercado,
    this.dataInicio,
    this.dataFim,
  });

  @override
  State<DetalhesCategoriaPage> createState() => _DetalhesCategoriaPageState();
}

class _DetalhesCategoriaPageState extends State<DetalhesCategoriaPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _buscaController = TextEditingController();

  late Future<List<DetalheCategoriaModel>> _futureDetalhes;
  String _buscaProduto = '';

  @override
  void initState() {
    super.initState();
    _futureDetalhes = _buscarDetalhes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<List<DetalheCategoriaModel>> _buscarDetalhes() {
    return _apiService.buscarDetalhesPorCategoria(
      categoria: widget.categoria,
      ano: widget.ano,
      mes: widget.mes,
      idMercado: widget.idMercado,
      dataInicio: widget.dataInicio,
      dataFim: widget.dataFim,
    );
  }

  Future<void> _recarregar() async {
    setState(() {
      _futureDetalhes = _buscarDetalhes();
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

      final hora = dateTime.hour.toString().padLeft(2, '0');
      final minuto = dateTime.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$ano $hora:$minuto';
    } catch (_) {
      return data;
    }
  }

  double _calcularTotal(List<DetalheCategoriaModel> itens) {
    return itens.fold(
      0.0,
      (total, item) => total + item.valorTotal,
    );
  }

  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  bool _produtoBateBusca(DetalheCategoriaModel item) {
    final busca = _normalizarTexto(_buscaProduto);
    if (busca.isEmpty) return false;

    final produto = _normalizarTexto(item.produtoNome);
    return produto.contains(busca);
  }

  List<DetalheCategoriaModel> _ordenarItensComBusca(
    List<DetalheCategoriaModel> itens,
  ) {
    final busca = _normalizarTexto(_buscaProduto);
    if (busca.isEmpty) return itens;

    final encontrados = itens.where(_produtoBateBusca).toList();
    final restantes = itens.where((item) => !_produtoBateBusca(item)).toList();

    return [...encontrados, ...restantes];
  }

  void _rolar(double delta) {
    if (!_scrollController.hasClients) return;

    final posicaoAtual = _scrollController.offset;
    final destino = (posicaoAtual + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    ).toDouble();

    _scrollController.animateTo(
      destino,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _onTecla(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final tecla = event.logicalKey;

    if (tecla == LogicalKeyboardKey.arrowDown) {
      _rolar(220);
      return KeyEventResult.handled;
    }

    if (tecla == LogicalKeyboardKey.arrowUp) {
      _rolar(-220);
      return KeyEventResult.handled;
    }

    if (tecla == LogicalKeyboardKey.pageDown) {
      _rolar(620);
      return KeyEventResult.handled;
    }

    if (tecla == LogicalKeyboardKey.pageUp) {
      _rolar(-620);
      return KeyEventResult.handled;
    }

    if (tecla == LogicalKeyboardKey.home && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return KeyEventResult.handled;
    }

    if (tecla == LogicalKeyboardKey.end && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categoria: ${widget.categoria}'),
        centerTitle: true,
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _onTecla,
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: _recarregar,
            child: FutureBuilder<List<DetalheCategoriaModel>>(
              future: _futureDetalhes,
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

                final itens = snapshot.data ?? [];

                if (itens.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhum item encontrado para esta categoria no período selecionado.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final total = _calcularTotal(itens);
                final itensOrdenados = _ordenarItensComBusca(itens);
                final quantidadeEncontrada =
                    itens.where(_produtoBateBusca).length;

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.categoria,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Itens encontrados: ${itens.length}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total: ${_formatarMoeda(total)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
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
                            Text(
                              'Pesquisar produto nesta categoria',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _buscaController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                labelText: 'Buscar produto',
                                hintText: 'Ex: carne suína, coca, arroz...',
                                helperText: _buscaProduto.trim().isEmpty
                                    ? 'Use as setas ↑ ↓, Page Up, Page Down, Home e End para navegar.'
                                    : quantidadeEncontrada == 0
                                        ? 'Nenhum produto encontrado com esse texto.'
                                        : '$quantidadeEncontrada produto(s) encontrado(s). Eles aparecem primeiro em verde.',
                                suffixIcon: _buscaProduto.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _buscaController.clear();
                                            _buscaProduto = '';
                                          });
                                          _keyboardFocusNode.requestFocus();
                                        },
                                      ),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _buscaProduto = value;
                                });
                              },
                              onSubmitted: (_) {
                                _keyboardFocusNode.requestFocus();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itensOrdenados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = itensOrdenados[index];
                        final encontrado = _produtoBateBusca(item);

                        return Card(
                          color: encontrado
                              ? Colors.green.withOpacity(0.14)
                              : null,
                          shape: encontrado
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.green.shade600,
                                    width: 1.6,
                                  ),
                                )
                              : null,
                          child: ListTile(
                            leading: encontrado
                                ? CircleAvatar(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    child: const Icon(Icons.search),
                                  )
                                : null,
                            title: Text(
                              encontrado
                                  ? '${item.produtoNome} • encontrado'
                                  : item.produtoNome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item.mercadoNome}\n'
                              '${_formatarData(item.dataCompra)}\n'
                              '${item.quantidade.toStringAsFixed(3)} ${item.unidade} • '
                              'Unitário: ${_formatarMoeda(item.valorUnitario)}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              _formatarMoeda(item.valorTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
      ),
    );
  }
}