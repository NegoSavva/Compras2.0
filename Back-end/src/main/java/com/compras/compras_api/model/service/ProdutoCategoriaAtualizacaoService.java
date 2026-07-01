package com.compras.compras_api.model.service;

import com.compras.compras_api.model.Categoria;
import com.compras.compras_api.model.Produto;
import com.compras.compras_api.model.RegraCategoria;
import com.compras.compras_api.repository.CategoriaRepository;
import com.compras.compras_api.repository.ProdutoRepository;
import com.compras.compras_api.repository.RegraCategoriaRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProdutoCategoriaAtualizacaoService {

    private final ProdutoRepository produtoRepository;
    private final CategoriaRepository categoriaRepository;
    private final RegraCategoriaRepository regraCategoriaRepository;

    /**
     * Reaplica as regras de categoria atuais aos produtos já salvos.
     *
     * Isso resolve o caso em que o produto foi salvo como "Sem categoria",
     * depois o usuário cria/edita uma regra como "marmitex -> Alimentos" e
     * aperta Atualizar nos relatórios. O relatório passa a usar a categoria atualizada.
     *
     * A rotina não remove categorias manualmente cadastradas quando nenhuma regra bate;
     * ela apenas atualiza produtos que possuem uma regra ativa correspondente.
     */
    @Transactional
    public int reaplicarRegrasAtivasNosProdutos() {
        List<RegraCategoria> regras = regraCategoriaRepository.findByAtivoTrueOrderByPalavraChaveAsc();

        if (regras.isEmpty()) {
            return 0;
        }

        int atualizados = 0;

        for (Produto produto : produtoRepository.findAll()) {
            RegraCategoria regraEncontrada = encontrarRegra(produto, regras);

            if (regraEncontrada == null) {
                continue;
            }

            Categoria novaCategoria = obterOuCriarCategoria(regraEncontrada.getCategoria());

            if (novaCategoria == null) {
                continue;
            }

            Categoria categoriaAtual = produto.getCategoria();

            boolean precisaAtualizar = categoriaAtual == null
                    || categoriaAtual.getIdCategoria() == null
                    || !categoriaAtual.getIdCategoria().equals(novaCategoria.getIdCategoria());

            if (precisaAtualizar) {
                produto.setCategoria(novaCategoria);
                produtoRepository.save(produto);
                atualizados++;
            }
        }

        return atualizados;
    }

    private RegraCategoria encontrarRegra(Produto produto, List<RegraCategoria> regras) {
        if (produto == null || produto.getNome() == null || produto.getNome().isBlank()) {
            return null;
        }

        String nomeProduto = normalizar(produto.getNome());

        for (RegraCategoria regra : regras) {
            String palavraChave = normalizar(regra.getPalavraChave());

            if (palavraChave == null || palavraChave.isBlank()) {
                continue;
            }

            if (nomeProduto.contains(palavraChave)) {
                return regra;
            }
        }

        return null;
    }

    private Categoria obterOuCriarCategoria(String nomeCategoria) {
        if (nomeCategoria == null || nomeCategoria.isBlank()) {
            return null;
        }

        String nomeFinal = nomeCategoria.trim();

        return categoriaRepository.findByNomeIgnoreCase(nomeFinal)
                .orElseGet(() -> {
                    Categoria categoria = new Categoria();
                    categoria.setNome(nomeFinal);
                    return categoriaRepository.save(categoria);
                });
    }

    private String normalizar(String texto) {
        if (texto == null) {
            return null;
        }

        String normalizado = Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase()
                .trim();

        return normalizado.replaceAll("\\s+", " ");
    }
}
