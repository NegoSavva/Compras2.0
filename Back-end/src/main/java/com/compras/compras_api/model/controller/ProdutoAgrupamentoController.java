package com.compras.compras_api.model.controller;


import com.compras.compras_api.model.dto.ProdutoAgrupamentoRequest;
import com.compras.compras_api.model.dto.ProdutoAgrupamentoResponse;
import com.compras.compras_api.model.service.ProdutoAgrupamentoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/produtos-agrupamento")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ProdutoAgrupamentoController {

    private final ProdutoAgrupamentoService produtoAgrupamentoService;

    @GetMapping
    public ResponseEntity<List<ProdutoAgrupamentoResponse>> buscarProdutos(
            @RequestParam(required = false) String nome,
            @RequestParam(required = false) String nomeRelatorio,
            @RequestParam(required = false) String categoria,
            @RequestParam(required = false) Boolean somenteSemGrupo
    ) {
        List<ProdutoAgrupamentoResponse> response =
                produtoAgrupamentoService.buscarProdutos(
                        nome,
                        nomeRelatorio,
                        categoria,
                        somenteSemGrupo
                );

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{idProduto}")
    public ResponseEntity<ProdutoAgrupamentoResponse> atualizarAgrupamento(
            @PathVariable Integer idProduto,
            @RequestBody ProdutoAgrupamentoRequest request
    ) {
        ProdutoAgrupamentoResponse response =
                produtoAgrupamentoService.atualizarAgrupamento(
                        idProduto,
                        request
                );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{idProduto}")
    public ResponseEntity<Void> removerAgrupamento(
            @PathVariable Integer idProduto
    ) {
        produtoAgrupamentoService.removerAgrupamento(idProduto);
        return ResponseEntity.noContent().build();
    }
}
