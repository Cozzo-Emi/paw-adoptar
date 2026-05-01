skill:
  name: "ai_integration"
  description: "Integra agentes IA en el flujo de trabajo del IDE"
  inputs:
    - idea
    - text
  outputs:
    - prompt: "optimized_prompt.txt"
    - yaml: "structured_prompt.yml"
    - embedding: "vector_representation.json"
  actions:
    - "Traducir ideas a YAML/Markdown estructurado"
    - "Transformar texto en embeddings para búsquedas"
    - "Ajustar iterativamente prompts con preguntas mínimas"
