package com.compras.compras_api.model.controller;
import org.springframework.format.annotation.DateTimeFormat;

import java.math.BigDecimal;
import java.time.LocalDate;


import com.compras.compras_api.model.dto.CompraDetalheResponse;
import com.compras.compras_api.model.dto.CompraSalvaResponse;
import com.compras.compras_api.model.dto.CompraSalvarRequest;
import com.compras.compras_api.model.dto.CompraResumoResponse;
import com.compras.compras_api.model.service.CompraService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/compras")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CompraController {

    private final CompraService compraService;

    @DeleteMapping("/{idCompra}")
public ResponseEntity<Void> excluirCompra(
        @PathVariable Integer idCompra
) {
    compraService.excluirCompra(idCompra);
    return ResponseEntity.noContent().build();
}
    @PostMapping
    public ResponseEntity<CompraSalvaResponse> salvarCompra(
            @Valid @RequestBody CompraSalvarRequest request
    ) {
        CompraSalvaResponse response = compraService.salvarCompra(request);
        return ResponseEntity.ok(response);
    }

   @GetMapping
public ResponseEntity<List<CompraResumoResponse>> listarCompras(
        @RequestParam(required = false) Integer idMercado,

        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataInicio,

        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
        LocalDate dataFim,

        @RequestParam(required = false) BigDecimal valorMinimo,
        @RequestParam(required = false) BigDecimal valorMaximo,
        @RequestParam(required = false) String formaPagamento
) {
    List<CompraResumoResponse> response = compraService.listarCompras(
            idMercado,
            dataInicio,
            dataFim,
            valorMinimo,
            valorMaximo,
            formaPagamento
    );

    return ResponseEntity.ok(response);
}

    @GetMapping("/{idCompra}")
    public ResponseEntity<CompraDetalheResponse> buscarCompraPorId(
            @PathVariable Integer idCompra
    ) {
        CompraDetalheResponse response = compraService.buscarCompraPorId(idCompra);
        return ResponseEntity.ok(response);
    }
}
