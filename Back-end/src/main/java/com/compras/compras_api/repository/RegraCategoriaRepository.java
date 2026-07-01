package com.compras.compras_api.repository;


import com.compras.compras_api.model.RegraCategoria;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RegraCategoriaRepository extends JpaRepository<RegraCategoria, Integer> {

    List<RegraCategoria> findByAtivoTrueOrderByPalavraChaveAsc();

    List<RegraCategoria> findAllByOrderByPalavraChaveAsc();

    Optional<RegraCategoria> findByPalavraChaveIgnoreCaseAndAtivoTrue(String palavraChave);
}