import 'package:flutter/material.dart';

import '../models/compras_por_mercado_model.dart';
import '../models/gasto_mensal_model.dart';
import '../models/gastos_por_categoria_model.dart';
import '../models/mercado_model.dart';
import 'analise_periodo_page.dart';
import '../models/produto_mais_comprado_model.dart';
import '../services/api_service.dart';
import 'detalhes_categoria_page.dart';
import '../models/historico_gasto_mensal_model.dart';
import 'historico_preco_produto_page.dart';

enum TipoPeriodoRelatorio {
  mesAno,
  personalizado,
}

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _anoController = TextEditingController();

  TipoPeriodoRelatorio _tipoPeriodo = TipoPeriodoRelatorio.mesAno;

  int _mesSelecionado = DateTime.now().month;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  List<MercadoModel> _mercados = [];
  int? _idMercadoSelecionado;

  GastoMensalModel? _gastoMensal;
  List<ComprasPorMercadoModel> _comprasPorMercado = [];
  List<ProdutoMaisCompradoModel> _produtosMaisComprados = [];
  List<GastosPorCategoriaModel> _gastosPorCategoria = [];

  bool _carregando = false;
  bool _carregandoMercados = false;
  bool _carregandoProdutos = false;
  bool _carregandoCategorias = false;

  String? _erro;

  @override
  void initState() {
    super.initState();

    final agora = DateTime.now();

    _anoController.text = agora.year.toString();
    _dataInicio = DateTime(agora.year, agora.month, 1);
    _dataFim = DateTime(agora.year, agora.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarMercados();
      _buscarTodosRelatorios();
    });
  }
List<HistoricoGastoMensalModel> _historicoGastosMensais = [];
bool _carregandoHistoricoMensal = false;
  @override
  void dispose() {
    _anoController.dispose();
    super.dispose();
  }
