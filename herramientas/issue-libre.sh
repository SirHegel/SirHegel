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

# 4. Reclamo en prosa: no hay PR todavía pero alguien dice que lo está haciendo.
#    jsonschema#1536 no tenía PR y el cuerpo decía "I have a working patch and tests".
cuerpo=$(jq -r '.body // ""' <<<"$info")
reclamo=$(grep -Eio ".{0,60}(I have (a |an )?(working )?(patch|fix|PR)|I(.| a)?m working on (this|it)|I(.| wi)?ll (open|send|submit) (a )?(PR|pull request)|will open a PR|assign (this |it )?to me|I would like to (work on|take) th).{0,60}" <<<"$cuerpo" | head -3)
# Y en los comentarios, por si alguien lo reclamó después.
coment=$(gh api "repos/$repo/issues/$num/comments" --paginate 2>/dev/null | jq -r '.[] | "\(.user.login): \(.body)"' 2>/dev/null \
  | grep -Eio ".{0,50}(I(.| a)?m working on|I(.| wi)?ll (open|send|submit)|assign (this|it) to me|I would like to (work on|take)).{0,60}" | head -3)

ocupado=""
[ -n "$enlazados$mencion$reclamo$coment" ] && ocupado=1

echo "$([ -n "$ocupado" ] && echo OCUPADO || echo LIBRE)  $repo#$num  ($estado, autor $autor, asignado a $asig)"
echo "  $titulo"
[ -n "$enlazados" ] && { echo "  PR enlazados por GitHub:"; echo "$enlazados"; }
[ -n "$mencion" ]   && { echo "  PR abiertos que mencionan el número:"; echo "$mencion"; }
[ -n "$suyos" ]     && { echo "  PR abiertos del propio autor del issue (revisar si alguno lo cubre):"; echo "$suyos"; }
[ -n "$reclamo" ] && { echo "  RECLAMADO en el cuerpo del issue:"; sed 's/^/    · /' <<<"$reclamo"; }
[ -n "$coment" ] && { echo "  RECLAMADO en los comentarios:"; sed 's/^/    · /' <<<"$coment"; }
[ -z "$ocupado" ] && echo "  → sin PR abiertos ni reclamo visible"
