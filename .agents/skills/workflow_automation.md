skill:
  name: "workflow_automation"
  description: "Automatiza tareas comunes de inicio y configuración de proyectos"
  inputs:
    - project_name
    - language
  outputs:
    - folders: ["src", "tests", "docs"]
    - files: ["README.md", "requirements.txt", ".gitignore", "docker-compose.yml", ".env"]
  actions:
    - "Generar estructura inicial de carpetas"
    - "Crear archivos base de configuración"
    - "Plantillas de commits y ramas (feat/, fix/, docs/)"
