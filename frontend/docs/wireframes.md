# PAW — UI Flows y Wireframes Base

Este documento define la estructura de pantallas para Flutter según los flujos requeridos en el documento de proyecto MVP.

## 1. Flow: Onboarding
**Objetivo:** Registro rápido, elección de rol y nivel básico de verificación.

- **Pantalla 1: Splash & Welcome**
  - Logo PAW.
  - Botones: "Iniciar Sesión" / "Crear Cuenta".
- **Pantalla 2: Registro**
  - Formulario básico: Email, Contraseña, Nombre Completo.
  - Botón: "Siguiente".
- **Pantalla 3: Verificación (Nivel 1)**
  - Input para código OTP (enviado por email).
- **Pantalla 4: Elección de Rol**
  - Dos grandes cards seleccionables: "Quiero Adoptar" / "Tengo mascotas para dar en adopción".
  - *Nota: Un usuario puede seleccionar ambas.*

---

## 2. Flow: Feed de Mascotas (Adoptante)
**Objetivo:** Búsqueda, filtros y visualización de matches.

- **Pantalla 1: Home (Feed Recomendado)**
  - Header: Saludo + Ubicación actual.
  - Barra superior: Chips de filtros rápidos (Perros, Gatos, Cachorros, Cerca de mí).
  - Cuerpo: Tarjetas tipo Tinder/Feed ordenadas por *Score de Compatibilidad*.
    - Info en tarjeta: Foto principal, Nombre, Edad, Distancia, y % de Match.
- **Pantalla 2: Filtros Avanzados (Modal)**
  - Sliders y selects: Distancia máxima, tamaño, nivel de energía, edad min/max.
- **Pantalla 3: Ficha Detalle de Mascota**
  - Carrusel de fotos (mínimo 2).
  - Secciones colapsables: Salud (vacunas/castración), Comportamiento, Requisitos del Donante.
  - Footer fijo: Botón grande "Expresar Interés" (Heart icon).

---

## 3. Flow: Publicación (Donante)
**Objetivo:** Subida de ficha estandarizada.

- **Pantalla 1: Dashboard Donante**
  - Resumen: Mascotas activas, Matches pendientes, Adopciones completadas.
  - Botón flotante: "+ Publicar Mascota".
- **Pantalla 2: Formulario de Mascota (Step-by-step)**
  - *Step 1:* Fotos (Uploader conectado a Cloudinary con restricción mín 2 fotos).
  - *Step 2:* Datos básicos (Nombre, Especie, Sexo, Edad, Tamaño).
  - *Step 3:* Salud y Comportamiento.
  - *Step 4:* Requisitos para el adoptante (Tiene patio, Experiencia, etc).
  - *Botón Final:* "Publicar" (Valida form y sube a BD).

---

## 4. Flow: Match y Chat (Post-Match)
**Objetivo:** Conexión y mensajería segura.

- **Pantalla 1: Bandeja de Matches (Donante)**
  - Lista de adoptantes interesados en sus mascotas.
  - Muestra: Foto del adoptante, Reputación (Estrellas), % de compatibilidad.
  - Acciones: "Aceptar" (Abre chat) o "Rechazar".
- **Pantalla 2: Bandeja de Chats**
  - Lista de conversaciones activas ordenadas por última actividad.
- **Pantalla 3: Sala de Chat P2P**
  - Mensajería en tiempo real.
  - Header: Nombre de la otra parte + Nombre de la mascota vinculada.
  - Alerta superior (Si status=accepted): Botón "Confirmar Adopción" (Requiere acuerdo de ambas partes).

---

## 5. Flow: Post-Adopción y Reputación
**Objetivo:** Seguimiento a las 48-72h.

- **Pantalla 1: Notificación In-App (Modal de Seguimiento)**
  - Título: "¿Cómo está [Nombre Mascota]?"
  - Descripción: "Tu adopción fue hace 48h. Sube una foto para asegurar su bienestar y sumar puntos de reputación."
- **Pantalla 2: Formulario de Evidencia**
  - Botón: "Tomar Foto" / "Subir de Galería".
  - Textarea: "¿Cómo se está adaptando?".
  - Botón: "Enviar Evidencia".
- **Pantalla 3: Dejar Review (Ambas partes)**
  - Selector de 1 a 5 estrellas.
  - Textarea opcional para comentarios.
  - Afecta directamente la reputación del usuario en la BD.
