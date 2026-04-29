---
name: tdd
description: Drive every behavior change with a failing test first. Red → green → refactor. Mocks are limited to repository interfaces and external API clients.
---

# TDD — outside-in, behavior-first

Use this skill **whenever production code is about to change**. If
the change has no behavior (rename, formatting, dead-code removal),
skip the skill but say so explicitly in the plan.

The rules in `agent-core/principles/ENGINEERING_PRINCIPLES.md` and
`agent-core/rules/TESTING_RULES.md` are the source of truth. This
skill is the operational loop.

---

## Loop

1. **Pick the next behavior.**
   State the next required behavior in one sentence. If you cannot
   articulate the behavior as a specification (input → expected
   observable outcome), STOP and clarify with the user. The
   behavior is not yet understood.

2. **Write the failing test (RED).**
   - Place the test where the public API of the unit-under-design
     lives. Tests interact only with public interfaces.
   - Name the test as a behavioral statement, e.g.
     `shouldRejectCancellationWhenOrderIsShipped`.
   - Document the perspective the test verifies (JavaDoc / TSDoc
     above the method). Restating the method name is forbidden.
   - Run the test. Confirm it fails for the *right* reason.

3. **Write the minimum code to pass (GREEN).**
   No abstraction, no premature generalization. Just enough.

4. **Refactor under the test's protection.**
   Improve names, collapse duplication, push responsibilities to
   their right layer. The test set must stay green throughout.

5. **Commit at the green bar.**
   One behavior, one perspective, one commit. The diff should read
   as "added behavior X with the test that defines it."

6. **Repeat from step 1** until the work unit is done.

---

## Mocking boundary (strict)

Default: real domain objects, real database (containerized), real
infrastructure.

Mocks are allowed **only** at:

- a `Repository` interface declared in `domains/`
- an external API client

Mocking any other stereotype (Aggregate, Entity, ValueObject,
Processor, Specification, Policy, Factory, UseCase, Converter,
ApplicationDto, Resource, Request, Response, Handler, Event, Result,
RepositoryImpl, ExternalClient) is **forbidden**.

If the design forces a mock outside the allowed boundary, the design
is wrong. Refactor the design, not the test.

---

## One perspective per test method

Each test method verifies one behavioral perspective. If a scenario
needs to assert the return value, the persistence side-effect, and an
emitted event, write three test methods. Verbose suites are
acceptable; combined assertions are not.

---

## Local-first

Tests run with no network, no shared cloud, no staging databases.
Reproduce external dependencies locally (Testcontainers, recorded
fixtures). A test that requires environment-specific credentials is
forbidden as the default.

---

## When this skill says STOP

- The behavior cannot be expressed as a test → clarify, do not code.
- Tests are hard to write → the design is wrong, redesign before
  continuing.
- A passing test was written *after* its production code → discard
  the production change, restart from RED.

The test is the specification. The code is its consequence.
