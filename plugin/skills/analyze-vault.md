# Skill: Análisis topológico del vault (/analyze-vault)

Detecta degradación estructural: proyectos aislados, áreas descuidadas, recursos sin acción,
y señales débiles acumuladas sin procesar. Ejecutar mensualmente o cuando el vault se sienta "pesado".

## Qué leer
1. Todos los archivos en `Projects/` (incluyendo `Projects/dev/`)
2. Todos los archivos en `Areas/`
3. Todos los archivos en `Resources/concepts/`
4. `Resources/moc-*.md`
5. `Inbox/` — últimas 2 semanas de notas diarias (sección `## Señales débiles`)

## Qué detectar

### Proyectos huérfanos
- Proyectos sin frontmatter `related` apuntando a un Area
- Proyectos con `status: active` pero sin tarea abierta (`- [ ]`) en el cuerpo
- Proyectos con última modificación > 30 días sin nota de pausa explícita

### Áreas descuidadas
- `Areas/` con última modificación > 60 días
- `Areas/` sin ningún proyecto activo enlazado en `Resources/moc-*.md`

### Recursos sin acción
- `Resources/concepts/` sin wikilinks entrantes desde `Projects/` o `Areas/`
- `Resources/moc-*.md` con enlaces rotos (apuntan a notas que no existen)

### Señales débiles acumuladas
- Entradas en `## Señales débiles` de las últimas 2 semanas sin convertir en tarea o concepto
- Mismo tema apareciendo en Señales débiles más de 2 veces → candidato a nota atómica

## Qué generar
Un informe conciso con cuatro secciones:
1. **Proyectos que necesitan atención** — listado con diagnóstico
2. **Áreas descuidadas** — listado con días desde última modificación
3. **Recursos huérfanos** — listado con acción sugerida (conectar / archivar / eliminar)
4. **Señales débiles recurrentes** — temas que merecen una nota atómica en `Resources/concepts/`

Presentar informe → usuario decide qué accionar → Claude ejecuta solo lo que el usuario aprueba.
**No modificar nada sin aprobación explícita.**
