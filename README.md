# Sublocator

[![Build Status](https://travis-ci.org/westonlit/sublocator.svg)](https://travis-ci.org/westonlit/sublocator) [![Coverage Status](https://coveralls.io/repos/github/westonlit/sublocator/badge.svg?branch=master)](https://coveralls.io/github/westonlit/sublocator?branch=master) [![hex.pm version](https://img.shields.io/hexpm/v/sublocator.svg)](https://hex.pm/packages/sublocator)

An Elixir library for identifying the location(s) of a pattern in a given string.

Using `Sublocator.locate/3`, the pattern can be a string, a list of strings, or
a regular expression, and the result is a list of simple line and column data or
an empty list.

## Installation

```elixir
def deps do
  [{:sublocator, "~> 0.1.0"}]
end
```

## Usage

Docs can be found at [https://hexdocs.pm/sublocator](https://hexdocs.pm/sublocator).
