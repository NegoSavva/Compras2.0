package com.compras.compras_api.model.controller;


import com.compras.compras_api.model.dto.NotaLeituraRequest;
import com.compras.compras_api.model.dto.NotaLeituraResponse;
import com.compras.compras_api.model.service.NotaLeituraService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notas")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class NotaController {

    private final NotaLeituraService notaLeituraService;

    @PostMapping("/ler")
    public ResponseEntity<NotaLeituraResponse> lerNota(
            @Valid @RequestBody NotaLeituraRequest request
    ) {
        NotaLeituraResponse response = notaLeituraService.lerNota(request.getUrl());
        return ResponseEntity.ok(response);
    }
}
