---
description: Modo de trabajo en produccion
---

1. Inicio y alineación
Objetivo: Entender el propósito del proyecto, restricciones y éxito medible.

Instrucción:
"Antes de generar cualquier código o contenido, responde: ¿Cuál es el resultado esperado? ¿Qué métricas definirán el éxito? ¿Hay restricciones de tiempo, costo o compliance?"

2. Planificación y diseño
Tareas: Desglosar en módulos, definir dependencias, elegir herramientas.

Instrucción:
"Crea un plan en etapas (análisis → diseño → implementación → pruebas → despliegue). Incluye revisión humana en cada etapa crítica. Usa formato de checklist."

3. Implementación asistida
Reglas:

Genera código/documentación atómica (pequeños commits).

Incluye comentarios de lógica y posibles fallos.

Etiqueta secciones inciertas con #REVISAR_HUMANO.

Ejemplo:
"Para cada función, escribe casos de prueba unitaria antes del cuerpo de la función (TDD guiado por IA)."

4. Verificación automática y humana
Controles:

Ejecuta pruebas locales de caja negra y blanca.

Simula entradas límite.

Marca errores con #ERROR_[tipo].

Instrucción:
"Si encuentras algo que no cumple con requerimientos no negociables (seguridad, privacidad), detén el flujo y notifica con prioridad alta."

5. Entrega controlada
Pasos:

Genera artefactos (logs, métricas, resumen de decisiones).

Propone un plan de rollback.

Instrucción:
"Solo despliega si todas las pruebas críticas pasan y un humano da el go explícito. Registra cada acción en un log inmutable."

6. Monitoreo post-despliegue
Tareas:

Define alertas automáticas (latencia, errores, drift).

Programa retrospectivas diarias con humanos.

Instrucción:
"Reporta cualquier desviación del comportamiento esperado en menos de 5 minutos. Propón hipótesis de causa raíz."

Buenas prácticas adicionales para indicar:
Human-in-the-loop obligatorio en decisiones de: cambio de alcance, datos sensibles, umbrales de confianza bajos.

Memoria compartida (un archivo WORKFLOW_STATE.json que actualice cada agente).

Versionado semántico de cada paso del flujo.

Canal único de coordinación (ej. una cola de mensajes o issue tracker).