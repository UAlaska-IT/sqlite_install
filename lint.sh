#!/usr/bin/env bash

rubocop
foodcritic .
foodcritic test/fixtures/cookbooks/test_harness