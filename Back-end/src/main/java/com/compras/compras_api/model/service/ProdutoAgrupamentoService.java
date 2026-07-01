package com.compras.compras_api.model.service;


import com.compras.compras_api.model.dto.ProdutoAgrupamentoRequest;
import com.compras.compras_api.model.dto.ProdutoAgrupamentoResponse;
import com.compras.compras_api.model.Produto;
import com.compras.compras_api.repository.ProdutoRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProdutoAgrupamentoService {

    private final ProdutoRepository produtoRepository;

    public List<ProdutoAgrupamentoResponse> buscarProdutos(
            String nome,
            String nomeRelatorio,
            String categoria,
            Boolean somenteSemGrupo
    ) {
        String nomeFiltro = limparTexto(nome);
        String nomeRelatorioFiltro = limparTexto(nomeRelatorio);
        String categoriaFiltro = limparTexto(categoria);
        boolean semGrupo = Boolean.TRUE.equals(somenteSemGrupo);

        return produtoRepository.buscarProdutosAgrupamento(
                        nomeFiltro,
                        nomeRelatorioFiltro,
                        categoriaFiltro,
                        semGrupo
                )
                .stream()
                .map(resultado -> new ProdutoAgrupamentoResponse(
                        ((Number) resultado[0]).intValue(),
                        (String) resultado[1],
                        (String) resultado[2],
                        (String) resultado[3]
                ))
                .toList();
    }

    @Transactional
    public ProdutoAgrupamentoResponse atualizarAgrupamento(
            Integer idProduto,
            ProdutoAgrupamentoRequest request
    ) {
        Produto produto = produtoRepository.findById(idProduto)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Produto não encontrado."
                ));

        String nomeRelatorio = limparTexto(request.getNomeRelatorio());

        produto.setNomeRelatorio(nomeRelatorio);

        Produto salvo = produtoRepository.save(produto);

        return converterParaResponse(salvo);
    }

    @Transactional
    public void removerAgrupamento(Integer idProduto) {
        Produto produto = produtoRepository.findById(idProduto)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Produto não encontrado."
                ));

        produto.setNomeRelatorio(null);
        produtoRepository.save(produto);
    }

    private ProdutoAgrupamentoResponse converterParaResponse(Produto produto) {
        String categoria = "Sem categoria";

        if (produto.getCategoria() != null) {
            if (
                    produto.getCategoria().getNomeRelatorio() != null
                            && !produto.getCategoria().getNomeRelatorio().isBlank()
            ) {
                categoria = produto.getCategoria().getNomeRelatorio();
            } else if (
                    produto.getCategoria().getNome() != null
                            && !produto.getCategoria().getNome().isBlank()
            ) {
                categoria = produto.getCategoria().getNome();
            }
        }

        return new ProdutoAgrupamentoResponse(
                produto.getIdProduto(),
                produto.getNome(),
                produto.getNomeRelatorio(),
                categoria
        );
    }

    private String limparTexto(String texto) {
        if (texto == null || texto.isBlank()) {
            return null;
        }

        return texto.trim();
    }
}