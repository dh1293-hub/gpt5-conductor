# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## <small>0.1.7 (2025-09-09)</small>

* fix(smoke): write a JSONL line at bootstrap to satisfy E2E log expectations ([c56f8e3](https://github.com/dh1293-hub/gpt5-conductor/commit/c56f8e3))
* fix(lint,smoke): remove useless escapes; replace while(true) with for(;;); ensure logs/app.log exist ([4244d4f](https://github.com/dh1293-hub/gpt5-conductor/commit/4244d4f))
* build(release): add auto-push; ignore venv/pycache; untrack accidental node_modules lock ([a8f7757](https://github.com/dh1293-hub/gpt5-conductor/commit/a8f7757))
* build(release): add standard-version and npm release scripts ([902ac01](https://github.com/dh1293-hub/gpt5-conductor/commit/902ac01))



### [0.1.5](https://github.com/dh1293-hub/gpt5-conductor/compare/v0.1.4...v0.1.5) (2025-09-09)

### [0.1.4](https://github.com/dh1293-hub/gpt5-conductor/compare/v0.1.3...v0.1.4) (2025-09-09)

### [0.1.3](https://github.com/dh1293-hub/gpt5-conductor/compare/v0.1.2...v0.1.3) (2025-09-09)

### [0.1.2](https://github.com/dh1293-hub/gpt5-conductor/compare/v0.1.1...v0.1.2) (2025-09-08)

### [0.1.1](https://github.com/dh1293-hub/gpt5-conductor/compare/v0.1.0...v0.1.1) (2025-09-08)


### Bug Fixes

* **build:** add minimal bootstrap to satisfy TS inputs ([0865d13](https://github.com/dh1293-hub/gpt5-conductor/commit/0865d13b13ff8902613e723b8bc6fa46899b6f25))

## 0.1.0 (2025-09-08)


### Bug Fixes

* **app:** call locator via ports.locator.locate() (bugfix from debug run) ([a3c6b6e](https://github.com/dh1293-hub/gpt5-conductor/commit/a3c6b6e27248d2ee376bdf4dc856fa4416e427ec))
* **app:** treat run as success when no action failed; rewrite orchestrator for stability ([8ca3dff](https://github.com/dh1293-hub/gpt5-conductor/commit/8ca3dff455708aaad05d718acb715c4c6c2c2d13))
* **dsl:** switch to unevaluatedProperties=false for actions; allow Common fields; fix test assertion ([f41604c](https://github.com/dh1293-hub/gpt5-conductor/commit/f41604c23a3f6d6ee1e3d1cd8709ec5a88505701))
