import 'package:flutter/material.dart';

import '../models/item_extraido_model.dart';
import '../models/nota_leitura_model.dart';
import '../services/api_service.dart';

class ConferenciaCompraPage extends StatefulWidget {
  final NotaLeituraModel nota;

  const ConferenciaCompraPage({
    super.key,
    required this.nota,
  });

  @override
  State<ConferenciaCompraPage> createState() => _ConferenciaCompraPageState();
}

class _ConferenciaCompraPageState extends State<ConferenciaCompraPage> {
  final ApiService _apiService = ApiService();

  late final TextEditingController _mercadoNomeController;
  late final TextEditingController _mercadoCnpjController;
  late final TextEditingController _mercadoEnderecoController;
  late final TextEditingController _formaPagamentoController;
  late final TextEditingController _valorTotalController;

  final List<_ItemEditavel> _itens = [];

  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    final nota = widget.nota;

    _mercadoNomeController = TextEditingController(text: nota.mercadoNome);
    _mercadoCnpjController = TextEditingController(text: nota.mercadoCnpj);
    _mercadoEnderecoController = TextEditingController(text: nota.mercadoEndereco);
    _formaPagamentoController = TextEditingController(text: nota.formaPagamento);
    _valorTotalController = TextEditingController(
      text: nota.valorTotal.toStringAsFixed(2),
    );

