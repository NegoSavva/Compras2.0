package com.compras.compras_api.model.service;


import com.compras.compras_api.model.dto.ComprasPorMercadoResponse;
import com.compras.compras_api.model.dto.GastoMensalResponse;
import com.compras.compras_api.repository.CompraRepository;
import com.compras.compras_api.repository.ItemCompraRepository;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;

import com.compras.compras_api.model.dto.HistoricoPrecoProdutoResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;


import java.util.Map;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import com.compras.compras_api.model.dto.ProdutoMaisCompradoResponse;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import com.compras.compras_api.model.dto.GastosPorCategoriaResponse;
import com.compras.compras_api.model.dto.DetalheCategoriaResponse;
import com.compras.compras_api.model.dto.HistoricoGastoMensalResponse;
import com.compras.compras_api.model.util.ResultadoNormalizacao;
import com.compras.compras_api.model.util.UnidadeNormalizer;

@Service
@RequiredArgsConstructor


public class RelatorioService {
private final ProdutoCategoriaAtualizacaoService produtoCategoriaAtualizacaoService;
public List<GastosPorCategoriaResponse> listarGastosPorCategoria(
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    produtoCategoriaAtualizacaoService.reaplicarRegrasAtivasNosProdutos();

    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    return itemCompraRepository.buscarGastosPorCategoriaPorPeriodo(
                    periodo.inicio(),
                    periodo.fim(),
                    idMercado
            )
            .stream()
            .map(resultado -> new GastosPorCategoriaResponse(
                    (String) resultado[0],
                    (Long) resultado[1],
                    (BigDecimal) resultado[2],
                    (BigDecimal) resultado[3]
            ))
            .toList();
}

public byte[] gerarExcelRelatorio(
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    List<Object[]> itens = itemCompraRepository.buscarItensParaExportacaoCsv(
            periodo.inicio(),
            periodo.fim(),
            idMercado
    );

    GastoMensalResponse resumo = calcularGastoMensal(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    List<ComprasPorMercadoResponse> comprasPorMercado = listarComprasPorMercado(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    List<ProdutoMaisCompradoResponse> produtosMaisComprados = listarProdutosMaisComprados(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    List<GastosPorCategoriaResponse> gastosPorCategoria = listarGastosPorCategoria(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    try (Workbook workbook = new XSSFWorkbook()) {
        CellStyle headerStyle = criarEstiloCabecalho(workbook);

        criarAbaResumo(workbook, headerStyle, resumo);
        criarAbaItens(workbook, headerStyle, itens);
        criarAbaItensSemCategoria(workbook, headerStyle, itens);
        criarAbaGastosPorCategoria(workbook, headerStyle, gastosPorCategoria);
        criarAbaProdutosMaisComprados(workbook, headerStyle, produtosMaisComprados);
        criarAbaComprasPorMercado(workbook, headerStyle, comprasPorMercado);

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        workbook.write(outputStream);

        return outputStream.toByteArray();
    } catch (IOException e) {
        throw new IllegalArgumentException("Erro ao gerar arquivo Excel: " + e.getMessage());
    }
}
public byte[] gerarCsvRelatorio(
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    List<Object[]> itens = itemCompraRepository.buscarItensParaExportacaoCsv(
            periodo.inicio(),
            periodo.fim(),
            idMercado
    );

    StringBuilder csv = new StringBuilder();

    // BOM UTF-8 para o Excel reconhecer acentos corretamente.
    csv.append('\uFEFF');

    csv.append("ID Compra;");
    csv.append("Data;");
    csv.append("Mercado;");
    csv.append("Categoria;");
    csv.append("Produto;");
    csv.append("Quantidade;");
    csv.append("Unidade;");
    csv.append("Valor Unitário;");
    csv.append("Valor Total\n");

    for (Object[] item : itens) {
        csv.append(formatarCampoCsv(item[0])).append(";");
        csv.append(formatarCampoCsv(item[1])).append(";");
        csv.append(formatarCampoCsv(item[2])).append(";");
        csv.append(formatarCampoCsv(item[3])).append(";");
        csv.append(formatarCampoCsv(item[4])).append(";");
        csv.append(formatarCampoCsv(item[5])).append(";");
        csv.append(formatarCampoCsv(item[6])).append(";");
        csv.append(formatarCampoCsv(item[7])).append(";");
        csv.append(formatarCampoCsv(item[8])).append("\n");
    }

    return csv.toString().getBytes(StandardCharsets.UTF_8);
}
private CellStyle criarEstiloCabecalho(Workbook workbook) {
    Font font = workbook.createFont();
    font.setBold(true);

    CellStyle style = workbook.createCellStyle();
    style.setFont(font);

    return style;
}

private void criarAbaResumo(
        Workbook workbook,
        CellStyle headerStyle,
        GastoMensalResponse resumo
) {
    Sheet sheet = workbook.createSheet("Resumo");

    criarLinha(sheet, headerStyle, 0, "Campo", "Valor");

    criarLinha(sheet, null, 1, "Período", resumo.getPeriodo());
    criarLinha(sheet, null, 2, "Ano", resumo.getAno());
    criarLinha(sheet, null, 3, "Mês", resumo.getMes());
    criarLinha(sheet, null, 4, "Total gasto", resumo.getTotalGasto());
    criarLinha(sheet, null, 5, "Quantidade de compras", resumo.getQuantidadeCompras());

    ajustarColunas(sheet, 2);
}

private void criarAbaItens(
        Workbook workbook,
        CellStyle headerStyle,
        List<Object[]> itens
) {
    Sheet sheet = workbook.createSheet("Itens");

    criarCabecalhoItens(sheet, headerStyle);

    int rowIndex = 1;

    for (Object[] item : itens) {
        criarLinhaItem(sheet, rowIndex, item);
        rowIndex++;
    }

    ajustarColunas(sheet, 9);
}

private void criarAbaItensSemCategoria(
        Workbook workbook,
        CellStyle headerStyle,
        List<Object[]> itens
) {
    Sheet sheet = workbook.createSheet("Itens sem categoria");

    criarCabecalhoItens(sheet, headerStyle);

    int rowIndex = 1;

    for (Object[] item : itens) {
        String categoria = item[3] != null ? item[3].toString() : "Sem categoria";

        if (categoria.equalsIgnoreCase("Sem categoria")) {
            criarLinhaItem(sheet, rowIndex, item);
            rowIndex++;
        }
    }

    ajustarColunas(sheet, 9);
}

private void criarAbaGastosPorCategoria(
        Workbook workbook,
        CellStyle headerStyle,
        List<GastosPorCategoriaResponse> dados
) {
    Sheet sheet = workbook.createSheet("Gastos por categoria");

    criarLinha(
            sheet,
            headerStyle,
            0,
            "Categoria",
            "Quantidade de itens",
            "Quantidade total de produtos",
            "Total gasto"
    );

    int rowIndex = 1;

    for (GastosPorCategoriaResponse item : dados) {
        criarLinha(
                sheet,
                null,
                rowIndex,
                item.getCategoriaNome(),
                item.getQuantidadeItens(),
                item.getQuantidadeTotalProdutos(),
                item.getTotalGasto()
        );

        rowIndex++;
    }

    ajustarColunas(sheet, 4);
}

private void criarAbaProdutosMaisComprados(
        Workbook workbook,
        CellStyle headerStyle,
        List<ProdutoMaisCompradoResponse> dados
) {
    Sheet sheet = workbook.createSheet("Produtos mais comprados");

    criarLinha(
            sheet,
            headerStyle,
            0,
            "Produto",
            "Categoria",
            "Frequência de compra",
            "Quantidade total",
            "Total gasto"
    );

    int rowIndex = 1;

    for (ProdutoMaisCompradoResponse item : dados) {
        criarLinha(
                sheet,
                null,
                rowIndex,
                item.getProdutoNome(),
                item.getCategoriaNome(),
                item.getFrequenciaCompra(),
                item.getQuantidadeTotal(),
                item.getTotalGasto()
        );

        rowIndex++;
    }

    ajustarColunas(sheet, 5);
}

private void criarAbaComprasPorMercado(
        Workbook workbook,
        CellStyle headerStyle,
        List<ComprasPorMercadoResponse> dados
) {
    Sheet sheet = workbook.createSheet("Compras por mercado");

    criarLinha(
            sheet,
            headerStyle,
            0,
            "Mercado",
            "Quantidade de compras",
            "Total gasto"
    );

    int rowIndex = 1;

    for (ComprasPorMercadoResponse item : dados) {
        criarLinha(
                sheet,
                null,
                rowIndex,
                item.getMercadoNome(),
                item.getQuantidadeCompras(),
                item.getTotalGasto()
        );

        rowIndex++;
    }

    ajustarColunas(sheet, 3);
}

private void criarCabecalhoItens(Sheet sheet, CellStyle headerStyle) {
    criarLinha(
            sheet,
            headerStyle,
            0,
            "ID Compra",
            "Data",
            "Mercado",
            "Categoria",
            "Produto",
            "Quantidade",
            "Unidade",
            "Valor Unitário",
            "Valor Total"
    );
}

private void criarLinhaItem(Sheet sheet, int rowIndex, Object[] item) {
    criarLinha(
            sheet,
            null,
            rowIndex,
            item[0],
            formatarDataExcel(item[1]),
            item[2],
            item[3],
            item[4],
            item[5],
            item[6],
            item[7],
            item[8]
    );
}

private String formatarDataExcel(Object valor) {
    if (valor == null) {
        return "";
    }

    if (valor instanceof LocalDateTime data) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        return data.format(formatter);
    }

    return valor.toString();
}

private void criarLinha(
        Sheet sheet,
        CellStyle style,
        int rowIndex,
        Object... valores
) {
    Row row = sheet.createRow(rowIndex);

    for (int i = 0; i < valores.length; i++) {
        Cell cell = row.createCell(i);

        Object valor = valores[i];

        if (valor == null) {
            cell.setCellValue("");
        } else if (valor instanceof Number numero) {
            cell.setCellValue(numero.doubleValue());
        } else {
            cell.setCellValue(valor.toString());
        }

        if (style != null) {
            cell.setCellStyle(style);
        }
    }
}

private void ajustarColunas(Sheet sheet, int quantidadeColunas) {
    for (int i = 0; i < quantidadeColunas; i++) {
        sheet.autoSizeColumn(i);
    }
}
private String formatarCampoCsv(Object valor) {
    if (valor == null) {
        return "";
    }

    String texto = valor.toString();

    texto = texto.replace("\"", "\"\"");

    return "\"" + texto + "\"";
}
    private final CompraRepository compraRepository;
        private final ItemCompraRepository itemCompraRepository;
        public List<HistoricoPrecoProdutoResponse> listarHistoricoPrecoProduto(
        String produtoNome,
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    if (produtoNome == null || produtoNome.isBlank()) {
        throw new IllegalArgumentException("O nome do produto é obrigatório.");
    }

    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    return itemCompraRepository.buscarHistoricoPrecoProdutoPorPeriodo(
                    produtoNome.trim(),
                    periodo.inicio(),
                    periodo.fim(),
                    idMercado
            )
            .stream()
            .map(resultado -> {
                String nomeProdutoHistorico = (String) resultado[1];
                BigDecimal quantidade = (BigDecimal) resultado[4];
                String unidade = (String) resultado[5];
                BigDecimal valorTotal = (BigDecimal) resultado[7];

                ResultadoNormalizacao normalizacao = UnidadeNormalizer.normalizar(
                        quantidade,
                        unidade,
                        nomeProdutoHistorico,
                        (BigDecimal) resultado[6],
                        valorTotal
                );

                // Recalcula sempre para o histórico refletir corretamente o nome real
                // da embalagem, mesmo em compras antigas salvas com normalização errada.
                BigDecimal quantidadeNormalizada = normalizacao.getQuantidade();

                String unidadeNormalizada = normalizacao.getUnidade();

                BigDecimal precoPorUnidade = null;

                if (quantidadeNormalizada != null
                        && quantidadeNormalizada.compareTo(BigDecimal.ZERO) > 0
                        && valorTotal != null) {
                    precoPorUnidade = valorTotal.divide(
                            quantidadeNormalizada,
                            4,
                            java.math.RoundingMode.HALF_UP
                    );
                }

                return new HistoricoPrecoProdutoResponse(
                        ((Number) resultado[0]).intValue(),
                        nomeProdutoHistorico,
                        (String) resultado[2],
                        (LocalDateTime) resultado[3],
                        quantidade,
                        unidade,
                        (BigDecimal) resultado[6],
                        valorTotal,
                        quantidadeNormalizada,
                        unidadeNormalizada,
                        precoPorUnidade
                );
            })
            .toList();
}
public List<DetalheCategoriaResponse> listarDetalhesPorCategoria(
        String categoria,
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    if (categoria == null || categoria.isBlank()) {
        throw new IllegalArgumentException("A categoria é obrigatória.");
    }

    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    return itemCompraRepository.buscarDetalhesPorCategoriaPorPeriodo(
                    categoria.trim(),
                    periodo.inicio(),
                    periodo.fim(),
                    idMercado
            )
            .stream()
            .map(resultado -> new DetalheCategoriaResponse(
                    (Integer) resultado[0],
                    (String) resultado[1],
                    (String) resultado[2],
                    (String) resultado[3],
                    (LocalDateTime) resultado[4],
                    (BigDecimal) resultado[5],
                    (String) resultado[6],
                    (BigDecimal) resultado[7],
                    (BigDecimal) resultado[8]
            ))
            .toList();
}
   public GastoMensalResponse calcularGastoMensal(
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    BigDecimal total = compraRepository.somarValorTotalPorPeriodo(
            periodo.inicio(),
            periodo.fim(),
            idMercado
    );

    if (total == null) {
        total = BigDecimal.ZERO;
    }

    Long quantidade = compraRepository.contarComprasPorPeriodo(
            periodo.inicio(),
            periodo.fim(),
            idMercado
    );

String periodoTexto = periodo.periodoTexto();
    return new GastoMensalResponse(
            periodo.ano(),
            periodo.mes(),
            periodoTexto,
            total,
            quantidade
    );
}
public List<HistoricoGastoMensalResponse> listarHistoricoGastosMensais(
        Integer ano,
        Integer idMercado
) {
    LocalDate hoje = LocalDate.now();

    int anoConsulta = ano != null ? ano : hoje.getYear();

    LocalDateTime inicio = LocalDate.of(anoConsulta, 1, 1).atStartOfDay();
    LocalDateTime fim = LocalDate.of(anoConsulta + 1, 1, 1).atStartOfDay();

    List<Object[]> resultados = compraRepository.buscarHistoricoGastosMensais(
            inicio,
            fim,
            idMercado
    );

    Map<Integer, Object[]> porMes = resultados
            .stream()
            .collect(Collectors.toMap(
                    resultado -> ((Number) resultado[0]).intValue(),
                    resultado -> resultado
            ));

    List<HistoricoGastoMensalResponse> historico = new ArrayList<>();

    for (int mes = 1; mes <= 12; mes++) {
        Object[] resultado = porMes.get(mes);

        BigDecimal total = BigDecimal.ZERO;
        Long quantidade = 0L;

        if (resultado != null) {
            quantidade = ((Number) resultado[1]).longValue();
            total = (BigDecimal) resultado[2];
        }

        String periodo = String.format("%02d/%d", mes, anoConsulta);

        historico.add(
                new HistoricoGastoMensalResponse(
                        anoConsulta,
                        mes,
                        periodo,
                        total,
                        quantidade
                )
        );
    }

    return historico;
}
   public List<ProdutoMaisCompradoResponse> listarProdutosMaisComprados(
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
   PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    return itemCompraRepository.buscarProdutosMaisCompradosPorPeriodo(
                    periodo.inicio(),
                    periodo.fim(),
                    idMercado
            )
            .stream()
            .map(resultado -> new ProdutoMaisCompradoResponse(
                    (String) resultado[0],
                    (String) resultado[1],
                    (Long) resultado[2],
                    (BigDecimal) resultado[3],
                    (BigDecimal) resultado[4]
            ))
            .toList();
}

private PeriodoConsulta montarPeriodo(
        Integer ano,
        Integer mes,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    if (dataInicio != null || dataFim != null) {
        if (dataInicio == null || dataFim == null) {
            throw new IllegalArgumentException("Informe data inicial e data final.");
        }

        if (dataFim.isBefore(dataInicio)) {
            throw new IllegalArgumentException("A data final não pode ser anterior à data inicial.");
        }

        LocalDateTime inicio = dataInicio.atStartOfDay();
        LocalDateTime fim = dataFim.plusDays(1).atStartOfDay();

        String periodoTexto = dataInicio + " até " + dataFim;

        return new PeriodoConsulta(
                dataInicio.getYear(),
                dataInicio.getMonthValue(),
                inicio,
                fim,
                periodoTexto
        );
    }

    LocalDate hoje = LocalDate.now();

    int anoConsulta = ano != null ? ano : hoje.getYear();
    int mesConsulta = mes != null ? mes : hoje.getMonthValue();

    if (mesConsulta < 1 || mesConsulta > 12) {
        throw new IllegalArgumentException("O mês deve estar entre 1 e 12.");
    }

    YearMonth yearMonth = YearMonth.of(anoConsulta, mesConsulta);

    LocalDateTime inicio = yearMonth.atDay(1).atStartOfDay();
    LocalDateTime fim = yearMonth.plusMonths(1).atDay(1).atStartOfDay();

    String periodoTexto = String.format("%02d/%d", mesConsulta, anoConsulta);

    return new PeriodoConsulta(
            anoConsulta,
            mesConsulta,
            inicio,
            fim,
            periodoTexto
    );
}

private record PeriodoConsulta(
        int ano,
        int mes,
        LocalDateTime inicio,
        LocalDateTime fim,
        String periodoTexto
) {
}
 public List<ComprasPorMercadoResponse> listarComprasPorMercado(
        Integer ano,
        Integer mes,
        Integer idMercado,
        LocalDate dataInicio,
        LocalDate dataFim
) {
    PeriodoConsulta periodo = montarPeriodo(ano, mes, dataInicio, dataFim);

    return compraRepository.buscarComprasPorMercadoPorPeriodo(
                    periodo.inicio(),
                    periodo.fim(),
                    idMercado
            )
            .stream()
            .map(resultado -> new ComprasPorMercadoResponse(
                    (String) resultado[0],
                    (Long) resultado[1],
                    (BigDecimal) resultado[2]
            ))
            .toList();
}
}