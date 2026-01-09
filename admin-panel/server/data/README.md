# Pasta de dados do CineFlow

Esta pasta contém os arquivos de conteúdo servidos pelo servidor.

## Arquivos

- `canais.m3u` - Lista principal de canais IPTV

## Como atualizar

1. Substitua o arquivo `canais.m3u` por uma versão atualizada
2. Atualize a versão no painel admin ou diretamente no arquivo `content-version.json`
3. Faça deploy no Railway

## Formato do content-version.json

```json
{
  "version": "2024.01.09",
  "updatedAt": "2024-01-09T10:00:00Z",
  "description": "Atualização de canais"
}
```
