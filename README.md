# transcript

CLI para transcrição de áudio usando [Parakeet TDT](https://github.com/senstella/parakeet-mlx) — modelo da NVIDIA rodando localmente via Apple MLX.

Gera arquivos `.md` com front matter YAML contendo metadados da transcrição.

## Como funciona

1. Recebe um ou mais arquivos de áudio/vídeo
2. Transcreve com o modelo `parakeet-tdt-0.6b-v3` (roda 100% local, Apple Silicon)
3. Salva um `.md` por arquivo com front matter + texto transcrito

### Exemplo de saída

```markdown
---
title: "entrevista-cliente"
date: 2026-04-09
source: "/Users/fulano/Downloads/entrevista-cliente.m4a"
duration: "14:28"
---

Texto transcrito aqui...
```

## Setup

### Requisitos

- macOS com Apple Silicon (M1/M2/M3/M4)
- [Homebrew](https://brew.sh)
- Python 3 e [uv](https://docs.astral.sh/uv/)

### Instalação

```bash
# 1. Instalar dependências
brew install ffmpeg yt-dlp

# 2. Instalar parakeet-mlx
uv tool install parakeet-mlx -U

# 3. Clonar e instalar o script
git clone https://github.com/gocasimiro/transcript ~/Dev/transcript
sudo ln -sf ~/Dev/transcript/transcript /usr/local/bin/transcript
```

Na primeira transcrição, o modelo (~600MB) é baixado automaticamente do HuggingFace.

> Se encontrar erro 429 (rate limit), faça login: salve seu token em `~/.cache/huggingface/token`

## Uso

```bash
# Transcrever um arquivo (saída no mesmo diretório do áudio)
transcript audio.m4a

# Transcrever um vídeo do YouTube (saída no diretório atual)
transcript "https://www.youtube.com/watch?v=..."

# Transcrever com diretório de saída customizado
transcript audio.m4a --out ~/transcrições/
transcript "https://youtube.com/watch?v=..." --out ~/transcrições/

# Múltiplos arquivos e URLs juntos
transcript aula1.m4a "https://youtube.com/watch?v=..." reuniao.mp3
```

Formatos suportados: qualquer formato que o `ffmpeg` aceita (`.m4a`, `.mp3`, `.wav`, `.mov`, `.mp4`, etc.), além de qualquer URL suportada pelo `yt-dlp` (YouTube, Vimeo, etc.).

## Idiomas suportados

O modelo padrão (`parakeet-tdt-0.6b-v3`) é **multilíngue** — detecta o idioma automaticamente sem configuração. Suporta 25 idiomas europeus, incluindo português (pt), inglês (en), espanhol (es), francês (fr), alemão (de) e italiano (it).

> Nota: o modelo foi treinado principalmente com português europeu (EP). Português brasileiro pode ter qualidade ligeiramente inferior.

## Opções avançadas

| Flag | Padrão | Descrição |
|------|--------|-----------|
| `--out <dir>` | mesmo diretório do áudio | Diretório de saída |
| `--model <repo>` | `mlx-community/parakeet-tdt-0.6b-v3` | Modelo HuggingFace a usar |
| `--decoding <método>` | `greedy` | Algoritmo: `greedy` ou `beam` |
| `--beam-size <n>` | `5` | Largura do beam (requer `--decoding beam`) |
| `--chunk <segundos>` | `120` | Duração de cada chunk (`0` = desativado) |
| `--overlap <segundos>` | `15` | Sobreposição entre chunks |
| `--local-attention` | desativado | Atenção local para áudios longos (recomendado para >24 min) |

### Exemplos

```bash
# Transcrição padrão (português detectado automaticamente)
transcript audio.m4a

# Áudio longo com atenção local
transcript reuniao_3h.mp4 --local-attention

# Áudio muito longo com chunks menores
transcript reuniao_3h.mp4 --chunk 60 --overlap 5 --local-attention
```

## Filosofia

A ideia por trás dessa ferramenta é tratar gravações de áudio como **matéria-prima** para trabalho com IA. O arquivo `.md` com front matter é o formato ideal para isso — a IA processa bem, é legível por humanos e integra com ferramentas como Obsidian, Claude Code e qualquer sistema de arquivos baseado em texto.

O fluxo de trabalho é: **gravar → transcrever → co-criar com IA a partir da transcrição**.
