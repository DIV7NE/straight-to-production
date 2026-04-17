// STP v1.1 — Tree-sitter queries per language (v0.20 ABI)
//
// Flat patterns only — tree-sitter 0.20 doesn't support the parent-context
// nesting (e.g. "(program (function_declaration))") that later ABIs do.
// We match any function/class/etc. declaration at any depth and let the
// caller decide scope. For most codebases this is what you want anyway —
// nested classes and helper functions are still meaningful in the graph.

'use strict';

// ── TypeScript / TSX / JavaScript ──────────────────────────────────
// Imports: ES6 named/default/namespace/bare
// Exports: export statement wrappers
// Symbols: function, class, variable declarations
const TS_JS_QUERY = `
  ; Imports — capture source + any named/default/namespace symbols
  (import_statement
    source: (string (string_fragment) @import.source))

  ; CommonJS: require("./foo")  or  const x = require("./foo")
  (call_expression
    function: (identifier) @_req
    arguments: (arguments (string (string_fragment) @import.source))
    (#eq? @_req "require"))

  ; Named imports: import { x, y } from "./foo"
  (import_specifier name: (identifier) @import.symbol)

  ; Default import: import Foo from "./foo"  → identifier inside import_clause
  (import_clause (identifier) @import.symbol)

  ; Namespace import: import * as Foo → namespace_import
  (namespace_import (identifier) @import.symbol)

  ; Function / class declarations
  (function_declaration name: (identifier) @symbol.function)
  (class_declaration name: (identifier) @symbol.class)

  ; Lexical declarations (const / let / var)
  (lexical_declaration
    (variable_declarator name: (identifier) @symbol.variable))
  (variable_declaration
    (variable_declarator name: (identifier) @symbol.variable))

  ; Export wrappers — capture the underlying symbol again with export.* prefix
  (export_statement
    (function_declaration name: (identifier) @export.function))
  (export_statement
    (class_declaration name: (identifier) @export.class))
  (export_statement
    (lexical_declaration
      (variable_declarator name: (identifier) @export.variable)))

  ; Re-export: export { Foo } from "./bar"
  (export_specifier name: (identifier) @export.symbol)
`;

// ── TypeScript-only additions (interfaces, type aliases) ────────────
const TS_EXTRA = `
  (interface_declaration name: (type_identifier) @symbol.interface)
  (type_alias_declaration name: (type_identifier) @symbol.type)
`;

// ── Python ────────────────────────────────────────────────────────
const PY_QUERY = `
  ; import foo  /  import foo.bar
  (import_statement
    name: (dotted_name) @import.source)

  ; from foo import bar
  (import_from_statement
    module_name: (dotted_name) @import.source)

  ; Function + class definitions (any depth — nested defs are still symbols)
  (function_definition name: (identifier) @symbol.function)
  (class_definition name: (identifier) @symbol.class)
`;

// ── Rust ──────────────────────────────────────────────────────────
const RUST_QUERY = `
  ; use foo::bar → capture the whole path as import source
  (use_declaration (scoped_identifier) @import.source)
  (use_declaration (identifier) @import.source)

  ; Top-level items (any visibility)
  (function_item name: (identifier) @symbol.function)
  (struct_item name: (type_identifier) @symbol.struct)
  (enum_item name: (type_identifier) @symbol.enum)
  (trait_item name: (type_identifier) @symbol.trait)
  (impl_item type: (type_identifier) @symbol.impl)
  (const_item name: (identifier) @symbol.const)
  (static_item name: (identifier) @symbol.static)
  (mod_item name: (identifier) @symbol.module)
`;

// ── Go ─────────────────────────────────────────────────────────────
const GO_QUERY = `
  ; import "foo"  /  import ( "a" "b" )
  (import_spec path: (interpreted_string_literal) @import.source)

  (function_declaration name: (identifier) @symbol.function)
  (method_declaration name: (field_identifier) @symbol.method)
  (type_spec name: (type_identifier) @symbol.type)
  (const_spec name: (identifier) @symbol.const)
  (var_spec name: (identifier) @symbol.variable)
`;

// ── Java ───────────────────────────────────────────────────────────
const JAVA_QUERY = `
  (import_declaration (scoped_identifier) @import.source)

  (class_declaration name: (identifier) @symbol.class)
  (interface_declaration name: (identifier) @symbol.interface)
  (enum_declaration name: (identifier) @symbol.enum)
  (method_declaration name: (identifier) @symbol.method)
`;

// ── C# ─────────────────────────────────────────────────────────────
const CSHARP_QUERY = `
  (using_directive (qualified_name) @import.source)
  (using_directive (identifier) @import.source)

  (class_declaration name: (identifier) @symbol.class)
  (struct_declaration name: (identifier) @symbol.struct)
  (interface_declaration name: (identifier) @symbol.interface)
  (enum_declaration name: (identifier) @symbol.enum)
  (method_declaration name: (identifier) @symbol.method)
  (namespace_declaration name: (qualified_name) @symbol.namespace)
  (namespace_declaration name: (identifier) @symbol.namespace)
`;

// ── C++ / C ────────────────────────────────────────────────────────
const CPP_QUERY = `
  (preproc_include path: (string_literal) @import.source)
  (preproc_include path: (system_lib_string) @import.source)

  (function_definition
    declarator: (function_declarator
      declarator: (identifier) @symbol.function))

  (class_specifier name: (type_identifier) @symbol.class)
  (struct_specifier name: (type_identifier) @symbol.struct)
  (namespace_definition name: (namespace_identifier) @symbol.namespace)
`;

// ── Export table ──────────────────────────────────────────────────
module.exports = {
  typescript: TS_JS_QUERY + '\n' + TS_EXTRA,
  tsx:        TS_JS_QUERY + '\n' + TS_EXTRA,
  javascript: TS_JS_QUERY,
  python:     PY_QUERY,
  rust:       RUST_QUERY,
  go:         GO_QUERY,
  java:       JAVA_QUERY,
  c_sharp:    CSHARP_QUERY,
  cpp:        CPP_QUERY,
  c:          CPP_QUERY,
};
