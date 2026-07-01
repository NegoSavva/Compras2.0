package com.compras.compras_api.model;



import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "itens_compra")
@Getter
@Setter
public class ItemCompra {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item")
    private Integer idItem;

    @ManyToOne
    @JoinColumn(name = "id_compra")
    private Compra compra;
@Column(name = "unidade_normalizada")




private String unidadeNormalizada;

@Column(name = "quantidade_normalizada", precision = 14, scale = 4)
private BigDecimal quantidadeNormalizada;
    @ManyToOne
    @JoinColumn(name = "id_produto")
    private Produto produto;
@Column(name = "preco_por_unidade", precision = 14, scale = 4)
private BigDecimal precoPorUnidade;
    @Column(name = "quantidade", precision = 10, scale = 3)
    private BigDecimal quantidade;

    @Column(name = "unidade", length = 20)

    public String getUnidadeNormalizada() {
    return unidadeNormalizada;
}
public BigDecimal getPrecoPorUnidade() {
    return precoPorUnidade;
}

public void setPrecoPorUnidade(BigDecimal precoPorUnidade) {
    this.precoPorUnidade = precoPorUnidade;
}
public void setUnidadeNormalizada(String unidadeNormalizada) {
    this.unidadeNormalizada = unidadeNormalizada;
}

public BigDecimal getQuantidadeNormalizada() {
    return quantidadeNormalizada;
}

public void setQuantidadeNormalizada(BigDecimal quantidadeNormalizada) {
    this.quantidadeNormalizada = quantidadeNormalizada;
}
    private String unidade;

    @Column(name = "valor_unitario", precision = 10, scale = 2)
    private BigDecimal valorUnitario;

    @Column(name = "valor_total", precision = 10, scale = 2)
    private BigDecimal valorTotal;
}
