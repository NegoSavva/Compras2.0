import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/campo_copiavel.dart';
import '../models/compra_detalhe_model.dart';
import '../services/api_service.dart';
import 'historico_preco_produto_page.dart';

class DetalhesCompraPage extends StatefulWidget {
  final int idCompra;
  final String? produtoDestacado;

  const DetalhesCompraPage({
    super.key,
    required this.idCompra,
    this.produtoDestacado,
  });

  @override
  State<DetalhesCompraPage> createState() => _DetalhesCompraPageState();
}

class _DetalhesCompraPageState extends State<DetalhesCompraPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  late Future<CompraDetalheModel> _futureCompra;

  @override
  void initState() {
    super.initState();
    _futureCompra = _apiService.buscarCompraPorId(widget.idCompra);
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
    super.dispose();
  }

  void _rolar(double delta) {
    if (!_scrollController.hasClients) return;

    final destino = (_scrollController.offset + delta).clamp(
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

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da compra'),
        centerTitle: true,
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _onTecla,
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder<CompraDetalheModel>(
            future: _futureCompra,
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

              final compra = snapshot.data;

              if (compra == null) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Compra não encontrada.'),
                      ),
                    ),
                  ],
                );
              }

              final veioDeProduto = widget.produtoDestacado != null &&
                  widget.produtoDestacado!.trim().isNotEmpty;

              final dadosCard = _DadosCompraCard(
                compra: compra,
                formatarData: _formatarData,
                formatarMoeda: _formatarMoeda,
              );

              final itensCard = _ItensCompraCard(
                compra: compra,
                formatarMoeda: _formatarMoeda,
                produtoDestacado: widget.produtoDestacado,
              );

              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                children: veioDeProduto
                    ? [
                        itensCard,
                        const SizedBox(height: 16),
                        dadosCard,
                      ]
                    : [
                        dadosCard,
                        const SizedBox(height: 16),
                        itensCard,
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

class _DadosCompraCard extends StatelessWidget {
  final CompraDetalheModel compra;
  final String Function(String?) formatarData;
  final String Function(double) formatarMoeda;

  const _DadosCompraCard({
    required this.compra,
    required this.formatarData,
    required this.formatarMoeda,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CampoCopiavel(
              titulo: 'Mercado',
              valor: compra.mercadoNome,
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'ID da compra',
              valor: compra.idCompra.toString(),
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'CNPJ',
              valor: compra.mercadoCnpj,
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'Endereço',
              valor: compra.mercadoEndereco,
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'Data da compra',
              valor: formatarData(compra.dataCompra),
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'Forma de pagamento',
              valor: compra.formaPagamento,
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'Status',
              valor: compra.statusProcessamento,
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'Chave de acesso',
              valor: compra.chaveAcesso,
            ),

            const Divider(),

            CampoCopiavel(
              titulo: 'URL da nota',
              valor: compra.urlNota,
            ),

            const Divider(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total: ${formatarMoeda(compra.valorTotal)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ItensCompraCard extends StatefulWidget {
  final CompraDetalheModel compra;
  final String Function(double) formatarMoeda;
  final String? produtoDestacado;

  const _ItensCompraCard({
    required this.compra,
    required this.formatarMoeda,
    this.produtoDestacado,
  });

  @override
  State<_ItensCompraCard> createState() => _ItensCompraCardState();
}

class _ItensCompraCardState extends State<_ItensCompraCard> {
  final Map<int, GlobalKey> _itemKeys = {};
  bool _rolagemExecutada = false;

  @override
  void didUpdateWidget(covariant _ItensCompraCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.produtoDestacado != widget.produtoDestacado ||
        oldWidget.compra.idCompra != widget.compra.idCompra) {
      _rolagemExecutada = false;
    }
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

  bool _ehProdutoSelecionado(String produtoAtual) {
    final produtoBuscado = widget.produtoDestacado;

    if (produtoBuscado == null || produtoBuscado.trim().isEmpty) {
      return false;
    }

    final atual = _normalizarTexto(produtoAtual);
    final buscado = _normalizarTexto(produtoBuscado);

    if (atual.isEmpty || buscado.isEmpty) {
      return false;
    }

    if (atual == buscado || atual.contains(buscado) || buscado.contains(atual)) {
      return true;
    }

    final palavrasBuscadas = buscado
        .split(' ')
        .where((palavra) => palavra.length >= 3)
        .toList();

    if (palavrasBuscadas.isEmpty) {
      return false;
    }

    final quantidadeEncontrada = palavrasBuscadas
        .where((palavra) => atual.contains(palavra))
        .length;

    return quantidadeEncontrada == palavrasBuscadas.length;
  }

  void _rolarParaProdutoSelecionado(int index) {
    if (_rolagemExecutada) return;

    _rolagemExecutada = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[index];
      final contextAlvo = key?.currentContext;

      if (contextAlvo == null) return;

      Scrollable.ensureVisible(
        contextAlvo,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
        alignment: 0.18,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compra.itens.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum item encontrado para esta compra.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Itens da compra',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.produtoDestacado != null && widget.produtoDestacado!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.my_location, size: 18),
                  label: Text('Produto selecionado: ${widget.produtoDestacado}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.compra.itens.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = widget.compra.itens[index];
                final destacado = _ehProdutoSelecionado(item.produtoNome);

                if (destacado) {
                  _itemKeys.putIfAbsent(index, () => GlobalKey());
                  _rolarParaProdutoSelecionado(index);
                }

                return Container(
                  key: destacado ? _itemKeys[index] : null,
                  decoration: destacado
                      ? BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.4,
                          ),
                        )
                      : null,
                  child: ListTile(
                    title: Text(
                      item.produtoNome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item.quantidade.toStringAsFixed(3)} ${item.unidade}\n'
                      'Categoria: ${item.categoriaNome}\n'
                      'Unitário: ${widget.formatarMoeda(item.valorUnitario)}'
                      '${item.precoPorUnidade > 0 ? '\nPreço normalizado: ${widget.formatarMoeda(item.precoPorUnidade)} / ${item.unidadeNormalizada}' : ''}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.formatarMoeda(item.valorTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          tooltip: 'Ver histórico de preços',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoricoPrecoProdutoPage(
                                  produtoNome: item.produtoNome,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copiar produto',
                          onPressed: () async {
                            final texto = '${item.produtoNome}\n'
                                'Categoria: ${item.categoriaNome}\n'
                                'Quantidade: ${item.quantidade.toStringAsFixed(3)} ${item.unidade}\n'
                                'Valor unitário: ${widget.formatarMoeda(item.valorUnitario)}\n'
                                '${item.precoPorUnidade > 0 ? 'Preço normalizado: ${widget.formatarMoeda(item.precoPorUnidade)} / ${item.unidadeNormalizada}\n' : ''}'
                                'Valor total: ${widget.formatarMoeda(item.valorTotal)}';

                            await Clipboard.setData(
                              ClipboardData(text: texto),
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Produto copiado.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
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
