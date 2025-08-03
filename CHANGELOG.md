# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.3] - 2025-08-03

### Features
- feat: add think_in feature for multilingual reasoning (2e587f3)
- feat: add custom instructions support for agents (95c2689)
- feat: add think_in languages example (505ef60)

### Code Refactoring
- refactor: optimize think_in feature and improve security (4bcd026)
- refactor: remove confidence score from result and related components (057cf93)
- refactor: extract response parsing and result building into separate concerns (0d62388)

### Tests
- test: fix RSpec violations and restructure tests (17c1af7)
- test: add RSpec test for think_in feature (759c113)
- test: remove test_helpers module and update test files (2e587f3)

### Documentation
- docs: add documentation for custom instructions and multilingual thinking features (151e8e3)
- docs: add Rails integration documentation (41815e6)

### Chores
- chore(release): add changelog extraction step for GitHub release (cbb65d8)
- chore: add .rspec_status to gitignore (0a0ebb3)

## [0.0.2] - 2025-08-01

### Features
- feat(agent_tool): add support for 'Object' type mapping

### Code Refactoring
- refactor: remove dry-rb dependencies
- refactor: change tool execution method from call to execute

### Chores
- chore: update gemspec description to include 'Gemini AI Studio'
- chore(README): update footer to include creator information

## [0.0.1] - 2025-07-29

### Code Refactoring
- refactor(llms): remove streaming support and response parser module (陳均均, 2025-07-29)

## [0.0.1.beta2] - 2025-07-29

### Chores
- chore: update .gitignore to include new documentation files (e122098)

### Added
- Initial release of Soka gem
- Multi-LLM provider support (Gemini Studio, OpenAI, Anthropic)
- Object-oriented tool system with parameter validation
- ReAct (Reasoning and Acting) engine implementation
- Memory and ThoughtsMemory systems for conversation tracking
- Global and instance-level configuration system
- Retry mechanism with exponential backoff
- Test helper utilities
- Comprehensive documentation and examples

### Features
- Agent base class with DSL for easy customization
- Tool registration with conditional loading
- Before/after action hooks and error handlers
- Real-time event streaming during agent execution
- Result objects with detailed execution information