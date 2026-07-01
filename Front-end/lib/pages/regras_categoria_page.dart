import 'package:flutter/material.dart';

import '../models/produto_classificacao_model.dart';
import '../models/regra_categoria_model.dart';
import '../services/api_service.dart';

class RegrasCategoriaPage extends StatefulWidget {
  const RegrasCategoriaPage({super.key});

  @override
  State<RegrasCategoriaPage> createState() => _RegrasCategoriaPageState();
}

class _RegrasCategoriaPageState extends State<RegrasCategoriaPage> {
  final ApiService _apiService = ApiService();

  final TextEditingController _buscaRegraController = TextEditingController();
  final TextEditingController _buscaProdutoController = TextEditingController();
  final TextEditingController _categoriaProdutoController =
      TextEditingController();

  late Future<List<RegraCategoriaModel>> _futureRegras;

  List<ProdutoClassificacaoModel> _produtosClassificados = [];
  bool _buscandoProdutos = false;
  String? _erroBuscaProdutos;

  @override
  void initState() {
    super.initState();
    _futureRegras = _apiService.listarRegrasCategoria();
  }

  @override
  void dispose() {
    _buscaRegraController.dispose();
    _buscaProdutoController.dispose();
    _categoriaProdutoController.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    setState(() {
      _futureRegras = _apiService.listarRegrasCategoria();
    });
  }

  List<RegraCategoriaModel> _filtrarRegras(
    List<RegraCategoriaModel> regras,
  ) {
    final busca = _buscaRegraController.text.trim().toLowerCase();

    if (busca.isEmpty) {
      return regras;
    }

    return regras.where((regra) {
      final palavra = regra.palavraChave.toLowerCase();
      final categoria = regra.categoria.toLowerCase();

      return palavra.contains(busca) || categoria.contains(busca);
    }).toList();
  }

  Future<void> _buscarProdutosClassificados() async {
    setState(() {
      _buscandoProdutos = true;
      _erroBuscaProdutos = null;
    });

    try {
      final resultado = await _apiService.buscarProdutosClassificados(
        nome: _buscaProdutoController.text,
        categoria: _categoriaProdutoController.text,
      );

      if (!mounted) return;

      setState(() {
        _produtosClassificados = resultado;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erroBuscaProdutos = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _buscandoProdutos = false;
      });
    }
  }

  Future<void> _abrirFormulario({RegraCategoriaModel? regra}) async {
    final palavraController = TextEditingController(
      text: regra?.palavraChave ?? '',
    );

    final categoriaController = TextEditingController(
      text: regra?.categoria ?? '',
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        final editando = regra != null;

        return AlertDialog(
          title: Text(editando ? 'Editar regra' : 'Nova regra'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: palavraController,
                  decoration: const InputDecoration(
                    labelText: 'Palavra-chave',
                    hintText: 'Ex: imperio, omo, sadia',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Ex: Bebidas, Limpeza, Carnes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(editando ? 'Salvar' : 'Criar'),
            ),
          ],
        );
      },
    );

    if (resultado != true) {
      palavraController.dispose();
      categoriaController.dispose();
      return;
    }

    final palavraChave = palavraController.text.trim();
    final categoria = categoriaController.text.trim();

    palavraController.dispose();
    categoriaController.dispose();

