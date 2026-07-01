package com.compras.compras_api.model.controller;


import com.compras.compras_api.model.dto.MercadoResponse;
import com.compras.compras_api.model.service.MercadoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/mercados")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MercadoController {

    private final MercadoService mercadoService;

    @GetMapping
    public ResponseEntity<List<MercadoResponse>> listarMercados() {
        List<MercadoResponse> response = mercadoService.listarMercados();
        return ResponseEntity.ok(response);
    }
}
