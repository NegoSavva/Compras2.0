package com.compras.compras_api.model.controller;


import com.compras.compras_api.model.dto.RegraCategoriaRequest;
import com.compras.compras_api.model.dto.RegraCategoriaResponse;
import com.compras.compras_api.model.service.RegraCategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/regras-categoria")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RegraCategoriaController {

    private final RegraCategoriaService regraCategoriaService;

    @GetMapping
    public ResponseEntity<List<RegraCategoriaResponse>> listarRegras() {
        List<RegraCategoriaResponse> response = regraCategoriaService.listarRegras();
        return ResponseEntity.ok(response);
    }

    @PostMapping
    public ResponseEntity<RegraCategoriaResponse> criarRegra(
            @Valid @RequestBody RegraCategoriaRequest request
    ) {
        RegraCategoriaResponse response = regraCategoriaService.criarRegra(request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{idRegra}")
    public ResponseEntity<RegraCategoriaResponse> atualizarRegra(
            @PathVariable Integer idRegra,
            @Valid @RequestBody RegraCategoriaRequest request
    ) {
        RegraCategoriaResponse response = regraCategoriaService.atualizarRegra(idRegra, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{idRegra}")
    public ResponseEntity<Void> desativarRegra(
            @PathVariable Integer idRegra
    ) {
        regraCategoriaService.desativarRegra(idRegra);
        return ResponseEntity.noContent().build();
    }
}