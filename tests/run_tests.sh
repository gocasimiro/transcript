#!/usr/bin/env bash
# Testes unitários para o script transcript
# Uso: bash tests/run_tests.sh

set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/transcript"
PASS=0
FAIL=0
ERRORS=()

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); ERRORS+=("$1"); }

assert_contains() {
  local label="$1" output="$2" expected="$3"
  if echo "$output" | grep -qF -- "$expected"; then
    pass "$label"
  else
    fail "$label — esperado conter: '$expected'"
    echo "    Output: $output"
  fi
}

assert_not_contains() {
  local label="$1" output="$2" unexpected="$3"
  if echo "$output" | grep -qF -- "$unexpected"; then
    fail "$label — não deveria conter: '$unexpected'"
    echo "    Output: $output"
  else
    pass "$label"
  fi
}

assert_exit() {
  local label="$1" code="$2" expected="$3"
  if [[ "$code" -eq "$expected" ]]; then
    pass "$label"
  else
    fail "$label — exit code esperado: $expected, obtido: $code"
  fi
}

echo "=== transcript — testes de comportamento ==="
echo ""

# ---------------------------------------------------------------------------
# 1. --help imprime uso e sai com 0
# ---------------------------------------------------------------------------
echo "# Grupo 1: --help"
output=$("$SCRIPT" --help 2>&1) && code=$? || code=$?
assert_exit  "--help sai com código 0"   "$code" "0"
assert_contains "--help mostra 'transcript'"  "$output" "transcript"
assert_contains "--help mostra '--out'"       "$output" "--out"
assert_contains "--help mostra '--model'"     "$output" "--model"
assert_contains "--help mostra '--decoding'"  "$output" "--decoding"
assert_contains "--help mostra '--beam-size'" "$output" "--beam-size"
assert_contains "--help mostra '--chunk'"     "$output" "--chunk"
assert_contains "--help mostra '--overlap'"         "$output" "--overlap"
assert_contains "--help mostra '--local-attention'" "$output" "--local-attention"
echo ""

# ---------------------------------------------------------------------------
# 2. Nenhum argumento → erro e exit 1
# ---------------------------------------------------------------------------
echo "# Grupo 2: sem argumentos"
output=$("$SCRIPT" 2>&1) && code=$? || code=$?
assert_exit "sem args sai com código 1" "$code" "1"
assert_contains "sem args mostra 'Uso:'" "$output" "Uso:"
echo ""

# ---------------------------------------------------------------------------
# 3. Opção desconhecida → erro e exit 1
# ---------------------------------------------------------------------------
echo "# Grupo 3: opção inválida"
output=$("$SCRIPT" --invalid-flag 2>&1) && code=$? || code=$?
assert_exit "opção inválida sai com código 1" "$code" "1"
assert_contains "opção inválida mostra mensagem de erro" "$output" "Opção desconhecida"
echo ""

# ---------------------------------------------------------------------------
# 4. Arquivo inexistente → avisa no stderr
# ---------------------------------------------------------------------------
echo "# Grupo 4: arquivo inexistente"
output=$("$SCRIPT" /tmp/arquivo_que_nao_existe_transcript_test.mp3 2>&1) && code=$? || code=$?
assert_contains "arquivo inexistente mostra aviso" "$output" "Arquivo não encontrado"
echo ""

# ---------------------------------------------------------------------------
# 5. Parsing de novas flags (aceitas pelo parser sem "Opção desconhecida")
# ---------------------------------------------------------------------------
echo "# Grupo 5: parsing de novas flags"
for flag_and_val in "--model mlx-community/test" "--decoding beam" "--beam-size 8" "--chunk 60" "--overlap 10"; do
  flag=$(echo "$flag_and_val" | cut -d' ' -f1)
  val=$(echo "$flag_and_val" | cut -d' ' -f2)
  output=$("$SCRIPT" "$flag" "$val" /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
  assert_not_contains "flag $flag reconhecida pelo parser" "$output" "Opção desconhecida"
done
output=$("$SCRIPT" --local-attention /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_not_contains "flag --local-attention reconhecida pelo parser" "$output" "Opção desconhecida"
echo ""

# ---------------------------------------------------------------------------
# 6. Validação de --decoding (rejeita valores inválidos)
# ---------------------------------------------------------------------------
echo "# Grupo 6: validação de --decoding"
output=$("$SCRIPT" --decoding invalido /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_exit "--decoding inválido sai com código 1" "$code" "1"
assert_contains "--decoding inválido mostra erro" "$output" "greedy"

output=$("$SCRIPT" --decoding greedy /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_not_contains "--decoding greedy aceito sem erro" "$output" "Erro:"

output=$("$SCRIPT" --decoding beam /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_not_contains "--decoding beam aceito sem erro" "$output" "Erro:"
echo ""

# ---------------------------------------------------------------------------
# 7. Validação de --beam-size (rejeita não-inteiro e zero)
# ---------------------------------------------------------------------------
echo "# Grupo 7: validação de --beam-size"
output=$("$SCRIPT" --beam-size abc /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_exit "--beam-size string sai com código 1" "$code" "1"
assert_contains "--beam-size string mostra erro" "$output" "inteiro positivo"

output=$("$SCRIPT" --beam-size 0 /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_exit "--beam-size 0 sai com código 1" "$code" "1"

output=$("$SCRIPT" --decoding beam --beam-size 5 /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_not_contains "--beam-size válido com beam aceito" "$output" "Erro:"
echo ""

# ---------------------------------------------------------------------------
# 8. --beam-size sem --decoding beam emite aviso
# ---------------------------------------------------------------------------
echo "# Grupo 8: --beam-size sem --decoding beam"
output=$("$SCRIPT" --beam-size 8 /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_contains "--beam-size sem beam emite aviso" "$output" "Aviso"
echo ""

# ---------------------------------------------------------------------------
# 9a. --local-attention (flag booleana sem valor)
# ---------------------------------------------------------------------------
echo "# Grupo 9a: --local-attention"
output=$("$SCRIPT" --local-attention /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_not_contains "--local-attention não emite erro" "$output" "Erro:"
echo ""

# ---------------------------------------------------------------------------
# 9b. --chunk 0 não deve emitir erro (é o modo "desativado")
# ---------------------------------------------------------------------------
echo "# Grupo 9b: --chunk 0"
output=$("$SCRIPT" --chunk 0 /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
assert_not_contains "--chunk 0 não emite erro de validação" "$output" "Erro:"
echo ""

# ---------------------------------------------------------------------------
# Resultado final
# ---------------------------------------------------------------------------
echo "==================================="
echo "Resultado: $PASS passed, $FAIL failed"
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "Falhas:"
  for e in "${ERRORS[@]}"; do echo "  - $e"; done
  exit 1
fi
echo "Todos os testes passaram."