void _abrirHistoricoPrecoProduto(ProdutoMaisCompradoModel produto) {
  final ano = int.tryParse(_anoController.text.trim());

  final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataInicio!)
      : null;

      

  final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataFim!)
      : null;

  final anoConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

  final mesConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HistoricoPrecoProdutoPage(
        produtoNome: produto.produtoNome,
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
      ),
    ),
  );
}
Future<void> _baixarExcel() async {
  final ano = int.tryParse(_anoController.text.trim());

  if (_tipoPeriodo == TipoPeriodoRelatorio.mesAno && ano == null) {
    setState(() {
      _erro = 'Informe um ano válido.';
    });
    return;
  }

  if (_tipoPeriodo == TipoPeriodoRelatorio.personalizado) {
    if (_dataInicio == null || _dataFim == null) {
      setState(() {
        _erro = 'Selecione a data inicial e a data final.';
      });
      return;
    }

    if (_dataFim!.isBefore(_dataInicio!)) {
      setState(() {
        _erro = 'A data final não pode ser anterior à data inicial.';
      });
      return;
    }
  }

  final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataInicio!)
      : null;

  final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataFim!)
      : null;

  final anoConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

  final mesConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

  await _apiService.baixarRelatorioExcel(
    ano: anoConsulta,
    mes: mesConsulta,
    idMercado: _idMercadoSelecionado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );
}
Future<void> _baixarCsv() async {
  final ano = int.tryParse(_anoController.text.trim());

  if (_tipoPeriodo == TipoPeriodoRelatorio.mesAno && ano == null) {
    setState(() {
      _erro = 'Informe um ano válido.';
    });
    return;
  }

  if (_tipoPeriodo == TipoPeriodoRelatorio.personalizado) {
    if (_dataInicio == null || _dataFim == null) {
      setState(() {
        _erro = 'Selecione a data inicial e a data final.';
      });
      return;
    }

    if (_dataFim!.isBefore(_dataInicio!)) {
      setState(() {
        _erro = 'A data final não pode ser anterior à data inicial.';
      });
      return;
    }
  }

  final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataInicio!)
      : null;

  final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataFim!)
      : null;

  final anoConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

  final mesConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

  await _apiService.baixarRelatorioCsv(
    ano: anoConsulta,
    mes: mesConsulta,
    idMercado: _idMercadoSelecionado,
    dataInicio: dataInicio,
    dataFim: dataFim,
  );
}
  Future<void> _carregarMercados() async {
    try {
      final mercados = await _apiService.listarMercados();


      if (!mounted) return;

      setState(() {
        _mercados = mercados;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _buscarTodosRelatorios() async {
    final ano = int.tryParse(_anoController.text.trim());
    final anoHistorico = ano ?? DateTime.now().year;

    if (_tipoPeriodo == TipoPeriodoRelatorio.mesAno && ano == null) {
      setState(() {
        _erro = 'Informe um ano válido.';
      });
      return;
    }

    if (_tipoPeriodo == TipoPeriodoRelatorio.personalizado) {
      if (_dataInicio == null || _dataFim == null) {
        setState(() {
          _erro = 'Selecione a data inicial e a data final.';
        });
        return;
      }

      if (_dataFim!.isBefore(_dataInicio!)) {
        setState(() {
          _erro = 'A data final não pode ser anterior à data inicial.';
        });
        return;
      }
    }

   setState(() {
  _carregando = true;
  _carregandoMercados = true;
  _carregandoProdutos = true;
  _carregandoCategorias = true;
  _carregandoHistoricoMensal = true;
  _erro = null;
});

    try {
      final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
          ? _formatarDataIso(_dataInicio!)
          : null;
final historicoGastosMensais =
    await _apiService.buscarHistoricoGastosMensais(
  ano: anoHistorico,
  idMercado: _idMercadoSelecionado,
);
      final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
          ? _formatarDataIso(_dataFim!)
          : null;

      final anoConsulta =
          _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

      final mesConsulta =
          _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

      final gastoMensal = await _apiService.buscarGastoMensal(
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      final comprasPorMercado = await _apiService.buscarComprasPorMercado(
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      final produtosMaisComprados =
          await _apiService.buscarProdutosMaisComprados(
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      final gastosPorCategoria = await _apiService.buscarGastosPorCategoria(
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      if (!mounted) return;

    setState(() {
  _gastoMensal = gastoMensal;
  _comprasPorMercado = comprasPorMercado;
  _produtosMaisComprados = produtosMaisComprados;
  _gastosPorCategoria = gastosPorCategoria;
  _historicoGastosMensais = historicoGastosMensais;
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
        _carregandoMercados = false;
        _carregandoProdutos = false;
        _carregandoCategorias = false;
        _carregandoHistoricoMensal = false;
      });
    }
  }
  void _abrirAnalisePeriodo() {
  final ano = int.tryParse(_anoController.text.trim());

  final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataInicio!)
      : null;

  final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataFim!)
      : null;

  final anoConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

  final mesConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AnalisePeriodoPage(
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
        periodoTitulo: _gastoMensal?.periodo ?? '',
      ),
    ),
  );
}
  void _abrirMesDoHistorico(HistoricoGastoMensalModel item) {
  setState(() {
    _tipoPeriodo = TipoPeriodoRelatorio.mesAno;
    _mesSelecionado = item.mes;
    _anoController.text = item.ano.toString();
  });

  _buscarTodosRelatorios();
}
void _abrirDetalhesCategoria(GastosPorCategoriaModel categoria) {
  final ano = int.tryParse(_anoController.text.trim());

  final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataInicio!)
      : null;

  final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
      ? _formatarDataIso(_dataFim!)
      : null;

  final anoConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

  final mesConsulta =
      _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetalhesCategoriaPage(
        categoria: categoria.categoriaNome,
        ano: anoConsulta,
        mes: mesConsulta,
        idMercado: _idMercadoSelecionado,
        dataInicio: dataInicio,
        dataFim: dataFim,
      ),
    ),
  );
}
  Future<void> _buscarComprasPorMercado() async {
    await _buscarApenasRelatorio(
      tipo: 'mercados',
    );
  }

  Future<void> _buscarProdutosMaisComprados() async {
    await _buscarApenasRelatorio(
      tipo: 'produtos',
    );
  }

  Future<void> _buscarGastosPorCategoria() async {
    await _buscarApenasRelatorio(
      tipo: 'categorias',
    );
  }

  Future<void> _buscarApenasRelatorio({
    required String tipo,
  }) async {
    final ano = int.tryParse(_anoController.text.trim());

    if (_tipoPeriodo == TipoPeriodoRelatorio.mesAno && ano == null) {
      setState(() {
        _erro = 'Informe um ano válido.';
      });
      return;
    }

    if (_tipoPeriodo == TipoPeriodoRelatorio.personalizado) {
      if (_dataInicio == null || _dataFim == null) {
        setState(() {
          _erro = 'Selecione a data inicial e a data final.';
        });
        return;
      }

      if (_dataFim!.isBefore(_dataInicio!)) {
        setState(() {
          _erro = 'A data final não pode ser anterior à data inicial.';
        });
        return;
      }
    }

    final dataInicio = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
        ? _formatarDataIso(_dataInicio!)
        : null;

    final dataFim = _tipoPeriodo == TipoPeriodoRelatorio.personalizado
        ? _formatarDataIso(_dataFim!)
        : null;

    final anoConsulta =
        _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? ano : null;

    final mesConsulta =
        _tipoPeriodo == TipoPeriodoRelatorio.mesAno ? _mesSelecionado : null;

    try {
      setState(() {
        _erro = null;

        if (tipo == 'mercados') _carregandoMercados = true;
        if (tipo == 'produtos') _carregandoProdutos = true;
        if (tipo == 'categorias') _carregandoCategorias = true;
      });

      if (tipo == 'mercados') {
        final resultado = await _apiService.buscarComprasPorMercado(
          ano: anoConsulta,
          mes: mesConsulta,
          idMercado: _idMercadoSelecionado,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );

        if (!mounted) return;

        setState(() {
          _comprasPorMercado = resultado;
        });
      }

      if (tipo == 'produtos') {
        final resultado = await _apiService.buscarProdutosMaisComprados(
          ano: anoConsulta,
          mes: mesConsulta,
          idMercado: _idMercadoSelecionado,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );

        if (!mounted) return;

        setState(() {
          _produtosMaisComprados = resultado;
        });
      }

      if (tipo == 'categorias') {
        final resultado = await _apiService.buscarGastosPorCategoria(
          ano: anoConsulta,
          mes: mesConsulta,
          idMercado: _idMercadoSelecionado,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );

        if (!mounted) return;

        setState(() {
          _gastosPorCategoria = resultado;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        if (tipo == 'mercados') _carregandoMercados = false;
        if (tipo == 'produtos') _carregandoProdutos = false;
        if (tipo == 'categorias') _carregandoCategorias = false;
        
      });
    }
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

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarDataIso(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  String _formatarDataBr(DateTime? data) {
    if (data == null) return 'Selecionar';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString().padLeft(4, '0');

    return '$dia/$mes/$ano';
  }

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final gasto = _gastoMensal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Relatórios',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Selecione um mês ou um intervalo personalizado para visualizar os relatórios.',
              ),

              const SizedBox(height: 24),

              _FiltroPeriodoCard(
                tipoPeriodo: _tipoPeriodo,
                mesSelecionado: _mesSelecionado,
                anoController: _anoController,
                dataInicio: _dataInicio,
                dataFim: _dataFim,
                carregando: _carregando,
                nomeMes: _nomeMes,
                formatarDataBr: _formatarDataBr,
                mercados: _mercados,
                idMercadoSelecionado: _idMercadoSelecionado,
                onTipoPeriodoChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _tipoPeriodo = value;
                  });
                },
                onMesChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _mesSelecionado = value;
                  });
                },
                onMercadoChanged: (value) {
                  setState(() {
                    _idMercadoSelecionado = value;
                  });
                },
                onSelecionarDataInicio: _selecionarDataInicio,
                onSelecionarDataFim: _selecionarDataFim,
                onBaixarCsv: _baixarCsv,
                onBaixarExcel: _baixarExcel,
                onBuscar: _buscarTodosRelatorios,
                
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

