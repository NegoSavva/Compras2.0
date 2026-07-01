import 'package:flutter/material.dart';
import 'conferencia_compra_page.dart';
import '../models/nota_leitura_model.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';
import 'qr_scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();

  NotaLeituraModel? _nota;
  bool _carregando = false;
  String? _erro;

  Future<void> _lerNota() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _erro = 'Cole a URL da NFC-e antes de continuar.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
      _nota = null;
    });

    try {
      final nota = await _apiService.lerNota(url);

      setState(() {
        _nota = nota;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }


  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nota = _nota;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de nota'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Leitura de NFC-e',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Escaneie o QR Code pela câmera ou cole manualmente a URL da NFC-e.',
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DashboardPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para o dashboard'),
              ),

              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: () async {
                  final urlLida = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QrScannerPage(),
                    ),
                  );

                  if (!context.mounted) return;

                  if (urlLida == null || urlLida.trim().isEmpty) {
                    return;
                  }

                  _urlController.text = urlLida.trim();

                  await _lerNota();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear nota pela câmera'),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL da NFC-e',
                  hintText: 'https://www.fazenda.sp.gov.br/nfce/qrcode?p=...',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _carregando ? null : _lerNota,
                icon: _carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: Text(_carregando ? 'Lendo nota...' : 'Ler nota'),
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

              if (nota != null) ...[
                const SizedBox(height: 24),
                _ResumoNotaCard(nota: nota),
                const SizedBox(height: 16),
                _ItensNotaCard(nota: nota),
                const SizedBox(height: 16),
                ElevatedButton.icon(
  onPressed: () async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConferenciaCompraPage(nota: nota),
      ),
    );

    if (!context.mounted) return;

    if (salvou == true) {
      setState(() {
        _nota = null;
        _urlController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra cadastrada. Você pode vê-la no histórico.'),
        ),
      );
    }
  },
  icon: const Icon(Icons.edit_note),
  label: const Text('Conferir e editar antes de salvar'),
),
              ],
            ],
          ),
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