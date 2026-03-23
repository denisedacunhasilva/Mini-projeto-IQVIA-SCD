-- Comparativo Real: Bronze (Arquivo) vs Gold (Data Warehouse)
SELECT 
    -- Buscamos os dados BRUTOS da tabela externa (Bronze)
    bronze.ean AS ean_original,
    bronze.cod_produto_catarinense AS cod_original,
    bronze.vol_marca_pp AS volume_original,
    
    -- Buscamos os dados LIMPOS da tabela final (Gold)
    gold.id_produto_original AS ean_padronizado,
    gold.cod_produto_catarinense AS cod_padronizado,
    gold.nome_produto,
    gold.valor_produto AS preco_final
    
FROM `lab365-denisec.iqvia_dw.ext_vendas_lote_cru` AS bronze
INNER JOIN `lab365-denisec.iqvia_dw.dim_produto` AS gold
  ON LPAD(TRIM(bronze.ean), 15, '0') = gold.id_produto_original
WHERE gold.flag_ativo = TRUE
LIMIT 10;