import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/produto_agrupamento_model.dart';
import '../services/api_service.dart';

class AgrupamentoProdutosPage extends StatefulWidget {
  const AgrupamentoProdutosPage({super.key});

  @override
  State<AgrupamentoProdutosPage> createState() =>
      _AgrupamentoProdutosPageState();
}

class _AgrupamentoProdutosPageState extends State<AgrupamentoProdutosPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _nomeRelatorioController =
      TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  List<ProdutoAgrupamentoModel> _produtos = [];

  bool _carregando = false;
  bool _somenteSemGrupo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarProdutos();
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
    _nomeController.dispose();
    _nomeRelatorioController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  bool _temAgrupamento(ProdutoAgrupamentoModel produto) {
    return produto.nomeRelatorio != null &&
        produto.nomeRelatorio!.trim().isNotEmpty;
  }

  List<ProdutoAgrupamentoModel> get _produtosAgrupados {
    final lista = _produtos.where(_temAgrupamento).toList();
    lista.sort((a, b) {
      final grupoA = a.nomeRelatorio!.toLowerCase();
      final grupoB = b.nomeRelatorio!.toLowerCase();
      final grupoCompare = grupoA.compareTo(grupoB);
      if (grupoCompare != 0) return grupoCompare;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return lista;
  }

  List<ProdutoAgrupamentoModel> get _produtosSemAgrupamento {
    final lista = _produtos.where((produto) => !_temAgrupamento(produto)).toList();
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  Map<String, List<ProdutoAgrupamentoModel>> get _gruposProdutos {
    final grupos = <String, List<ProdutoAgrupamentoModel>>{};

    for (final produto in _produtosAgrupados) {
      final nomeGrupo = produto.nomeRelatorio!.trim();
      grupos.putIfAbsent(nomeGrupo, () => <ProdutoAgrupamentoModel>[]);
      grupos[nomeGrupo]!.add(produto);
    }

    final entradasOrdenadas = grupos.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return Map.fromEntries(entradasOrdenadas);
  }

  Future<void> _buscarProdutos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _apiService.buscarProdutosAgrupamento(
        nome: _nomeController.text,
        nomeRelatorio: _nomeRelatorioController.text,
        categoria: _categoriaController.text,
        somenteSemGrupo: _somenteSemGrupo,
      );

      if (!mounted) return;

      setState(() {
        _produtos = resultado;
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

  void _limparFiltros() {
    setState(() {
      _nomeController.clear();
      _nomeRelatorioController.clear();
      _categoriaController.clear();
      _somenteSemGrupo = false;
    });

    _buscarProdutos();
  }

  Future<void> _editarAgrupamento(ProdutoAgrupamentoModel produto) async {
    final controller = TextEditingController(
      text: produto.nomeRelatorio ?? '',
    );

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar agrupamento'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    produto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nome agrupado',
                    hintText: 'Ex: Detergente, Arroz, Sabonete...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (resultado == null) return;

    if (resultado.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um nome agrupado.'),
        ),
      );
      return;
    }

    try {
      await _apiService.atualizarAgrupamentoProduto(
        idProduto: produto.idProduto,
        nomeRelatorio: resultado.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrupamento atualizado com sucesso.'),
        ),
      );

      _buscarProdutos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _removerAgrupamento(ProdutoAgrupamentoModel produto) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover agrupamento'),
          content: Text(
            'Deseja remover o agrupamento do produto "${produto.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    try {
      await _apiService.removerAgrupamentoProduto(produto.idProduto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrupamento removido com sucesso.'),
        ),
      );

      _buscarProdutos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Widget _buildSecaoTitulo({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitulo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupoProdutosCard(
    String nomeGrupo,
    List<ProdutoAgrupamentoModel> produtos,
  ) {
    final categoriaPrincipal = produtos.first.categoria;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: const CircleAvatar(
            child: Icon(Icons.inventory_2_outlined),
          ),
          title: Text(
            nomeGrupo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${produtos.length} produto(s) agrupado(s) • Categoria: $categoriaPrincipal',
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Produtos completos dentro deste grupo:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            ...produtos.map(
              (produto) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: const Icon(Icons.subdirectory_arrow_right),
                title: Text(
                  produto.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Categoria: ${produto.categoria}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editarAgrupamento(produto),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar agrupamento deste produto',
                    ),
                    IconButton(
                      onPressed: () => _removerAgrupamento(produto),
                      icon: const Icon(Icons.link_off),
                      tooltip: 'Remover deste grupo',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoSemAgrupamentoCard(ProdutoAgrupamentoModel produto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.link_off),
          ),
          title: Text(
            produto.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Agrupado como: Sem agrupamento\n'
            'Categoria: ${produto.categoria}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            onPressed: () => _editarAgrupamento(produto),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Criar agrupamento',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gruposProdutos = _gruposProdutos;
    final produtosSemAgrupamento = _produtosSemAgrupamento;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agrupamento de produtos'),
        centerTitle: true,
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _onTecla,
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
            children: [
              _FiltrosAgrupamentoProdutosCard(
                nomeController: _nomeController,
                nomeRelatorioController: _nomeRelatorioController,
                categoriaController: _categoriaController,
                somenteSemGrupo: _somenteSemGrupo,
                carregando: _carregando,
                onSomenteSemGrupoChanged: (value) {
                  setState(() {
                    _somenteSemGrupo = value ?? false;
                  });
                },
                onBuscar: _buscarProdutos,
                onLimpar: _limparFiltros,
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dica: use ↑ ↓, Page Up, Page Down, Home e End para navegar pela página.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 16),

              if (_erro != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _erro!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
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
                _ResumoAgrupamentoProdutosCard(
                  quantidadeTotal: _produtos.length,
                  quantidadeAgrupados: _produtosAgrupados.length,
                  quantidadeSemAgrupamento: produtosSemAgrupamento.length,
                  quantidadeGrupos: gruposProdutos.length,
                ),

                const SizedBox(height: 16),

                if (_produtos.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum produto encontrado.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  if (gruposProdutos.isNotEmpty) ...[
                    _buildSecaoTitulo(
                      icon: Icons.folder_copy_outlined,
                      titulo: 'Produtos já agrupados',
                      subtitulo:
                          'Os grupos aparecem primeiro e mostram os nomes completos dos produtos dentro deles.',
                    ),
                    ...gruposProdutos.entries.map(
                      (entry) => _buildGrupoProdutosCard(entry.key, entry.value),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (produtosSemAgrupamento.isNotEmpty) ...[
                    _buildSecaoTitulo(
                      icon: Icons.playlist_add_outlined,
                      titulo: 'Produtos sem agrupamento',
                      subtitulo:
                          'Produtos que ainda não possuem nome agrupado para relatórios.',
                    ),
                    ...produtosSemAgrupamento.map(_buildProdutoSemAgrupamentoCard),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _FiltrosAgrupamentoProdutosCard extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController nomeRelatorioController;
  final TextEditingController categoriaController;
  final bool somenteSemGrupo;
  final bool carregando;
  final void Function(bool? value) onSomenteSemGrupoChanged;
  final VoidCallback onBuscar;
  final VoidCallback onLimpar;

  const _FiltrosAgrupamentoProdutosCard({
    required this.nomeController,
    required this.nomeRelatorioController,
    required this.categoriaController,
    required this.somenteSemGrupo,
    required this.carregando,
    required this.onSomenteSemGrupoChanged,
    required this.onBuscar,
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
                'Buscar produtos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome original',
                hintText: 'Ex: det, limpol, feij, arroz...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: nomeRelatorioController,
              decoration: const InputDecoration(
                labelText: 'Nome agrupado',
                hintText: 'Ex: Detergente, Feijão, Arroz...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: categoriaController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                hintText: 'Ex: Limpeza, Bebidas, Alimentos...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            CheckboxListTile(
              value: somenteSemGrupo,
              onChanged: onSomenteSemGrupoChanged,
              title: const Text('Mostrar somente produtos sem agrupamento'),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: carregando ? null : onBuscar,
                    icon: carregando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(carregando ? 'Buscando...' : 'Buscar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: carregando ? null : onLimpar,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar'),
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

class _ResumoAgrupamentoProdutosCard extends StatelessWidget {
  final int quantidadeTotal;
  final int quantidadeAgrupados;
  final int quantidadeSemAgrupamento;
  final int quantidadeGrupos;

  const _ResumoAgrupamentoProdutosCard({
    required this.quantidadeTotal,
    required this.quantidadeAgrupados,
    required this.quantidadeSemAgrupamento,
    required this.quantidadeGrupos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ResumoChip(
              icon: Icons.inventory_2_outlined,
              texto: 'Produtos encontrados: $quantidadeTotal',
            ),
            _ResumoChip(
              icon: Icons.folder_copy_outlined,
              texto: 'Grupos: $quantidadeGrupos',
            ),
            _ResumoChip(
              icon: Icons.link,
              texto: 'Agrupados: $quantidadeAgrupados',
            ),
            _ResumoChip(
              icon: Icons.link_off,
              texto: 'Sem agrupamento: $quantidadeSemAgrupamento',
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoChip extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _ResumoChip({
    required this.icon,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
