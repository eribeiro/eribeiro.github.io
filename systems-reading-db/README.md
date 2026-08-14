# Systems Reading Map

Catálogo estático para GitHub Pages de papers, researchers e venues em distributed systems, databases, data management, infrastructure e AI/ML systems.

## Dados

- `papers.yaml`: papers, tags, áreas, ano, década, era, links e múltiplas linhagens.
- `researchers.yaml`: researchers, áreas e papers relacionados.
- `venues.yaml`: conferências, journals e workshops.

O schema atual é **v4**. `lineages` é many-to-many; `predecessors`/`successors` representam relações conceituais de leitura, não um grafo formal de citações.

## Dimensão temporal

Cada paper possui:
- `year`
- `decade`
- `era`

A UI permite filtrar por ano/década/era e agrupar a listagem por ano ou década.

## Teste local

Não abra `index.html` via `file://`, pois o browser bloqueará `fetch()` dos YAMLs.

```bash
cd systems-reading-db
python3 -m http.server 8000
```

Abra `http://localhost:8000/`.

## GitHub Pages

Publique os arquivos no diretório servido pelo GitHub Pages. Não há backend nem etapa de build; a única dependência de runtime é `js-yaml`, carregada via CDN.
