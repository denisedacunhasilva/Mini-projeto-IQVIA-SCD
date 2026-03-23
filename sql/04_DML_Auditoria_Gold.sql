-- Auditoria de Versões e Status
SELECT 
    sk_produto,
    id_produto_original,
    nome_produto,
    valor_produto,
    data_inicio_validade,
    data_fim_validade,
    flag_ativo
FROM `lab365-denisec.iqvia_dw.dim_produto`
ORDER BY id_produto_original, data_inicio_validade DESC;