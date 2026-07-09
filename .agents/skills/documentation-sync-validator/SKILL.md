---
name: documentation-sync-validator
description: >-
  Instrucciones para mantener actualizada la documentación técnica del proyecto
  (READMEs) en consonancia con cualquier cambio en mensajes, contratos, base de datos o comandos.
---

# Sincronización y Validación de Documentación

Busca que la documentación técnica del proyecto refleje con precisión el comportamiento real de los sistemas.

## 1. Documentos Técnicos Clave

El proyecto contiene tres archivos `README.md` principales que describen distintas partes del ecosistema. Al realizar cambios en el código, es obligatorio revisar e incrementar su documentación:

1.  **README Principal del Proyecto ([README.md](__dir__/README.md)):**
    *   Describe la arquitectura de comunicación E2E y el diagrama de flujo.
    *   Detalla los canales de Phoenix (WebSockets), tópicos y eventos.
    *   Lista las colas de RabbitMQ.
    *   **Importante:** Contiene las especificaciones exactas de los payloads JSON de entrada y salida para todos los flujos principales (Flujo de Jugadores, Flujo de Batallas, etc.).
2.  **README del Motor de Batalla ([battle_engine/README.md](__dir__/battle_engine/README.md)):**
    *   Detalla la configuración local y de Docker del motor Ruby.
    *   Lista las tareas Rake y herramientas de consola/calidad de código.
    *   Explica la arquitectura interna de boot y persistencia.
3.  **README de Tiempo Real ([battle_real_time/README.md](__dir__/battle_real_time/README.md)):**
    *   Muestra el setup y ejecución del servidor Phoenix.
    *   Explica el árbol de supervisión OTP.
    *   Lista las tareas Mix y comandos de prueba para inyectar mensajes.

## 2. Pautas para Documentar Mensajes y Eventos
Cuando agregues o modifiques un mensaje en un contrato (Elixir o Ruby), asegúrate de reflejarlo en el `README.md` principal:

*   **Bloques de Código JSON Válidos:** Usa bloques de markdown `json` y asegúrate de que el JSON de ejemplo sea sintácticamente válido.
*   **Campos Requeridos vs. Opcionales:** Indica con claridad qué propiedades son obligatorias (`required` en el contrato) y cuáles son opcionales.
*   **Especificación de Tipos de Datos:** Si el payload incluye ids como enteros o uuids como strings, documéntalo coherentemente.
*   **Diagramas:** Si el cambio introduce un nuevo paso o una bifurcación de mensajes, actualiza el flujo en el diagrama de Mermaid correspondiente.
