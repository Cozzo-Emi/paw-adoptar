skill:
  name: "quality_control"
  description: "Valida calidad y consistencia del proyecto"
  inputs:
    - project_structure
    - git_history
  outputs:
    - report: "quality_report.md"
  actions:
    - "Ejecutar linters y formateadores"
    - "Validar estructura contra checklist predefinido"
    - "Detectar conflictos en merges y sugerir resolución"
