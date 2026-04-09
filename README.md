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
# 1. Instalar ffmpeg
brew install ffmpeg

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

# Transcrever com diretório de saída customizado
transcript audio.m4a --out ~/transcrições/

# Múltiplos arquivos
transcript aula1.m4a aula2.mov reuniao.mp3
```

Formatos suportados: qualquer formato que o `ffmpeg` aceita (`.m4a`, `.mp3`, `.wav`, `.mov`, `.mp4`, etc.)

## Filosofia

A ideia por trás dessa ferramenta é tratar gravações de áudio como **matéria-prima** para trabalho com IA. O arquivo `.md` com front matter é o formato ideal para isso — a IA processa bem, é legível por humanos e integra com ferramentas como Obsidian, Claude Code e qualquer sistema de arquivos baseado em texto.

O fluxo de trabalho é: **gravar → transcrever → co-criar com IA a partir da transcrição**.