    if (palavraChave.isEmpty || categoria.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha palavra-chave e categoria.'),
        ),
      );
      return;
    }

    try {
      if (regra == null) {
        await _apiService.criarRegraCategoria(
          palavraChave: palavraChave,
          categoria: categoria,
        );
      } else {
        await _apiService.atualizarRegraCategoria(
          idRegra: regra.idRegra,
          palavraChave: palavraChave,
          categoria: categoria,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            regra == null
                ? 'Regra criada com sucesso.'
                : 'Regra atualizada com sucesso.',
          ),
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

  Future<void> _desativarRegra(RegraCategoriaModel regra) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Desativar regra'),
          content: Text(
            'Deseja desativar a regra "${regra.palavraChave}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desativar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    try {
      await _apiService.desativarRegraCategoria(regra.idRegra);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Regra desativada com sucesso.'),
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

  Color _corStatus(RegraCategoriaModel regra) {
    return regra.ativo ? Colors.green : Colors.grey;
  }

  String _textoStatus(RegraCategoriaModel regra) {
    return regra.ativo ? 'Ativa' : 'Inativa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regras de categoria'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova regra'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder<List<RegraCategoriaModel>>(
            future: _futureRegras,
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

              final regras = snapshot.data ?? [];
              final regrasFiltradas = _filtrarRegras(regras);

              return RefreshIndicator(
                onRefresh: _recarregar,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _BuscaRegrasCard(
                      controller: _buscaRegraController,
                      onChanged: () {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _BuscaProdutosClassificadosCard(
                      buscaProdutoController: _buscaProdutoController,
                      categoriaController: _categoriaProdutoController,
                      buscando: _buscandoProdutos,
                      erro: _erroBuscaProdutos,
                      produtos: _produtosClassificados,
                      onBuscar: _buscarProdutosClassificados,
                      onEditarRegra: (regra) => _abrirFormulario(regra: regra),
                      onRemoverRegra: _desativarRegra,
                    ),
                    const SizedBox(height: 16),
                    if (regras.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma regra cadastrada ainda.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (regrasFiltradas.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma regra encontrada para a busca.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...regrasFiltradas.map((regra) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _corStatus(regra),
                                child: const Icon(
                                  Icons.category,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                regra.palavraChave,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Categoria: ${regra.categoria}\n'
                                'Status: ${_textoStatus(regra)}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _abrirFormulario(regra: regra),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar regra',
                                  ),
                                  IconButton(
                                    onPressed: regra.ativo
                                        ? () => _desativarRegra(regra)
                                        : null,
                                    icon: const Icon(Icons.block),
                                    tooltip: 'Desativar regra',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BuscaRegrasCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _BuscaRegrasCard({
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
            labelText: 'Buscar regras',
            hintText: 'Ex: bebidas, imperio, limpeza, arroz...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
    );
  }
}

class _BuscaProdutosClassificadosCard extends StatelessWidget {
  final TextEditingController buscaProdutoController;
  final TextEditingController categoriaController;
  final bool buscando;
  final String? erro;
  final List<ProdutoClassificacaoModel> produtos;
  final VoidCallback onBuscar;
  final ValueChanged<RegraCategoriaModel> onEditarRegra;
  final ValueChanged<RegraCategoriaModel> onRemoverRegra;

  const _BuscaProdutosClassificadosCard({
    required this.buscaProdutoController,
    required this.categoriaController,
    required this.buscando,
    required this.erro,
    required this.produtos,
    required this.onBuscar,
    required this.onEditarRegra,
    required this.onRemoverRegra,
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
                'Buscar produtos classificados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: buscaProdutoController,
              decoration: const InputDecoration(
                labelText: 'Nome do produto',
                hintText: 'Ex: imperio, arroz, omo...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoriaController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                hintText: 'Ex: Bebidas, Limpeza, Alimentos...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: buscando ? null : onBuscar,
              icon: buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(buscando ? 'Buscando...' : 'Buscar produtos'),
            ),
            if (erro != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    erro!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            ],
            if (produtos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resultado: ${produtos.length} produto(s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: produtos.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final produto = produtos[index];

                  final idRegra = produto.idRegra;
                  final regra = idRegra == null
                      ? null
                      : RegraCategoriaModel(
                          idRegra: idRegra,
                          palavraChave: produto.palavraChaveRegra ?? '',
                          categoria: produto.categoriaRegra ?? produto.categoria,
                          ativo: true,
                        );

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(produto.idProduto.toString()),
                    ),
                    title: Text(
                      produto.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      regra == null
                          ? 'Categoria: ${produto.categoria}\nRegra: não identificada para este produto'
                          : 'Categoria: ${produto.categoria}\nRegra: ${regra.palavraChave} → ${regra.categoria}',
                    ),
                    isThreeLine: true,
                    trailing: regra == null
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => onEditarRegra(regra),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar regra usada neste produto',
                              ),
                              IconButton(
                                onPressed: () => onRemoverRegra(regra),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover regra usada neste produto',
                              ),
                            ],
                          ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}