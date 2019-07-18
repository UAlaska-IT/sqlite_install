# SQLite Install Cookbook

[![License](https://img.shields.io/github/license/ualaska-it/sqlite_install.svg)](https://github.com/ualaska-it/sqlite_install)
[![GitHub Tag](https://img.shields.io/github/tag/ualaska-it/sqlite_install.svg)](https://github.com/ualaska-it/sqlite_install)

__Maintainer: OIT Systems Engineering__ (<ua-oit-se@alaska.edu>)

## Purpose

This cookbook provides a single resource that downloads, configures, compiles, and installs SQLite.

## Requirements

### Chef

This cookbook requires Chef 14+

### Platforms

Supported Platform Families:

* Debian
  * Ubuntu, Mint
* Red Hat Enterprise Linux
  * Amazon, CentOS, Oracle
* Suse

Platforms validated via Test Kitchen:

* Ubuntu
* Debian
* CentOS
* Oracle
* Fedora
* Amazon
* Suse

Notes:

* This cookbook should support any recent Linux variant.

### Dependencies

This cookbook does not constrain its dependencies because it is intended as a utility library.
It should ultimately be used within a wrapper cookbook.

## Resources

This cookbook provides one resource for creating an SQLite installation.

### sqlite_installation


## Recipes

This cookbook provides no recipes.

## Examples

Custom resources can be used as below.

```ruby
```

## Development

See CONTRIBUTING.md and TESTING.md.
