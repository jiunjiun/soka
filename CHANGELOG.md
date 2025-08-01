# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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