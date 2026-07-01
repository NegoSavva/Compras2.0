// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  static bool _viewFactoryRegistrada = false;

  bool _lendo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _registrarViewFactory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarLeitura();
    });
  }

  void _registrarViewFactory() {
    if (_viewFactoryRegistrada) return;

    ui_web.platformViewRegistry.registerViewFactory(
      'qr-reader-view',
      (int viewId) {
        final element = html.DivElement()
          ..id = 'qr-reader'
          ..style.width = '100%'
          ..style.minHeight = '360px'
          ..style.border = '1px solid #ddd'
          ..style.borderRadius = '12px'
          ..style.overflow = 'hidden';

        return element;
      },
    );

    _viewFactoryRegistrada = true;
  }

  void _iniciarLeitura() {
    setState(() {
      _lendo = true;
      _erro = null;
    });

    js_util.callMethod(
      html.window,
      'comprasQrStart',
      [
        js_util.allowInterop((dynamic decodedText) {
          final texto = decodedText.toString();

          if (!mounted) return;

          Navigator.pop(context, texto);
        }),
        js_util.allowInterop((dynamic error) {
          if (!mounted) return;

          setState(() {
            _lendo = false;
            _erro = error.toString();
          });
        }),
      ],
    );
  }

  void _pararLeitura() {
    js_util.callMethod(
      html.window,
      'comprasQrStop',
      [],
    );
  }

  @override
  void dispose() {
    _pararLeitura();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Aponte a câmera para o QR Code da NFC-e',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Quando o QR Code for identificado, a URL será enviada para a tela inicial.',
              ),

              const SizedBox(height: 24),

              const SizedBox(
                height: 380,
                child: HtmlElementView(
                  viewType: 'qr-reader-view',
                ),
              ),

              const SizedBox(height: 16),

              if (_lendo)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Câmera ativa. Aguardando leitura do QR Code...',
                      textAlign: TextAlign.center,
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

              OutlinedButton.icon(
                onPressed: _iniciarLeitura,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () {
                  _pararLeitura();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancelar leitura'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}