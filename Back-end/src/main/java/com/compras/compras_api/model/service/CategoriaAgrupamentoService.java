package com.compras.compras_api.model.service;

import com.compras.compras_api.model.dto.CategoriaAgrupamentoRequest;
import com.compras.compras_api.model.dto.CategoriaAgrupamentoResponse;
import com.compras.compras_api.model.Categoria;
import com.compras.compras_api.repository.CategoriaRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoriaAgrupamentoService {

    private final CategoriaRepository categoriaRepository;

    public List<CategoriaAgrupamentoResponse> buscarCategorias(
            String nome,
            String nomeRelatorio,
            Boolean somenteSemGrupo
    ) {
        String nomeFiltro = limparTexto(nome);
        String nomeRelatorioFiltro = limparTexto(nomeRelatorio);
        boolean semGrupo = Boolean.TRUE.equals(somenteSemGrupo);

        return categoriaRepository.buscarCategoriasAgrupamento(
                        nomeFiltro,
                        nomeRelatorioFiltro,
                        semGrupo
                )
                .stream()
                .map(resultado -> new CategoriaAgrupamentoResponse(
                        ((Number) resultado[0]).intValue(),
                        (String) resultado[1],
                        (String) resultado[2]
                ))
                .toList();
    }

    @Transactional
    public CategoriaAgrupamentoResponse atualizarAgrupamento(
            Integer idCategoria,
            CategoriaAgrupamentoRequest request
    ) {
        Categoria categoria = categoriaRepository.findById(idCategoria)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Categoria não encontrada."
                ));

        String nomeRelatorio = limparTexto(request.getNomeRelatorio());

        categoria.setNomeRelatorio(nomeRelatorio);

        Categoria salva = categoriaRepository.save(categoria);

        return converterParaResponse(salva);
    }

    @Transactional
    public void removerAgrupamento(Integer idCategoria) {
        Categoria categoria = categoriaRepository.findById(idCategoria)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Categoria não encontrada."
                ));

        categoria.setNomeRelatorio(null);
        categoriaRepository.save(categoria);
    }

    private CategoriaAgrupamentoResponse converterParaResponse(Categoria categoria) {
        return new CategoriaAgrupamentoResponse(
                categoria.getIdCategoria(),
                categoria.getNome(),
                categoria.getNomeRelatorio()
        );
    }

    private String limparTexto(String texto) {
        if (texto == null || texto.isBlank()) {
            return null;
        }

        return texto.trim();
    }
}