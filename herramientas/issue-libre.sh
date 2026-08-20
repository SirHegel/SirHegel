#!/usr/bin/env bash
# issue-libre.sh <org/repo> <numero> — ¿está realmente libre este issue?
#
# Existe porque cinco PR seguidos duplicaron trabajo ajeno. El filtro que usaba
# —sin asignar, sin comentarios— no detecta nada: un mantenedor que abre un issue
# y lo arregla él mismo no se autoasigna ni se comenta. Hay que mirar los PR.
set -uo pipefail
repo="${1:?uso: issue-libre.sh org/repo numero}"; num="${2:?falta el número}"

info=$(gh api "repos/$repo/issues/$num" 2>/dev/null) || { echo "NO EXISTE  $repo#$num"; exit 2; }
autor=$(jq -r .user.login <<<"$info"); estado=$(jq -r .state <<<"$info")
asig=$(jq -r '.assignee.login // "nadie"' <<<"$info"); titulo=$(jq -r .title <<<"$info")

# 1. Referencias cruzadas: PR que GitHub ya enlazó a este issue.
enlazados=$(gh api "repos/$repo/issues/$num/timeline" --paginate 2>/dev/null \
  | jq -r '.[] | select(.event=="cross-referenced") | .source.issue
           | select(.pull_request != null) | select(.state=="open")
           | "  #\(.number) \(.user.login) \(.created_at[0:10]) \(.title[0:52])"' 2>/dev/null | sort -u)

# 2. Búsqueda por texto: PR abiertos que mencionan el número.
mencion=$(gh api "search/issues?q=repo:$repo+is:pr+is:open+$num" \
  --jq '.items[] | "  #\(.number) \(.user.login) \(.created_at[0:10]) \(.title[0:52])"' 2>/dev/null | sort -u)

# 3. ¿El autor del issue tiene PR abiertos aquí? Suele arreglarse lo que uno reporta.
suyos=$(gh api "search/issues?q=repo:$repo+is:pr+is:open+author:$autor" \
  --jq '.items[] | "  #\(.number) \(.created_at[0:10]) \(.title[0:52])"' 2>/dev/null | head -6)

ocupado=""
[ -n "$enlazados$mencion" ] && ocupado=1

echo "$([ -n "$ocupado" ] && echo OCUPADO || echo LIBRE)  $repo#$num  ($estado, autor $autor, asignado a $asig)"
echo "  $titulo"
[ -n "$enlazados" ] && { echo "  PR enlazados por GitHub:"; echo "$enlazados"; }
[ -n "$mencion" ]   && { echo "  PR abiertos que mencionan el número:"; echo "$mencion"; }
[ -n "$suyos" ]     && { echo "  PR abiertos del propio autor del issue (revisar si alguno lo cubre):"; echo "$suyos"; }
[ -z "$ocupado" ] && echo "  → sin PR abiertos referenciándolo"
