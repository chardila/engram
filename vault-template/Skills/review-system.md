---
name: review-system
description: Use when running /review-system or asked to improve, review, or audit the vault system itself. Analyzes one month of session logs for friction and patterns, proposes concrete changes to skills and CLAUDE.md. Run first day of each month.
---

# Skill: Revisión y mejora continua del sistema (/review-system)

Analiza un mes de uso del vault para detectar fricciones, patrones de abandono y oportunidades
de mejora. Propone cambios concretos al sistema (skills, CLAUDE.md, estructura) como borradores
para aprobación. Ningún archivo se modifica sin que el usuario lo autorice explícitamente.

Ejecutar: primer día de cada mes, antes del `/analyze-vault` mensual.

## Qué leer
1. `AI/sessions/` — todos los logs del mes anterior
2. `Inbox/` — notas diarias del mes (sección `## Señales débiles`)
3. `plugin/skills/*.md` — versión actual de cada skill
4. `CLAUDE.md` — instrucciones actuales

## Qué detectar

### Patrones de uso
- ¿Qué skills se ejecutaron más? ¿Cuáles no se ejecutaron ninguna vez?
- ¿Qué secciones del protocolo se saltaron consistentemente?
- ¿Hubo sesiones sin `/end-day`? ¿Con qué frecuencia?

### Fricciones registradas
- Entradas en `## Señales débiles` que mencionan el sistema, la captura o el vault
- Comentarios en `## Contexto para Claude` que corrijan comportamiento de Claude
- Tareas repetidas que podrían convertirse en un nuevo skill

### Deriva del sistema
- ¿`CLAUDE.md` creció más de 50 líneas este mes? ¿Por qué?
- ¿Algún skill tiene pasos que el usuario omite siempre? → candidato a simplificación
- ¿Algún flujo manual se repitió 3+ veces sin skill? → candidato a nuevo skill

## Qué generar

Un informe con tres secciones:

### 1. Diagnóstico de uso
Métricas observadas: skills usados, sesiones con `/end-day`, frecuencia de captura en
Señales débiles, etc.

### 2. Propuestas de cambio
Para cada propuesta, especificar:
- Qué cambiaría (skill X, sección Y de CLAUDE.md, nueva estructura Z)
- Por qué (patrón observado que lo justifica)
- Borrador del cambio propuesto (diff o texto completo del nuevo contenido)

### 3. Experimentos para el próximo mes
1–2 ajustes pequeños para probar antes de comprometerse con un cambio permanente.

## Flujo de aprobación
1. Presentar informe completo
2. Para cada propuesta: "¿Aplico este cambio? (sí / no / modificar)"
3. Solo tras aprobación explícita: editar el archivo en `plugin/skills/` o `CLAUDE.md`
4. Registrar cambios aprobados en `AI/sessions/YYYY-MM-DD-review-system.md`
   con `author: user` en las decisiones del usuario y `author: claude` en el diagnóstico
