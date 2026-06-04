# Coral RSE Model - Visual & Documentation Resources

A guide to the visual and written resources for the RSE model. (This file
previously pointed to a set of standalone `figures/*.html` explainer pages that
have been retired; the live resources below replace them.)

## Interactive model diagram

- **`model-diagram/`** -- a standalone interactive architecture diagram of the
  lab / orchard / reef compartments, size classes, pathways, and parameter
  layers. Run with `cd model-diagram && npm install && npm run dev`, or build a
  static copy with `npm run build` (output in `model-diagram/dist/`).
- The same diagram is embedded in the web app under `coral-app/` (see the
  diagram components in `coral-app/src/components/diagram/`).

## Conceptual figure (manuscript)

- **`figure-1/`** -- the manuscript conceptual schematic (operating model). See
  `figure-1/fig1.html` and `figure-1/README.md`; exports to `fig1.pdf` and
  `fig1_600dpi.png` via `figure-1/export.mjs`.

## Written model documentation

- **`docs/model_architecture.md`** -- the canonical model-architecture
  document (compartments, size classes, annual cycle, processes, outputs).
- **`docs/PARAMETER_PROVENANCE.md`** -- every parameter value and where it came
  from (the authoritative parameter reference).
- **`docs/FECUNDITY_LITERATURE_SUMMARY.md`** -- the size-dependent fecundity
  literature and how it maps to the model.

## Parameter tables

- **`make_parameter_tables.R`** -- regenerates the manuscript parameter tables
  into `tables/` (Word, PNG, HTML, CSV) from a single editable input spec.

## Web application

- **`coral-app/`** -- the interactive web app for exploring restoration
  strategies. See `coral-app/README.md` to run it.
