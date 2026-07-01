package com.compras.compras_api.model.service;


import com.compras.compras_api.model.dto.MercadoResponse;
import com.compras.compras_api.model.Mercado;
import com.compras.compras_api.repository.MercadoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MercadoService {

    private final MercadoRepository mercadoRepository;

    public List<MercadoResponse> listarMercados() {
        return mercadoRepository.findAll(Sort.by(Sort.Direction.ASC, "nome"))
                .stream()
                .map(this::converterParaResponse)
                .toList();
    }

    private MercadoResponse converterParaResponse(Mercado mercado) {
        return new MercadoResponse(
                mercado.getIdMercado(),
                mercado.getNome(),
                mercado.getCnpj(),
                mercado.getEndereco()
        );
    }
}
