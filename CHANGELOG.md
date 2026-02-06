# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [1.4.9](https://github.com/batinicaz/oci-apps/compare/v1.4.8...v1.4.9) (2026-02-06)

### [1.4.8](https://github.com/batinicaz/oci-apps/compare/v1.4.7...v1.4.8) (2026-02-06)

### [1.4.7](https://github.com/batinicaz/oci-apps/compare/v1.4.6...v1.4.7) (2026-02-03)

### [1.4.6](https://github.com/batinicaz/oci-apps/compare/v1.4.5...v1.4.6) (2026-02-03)

### [1.4.5](https://github.com/batinicaz/oci-apps/compare/v1.4.4...v1.4.5) (2026-02-03)

### [1.4.4](https://github.com/batinicaz/oci-apps/compare/v1.4.3...v1.4.4) (2026-02-03)

### [1.4.3](https://github.com/batinicaz/oci-apps/compare/v1.4.2...v1.4.3) (2026-02-03)

### [1.4.2](https://github.com/batinicaz/oci-apps/compare/v1.4.1...v1.4.2) (2026-02-03)

### [1.4.1](https://github.com/batinicaz/oci-apps/compare/v1.4.0...v1.4.1) (2026-02-02)


### Bug Fixes

* enable state locking ([671169c](https://github.com/batinicaz/oci-apps/commit/671169cd6f3b956eb3a788829224c6d30babd06c))

## [1.4.0](https://github.com/batinicaz/oci-apps/compare/v1.3.0...v1.4.0) (2026-02-02)


### Features

* security improvements ([08bfe56](https://github.com/batinicaz/oci-apps/commit/08bfe56da67c10f99223e3c3d1cd4f7cda2b04ae))


### Bug Fixes

* copy cache warm script + set fallback locale ([fe5230e](https://github.com/batinicaz/oci-apps/commit/fe5230e2a398e7519e59503c8ac0318d2c6701b9))
* missed path for php sessions ([b35370d](https://github.com/batinicaz/oci-apps/commit/b35370dab67126a5f824bc0767a5e8e66f84279b))

## [1.3.0](https://github.com/batinicaz/oci-apps/compare/v1.2.0...v1.3.0) (2026-02-02)


### Features

* add hourly backups ([d96283c](https://github.com/batinicaz/oci-apps/commit/d96283cc19626dc596b7297a5789ff33111a9ee0))


### Bug Fixes

* backups causing inconsistent systemd state ([24a0cb6](https://github.com/batinicaz/oci-apps/commit/24a0cb69a2c1f958c9c12680bd5c5edcc01d6a79))
* container names, freshrss connectivity to local feeds and timeout issues ([bf60aff](https://github.com/batinicaz/oci-apps/commit/bf60aff0507af943035cf51ba0a9a5c682b544a5))

## [1.2.0](https://github.com/batinicaz/oci-apps/compare/v1.1.6...v1.2.0) (2026-02-02)


### Features

* add healthchecks config for services ([09e8f9e](https://github.com/batinicaz/oci-apps/commit/09e8f9eaeef0d0604780e5e625156f652f86b4e2))


### Bug Fixes

* ensure fulltextrss starts if the ghcr token has not been written yet ([6ea3775](https://github.com/batinicaz/oci-apps/commit/6ea37750e71ca8aef22523c1ed40e44a1f529382))
* postgres 18 volume path ([fac6879](https://github.com/batinicaz/oci-apps/commit/fac6879ca5a31888fce662161652ef559754bec2))
* put nitter and freshrss on the same network so freshrss can pull feeds locally from nitter ([3b0b2d9](https://github.com/batinicaz/oci-apps/commit/3b0b2d9f7265fc23cc39b8b2e72e039d28f16e48))

### [1.1.6](https://github.com/batinicaz/oci-apps/compare/v1.1.5...v1.1.6) (2026-02-02)


### Bug Fixes

* fulltext rss config.php getting overwritten ([bbd9a11](https://github.com/batinicaz/oci-apps/commit/bbd9a11fccaf3c0d7f96a6e9007898d61fda7263))

### [1.1.5](https://github.com/batinicaz/oci-apps/compare/v1.1.4...v1.1.5) (2026-02-02)

### [1.1.4](https://github.com/batinicaz/oci-apps/compare/v1.1.3...v1.1.4) (2026-02-02)

### [1.1.3](https://github.com/batinicaz/oci-apps/compare/v1.1.2...v1.1.3) (2026-02-02)


### Bug Fixes

* stop objects being uploaded on every git checkout ([cf34270](https://github.com/batinicaz/oci-apps/commit/cf342706c54b818996effadb5e58d240f46a6e31))

### [1.1.2](https://github.com/batinicaz/oci-apps/compare/v1.1.1...v1.1.2) (2026-02-02)

### [1.1.1](https://github.com/batinicaz/oci-apps/compare/v1.1.0...v1.1.1) (2026-02-02)

## [1.1.0](https://github.com/batinicaz/oci-apps/compare/v1.0.1...v1.1.0) (2026-02-01)


### Features

* initial migration from legacy oci image to containers ([eb906cc](https://github.com/batinicaz/oci-apps/commit/eb906ccddd3b4a6f521e749ed9391e73ff58a6fe))

### 1.0.1 (2026-01-30)
