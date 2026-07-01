package com.compras.compras_api.model.controller;

import com.compras.compras_api.model.dto.ProdutoClassificacaoResponse;
import com.compras.compras_api.model.service.ProdutoClassificacaoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/produtos-classificacao")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ProdutoClassificacaoController {

    private final ProdutoClassificacaoService produtoClassificacaoService;

    @GetMapping
    public ResponseEntity<List<ProdutoClassificacaoResponse>> buscarProdutos(
            @RequestParam(required = false) String nome,
            @RequestParam(required = false) String categoria
    ) {
        List<ProdutoClassificacaoResponse> response =
                produtoClassificacaoService.buscarProdutos(nome, categoria);

        return ResponseEntity.ok(response);
    }
}