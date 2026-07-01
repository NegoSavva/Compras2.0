package com.compras.compras_api.model.service;

import com.compras.compras_api.model.dto.ProdutoClassificacaoResponse;
import com.compras.compras_api.repository.ProdutoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProdutoClassificacaoService {

    private final ProdutoRepository produtoRepository;

    public List<ProdutoClassificacaoResponse> buscarProdutos(
            String nome,
            String categoria
    ) {
        String nomeFiltro = limparTexto(nome);
        String categoriaFiltro = limparTexto(categoria);

        return produtoRepository.buscarProdutosClassificados(nomeFiltro, categoriaFiltro)
                .stream()
                .map(resultado -> new ProdutoClassificacaoResponse(
                        ((Number) resultado[0]).intValue(),
                        (String) resultado[1],
                        (String) resultado[2],
                        resultado[3] == null ? null : ((Number) resultado[3]).intValue(),
                        (String) resultado[4],
                        (String) resultado[5]
                ))
                .toList();
    }

    private String limparTexto(String texto) {
        if (texto == null || texto.isBlank()) {
            return null;
        }

        return texto.trim();
    }
}