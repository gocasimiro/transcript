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
assert_contains "--help mostra '--overlap'"   "$output" "--overlap"
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
# 4. Arquivo inexistente → avisa e continua (exit 0 porque o loop continua)
# ---------------------------------------------------------------------------
echo "# Grupo 4: arquivo inexistente"
# Para testar sem chamar parakeet-mlx de verdade, passamos um arquivo que não existe
# O script deve continuar e imprimir o erro, mas como FILES fica sem sucesso,
# queremos verificar a mensagem de erro.
output=$("$SCRIPT" /tmp/arquivo_que_nao_existe_transcript_test.mp3 2>&1) && code=$? || code=$?
assert_contains "arquivo inexistente mostra aviso" "$output" "Arquivo não encontrado"
echo ""

# ---------------------------------------------------------------------------
# 5. Dry-run de parsing: verifica que --model, --decoding, --beam-size,
#    --chunk e --overlap são aceitos sem "Opção desconhecida"
#    (vão falhar no parakeet-mlx pois o arquivo não existe, mas o parse
#     deve funcionar antes disso)
# ---------------------------------------------------------------------------
echo "# Grupo 5: parsing de novas flags"
for flag_and_val in "--model mlx-community/test" "--decoding beam" "--beam-size 8" "--chunk 60" "--overlap 10"; do
  flag=$(echo "$flag_and_val" | cut -d' ' -f1)
  val=$(echo "$flag_and_val" | cut -d' ' -f2)
  output=$("$SCRIPT" "$flag" "$val" /tmp/nao_existe.mp3 2>&1) && code=$? || code=$?
  if echo "$output" | grep -qF "Opção desconhecida"; then
    fail "flag $flag não reconhecida pelo parser"
  else
    pass "flag $flag reconhecida pelo parser"
  fi
done
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
