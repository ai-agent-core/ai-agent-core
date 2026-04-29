# Reference

Information-oriented documentation. Reference describes the system
neutrally, exhaustively, and accurately. Readers come here knowing
what they want to look up.

## What belongs here

- API reference (endpoints, request / response, error codes).
- Configuration tables (every setting, type, default, effect).
- Schema descriptions.
- CLI command listings.
- Generated docs from OpenAPI / GraphQL / protobuf belong here.

## What does NOT belong here

- Step-by-step guides → `../tutorials/` or `../how-to/`.
- Conceptual explanations → `../explanation/`.

## Style

- Descriptive, not instructive.
- Comprehensive — every public surface listed, no "etc.".
- Mirrors the structure of the system (one section per service /
  module).
- Examples are short and illustrative, not narrative.
- Generated reference (e.g. from OpenAPI) MUST be the source of
  truth — hand-written reference that drifts is forbidden.
