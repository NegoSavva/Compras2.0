package com.compras.compras_api.model.controller;

import com.compras.compras_api.model.dto.ComprasPorMercadoResponse;
import com.compras.compras_api.model.dto.HistoricoGastoMensalResponse;
import java.util.List;
import com.compras.compras_api.model.dto.HistoricoPrecoProdutoResponse;
import com.compras.compras_api.model.dto.GastoMensalResponse;
import com.compras.compras_api.model.service.RelatorioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.compras.compras_api.model.dto.ProdutoMaisCompradoResponse;
import org.springframework.format.annotation.DateTimeFormat;
import com.compras.compras_api.model.dto.DetalheCategoriaResponse;

import java.time.LocalDate;
import com.compras.compras_api.model.dto.GastosPorCategoriaResponse;
@RestController
@RequestMapping("/api/relatorios")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RelatorioController {
@GetMapping("/produtos/historico-preco")
public ResponseEntity<List<HistoricoPrecoProdutoResponse>> buscarHistoricoPrecoProduto(
        @RequestParam String produtoNome,
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    List<HistoricoPrecoProdutoResponse> response = relatorioService.listarHistoricoPrecoProduto(
            produtoNome,
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    return ResponseEntity.ok(response);
}
@GetMapping("/historico-gastos-mensais")
public ResponseEntity<List<HistoricoGastoMensalResponse>> buscarHistoricoGastosMensais(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer idMercado
) {
    List<HistoricoGastoMensalResponse> response =
            relatorioService.listarHistoricoGastosMensais(
                    ano,
                    idMercado
            );

    return ResponseEntity.ok(response);
}
    @GetMapping("/gastos-por-categoria/detalhes")
public ResponseEntity<List<DetalheCategoriaResponse>> buscarDetalhesPorCategoria(
        @RequestParam String categoria,
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    List<DetalheCategoriaResponse> response = relatorioService.listarDetalhesPorCategoria(
            categoria,
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    return ResponseEntity.ok(response);
}
    @GetMapping("/gastos-por-categoria")
public ResponseEntity<List<GastosPorCategoriaResponse>> buscarGastosPorCategoria(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    List<GastosPorCategoriaResponse> response = relatorioService.listarGastosPorCategoria(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    return ResponseEntity.ok(response);
}
@GetMapping("/exportar/csv")
public ResponseEntity<byte[]> exportarRelatorioCsv(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    byte[] arquivo = relatorioService.gerarCsvRelatorio(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    String nomeArquivo = "relatorio-compras.csv";

    return ResponseEntity.ok()
            .header(
                    HttpHeaders.CONTENT_DISPOSITION,
                    "attachment; filename=\"" + nomeArquivo + "\""
            )
            .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
            .body(arquivo);
}
  @GetMapping("/produtos-mais-comprados")
public ResponseEntity<List<ProdutoMaisCompradoResponse>> buscarProdutosMaisComprados(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    List<ProdutoMaisCompradoResponse> response = relatorioService.listarProdutosMaisComprados(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    return ResponseEntity.ok(response);
}


    private final RelatorioService relatorioService;

   @GetMapping("/gasto-mensal")
public ResponseEntity<GastoMensalResponse> buscarGastoMensal(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    GastoMensalResponse response = relatorioService.calcularGastoMensal(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    return ResponseEntity.ok(response);
}
@GetMapping("/exportar/excel")
public ResponseEntity<byte[]> exportarRelatorioExcel(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    byte[] arquivo = relatorioService.gerarExcelRelatorio(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    String nomeArquivo = "relatorio-compras.xlsx";

    return ResponseEntity.ok()
            .header(
                    HttpHeaders.CONTENT_DISPOSITION,
                    "attachment; filename=\"" + nomeArquivo + "\""
            )
            .contentType(MediaType.parseMediaType(
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            ))
            .body(arquivo);
}
    @GetMapping("/compras-por-mercado")
public ResponseEntity<List<ComprasPorMercadoResponse>> buscarComprasPorMercado(
        @RequestParam(required = false) Integer ano,
        @RequestParam(required = false) Integer mes,
        @RequestParam(required = false) Integer idMercado,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim
) {
    List<ComprasPorMercadoResponse> response = relatorioService.listarComprasPorMercado(
            ano,
            mes,
            idMercado,
            dataInicio,
            dataFim
    );

    return ResponseEntity.ok(response);
}

}