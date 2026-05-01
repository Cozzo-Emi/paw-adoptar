# PAW — App de Adopción de Mascotas
### Matching P2P — Documento de Proyecto

> Plataforma digital para conectar adoptantes con donantes de mascotas (gatos y perros), integrando matching por compatibilidad, verificación, chat P2P y seguimiento post-adopción.

| Campo   | Valor                          |
|---------|-------------------------------|
| Versión | 1.0 — MVP                     |
| Fecha   | 30 de abril de 2026           |
| Estado  | Para aprobación               |

*Documento interno — Uso restringido al equipo de proyecto*

---

## Tabla de Contenidos

1. [Resumen Ejecutivo y Propuesta de Valor](#1-resumen-ejecutivo-y-propuesta-de-valor)
2. [Objetivos SMART y KPIs](#2-objetivos-smart-y-kpis)
3. [Roles, Entidades y Datos Clave](#3-roles-entidades-y-datos-clave)
4. [Flujos de Usuario y Lógica de Negocio](#4-flujos-de-usuario-y-lógica-de-negocio)
5. [Algoritmo de Matching](#5-algoritmo-de-matching)
6. [Reputación, Verificación y Seguridad](#6-reputación-verificación-y-seguridad)
7. [Arquitectura Técnica](#7-arquitectura-técnica)
8. [MVP: Alcance y Fases](#8-mvp--alcance-y-fases)
9. [Cronograma (6 meses)](#9-cronograma-6-meses)
10. [Monetización y Sostenibilidad](#10-monetización-y-sostenibilidad)
11. [Riesgos, Mitigaciones y Viabilidad](#11-riesgos-mitigaciones-y-viabilidad)
12. [Checklist Técnico Pre-Lanzamiento](#12-checklist-técnico-pre-lanzamiento)
13. [Próximos Pasos y Decisiones Pendientes](#13-próximos-pasos-y-decisiones-pendientes)
- [Anexo A — Contrato Marco de Colaboración con Partners](#anexo-a--contrato-marco-de-colaboración-con-partners)

---

## 1. Resumen Ejecutivo y Propuesta de Valor

### Qué es el proyecto y por qué vale la pena construirlo

Este proyecto consiste en desarrollar una plataforma P2P de matching para adopción de mascotas (perros y gatos), inspirada en la mecánica de Tinder pero adaptada a las necesidades reales de un proceso de adopción responsable. La plataforma conecta a adoptantes (personas que quieren adoptar) con donantes (personas u organizaciones que tienen animales en adopción), aplicando filtros de compatibilidad, verificación de identidad, chat privado y un sistema de seguimiento post-adopción.

### Problema que resuelve

- Procesos de adopción fragmentados, sin trazabilidad ni verificación.
- Falta de confianza entre las partes (adoptante y donante).
- Ausencia de seguimiento posterior a la adopción.
- Riesgo de trato ilegal o venta encubierta de animales.

### Propuesta de Valor

- **Matching inteligente:** el algoritmo combina compatibilidad de requisitos, reputación y proximidad geográfica.
- **Confianza y seguridad:** verificación por niveles, sistema de reputación con estrellas y evidencia post-adopción.
- **Seguimiento real:** notificación a las 48-72 h post-adopción para que el adoptante suba foto y estado del animal.
- **Prevención de fraude:** moderación humana + detección automática de patrones sospechosos.

> **72 / 100 — Viabilidad Alta-Moderada.**
> Propuesta clara de valor social con demanda real en Argentina. El riesgo principal radica en la prevención de fraude y el control de costos de almacenamiento de imágenes. Con moderación efectiva y partnerships con refugios/ONGs, la puntuación puede superar 80/100.

---

## 2. Objetivos SMART y KPIs

### Objetivos generales del MVP

- Lanzar una plataforma funcional de matching para adopción en un plazo de 6 meses.
- Alcanzar al menos 500 usuarios registrados y 50 adopciones confirmadas en los primeros 90 días de operación.
- Lograr que el 70% de las adopciones completadas suban evidencia post-adopción.
- Mantener una tasa de fraude por debajo del 2% de publicaciones activas.

### KPIs

| KPI                       | Métrica                                   | Meta MVP (90 días) |
|---------------------------|-------------------------------------------|--------------------|
| Tasa de match             | Matches / publicaciones activas           | > 30%              |
| Tiempo match-adopción     | Días promedio                             | < 14 días          |
| Evidencia post-adopción   | % con foto subida en 7 días               | > 70%              |
| Satisfacción              | Valoración promedio (1-5)                 | > 4.0              |
| Fraude                    | Reportes / publicaciones activas          | < 2%               |
| Adopciones confirmadas    | % de matches que llegan a adopción        | > 10%              |

---

## 3. Roles, Entidades y Datos Clave

### Roles de usuario

| Rol        | Responsabilidades clave                                                          | Permisos                                      |
|------------|----------------------------------------------------------------------------------|-----------------------------------------------|
| Adoptante  | Completar formulario; solicitar matches; subir evidencia post-adopción           | Buscar, aplicar, chatear tras match           |
| Donante    | Publicar ficha de mascota; revisar solicitudes; confirmar entrega                | Publicar, aceptar/denegar matches, valorar    |
| Moderador  | Revisar reportes; validar publicaciones; detectar fraude                         | Panel de moderación, bloqueos                 |
| Admin      | Gestión de plataforma; métricas y políticas                                      | Acceso total, gestión de usuarios             |

### Entidades del sistema

| Entidad             | Propósito                                          | Visibilidad                                    |
|---------------------|----------------------------------------------------|------------------------------------------------|
| Usuario             | Persona registrada (adoptante o donante)           | Público parcial                                |
| Perfil Adoptante    | Info que demuestra aptitud para adoptar            | Al donante tras match/consentimiento           |
| Perfil Donante      | Info de quien entrega la mascota                   | Visible a adoptantes                           |
| Mascota             | Ficha por animal en adopción                       | Pública en búsquedas                           |
| Match               | Conexión entre adoptante y mascota/donante         | Privado a las partes                           |
| Chat                | Comunicación P2P entre usuarios                    | Privado                                        |
| Reporte/Moderación  | Gestión de abusos o fraudes                        | Solo admins                                    |

---

## 4. Flujos de Usuario y Lógica de Negocio

### 4.1 Onboarding

- Registro básico: email o teléfono + foto de perfil.
- Elección de rol: adoptante, donante, o ambos (un mismo usuario puede ser ambos).
- Verificación opcional (email/teléfono en MVP; ID y video en fases posteriores) para incrementar reputación.

### 4.2 Publicar una mascota (rol Donante)

- Crear ficha: fotos obligatorias (mínimo 2), campos estructurados (especie, raza, edad, sexo, salud, vacunas, comportamiento).
- Revisión automática de checks mínimos antes de publicar (fotos + campos requeridos).
- Visibilidad: pública en el feed y en búsquedas según filtros activos.

### 4.3 Buscar y hacer Match (rol Adoptante)

- Búsqueda por filtros: especie, raza, edad, distancia, tamaño, requisitos del donante.
- Feed recomendado ordenado por score de compatibilidad.
- Cuando el adoptante expresa interés y el donante acepta → se registra el Match y se habilita el chat.

### 4.4 Proceso de Adopción

- **Pre-match:** el adoptante debe completar su formulario de requisitos si aún no lo hizo.
- **Post-match:** intercambio de información, coordinación de visita y/o entrega del animal.
- **Confirmación:** el adoptante marca la adopción como completada; el donante confirma la entrega.

### 4.5 Seguimiento post-adopción

- Notificación automática a las 48-72 h al adoptante para que suba foto y estado del animal.
- El donante recibe la evidencia como notificación de bienestar del animal.
- Subir evidencia incrementa la reputación del adoptante; el donante puede dejar una valoración.
- Si el adoptante no sube evidencia en 7 días tras el recordatorio, el caso se marca para seguimiento manual.

---

## 5. Algoritmo de Matching

> **Score = 40% compatibilidad + 25% reputación + 20% proximidad + 15% afinidad**

### Pesos del score de compatibilidad

| Componente                   | Peso | Descripción                                                        |
|------------------------------|------|--------------------------------------------------------------------|
| Compatibilidad de requisitos | 40%  | El perfil del adoptante cumple los requisitos del donante          |
| Reputación                   | 25%  | Estrellas, adopciones confirmadas, evidencia subida                |
| Proximidad geográfica        | 20%  | Distancia entre adoptante y ubicación del donante                  |
| Afinidad de preferencias     | 15%  | Preferencias declaradas (tamaño, raza, energía del animal)         |

### Filtros duros (se aplican antes del score)

- Distancia máxima configurada por el donante.
- Especie (perro / gato).
- Edad del animal (rango aceptado por el adoptante).
- Requisitos legales o declarados por el donante.

### Reglas de negocio adicionales

- Si el adoptante no cumple los requisitos mínimos del donante → el match no se muestra.
- Se priorizan perfiles verificados sobre no verificados.
- Cuentas con reportes activos reciben penalización en el score.
- Si el donante no responde en X días → la mascota se reabre a otros adoptantes.
- Búsqueda manual siempre disponible además del feed recomendado.

---

## 6. Reputación, Verificación y Seguridad

### Sistema de reputación

- Estrellas (1-5) + comentarios visibles en el perfil.
- **Acciones que aumentan la reputación:** verificación de cuenta, adopciones confirmadas, evidencia post-adopción subida en tiempo.
- **Penalizaciones:** reportes activos, no respuesta reiterada, comportamiento sospechoso.

### Niveles de verificación

| Nivel           | Método                          | Beneficio                                     |
|-----------------|---------------------------------|-----------------------------------------------|
| Nivel 1         | Email / teléfono verificado     | Badge básico; acceso completo a búsqueda      |
| Nivel 2         | Documento de identidad (foto)   | Mayor score; acceso a chats ilimitados        |
| Nivel 3 (fase 2)| Videollamada de verificación    | Badge premium; prioridad en matches           |

### Moderación y prevención de fraude

- Sistema de reportes visible para todos los usuarios; revisión humana por moderadores.
- Bloqueos automáticos por patrones sospechosos (múltiples cuentas, metadatos de fotos, patrones de contacto).
- Límites de mensajes antes del match para reducir contacto no deseado.
- Moderador IA como primera línea de detección (piloto 4-6 semanas); cola humana para casos de alta sospecha.

### Privacidad y datos sensibles

- Datos sensibles (ID, dirección) solo visibles para las partes tras match y con consentimiento explícito.
- Cumplimiento de la **Ley 25.326** de Protección de Datos Personales (Argentina).
- Procesos documentados para Habeas Data: acceso, rectificación y eliminación de datos.
- Minimizar PII almacenada; retener solo lo necesario con políticas de expiración.

---

## 7. Arquitectura Técnica

> **Backend FastAPI + Expo + Cloudinary — Monolito modular para MVP**

### Stack tecnológico

| Capa                  | Tecnología                        | Notas                                                          |
|-----------------------|-----------------------------------|----------------------------------------------------------------|
| Backend               | Python FastAPI (async)            | Monolito modular para MVP; listo para fragmentar               |
| Base de datos         | PostgreSQL                        | Relacional; tablas: users, pets, matches, chat, reports        |
| Almacenamiento media  | Cloudinary (plan Free)            | Uploads firmados; fallback a S3+CDN si escala                  |
| Frontend móvil        | Expo / React Native               | Comparte lógica con versión web (React Native Web)             |
| Chat en tiempo real   | WebSockets / Pusher               | Alternativa: Firebase Realtime                                 |
| Notificaciones        | Firebase Cloud Messaging          | Push a móvil; email como fallback                              |
| Autenticación         | OAuth2 + JWT + Twilio SMS         | Refresh tokens; MFA para acciones sensibles                    |
| Hosting inicial       | Render / Railway (free tier)      | Migración a AWS/GCP/DO cuando crezca                           |
| Moderación admin      | Panel propio + colas de revisión  | Métricas y SLA de respuesta                                    |
| Infra / DevOps        | Docker + GitHub Actions           | CI/CD reproducible desde el día 1                              |

### Monolito vs Microservicios: decisión de arquitectura

| Criterio              | Monolito modular (MVP)          | Microservicios (escala futura)              |
|-----------------------|---------------------------------|---------------------------------------------|
| Velocidad desarrollo  | Alta                            | Media-baja                                  |
| Costos iniciales      | Bajos                           | Más altos (infra/ops)                       |
| Escalado              | Vertical; limitado por componente | Horizontal por servicio                   |
| Operaciones           | Simples                         | Requiere service mesh y observabilidad      |

> **Decisión:** Se recomienda arrancar con un monolito modular (módulos: auth, mascotas, chat, media) para acelerar el MVP. Diseñar los límites de cada módulo con claridad para facilitar la separación futura cuando el volumen de usuarios o la latencia lo justifiquen.

---

## 8. MVP — Alcance y Fases

### Incluido en el MVP

- Registro básico y perfiles (adoptante y donante).
- Publicación de ficha de mascota con fotos y formulario básico.
- Búsqueda por filtros y feed recomendado.
- Matching simple: el adoptante expresa interés y el donante acepta.
- Chat básico entre usuarios (post-match).
- Sistema de valoraciones y reputación básico.
- Notificación post-adopción a las 48-72 h y subida de evidencia con foto.
- Panel de moderación básico y sistema de reportes.

### Fuera del MVP (fases posteriores)

- Verificación avanzada: videollamada y revisión manual de ID.
- Algoritmos de scoring más complejos y modelos de Machine Learning.
- Integraciones externas: veterinarios, refugios, ONGs.
- Pagos o contratos legales dentro de la app.
- Moderador IA autónomo (piloto en fase 2).
- Seguimiento a 30 días y reportes de bienestar extendidos.

---

## 9. Cronograma (6 meses)

| Fase                      | Semanas | Entregables clave                                                                      |
|---------------------------|---------|----------------------------------------------------------------------------------------|
| Diseño y definición       | 1 - 3   | Formularios definitivos, UI flows, DB schema, políticas legales                        |
| Desarrollo MVP            | 4 - 13  | Backend FastAPI, integración Cloudinary, chat, matching básico, mobile app             |
| Beta cerrada y ajustes    | 14 - 21 | Testing con usuarios reales, correcciones, moderación operativa                        |
| Lanzamiento piloto        | 22 - 24 | Deploy en producción, métricas iniciales, feedback primer ciclo                        |

### Equipo mínimo recomendado

| Rol                    | Cantidad | Responsabilidad principal                    |
|------------------------|----------|----------------------------------------------|
| Backend Developer      | 1        | FastAPI, PostgreSQL, integraciones           |
| Frontend / Mobile Dev  | 1        | Expo / React Native (web + móvil)            |
| Diseñador UX/UI        | 1        | Flows, componentes, prototipo                |
| QA / DevOps            | 1        | Testing, Docker, CI/CD, deploy               |
| Moderador operativo    | 1        | Revisión de reportes, soporte inicial        |

---

## 10. Monetización y Sostenibilidad

> Estrategia freemium + donaciones para mantener la misión social

Al ser un proyecto de impacto social, la monetización debe ser gradual y no interferir con la accesibilidad de la plataforma. La estrategia recomendada combina donaciones voluntarias y suscripción premium ligera como fuentes principales.

| Modelo                | Descripción                                                           | Prioridad              |
|-----------------------|-----------------------------------------------------------------------|------------------------|
| Donaciones voluntarias| Botón de donación visible en la app; campaña en redes                | Alta (lanzamiento)     |
| Suscripción premium   | Perfiles verificados, prioridad en matches, sin publicidad            | Alta (3-6 meses)       |
| Publicidad nativa     | Banners no intrusivos de servicios veterinarios, pet shops            | Media (6-12 meses)     |
| Marketplace fees      | Comisión por servicios veterinarios / adopción verificada             | Baja (fase 3+)         |

> **Nota:** la publicidad, si se implementa, debe ser nativa y no intrusiva (rewarded o contextual); nunca interrumpir flujos críticos como el match o el chat.

---

## 11. Riesgos, Mitigaciones y Viabilidad

| Riesgo                            | Impacto  | Probabilidad | Mitigación                                                                 |
|-----------------------------------|----------|--------------|----------------------------------------------------------------------------|
| Fraude / venta de animales        | Crítico  | Media        | Verificación por niveles, límites de mensajes, moderación humana           |
| Sobrecosto de media (Cloudinary)  | Alto     | Media-Alta   | Uploads firmados, alertas de uso, fallback a S3                            |
| Incumplimiento legal (Ley 25.326) | Alto     | Baja         | Minimizar PII, consentimiento explícito, procesos Habeas Data              |
| Baja adopción de usuarios         | Alto     | Media        | Partnerships con refugios/ONGs para tráfico inicial                        |
| Fuga de datos sensibles           | Crítico  | Baja         | Cifrado at-rest, rotación de claves, políticas de retención                |
| Escalado no planificado           | Medio    | Baja         | Docker + CI/CD desde día 1; plan de migración a AWS                        |

### Indicadores clave para decidir continuidad del proyecto

- Tasa de adopciones confirmadas > 10% de matches en 90 días.
- Porcentaje de adopciones con evidencia subida > 70%.
- Costo por imagen/usuario dentro del presupuesto definido.
- Tasa de reportes por fraude < 2% de publicaciones activas.

---

## 12. Checklist Técnico Pre-Lanzamiento

### Autenticación y autorización

- [ ] OAuth2 + JWT con refresh tokens y mecanismo de revocación.
- [ ] MFA para acciones sensibles (confirmación de adopción, cambios de datos personales).
- [ ] Tokens almacenados en Keychain/Keystore en mobile; nunca en localStorage.

### Protección de la API

- [ ] HTTPS obligatorio con HSTS; CORS restringido a dominios oficiales.
- [ ] Rate limiting por IP y por usuario en endpoints críticos.
- [ ] Validación estricta con Pydantic; queries parametrizadas (no concatenación SQL).
- [ ] Límite de tamaño de payloads y número de uploads por usuario/día.

### Gestión de secretos

- [ ] Credenciales en vault (HashiCorp Vault o AWS Secrets Manager).
- [ ] Rotación periódica de claves.

### Manejo de imágenes (Cloudinary)

- [ ] Uploads firmados (signed uploads); validar tipos MIME.
- [ ] Activar strict transformations y allowed fetch domains.
- [ ] Moderación automática para UGC; alertas de uso configuradas.
- [ ] Plan de fallback documentado a S3+CDN.

### Observabilidad y respuesta

- [ ] Logs estructurados; métricas con Prometheus/Grafana; tracing con OpenTelemetry.
- [ ] Alertas por anomalías en endpoints críticos.
- [ ] Backups diarios de DB; pruebas trimestrales de restore; RTO/RPO definidos.

### Seguridad mobile

- [ ] Tokens en Keychain/Keystore; ofuscación de código sensible.
- [ ] Certificate pinning para endpoints críticos.

---

## 13. Próximos Pasos y Decisiones Pendientes

| # | Acción                                                                          | Responsable               | Cuándo       |
|---|---------------------------------------------------------------------------------|---------------------------|--------------|
| 1 | Aprobar alcance del MVP y presupuesto inicial                                   | Jefe de sección + equipo  | Inmediato    |
| 2 | Definir campos exactos de formularios (adoptante y animal)                      | Product Owner             | Semana 1     |
| 3 | Confirmar stack frontend (Expo vs Flutter)                                      | Tech Lead                 | Semana 1     |
| 4 | Asignar equipo y fecha de inicio formal                                         | Jefe de sección           | Semana 1-2   |
| 5 | Diseñar UI flows del MVP (onboarding, feed, match, chat)                        | UX Designer               | Semana 1-3   |
| 6 | Establecer política de verificación y flujos de moderación                      | Product + Legal           | Semana 2     |
| 7 | Configurar Cloudinary: uploads firmados y alertas de uso                        | Backend Dev               | Semana 3-4   |
| 8 | Planificar auditoría AppSec antes de la beta                                    | QA / DevOps               | Semana 8     |
| 9 | Redactar términos de uso y política de privacidad                               | Legal                     | Semana 3     |
|10 | Identificar y contactar a 3-5 refugios/ONGs para partnerships                  | Founder / PM              | Semana 2-4   |

---

## Anexo A — Contrato Marco de Colaboración con Partners

*Plantilla editable para convenios con refugios y ONGs*

---

**CONTRATO MARCO DE COLABORACIÓN**

**Entre:** [Nombre de la Plataforma] (CUIT: [________]) y [Nombre del Partner / Refugio] (CUIT/RUT: [________]).

**Fecha:** [__________]

### Objeto

Colaboración para facilitar procesos de adopción responsable, validación de animales y difusión de publicaciones de la plataforma.

### Obligaciones del Partner

- Validar y certificar animales según el protocolo acordado.
- Proveer información veraz y mantenerla actualizada.
- Colaborar en campañas de difusión conjuntas.

### Obligaciones de la Plataforma

- Proveer acceso a panel de partners con visibilidad preferencial en búsquedas.
- Compartir reportes periódicos de adopciones vinculadas al partner.
- Mantener confidencialidad de los datos compartidos.
- Notificar incidencias relevantes en un plazo no mayor a 48 horas.

### Confidencialidad y Protección de Datos

Ambas partes se comprometen a cumplir la normativa aplicable (Ley 25.326). Los datos sensibles solo se compartirán con consentimiento explícito de los usuarios.

### Duración y Terminación

Vigencia: [Plazo]. Rescisión con [X] días de preaviso por escrito.

### KPIs de la colaboración

- Número de adopciones validadas mensualmente.
- Tiempo medio de respuesta a publicaciones referenciadas.
- Tasa de publicaciones verificadas por el partner.

Revisión trimestral de los indicadores.

---

**Firmas:**

| Representante Plataforma       | Representante Partner          |
|-------------------------------|-------------------------------|
| [Nombre y firma]              | [Nombre y firma]              |

**Datos de contacto:** [email] | [teléfono]
