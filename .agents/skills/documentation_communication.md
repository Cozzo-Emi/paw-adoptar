skill:
  name: "documentation_communication"
  description: "Genera y traduce documentación técnica en distintos formatos"
  inputs:
    - source_code
    - comments
  outputs:
    - files: ["TECH_DOC.md", "CHANGELOG.md", "pipeline.yml"]
  actions:
    - "Extraer documentación desde comentarios de código"
    - "Traducir instrucciones a YAML/JSON para CI/CD"
    - "Generar changelog automático desde historial de Git"
