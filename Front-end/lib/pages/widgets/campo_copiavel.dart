import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoCopiavel extends StatelessWidget {
  final String titulo;
  final String? valor;
  final IconData icone;

  const CampoCopiavel({
    super.key,
    required this.titulo,
    required this.valor,
    this.icone = Icons.copy,
  });

  @override
  Widget build(BuildContext context) {
    final texto = valor == null || valor!.trim().isEmpty
        ? 'Não informado'
        : valor!.trim();

    final podeCopiar = valor != null && valor!.trim().isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: SelectableText(texto),
      trailing: IconButton(
        icon: Icon(icone),
        tooltip: 'Copiar',
        onPressed: podeCopiar
            ? () async {
                await Clipboard.setData(
                  ClipboardData(text: texto),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$titulo copiado.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            : null,
      ),
    );
  }
}