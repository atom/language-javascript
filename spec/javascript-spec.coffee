{TextEditor} = require 'atom'
fs = require 'fs'
path = require 'path'

describe "Javascript grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-javascript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.js")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.js"

  describe "strings", ->
    it "tokenizes single-line strings", ->
      delimsByScope =
        "string.quoted.double.js": '"'
        "string.quoted.single.js": "'"

      for scope, delim of delimsByScope
        {tokens} = grammar.tokenizeLine(delim + "x" + delim)
        expect(tokens[0].value).toEqual delim
        expect(tokens[0].scopes).toEqual ["source.js", scope, "punctuation.definition.string.begin.js"]
        expect(tokens[1].value).toEqual "x"
        expect(tokens[1].scopes).toEqual ["source.js", scope]
        expect(tokens[2].value).toEqual delim
        expect(tokens[2].scopes).toEqual ["source.js", scope, "punctuation.definition.string.end.js"]

  describe "keywords", ->
    it "tokenizes with as a keyword", ->
      {tokens} = grammar.tokenizeLine('with')
      expect(tokens[0]).toEqual value: 'with', scopes: ['source.js', 'keyword.control.js']


  describe "built-in globals", ->
    it "tokenizes them as support classes", ->
      {tokens} = grammar.tokenizeLine('window')
      expect(tokens[0]).toEqual value: 'window', scopes: ['source.js', 'support.class.js']

      {tokens} = grammar.tokenizeLine('$window')
      expect(tokens[0]).toEqual value: '$window', scopes: ['source.js']

  describe "regular expressions", ->
    it "tokenizes regular expressions", ->
      {tokens} = grammar.tokenizeLine('/test/')
      expect(tokens[0]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[2]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']

      {tokens} = grammar.tokenizeLine('foo + /test/')
      expect(tokens[0]).toEqual value: 'foo ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '+', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[3]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[4]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[5]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']

    it "tokenizes regular expressions inside arrays", ->
      {tokens} = grammar.tokenizeLine('[/test/]')
      expect(tokens[0]).toEqual value: '[', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[1]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[2]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[3]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[4]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']

      {tokens} = grammar.tokenizeLine('[1, /test/]')
      expect(tokens[0]).toEqual value: '[', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[1]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.js']
      expect(tokens[2]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[4]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[5]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[6]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[7]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']

      {tokens} = grammar.tokenizeLine('0x1D306')
      expect(tokens[0]).toEqual value: '0x1D306', scopes: ['source.js', 'constant.numeric.js']

      {tokens} = grammar.tokenizeLine('0X1D306')
      expect(tokens[0]).toEqual value: '0X1D306', scopes: ['source.js', 'constant.numeric.js']

      {tokens} = grammar.tokenizeLine('0b011101110111010001100110')
      expect(tokens[0]).toEqual value: '0b011101110111010001100110', scopes: ['source.js', 'constant.numeric.js']

      {tokens} = grammar.tokenizeLine('0B011101110111010001100110')
      expect(tokens[0]).toEqual value: '0B011101110111010001100110', scopes: ['source.js', 'constant.numeric.js']

      {tokens} = grammar.tokenizeLine('0o1411')
      expect(tokens[0]).toEqual value: '0o1411', scopes: ['source.js', 'constant.numeric.js']

      {tokens} = grammar.tokenizeLine('0O1411')
      expect(tokens[0]).toEqual value: '0O1411', scopes: ['source.js', 'constant.numeric.js']

    it "verifies that regular expressions have explicit count modifiers", ->
      source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'javascript.cson'), 'utf8')
      expect(source.search /{,/).toEqual -1

      source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'regular expressions (javascript).cson'), 'utf8')
      expect(source.search /{,/).toEqual -1

  describe "operators", ->
    it "tokenizes void correctly", ->
      {tokens} = grammar.tokenizeLine('void')
      expect(tokens[0]).toEqual value: 'void', scopes: ['source.js', 'keyword.operator.js']

    it "tokenizes the / arithmetic operator when separated by newlines", ->
      lines = grammar.tokenizeLines """
        1
        / 2
      """

      expect(lines[0][0]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.js']
      expect(lines[1][0]).toEqual value: '/ ', scopes: ['source.js']
      expect(lines[1][1]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

    it "tokenizes = correctly", ->
      {tokens} = grammar.tokenizeLine('test = 2')
      expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[3]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

    it "tokenizes + correctly", ->
      {tokens} = grammar.tokenizeLine('test + 2')
      expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '+', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[3]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

    describe "operators with 2 characters", ->
      it "tokenizes += correctly", ->
        {tokens} = grammar.tokenizeLine('test += 2')
        expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '+=', scopes: ['source.js', 'keyword.operator.js']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
        expect(tokens[3]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

      it "tokenizes -= correctly", ->
        {tokens} = grammar.tokenizeLine('test -= 2')
        expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '-=', scopes: ['source.js', 'keyword.operator.js']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
        expect(tokens[3]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

      it "tokenizes *= correctly", ->
        {tokens} = grammar.tokenizeLine('test *= 2')
        expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '*=', scopes: ['source.js', 'keyword.operator.js']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
        expect(tokens[3]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

      it "tokenizes /= correctly", ->
        {tokens} = grammar.tokenizeLine('test /= 2')
        expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '/=', scopes: ['source.js', 'keyword.operator.js']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
        expect(tokens[3]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

  describe "constants", ->
    it "tokenizes ALL_CAPS variables as constants", ->
      {tokens} = grammar.tokenizeLine('var MY_COOL_VAR = 42;')
      expect(tokens[0]).toEqual value: 'var', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: 'MY_COOL_VAR', scopes: ['source.js', 'constant.other.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[5]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[6]).toEqual value: '42', scopes: ['source.js', 'constant.numeric.js']
      expect(tokens[7]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

      {tokens} = grammar.tokenizeLine('something = MY_COOL_VAR * 1;')
      expect(tokens[0]).toEqual value: 'something ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[3]).toEqual value: 'MY_COOL_VAR', scopes: ['source.js', 'constant.other.js']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[5]).toEqual value: '*', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[6]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[7]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.js']
      expect(tokens[8]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

    it "tokenizes variables declared using `const` as constants", ->
      {tokens} = grammar.tokenizeLine('const myCoolVar = 42;')
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: 'myCoolVar', scopes: ['source.js', 'constant.other.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[5]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[6]).toEqual value: '42', scopes: ['source.js', 'constant.numeric.js']
      expect(tokens[7]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

  describe "ES6 string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('`hey ${name}`')
      expect(tokens[0]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'hey ', scopes: ['source.js', 'string.quoted.template.js']
      expect(tokens[2]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[3]).toEqual value: 'name', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source']
      expect(tokens[4]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[5]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.end.js']

  describe "ES6 class", ->
    it "tokenizes class", ->
      {tokens} = grammar.tokenizeLine('class MyClass')
      expect(tokens[0]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[2]).toEqual value: 'MyClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes class...extends", ->
      {tokens} = grammar.tokenizeLine('class MyClass extends SomeClass')
      expect(tokens[0]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[2]).toEqual value: 'MyClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']
      expect(tokens[4]).toEqual value: 'extends', scopes: ['source.js', 'meta.class.js', 'storage.modifier.js']
      expect(tokens[6]).toEqual value: 'SomeClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes anonymous class", ->
      {tokens} = grammar.tokenizeLine('class extends SomeClass')
      expect(tokens[0]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[2]).toEqual value: 'extends', scopes: ['source.js', 'meta.class.js', 'storage.modifier.js']
      expect(tokens[4]).toEqual value: 'SomeClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

  describe "ES6 import", ->
    it "Tokenizes import ... as", ->
      {tokens} = grammar.tokenizeLine('import \'react\' as React')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[6]).toEqual value: 'as', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "Tokenizes import ... from", ->
      {tokens} = grammar.tokenizeLine('import React from \'react\'')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[4]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      {tokens} = grammar.tokenizeLine('import {React} from \'react\'')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[6]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

  describe "ES6 yield", ->
    it "Tokenizes yield", ->
      {tokens} = grammar.tokenizeLine('yield next')
      expect(tokens[0]).toEqual value: 'yield', scopes: ['source.js', 'meta.control.yield.js', 'keyword.control.js']

    it "Tokenizes yield*", ->
      {tokens} = grammar.tokenizeLine('yield * next')
      expect(tokens[0]).toEqual value: 'yield', scopes: ['source.js', 'meta.control.yield.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '*', scopes: ['source.js', 'meta.control.yield.js', 'storage.modifier.js']

  it "doesn't confuse strings and functions (regression)", ->
    {tokens} = grammar.tokenizeLine("'a'.b(':c(d)')")

    expect(tokens[0]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.begin.js']
    expect(tokens[1]).toEqual value: "a", scopes: ['source.js', 'string.quoted.single.js']
    expect(tokens[2]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.end.js']
    expect(tokens[3]).toEqual value: ".", scopes: ['source.js', 'meta.delimiter.method.period.js']
    expect(tokens[4]).toEqual value: "b", scopes: ['source.js']
    expect(tokens[5]).toEqual value: "(", scopes: ['source.js', 'meta.brace.round.js']
    expect(tokens[6]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.begin.js']
    expect(tokens[7]).toEqual value: ":c(d)", scopes: ['source.js', 'string.quoted.single.js']
    expect(tokens[8]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.end.js']
    expect(tokens[9]).toEqual value: ")", scopes: ['source.js', 'meta.brace.round.js']

  describe "default: in a switch statement", ->
    it "tokenizes it as a keyword", ->
      {tokens} = grammar.tokenizeLine('default: ')
      expect(tokens[0]).toEqual value: 'default', scopes: ['source.js', 'keyword.control.js']

  it "tokenizes arrow functions with params", ->
    {tokens} = grammar.tokenizeLine('(param1,param2)=>{}')
    expect(tokens[0]).toEqual value: '(', scopes: ['source.js', 'meta.function.arrow.js', 'punctuation.definition.parameters.begin.js']
    expect(tokens[1]).toEqual value: 'param1', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
    expect(tokens[3]).toEqual value: 'param2', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
    expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'meta.function.arrow.js', 'punctuation.definition.parameters.end.js']
    expect(tokens[5]).toEqual value: '=>', scopes: ['source.js', 'meta.function.arrow.js', 'storage.type.arrow.js']

  it "tokenizes comments in function params", ->
    {tokens} = grammar.tokenizeLine('foo: function (/**Bar*/bar){')

    expect(tokens[5]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']
    expect(tokens[6]).toEqual value: '/**', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[7]).toEqual value: 'Bar', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js']
    expect(tokens[8]).toEqual value: '*/', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[9]).toEqual value: 'bar', scopes: ['source.js', 'meta.function.json.js', 'variable.parameter.function.js']

  describe "non-anonymous functions", ->
    it "tokenizes methods", ->
      {tokens} = grammar.tokenizeLine('Foo.method = function nonAnonymous(')

      expect(tokens[0]).toEqual value: 'Foo', scopes: ['source.js', 'meta.function.js', 'support.class.js']
      expect(tokens[2]).toEqual value: 'method', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'meta.function.js', 'keyword.operator.js']
      expect(tokens[6]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[8]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[9]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes methods", ->
      {tokens} = grammar.tokenizeLine('f(a, b) {}')
      expect(tokens[0]).toEqual value: 'f', scopes: ['source.js', 'meta.method.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[2]).toEqual value: 'a', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[4]).toEqual value: 'b', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.end.js']

    it "tokenizes functions", ->
      {tokens} = grammar.tokenizeLine('var func = function nonAnonymous(')

      expect(tokens[0]).toEqual value: 'var', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'func', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'meta.function.js', 'keyword.operator.js']
      expect(tokens[6]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[8]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[9]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes object functions", ->
      {tokens} = grammar.tokenizeLine('foo: function nonAnonymous(')

      expect(tokens[0]).toEqual value: 'foo', scopes: ['source.js', 'meta.function.json.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: ':', scopes: ['source.js', 'meta.function.json.js', 'keyword.operator.js']
      expect(tokens[3]).toEqual value: 'function', scopes: ['source.js', 'meta.function.json.js', 'storage.type.function.js']
      expect(tokens[5]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.json.js', 'entity.name.function.js']
      expect(tokens[6]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes quoted object functions", ->
      {tokens} = grammar.tokenizeLine('"foo": function nonAnonymous(')

      expect(tokens[1]).toEqual value: 'foo', scopes: ['source.js', 'meta.function.json.js', 'string.quoted.double.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: ':', scopes: ['source.js', 'meta.function.json.js', 'keyword.operator.js']
      expect(tokens[5]).toEqual value: 'function', scopes: ['source.js', 'meta.function.json.js', 'storage.type.function.js']
      expect(tokens[7]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.json.js', 'entity.name.function.js']
      expect(tokens[8]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes async functions", ->
      {tokens} = grammar.tokenizeLine('async function f(){}')
      expect(tokens[0]).toEqual value: 'async', scopes: ['source.js', 'meta.function.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[4]).toEqual value: 'f', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']

  it "tokenizes /* */ comments", ->
    {tokens} = grammar.tokenizeLine('/**/')

    expect(tokens[0]).toEqual value: '/*', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: '*/', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']

    {tokens} = grammar.tokenizeLine('/* foo */')

    expect(tokens[0]).toEqual value: '/*', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.js', 'comment.block.js']
    expect(tokens[2]).toEqual value: '*/', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']

  it "tokenizes /** */ comments", ->
    {tokens} = grammar.tokenizeLine('/***/')

    expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']

    {tokens} = grammar.tokenizeLine('/** foo */')

    expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.js', 'comment.block.documentation.js']
    expect(tokens[2]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']

  describe "indentation", ->
    editor = null

    beforeEach ->
      editor = new TextEditor({})
      editor.setGrammar(grammar)

    expectPreservedIndentation = (text) ->
      editor.setText(text)
      editor.autoIndentBufferRows(0, editor.getLineCount() - 1)

      expectedLines = text.split("\n")
      actualLines = editor.getText().split("\n")
      for actualLine, i in actualLines
        expect([
          actualLine,
          editor.indentLevelForLine(actualLine)
        ]).toEqual([
          expectedLines[i],
          editor.indentLevelForLine(expectedLines[i])
        ])

    it "indents allman-style curly braces", ->
      expectPreservedIndentation """
        if (true)
        {
          for (;;)
          {
            while (true)
            {
              x();
            }
          }
        }
        else
        {
          do
          {
            y();
          } while (true);
        }
      """

    it "indents non-allman-style curly braces", ->
      expectPreservedIndentation """
        if (true) {
          for (;;) {
            while (true) {
              x();
            }
          }
        } else {
          do {
            y();
          } while (true);
        }
      """

    it "doesn't indent case statements, because it wouldn't know when to outdent", ->
      expectPreservedIndentation """
        switch (e) {
          case 5:
          something();
          case 6:
          somethingElse();
        }
      """

    it "indents collection literals", ->
      expectPreservedIndentation """
        [
          {
            a: b,
            c: d
          },
          e,
          f
        ]
      """

    it "indents function arguments", ->
      expectPreservedIndentation """
        f(
          g(
            h,
            i
          ),
          j
        );
      """
