# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.8] - 2025-08-15

### Tests
- test: update specs to match reduced thought word limit (73564ae)

## [0.0.7] - 2025-08-15

### Features
- feat: add execution time tracking to ReAct engine (eea5efb)

### Code Refactoring
- refactor: reduce thought tag word limit for better conciseness (7b3290c)

## [0.0.6] - 2025-08-12

### Features
- feat: add OpenAI Responses API support with reasoning (8c81be8)
- feat: enhance ReAct prompt template with clearer instructions (d371c12)
- feat(gemini): add thinkingConfig to generationConfig (8e44e63)

### Bug Fixes
- fix(openai): update default model name from gpt-5-nano to gpt-5-mini (1e5971f)
- fix: update Final_Answer tag to FinalAnswer across codebase (feb6071)

### Documentation
- docs: add model testing results and update OpenAI model names (f83b987)
- docs: add problem solving guidelines for AI assistants (0e99e5f)

### Code Refactoring
- refactor: reorganize prompt templates into modular structure (0c10e21)
- refactor: improve format reminder in response processor (a3de6a5)
- refactor: remove configurable timeout option (7e7e7c3)
- refactor: reorganize Anthropic LLM class structure (4fc4f90)
- refactor: extract format helpers from prompt template (d371c12)
- refactor: simplify AgentTool type mapping with constant (c609949)
- refactor: standardize Action tag to use single-line JSON format (5ac06f0)
- refactor(context): simplify iteration handling and improve logging (3e65643)
- refactor(llms): remove max_tokens parameter from configurations (d7a1fc8)

### Performance
- perf: replace standard JSON parser with Oj for better performance (3fc969f)

### Chores
- chore: update gitignore and documentation (8dc5102)
- chore: adjust HTTP client timeout settings (38f47a7)
- chore: update .gitignore to include .serena (90e3d41)

## [0.0.5] - 2025-08-05

### Bug Fixes
- fix: remove confidence_score from examples and hook manager (12d9e8b)

### Tests
- test: fix Hash#inspect format compatibility for Ruby 3.4 (c9f1a31)

### Chores
- chore: update CI workflows to test multiple Ruby versions (d2e1b9a)
- chore: downgrade minimum Ruby version to 3.1 (8a3d7f0)

## [0.0.4] - 2025-08-04

### Features
- feat: add dynamic instructions via method support (e428631)

### Documentation
- docs: update README with dynamic instructions feature (b3f2d81)

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