const SizedBox(height: 24),

_HistoricoGastosMensaisCard(
  historico: _historicoGastosMensais,
  carregando: _carregandoHistoricoMensal,
  mesSelecionado: _tipoPeriodo == TipoPeriodoRelatorio.mesAno
      ? _mesSelecionado
      : null,
  formatarMoeda: _formatarMoeda,
  onSelecionarMes: _abrirMesDoHistorico,
),

const SizedBox(height: 24),

_TotalGastoCard(
  gasto: gasto,
  formatarMoeda: _formatarMoeda,
  onAbrirAnalise: _abrirAnalisePeriodo,
),
              const SizedBox(height: 24),

              _ComprasPorMercadoCard(
                comprasPorMercado: _comprasPorMercado,
                carregando: _carregandoMercados,
                formatarMoeda: _formatarMoeda,
                onAtualizar: _buscarComprasPorMercado,
              ),

              const SizedBox(height: 24),

             _ProdutosMaisCompradosCard(
  produtos: _produtosMaisComprados,
  carregando: _carregandoProdutos,
  formatarMoeda: _formatarMoeda,
  onAtualizar: _buscarProdutosMaisComprados,
  onAbrirProduto: _abrirHistoricoPrecoProduto,
),
              const SizedBox(height: 24),

             _GastosPorCategoriaCard(
  categorias: _gastosPorCategoria,
  carregando: _carregandoCategorias,
  formatarMoeda: _formatarMoeda,
  onAtualizar: _buscarGastosPorCategoria,
  onAbrirCategoria: _abrirDetalhesCategoria,
),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroPeriodoCard extends StatelessWidget {
  final TipoPeriodoRelatorio tipoPeriodo;
  final int mesSelecionado;
  final TextEditingController anoController;
  final DateTime? dataInicio;
  final VoidCallback onBaixarExcel;
  final VoidCallback onBaixarCsv;
  final DateTime? dataFim;
  final bool carregando;
  final String Function(int mes) nomeMes;
  final String Function(DateTime? data) formatarDataBr;
  final List<MercadoModel> mercados;
  final int? idMercadoSelecionado;
  final void Function(TipoPeriodoRelatorio? value) onTipoPeriodoChanged;
  final void Function(int? value) onMesChanged;
  final void Function(int? value) onMercadoChanged;
  final VoidCallback onSelecionarDataInicio;
  final VoidCallback onSelecionarDataFim;
  final VoidCallback onBuscar;

  const _FiltroPeriodoCard({
    required this.tipoPeriodo,
    required this.mesSelecionado,
    required this.anoController,
    required this.dataInicio,
    required this.dataFim,
    required this.carregando,
    required this.nomeMes,
    required this.onBaixarExcel,
    required this.formatarDataBr,
    required this.onBaixarCsv,
    required this.mercados,
    required this.idMercadoSelecionado,
    required this.onTipoPeriodoChanged,
    required this.onMesChanged,
    required this.onMercadoChanged,
    required this.onSelecionarDataInicio,
    required this.onSelecionarDataFim,
    required this.onBuscar,
  });

  @override
  Widget build(BuildContext context) {
    final usarMesAno = tipoPeriodo == TipoPeriodoRelatorio.mesAno;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<TipoPeriodoRelatorio>(
              value: tipoPeriodo,
              decoration: const InputDecoration(
                labelText: 'Tipo de período',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TipoPeriodoRelatorio.mesAno,
                  child: Text('Mês e ano'),
                ),
                DropdownMenuItem(
                  value: TipoPeriodoRelatorio.personalizado,
                  child: Text('Datas personalizadas'),
                ),
              ],
              onChanged: onTipoPeriodoChanged,
            ),

            const SizedBox(height: 12),

            if (usarMesAno) ...[
              DropdownButtonFormField<int>(
                value: mesSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Mês',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  final mes = index + 1;

                  return DropdownMenuItem(
                    value: mes,
                    child: Text(nomeMes(mes)),
                  );
                }),
                onChanged: onMesChanged,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: anoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
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
            ],

            const SizedBox(height: 12),

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

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: carregando ? null : onBuscar,
              icon: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    
                  : const Icon(Icons.search),
              label: Text(carregando ? 'Buscando...' : 'Buscar relatórios'),
            ),
            const SizedBox(height: 8),

