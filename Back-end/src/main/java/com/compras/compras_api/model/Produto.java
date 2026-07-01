package com.compras.compras_api.model;



import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "produtos")
@Getter
@Setter
public class Produto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_produto")
    private Integer idProduto;

    @ManyToOne
    @JoinColumn(name = "id_categoria")
    private Categoria categoria;
    
@Column(name = "nome_relatorio")
private String nomeRelatorio;

    @Column(name = "nome", nullable = false, length = 200)
    private String nome;
}