    for (final item in nota.itens) {
      _itens.add(_ItemEditavel.fromItem(item));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
  _recalcularTotal();
});
  }

  @override
  void dispose() {
    _mercadoNomeController.dispose();
    _mercadoCnpjController.dispose();
    _mercadoEnderecoController.dispose();
    _formaPagamentoController.dispose();
    _valorTotalController.dispose();

    for (final item in _itens) {
      item.dispose();
    }

    super.dispose();
  }

  double _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatarMoeda(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

 void _recalcularTotal() {
  double totalCompra = 0;

  for (final item in _itens) {
    final quantidade = _parseDouble(item.quantidadeController.text);
    final valorUnitario = _parseDouble(item.valorUnitarioController.text);
    final valorTotalAtual = _parseDouble(item.valorTotalController.text);

    double valorTotalItem = valorTotalAtual;

    // Caso 1: tem quantidade e valor unitário, calcula o total.
    if (quantidade > 0 && valorUnitario > 0) {
      valorTotalItem = quantidade * valorUnitario;
      item.valorTotalController.text = valorTotalItem.toStringAsFixed(2);
    }

    // Caso 2: tem quantidade e valor total, mas unitário veio zerado.
    // Então calcula o unitário a partir do total.
    else if (quantidade > 0 && valorTotalAtual > 0 && valorUnitario == 0) {
      final valorUnitarioCalculado = valorTotalAtual / quantidade;
      item.valorUnitarioController.text = valorUnitarioCalculado.toStringAsFixed(2);
      valorTotalItem = valorTotalAtual;
    }

    // Caso 3: não tem dados suficientes.
    // Mantém o valor total atual, mesmo que seja 0.
    else {
      valorTotalItem = valorTotalAtual;
    }

    totalCompra += valorTotalItem;
  }

  setState(() {
    _valorTotalController.text = totalCompra.toStringAsFixed(2);
  });
}

  void _adicionarItem() {
    setState(() {
      _itens.add(_ItemEditavel.vazio());
    });
  }

  void _removerItem(int index) {
    setState(() {
      final item = _itens.removeAt(index);
      item.dispose();
      _recalcularTotal();
    });
  }

  NotaLeituraModel _montarNotaEditada() {
    final itensEditados = _itens.map((item) {
      return ItemExtraidoModel(
        nome: item.nomeController.text.trim().isEmpty
            ? 'Produto não identificado'
            : item.nomeController.text.trim(),
        quantidade: _parseDouble(item.quantidadeController.text),
        unidade: item.unidadeController.text.trim().isEmpty
            ? 'UN'
            : item.unidadeController.text.trim(),
        valorUnitario: _parseDouble(item.valorUnitarioController.text),
        valorTotal: _parseDouble(item.valorTotalController.text),
        categoria: item.categoriaController.text.trim().isEmpty
            ? 'Sem categoria'
            : item.categoriaController.text.trim(),
      );
    }).toList();

    return NotaLeituraModel(
      mercadoNome: _mercadoNomeController.text.trim().isEmpty
          ? 'Mercado não identificado'
          : _mercadoNomeController.text.trim(),
      mercadoCnpj: _mercadoCnpjController.text.trim(),
      mercadoEndereco: _mercadoEnderecoController.text.trim(),
      chaveAcesso: widget.nota.chaveAcesso,
      urlNota: widget.nota.urlNota,
      dataCompra: widget.nota.dataCompra,
      valorTotal: _parseDouble(_valorTotalController.text),
      formaPagamento: _formaPagamentoController.text.trim().isEmpty
          ? 'Não informado'
          : _formaPagamentoController.text.trim(),
      statusProcessamento: 'PROCESSADO',
      itens: itensEditados,
    );
  }

  Future<void> _salvarCompra() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final notaEditada = _montarNotaEditada();
      final mensagem = await _apiService.salvarCompra(notaEditada);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAtual = _parseDouble(_valorTotalController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferir compra'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Conferência antes de salvar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Revise os dados extraídos. Você pode corrigir qualquer informação antes de cadastrar no banco.',
              ),

              const SizedBox(height: 24),

              _DadosGeraisCard(
                mercadoNomeController: _mercadoNomeController,
                mercadoCnpjController: _mercadoCnpjController,
                mercadoEnderecoController: _mercadoEnderecoController,
                formaPagamentoController: _formaPagamentoController,
                valorTotalController: _valorTotalController,
              ),

              const SizedBox(height: 16),

              _ProdutosEditaveisCard(
                itens: _itens,
                onAdicionar: _adicionarItem,
                onRemover: _removerItem,
                onRecalcular: _recalcularTotal,
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Total da compra: R\$ ${_formatarMoeda(totalAtual)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (_erro != null) ...[
                const SizedBox(height: 16),
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
              ],

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _salvando ? null : _salvarCompra,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_salvando ? 'Salvando...' : 'Salvar compra'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DadosGeraisCard extends StatelessWidget {
  final TextEditingController mercadoNomeController;
  final TextEditingController mercadoCnpjController;
  final TextEditingController mercadoEnderecoController;
  final TextEditingController formaPagamentoController;
  final TextEditingController valorTotalController;

  const _DadosGeraisCard({
    required this.mercadoNomeController,
    required this.mercadoCnpjController,
    required this.mercadoEnderecoController,
    required this.formaPagamentoController,
    required this.valorTotalController,
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
                'Dados gerais',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: mercadoNomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do mercado',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: mercadoCnpjController,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: mercadoEnderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: formaPagamentoController,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: valorTotalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor total da compra',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProdutosEditaveisCard extends StatelessWidget {
  final List<_ItemEditavel> itens;
  final VoidCallback onAdicionar;
  final void Function(int index) onRemover;
  final VoidCallback onRecalcular;

  const _ProdutosEditaveisCard({
    required this.itens,
    required this.onAdicionar,
    required this.onRemover,
    required this.onRecalcular,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Produtos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: onAdicionar,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar produto'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (itens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum produto informado.'),
              ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final item = itens[index];

                return _ItemEditavelWidget(
                  numero: index + 1,
                  item: item,
                  onRemover: () => onRemover(index),
                  onRecalcular: onRecalcular,
                );
              },
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRecalcular,
                icon: const Icon(Icons.calculate),
                label: const Text('Recalcular total'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditavelWidget extends StatelessWidget {
  final int numero;
  final _ItemEditavel item;
  final VoidCallback onRemover;
  final VoidCallback onRecalcular;

  const _ItemEditavelWidget({
    required this.numero,
    required this.item,
    required this.onRemover,
    required this.onRecalcular,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Produto $numero',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            IconButton(
              onPressed: onRemover,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remover produto',
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextField(
          controller: item.nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome do produto',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: item.categoriaController,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: item.quantidadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                ),
                 onChanged: (_) => onRecalcular(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: TextField(
                controller: item.unidadeController,
                decoration: const InputDecoration(
                  labelText: 'Unidade',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: item.valorUnitarioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor unitário',
                  border: OutlineInputBorder(),
                ),
                  onChanged: (_) => onRecalcular(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: TextField(
                controller: item.valorTotalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor total',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onRecalcular(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemEditavel {
  final TextEditingController nomeController;
  final TextEditingController quantidadeController;
  final TextEditingController unidadeController;
  final TextEditingController valorUnitarioController;
  final TextEditingController valorTotalController;
  final TextEditingController categoriaController;

  _ItemEditavel({
    required this.nomeController,
    required this.quantidadeController,
    required this.unidadeController,
    required this.valorUnitarioController,
    required this.valorTotalController,
    required this.categoriaController,
  });

  factory _ItemEditavel.fromItem(ItemExtraidoModel item) {
    return _ItemEditavel(
      nomeController: TextEditingController(text: item.nome),
      quantidadeController: TextEditingController(
        text: item.quantidade.toStringAsFixed(3),
      ),
      unidadeController: TextEditingController(text: item.unidade),
      valorUnitarioController: TextEditingController(
        text: item.valorUnitario.toStringAsFixed(2),
      ),
      valorTotalController: TextEditingController(
        text: item.valorTotal.toStringAsFixed(2),
      ),
      categoriaController: TextEditingController(text: item.categoria),
    );
  }

  factory _ItemEditavel.vazio() {
    return _ItemEditavel(
      nomeController: TextEditingController(),
      quantidadeController: TextEditingController(text: '1.000'),
      unidadeController: TextEditingController(text: 'UN'),
      valorUnitarioController: TextEditingController(text: '0.00'),
      valorTotalController: TextEditingController(text: '0.00'),
      categoriaController: TextEditingController(text: 'Sem categoria'),
    );
  }

  void dispose() {
    nomeController.dispose();
    quantidadeController.dispose();
    unidadeController.dispose();
    valorUnitarioController.dispose();
    valorTotalController.dispose();
    categoriaController.dispose();
  }
}