OutlinedButton.icon(
  onPressed: onBaixarCsv,
  icon: const Icon(Icons.download),
  label: const Text('Baixar CSV'),
),

const SizedBox(height: 8),

OutlinedButton.icon(
  onPressed: onBaixarExcel,
  icon: const Icon(Icons.table_chart),
  label: const Text('Baixar Excel'),
),
          ],
        ),
      ),
    );
  }
}

class _TotalGastoCard extends StatelessWidget {
  final GastoMensalModel? gasto;
  final String Function(double valor) formatarMoeda;
  final VoidCallback onAbrirAnalise;

  const _TotalGastoCard({
    required this.gasto,
    required this.formatarMoeda,
    required this.onAbrirAnalise,
  });

  @override
  Widget build(BuildContext context) {
    if (gasto == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum relatório carregado.'),
        ),
      );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAbrirAnalise,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total gasto no período',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Período: ${gasto!.periodo}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      formatarMoeda(gasto!.totalGasto),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Quantidade de compras: ${gasto!.quantidadeCompras}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComprasPorMercadoCard extends StatelessWidget {
  final List<ComprasPorMercadoModel> comprasPorMercado;
  final bool carregando;
  final String Function(double valor) formatarMoeda;
  final VoidCallback onAtualizar;

  const _ComprasPorMercadoCard({
    required this.comprasPorMercado,
    required this.carregando,
    required this.formatarMoeda,
    required this.onAtualizar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CabecalhoRelatorio(
              titulo: 'Compras por mercado',
              subtitulo: 'Veja quanto foi gasto em cada mercado no período.',
              carregando: carregando,
              onAtualizar: onAtualizar,
            ),

            const SizedBox(height: 12),

            if (comprasPorMercado.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma compra encontrada por mercado.'),
              ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comprasPorMercado.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = comprasPorMercado[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    item.mercadoNome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Quantidade de compras: ${item.quantidadeCompras}',
                  ),
                  trailing: Text(
                    formatarMoeda(item.totalGasto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
class _HistoricoGastosMensaisCard extends StatelessWidget {
  final List<HistoricoGastoMensalModel> historico;
  final bool carregando;
  final int? mesSelecionado;
  final String Function(double valor) formatarMoeda;
  final void Function(HistoricoGastoMensalModel item) onSelecionarMes;

  const _HistoricoGastosMensaisCard({
    required this.historico,
    required this.carregando,
    required this.mesSelecionado,
    required this.formatarMoeda,
    required this.onSelecionarMes,
  });

  String _nomeMesCurto(int mes) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return meses[mes - 1];
  }

  double _maiorValor() {
    if (historico.isEmpty) return 0;

    return historico
        .map((item) => item.totalGasto)
        .reduce((a, b) => a > b ? a : b);
  }

  double _totalAno() {
    return historico.fold<double>(
      0,
      (total, item) => total + item.totalGasto,
    );
  }

  int _totalCompras() {
    return historico.fold<int>(
      0,
      (total, item) => total + item.quantidadeCompras,
    );
  }

  HistoricoGastoMensalModel? _mesMaiorGasto() {
    if (historico.isEmpty) return null;

    HistoricoGastoMensalModel maior = historico.first;

    for (final item in historico) {
      if (item.totalGasto > maior.totalGasto) {
        maior = item;
      }
    }

    if (maior.totalGasto <= 0) return null;

    return maior;
  }

  @override
  Widget build(BuildContext context) {
    final maiorValor = _maiorValor();
    final totalAno = _totalAno();
    final totalCompras = _totalCompras();
    final mesMaiorGasto = _mesMaiorGasto();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Histórico de gastos por mês',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (carregando)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Clique em um mês para abrir os relatórios daquele período.',
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ResumoGraficoChip(
                  titulo: 'Total no ano',
                  valor: formatarMoeda(totalAno),
                  icone: Icons.payments_outlined,
                ),
                _ResumoGraficoChip(
                  titulo: 'Compras no ano',
                  valor: '$totalCompras',
                  icone: Icons.shopping_cart_outlined,
                ),
                _ResumoGraficoChip(
                  titulo: 'Maior mês',
                  valor: mesMaiorGasto == null
                      ? 'Sem dados'
                      : '${_nomeMesCurto(mesMaiorGasto.mes)} • ${formatarMoeda(mesMaiorGasto.totalGasto)}',
                  icone: Icons.trending_up,
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (historico.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum dado mensal encontrado.'),
              )
            else
              SizedBox(
                height: 300,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: historico.map((item) {
                        final selecionado = mesSelecionado == item.mes;
                        final temGasto = item.totalGasto > 0;

                        final proporcao = maiorValor <= 0
                            ? 0.0
                            : item.totalGasto / maiorValor;

                        final alturaMaxima = 170.0;
                        final alturaBarra = alturaMaxima * proporcao;
                        final alturaFinal = alturaBarra < 6 && temGasto
                            ? 6.0
                            : alturaBarra;

                        final corBarra = selecionado
                            ? Theme.of(context).colorScheme.primary
                            : temGasto
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest;

                        final corTexto = selecionado
                            ? Theme.of(context).colorScheme.primary
                            : null;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onSelecionarMes(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 6,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message:
                                          '${_nomeMesCurto(item.mes)}/${item.ano}\n'
                                          'Total: ${formatarMoeda(item.totalGasto)}\n'
                                          'Compras: ${item.quantidadeCompras}',
                                      child: Text(
                                        formatarMoeda(item.totalGasto),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: selecionado
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: corTexto,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 280),
                                      curve: Curves.easeOut,
                                      height: alturaFinal,
                                      width: selecionado ? 30 : 24,
                                      decoration: BoxDecoration(
                                        color: corBarra,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: selecionado
                                            ? Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 2,
                                              )
                                            : null,
                                        boxShadow: selecionado
                                            ? [
                                                BoxShadow(
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.25),
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      _nomeMesCurto(item.mes),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: selecionado
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: corTexto,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    Text(
                                      '${item.quantidadeCompras} compra(s)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResumoGraficoChip extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _ResumoGraficoChip({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _ProdutosMaisCompradosCard extends StatefulWidget {
  final List<ProdutoMaisCompradoModel> produtos;
  final bool carregando;
  final String Function(double valor) formatarMoeda;
  final VoidCallback onAtualizar;
  final void Function(ProdutoMaisCompradoModel produto) onAbrirProduto;

  const _ProdutosMaisCompradosCard({
    required this.produtos,
    required this.carregando,
    required this.formatarMoeda,
    required this.onAtualizar,
    required this.onAbrirProduto,
  });

  @override
  State<_ProdutosMaisCompradosCard> createState() =>
      _ProdutosMaisCompradosCardState();
}

class _ProdutosMaisCompradosCardState
    extends State<_ProdutosMaisCompradosCard> {
  int _quantidadeVisivel = 10;

  @override
  void didUpdateWidget(covariant _ProdutosMaisCompradosCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.produtos != widget.produtos) {
      _quantidadeVisivel = 10;
    }
  }

  void _verMais() {
    setState(() {
      _quantidadeVisivel += 10;
    });
  }

  void _mostrarMenos() {
    setState(() {
      _quantidadeVisivel = 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalProdutos = widget.produtos.length;

    final quantidadeParaMostrar =
        _quantidadeVisivel > totalProdutos ? totalProdutos : _quantidadeVisivel;

    final produtosVisiveis =
        widget.produtos.take(quantidadeParaMostrar).toList();

    final temMaisProdutos = quantidadeParaMostrar < totalProdutos;
    final mostrandoMaisQueDez = quantidadeParaMostrar > 10;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CabecalhoRelatorio(
              titulo: 'Produtos mais comprados',
              subtitulo:
                  'Ranking dos produtos com maior quantidade comprada.',
              carregando: widget.carregando,
              onAtualizar: widget.onAtualizar,
            ),

            const SizedBox(height: 8),

            if (totalProdutos > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mostrando $quantidadeParaMostrar de $totalProdutos produto(s)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            if (widget.produtos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum produto encontrado.'),
              ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: produtosVisiveis.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = produtosVisiveis[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    item.produtoNome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Categoria: ${item.categoriaNome}\n'
                    'Comprado ${item.frequenciaCompra} vez(es) • '
                    'Qtd total: ${item.quantidadeTotal.toStringAsFixed(3)}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    widget.formatarMoeda(item.totalGasto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => widget.onAbrirProduto(item),
                );
              },
            ),

            if (totalProdutos > 10) ...[
              const SizedBox(height: 12),

              Row(
                children: [
                  if (temMaisProdutos)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _verMais,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Ver mais 10'),
                      ),
                    ),

                  if (temMaisProdutos && mostrandoMaisQueDez)
                    const SizedBox(width: 12),

                  if (mostrandoMaisQueDez)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _mostrarMenos,
                        icon: const Icon(Icons.expand_less),
                        label: const Text('Mostrar menos'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _GastosPorCategoriaCard extends StatelessWidget {
  final List<GastosPorCategoriaModel> categorias;
  final bool carregando;
  final String Function(double valor) formatarMoeda;
  final VoidCallback onAtualizar;
  final void Function(GastosPorCategoriaModel categoria) onAbrirCategoria;

  const _GastosPorCategoriaCard({
    required this.categorias,
    required this.carregando,
    required this.formatarMoeda,
    required this.onAtualizar,
    required this.onAbrirCategoria,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CabecalhoRelatorio(
              titulo: 'Gastos por categoria',
              subtitulo: 'Veja quanto foi gasto em cada categoria no período.',
              carregando: carregando,
              onAtualizar: onAtualizar,
            ),

            const SizedBox(height: 12),

            if (categorias.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma categoria encontrada.'),
              ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = categorias[index];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    item.categoriaNome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Itens: ${item.quantidadeItens}\n'
                    'Quantidade total: ${item.quantidadeTotalProdutos.toStringAsFixed(3)}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    formatarMoeda(item.totalGasto),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                    onTap: () => onAbrirCategoria(item),
                    
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CabecalhoRelatorio extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool carregando;
  final VoidCallback onAtualizar;

  const _CabecalhoRelatorio({
    required this.titulo,
    required this.subtitulo,
    required this.carregando,
    required this.onAtualizar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: carregando ? null : onAtualizar,
              icon: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(carregando ? 'Atualizando...' : 'Atualizar'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(subtitulo),
        
      ],
    );
  }
}