import 'package:flutter/material.dart';

import '../models/categoria_agrupamento_model.dart';
import '../services/api_service.dart';

class AgrupamentoCategoriasPage extends StatefulWidget {
  const AgrupamentoCategoriasPage({super.key});

  @override
  State<AgrupamentoCategoriasPage> createState() =>
      _AgrupamentoCategoriasPageState();
}

class _AgrupamentoCategoriasPageState
    extends State<AgrupamentoCategoriasPage> {
  final ApiService _apiService = ApiService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _nomeRelatorioController =
      TextEditingController();

  List<CategoriaAgrupamentoModel> _categorias = [];

  bool _carregando = false;
  bool _somenteSemGrupo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarCategorias();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeRelatorioController.dispose();
    super.dispose();
  }

  Future<void> _buscarCategorias() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _apiService.buscarCategoriasAgrupamento(
        nome: _nomeController.text,
        nomeRelatorio: _nomeRelatorioController.text,
        somenteSemGrupo: _somenteSemGrupo,
      );

      if (!mounted) return;

      setState(() {
        _categorias = resultado;
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

  void _limparFiltros() {
    setState(() {
      _nomeController.clear();
      _nomeRelatorioController.clear();
      _somenteSemGrupo = false;
    });

    _buscarCategorias();
  }

  Future<void> _editarAgrupamento(
    CategoriaAgrupamentoModel categoria,
  ) async {
    final controller = TextEditingController(
      text: categoria.nomeRelatorio ?? '',
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
                    categoria.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nome no relatório',
                    hintText: 'Ex: Carnes, Bebidas, Doces...',
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
          content: Text('Informe um nome para aparecer no relatório.'),
        ),
      );
      return;
    }

    try {
      await _apiService.atualizarAgrupamentoCategoria(
        idCategoria: categoria.idCategoria,
        nomeRelatorio: resultado.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrupamento atualizado com sucesso.'),
        ),
      );

      _buscarCategorias();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _removerAgrupamento(
    CategoriaAgrupamentoModel categoria,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover agrupamento'),
          content: Text(
            'Deseja remover o agrupamento da categoria "${categoria.nome}"?',
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
      await _apiService.removerAgrupamentoCategoria(categoria.idCategoria);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrupamento removido com sucesso.'),
        ),
      );

      _buscarCategorias();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Color _corAgrupamento(CategoriaAgrupamentoModel categoria) {
    final agrupada = categoria.nomeRelatorio != null &&
        categoria.nomeRelatorio!.trim().isNotEmpty;

    return agrupada ? Colors.green : Colors.grey;
  }

  String _textoAgrupamento(CategoriaAgrupamentoModel categoria) {
    final agrupada = categoria.nomeRelatorio != null &&
        categoria.nomeRelatorio!.trim().isNotEmpty;

    if (agrupada) {
      return categoria.nomeRelatorio!;
    }

    return 'Sem agrupamento';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agrupamento de categorias'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _FiltrosAgrupamentoCategoriasCard(
                nomeController: _nomeController,
                nomeRelatorioController: _nomeRelatorioController,
                somenteSemGrupo: _somenteSemGrupo,
                carregando: _carregando,
                onSomenteSemGrupoChanged: (value) {
                  setState(() {
                    _somenteSemGrupo = value ?? false;
                  });
                },
                onBuscar: _buscarCategorias,
                onLimpar: _limparFiltros,
              ),

              const SizedBox(height: 16),

              if (_erro != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _erro!,
                      style: TextStyle(color: Colors.red.shade900),
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
                _ResumoAgrupamentoCategoriasCard(
                  quantidade: _categorias.length,
                ),

                const SizedBox(height: 16),

                if (_categorias.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma categoria encontrada.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ..._categorias.map((categoria) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _corAgrupamento(categoria),
                            child: const Icon(
                              Icons.category_outlined,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            categoria.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Aparece no relatório como: ${_textoAgrupamento(categoria)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _editarAgrupamento(categoria),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar agrupamento',
                              ),
                              IconButton(
                                onPressed: categoria.nomeRelatorio == null ||
                                        categoria.nomeRelatorio!.trim().isEmpty
                                    ? null
                                    : () => _removerAgrupamento(categoria),
                                icon: const Icon(Icons.link_off),
                                tooltip: 'Remover agrupamento',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltrosAgrupamentoCategoriasCard extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController nomeRelatorioController;
  final bool somenteSemGrupo;
  final bool carregando;
  final void Function(bool? value) onSomenteSemGrupoChanged;
  final VoidCallback onBuscar;
  final VoidCallback onLimpar;

  const _FiltrosAgrupamentoCategoriasCard({
    required this.nomeController,
    required this.nomeRelatorioController,
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
                'Buscar categorias',
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
                hintText: 'Ex: carne, bebida, doce...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: nomeRelatorioController,
              decoration: const InputDecoration(
                labelText: 'Nome no relatório',
                hintText: 'Ex: Carnes, Bebidas, Doces...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            CheckboxListTile(
              value: somenteSemGrupo,
              onChanged: onSomenteSemGrupoChanged,
              title: const Text('Mostrar somente categorias sem agrupamento'),
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

class _ResumoAgrupamentoCategoriasCard extends StatelessWidget {
  final int quantidade;

  const _ResumoAgrupamentoCategoriasCard({
    required this.quantidade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Categorias encontradas: $quantidade',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}