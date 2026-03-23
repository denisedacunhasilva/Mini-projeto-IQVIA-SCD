import os
from google.cloud import storage
from datetime import datetime

def executar_load_gcs(pasta_local, bucket_nome, project_id):
    print(f"\n--- [L] Carregamento Organizado: {datetime.now().strftime('%H:%M:%S')} ---")
    
    try:
        storage_client = storage.Client(project=project_id)
        bucket = storage_client.bucket(bucket_nome)

        # Mapeamento de destino para cada arquivo
        destinos = {
            'MS_12_2022_sample.csv': 'bronze/fato_vendas/MS_12_2022_sample.csv',
            'filial-brick_sample.csv': 'bronze/dim_filial/filial-brick_sample.csv'

        }

        for arquivo, caminho_gcs in destinos.items():
            caminho_local = os.path.join(pasta_local, arquivo)
            
            if os.path.exists(caminho_local):
                blob = bucket.blob(caminho_gcs)
                print(f"📤 Enviando para {caminho_gcs}...")
                blob.upload_from_filename(caminho_local)
                print(f"✅ Sucesso!")
            else:
                print(f"⚠️ Arquivo {arquivo} não encontrado em {pasta_local}")

    except Exception as e:
        print(f"🚨 Erro: {e}")

if __name__ == "__main__":
    executar_load_gcs('data/processed', 'iqvia_landing', 'lab365-denisec')