# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.2.3 - 2025-11-17]
### Changed
- Better documentation
- Tested with Ruby 3.4.5

## [2.2.2 - 2023-08-28]
### Changed
- Better documentation
- Tested used Ruby 3.2

## [2.2.1 - 2023-03-29]
### Changed
- changes Substitute method: `set_reserved(value)` -> `set_reserved`

## [2.1.0 - 2023-03-29]
### Changed
- Don't call automatically yield in the repo, just when calling
  `set_reserved(true)`

## [2.0.0 - 2022-12-09]
### Changed
- Renamed gem and repo from "idempotence" to "hubbado-idempotence-reservation"

## [1.2.0 - 2022-11-29]
### Changed
- Reserved metadata name is stored in `metadata.local_properties`
  instead of metadata.properties. `metadata.local_properties` is not followed
  so the info is not propagated to other messages


## [1.1.0 - 2022-10-07]
### Added
- Substitute for Reservation class

### Fixed
- Reservation stream not generated properly

## [1.0.0 - 2022-09-29]
### Changed
- First stable release
