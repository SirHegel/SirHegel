#!/usr/bin/env bash
# politica-ia.sh <org/repo> — clasifica la política de IA de un proyecto ANTES de contribuir.
#
# Existe porque una contribución técnicamente correcta a pallets/click fue cerrada
# como "AI junk": la política no estaba en el repositorio sino en el .github de la
# organización, y en la web del proyecto. Mirar solo el repo no basta.
#
# Salida: PROHIBIDO | DIVULGAR | RESPONSABLE | SIN-POLITICA  + las frases que lo deciden.
set -uo pipefail
repo="${1:?uso: politica-ia.sh org/repo}"; org="${repo%%/*}"

leer() { gh api "repos/$1/contents/$2" --jq .content 2>/dev/null | base64 -d 2>/dev/null; }

corpus=""; fuentes=()
# 1. Nivel ORGANIZACIÓN — la fuente que se pasa por alto y cerró el PR de Click.
for f in CONTRIBUTING.md AI_POLICY.md POLICY.md profile/README.md; do
  c=$(leer "$org/.github" "$f") && [ -n "$c" ] && { corpus+="$c"$'\n'; fuentes+=("$org/.github/$f"); }
done
# 2. Nivel REPOSITORIO.
for f in CONTRIBUTING.md CONTRIBUTING.rst .github/CONTRIBUTING.md AI_POLICY.md AGENTS.md \
         CODE_OF_CONDUCT.md .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md \
         docs/contributing.md docs/contributing.rst docs/CONTRIBUTING.md \
         Documentation/HOWTO-CONTRIBUTING.md; do
  c=$(leer "$repo" "$f") && [ -n "$c" ] && { corpus+="$c"$'\n'; fuentes+=("$repo/$f"); }
done
# 3. Web del proyecto, enlazada desde el repo (Pallets publica ahí su prohibición).
web=$(gh api "repos/$repo" --jq '.homepage // empty' 2>/dev/null)

if [ -z "$corpus" ]; then echo "SIN-DOCUMENTOS  $repo"; [ -n "$web" ] && echo "  revisar a mano: $web"; exit 2; fi

clasifica() { grep -Eiq "$1" <<<"$corpus"; }
# Solo frases inequívocas de prohibición. Nada de "(not )?" opcional: la política de
# Rust dice "LLM contributions are not banned" y un "not" opcional la invertiria.
if   clasifica 'closed on sight|likely to be blocked|we do not (accept|allow) (AI|LLM)|(AI|LLM)[a-z -]{0,30}(contributions|PRs|pull requests)[^.]{0,20} (are|is) (banned|prohibited|forbidden|not accepted)'
then estado="PROHIBIDO"
elif clasifica 'must disclose|MUST disclose|disclosure \(required\)|please disclose|Assisted-by|Co-authored-by.{0,30}trailer|AI Disclosure'
then estado="DIVULGAR"
elif clasifica 'LLM|AI[- ]generated|AI tools|generative AI|Copilot|ChatGPT|AI (coding )?agents?|AI models?'
then estado="RESPONSABLE"
else estado="SIN-POLITICA"
fi

# Regla legal que va aparte del permiso: systemd y util-linux aceptan trabajo asistido por
# IA pero prohiben acreditarla en el commit, justo lo contrario de lo que pide pytest.
if clasifica '[Oo]nly human beings can (ever )?be credited|no Co-Developed-By or Co-Authored-By'
then estado="$estado  [SIN-CREDITO-IA: no pongas Co-authored-by ni Assisted-by de un modelo]"
fi

echo "$estado  $repo"
printf '  fuente: %s\n' "${fuentes[@]}"
[ -n "$web" ] && echo "  web:    $web  (revisar /contributing a mano)"
echo "  frases decisivas:"
grep -Eio ".{0,110}(closed on sight|must disclose|Assisted-by|Co-authored-by|likely to be blocked|autonomous agents|AI[- ]generated|AI tools|LLM).{0,110}" <<<"$corpus" \
  | sed 's/[[:space:]]\+/ /g' | sort -u | head -6 | sed 's/^/    · /'
