package com.compras.compras_api.model.controller;

import com.compras.compras_api.model.dto.CategoriaAgrupamentoRequest;
import com.compras.compras_api.model.dto.CategoriaAgrupamentoResponse;
import com.compras.compras_api.model.service.CategoriaAgrupamentoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categorias-agrupamento")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CategoriaAgrupamentoController {

    private final CategoriaAgrupamentoService categoriaAgrupamentoService;

    @GetMapping
    public ResponseEntity<List<CategoriaAgrupamentoResponse>> buscarCategorias(
            @RequestParam(required = false) String nome,
            @RequestParam(required = false) String nomeRelatorio,
            @RequestParam(required = false) Boolean somenteSemGrupo
    ) {
        List<CategoriaAgrupamentoResponse> response =
                categoriaAgrupamentoService.buscarCategorias(
                        nome,
                        nomeRelatorio,
                        somenteSemGrupo
                );

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{idCategoria}")
    public ResponseEntity<CategoriaAgrupamentoResponse> atualizarAgrupamento(
            @PathVariable Integer idCategoria,
            @RequestBody CategoriaAgrupamentoRequest request
    ) {
        CategoriaAgrupamentoResponse response =
                categoriaAgrupamentoService.atualizarAgrupamento(
                        idCategoria,
                        request
                );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{idCategoria}")
    public ResponseEntity<Void> removerAgrupamento(
            @PathVariable Integer idCategoria
    ) {
        categoriaAgrupamentoService.removerAgrupamento(idCategoria);
        return ResponseEntity.noContent().build();
    }
}