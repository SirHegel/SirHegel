# herramientas

## `politica-ia.sh`

Clasifica la política de un proyecto sobre contribuciones asistidas por IA **antes** de
abrir un PR.

```console
$ ./politica-ia.sh pallets/click
PROHIBIDO  pallets/click
  fuente: pallets/.github/CONTRIBUTING.md
  frases decisivas:
    · AI-generated PRs and issues are closed on sight, without review or discussion.
```

### Por qué existe

Una contribución correcta a `pallets/click` —un fallo real del completado en bash, con
reproducción y test— fue cerrada como «AI junk» y la cuenta quedó bloqueada de la
organización. La prohibición no estaba en el repositorio de Click: estaba en el `.github`
de la organización y en la web del proyecto. Mirar solo el repositorio no basta.

### Qué revisa, en orden

1. `<org>/.github` — `CONTRIBUTING.md`, `AI_POLICY.md`, `profile/README.md`
2. El repositorio — `CONTRIBUTING*`, `AI_POLICY.md`, `AGENTS.md`, plantilla de PR, código
   de conducta, `docs/contributing*`, `Documentation/HOWTO-CONTRIBUTING.md`
3. La web declarada en `homepage` (a revisar a mano)

### Estados

| Estado | Significado |
|---|---|
| `PROHIBIDO` | No contribuir. |
| `DIVULGAR` | Permitido declarando la herramienta, en el formato que pida el proyecto. |
| `RESPONSABLE` | Permitido; hay que entender y sostener el cambio. |
| `SIN-POLITICA` | Nada escrito. Revisar la web a mano. |
| `[SIN-CREDITO-IA]` | Marca adicional: el trabajo se acepta pero **no** se acredita al modelo. |

Las reglas se contradicen entre proyectos y hay que leerlas una por una:

- **pip** exige `Assisted-by: <herramienta>` y **prohíbe** IA en `Co-authored-by`.
- **pytest** pide justo lo contrario: `Co-authored-by`.
- **Linux** manda `Assisted-by: AGENTE:MODELO` y prohíbe que la IA firme `Signed-off-by`.
- **systemd** y **util-linux** aceptan el trabajo pero prohíben acreditar al modelo.
- **astral-sh** (uv, ruff) permite el código pero prohíbe respuestas de IA a mantenedores.

El clasificador exige frases inequívocas. Un `(not )?` opcional en el patrón hacía que
«LLM contributions are **not banned**» de Rust se leyera como prohibición.

## `issue-libre.sh`

Comprueba si un issue está realmente libre **antes** de empezar a trabajarlo.

```console
$ ./issue-libre.sh pytest-dev/pytest 14819
OCUPADO  pytest-dev/pytest#14819  (open, autor RonnyPfannschmidt, asignado a nadie)
  PR enlazados por GitHub:
  #14822 RonnyPfannschmidt 2026-07-31 fix(rewrite): short-circuit chained comparisons
```

### Por qué existe

Cinco pull requests seguidos duplicaron trabajo que ya estaba abierto. El filtro que se
usaba —«sin asignar y sin comentarios»— no detecta nada, porque un mantenedor que abre un
issue y lo arregla él mismo no se autoasigna ni se comenta. Todos los casos que fallaron
tenían cero comentarios y ningún asignado, y un PR abierto encima.

### Qué mira

1. **Referencias cruzadas del timeline** — los PR que GitHub ya enlazó al issue. Es la
   señal fiable, y la que faltaba.
2. **Búsqueda por número** — PR abiertos que lo mencionan en el texto.
3. **PR abiertos del autor del issue** — quien reporta suele arreglar.

Un `OCUPADO` no siempre significa duplicado: en `scipy#25955` el PR enlazado era del mismo
autor pero sobre otro archivo y otro bug. Por eso imprime los candidatos en vez de decidir
solo: hay que abrir y comparar.
