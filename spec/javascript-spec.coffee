fs = require 'fs'
path = require 'path'
{eq} = require './spec-helper'
TextEditor = null
buildTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor ?= require('atom').TextEditor
    new TextEditor(params)

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
        eq tokens[0], delim, scopes: 'source.js ' + scope + ' punctuation.definition.string.begin.js'
        eq tokens[1], 'x', scopes: 'source.js ' + scope
        eq tokens[2], delim, scopes: 'source.js ' + scope + ' punctuation.definition.string.end.js'

    it "tokenizes invalid multiline strings", ->
      delimsByScope =
        "string.quoted.double.js": '"'
        "string.quoted.single.js": "'"

      for scope, delim of delimsByScope
        lines = grammar.tokenizeLines delim + """
          line1
          line2\\
          line3
        """ + delim
        eq lines[0][0], delim, scopes: 'source.js ' + scope + ' punctuation.definition.string.begin.js'
        eq lines[0][1], 'line1', scopes: 'source.js ' + scope + ' invalid.illegal.string.js'
        eq lines[1][0], 'line2\\', scopes: 'source.js ' + scope
        eq lines[2][0], 'line3', scopes: 'source.js ' + scope
        eq lines[2][1], delim, scopes: 'source.js ' + scope + ' punctuation.definition.string.end.js'

  describe "keywords", ->
    it "tokenizes with as a keyword", ->
      {tokens} = grammar.tokenizeLine('with')
      eq tokens[0], 'with', scope: 'keyword.control.js'

    map =
      super: 'variable.language.js'
      this: 'variable.language.js'
      null: 'constant.language.null.js'
      true: 'constant.language.boolean.true.js'
      false: 'constant.language.boolean.false.js'
      debugger: 'keyword.other.js'
      exports: 'support.variable.js'
      __filename: 'support.variable.js'

    for keyword, scope of map
      do (keyword, scope) ->
        it "does not tokenize `#{keyword}` when it is an object key", ->
          {tokens} = grammar.tokenizeLine("#{keyword}: 1")
          eq tokens[0], keyword, scope: 'source.js'
          eq tokens[1], ':', scope: 'keyword.operator.js'

        it "tokenizes `#{keyword}` in the middle of ternary expressions", ->
          {tokens} = grammar.tokenizeLine("a ? #{keyword} : b")
          eq tokens[2], ' ', scope: 'source.js'
          eq tokens[3], keyword, scope: scope

        it "tokenizes `#{keyword}` at the end of ternary expressions", ->
          {tokens} = grammar.tokenizeLine("a ? b : #{keyword}")
          eq tokens[4], ' ', scope: 'source.js'
          eq tokens[5], keyword, scope: scope

  describe "built-in globals", ->
    it "tokenizes built-in classes", ->
      {tokens} = grammar.tokenizeLine('window')
      eq tokens[0], 'window', scope: 'support.class.js'

      {tokens} = grammar.tokenizeLine('window.name')
      eq tokens[0], 'window', scope: 'support.class.js'

      {tokens} = grammar.tokenizeLine('$window')
      eq tokens[0], '$window', scope: 'source.js'

    it "tokenizes built-in variables", ->
      {tokens} = grammar.tokenizeLine('module')
      eq tokens[0], 'module', scope: 'support.variable.js'

      {tokens} = grammar.tokenizeLine('module.prop')
      eq tokens[0], 'module', scope: 'support.variable.js'

  describe "instantiation", ->
    it "tokenizes the new keyword and instance entities", ->
      {tokens} = grammar.tokenizeLine('new something')
      eq tokens[0], 'new', scopes: '_ meta.class.instance.constructor keyword.operator.new.js'
      eq tokens[1], ' ', scope: 'meta.class.instance.constructor'
      eq tokens[2], 'something', scopes: '_ meta.class.instance.constructor entity.name.type.instance.js'

      {tokens} = grammar.tokenizeLine('new Something')
      eq tokens[0], 'new', scopes: '_ meta.class.instance.constructor keyword.operator.new.js'
      eq tokens[1], ' ', scope: 'meta.class.instance.constructor'
      eq tokens[2], 'Something', scopes: '_ meta.class.instance.constructor entity.name.type.instance.js'

      {tokens} = grammar.tokenizeLine('new $something')
      eq tokens[0], 'new', scopes: '_ meta.class.instance.constructor keyword.operator.new.js'
      eq tokens[1], ' ', scope: 'meta.class.instance.constructor'
      eq tokens[2], '$something', scopes: '_ meta.class.instance.constructor entity.name.type.instance.js'

  describe "regular expressions", ->
    it "tokenizes regular expressions", ->
      {tokens} = grammar.tokenizeLine('/test/')
      eq tokens[0], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[1], 'test', scope: 'string.regexp.js'
      eq tokens[2], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'

      {tokens} = grammar.tokenizeLine('foo + /test/')
      eq tokens[0], 'foo ', scope: 'source.js'
      eq tokens[1], '+', scope: 'keyword.operator.js'
      eq tokens[2], ' ', scope: 'string.regexp.js'
      eq tokens[3], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[4], 'test', scope: 'string.regexp.js'
      eq tokens[5], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'

    it "tokenizes regular expressions inside arrays", ->
      {tokens} = grammar.tokenizeLine('[/test/]')
      eq tokens[0], '[', scope: 'meta.brace.square.js'
      eq tokens[1], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[2], 'test', scope: 'string.regexp.js'
      eq tokens[3], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'
      eq tokens[4], ']', scope: 'meta.brace.square.js'

      {tokens} = grammar.tokenizeLine('[1, /test/]')
      eq tokens[0], '[', scope: 'meta.brace.square.js'
      eq tokens[1], '1', scope: 'constant.numeric.decimal.js'
      eq tokens[2], ',', scope: 'meta.delimiter.object.comma.js'
      eq tokens[3], ' ', scope: 'string.regexp.js'
      eq tokens[4], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[5], 'test', scope: 'string.regexp.js'
      eq tokens[6], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'
      eq tokens[7], ']', scope: 'meta.brace.square.js'

    it "tokenizes regular expressions inside ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? /b/ : /c/')
      eq tokens[0], 'a ', scope: 'source.js'
      eq tokens[1], '?', scope: 'keyword.operator.js'
      eq tokens[2], ' ', scope: 'string.regexp.js'
      eq tokens[3], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[4], 'b', scope: 'string.regexp.js'
      eq tokens[5], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'
      eq tokens[6], ' ', scope: 'source.js'
      eq tokens[7], ':', scope: 'keyword.operator.js'
      eq tokens[8], ' ', scope: 'string.regexp.js'
      eq tokens[9], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[10], 'c', scope: 'string.regexp.js'
      eq tokens[11], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'

    it "tokenizes regular expressions inside arrow function expressions", ->
      {tokens} = grammar.tokenizeLine('getRegex = () => /^helloworld$/;')
      eq tokens[9], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[10], '^', scopes: '_ string.regexp.js keyword.control.anchor.regexp'
      eq tokens[11], 'helloworld', scopes: '_ string.regexp.js'
      eq tokens[12], '$', scopes: '_ string.regexp.js keyword.control.anchor.regexp'
      eq tokens[13], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'
      eq tokens[14], ';', scopes: '_ punctuation.terminator.statement.js'

    it "verifies that regular expressions have explicit count modifiers", ->
      source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'javascript.cson'), 'utf8')
      expect(source.search /{,/).toEqual -1

      source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'regular expressions (javascript).cson'), 'utf8')
      expect(source.search /{,/).toEqual -1

  describe "numbers", ->
    it "tokenizes hexadecimals", ->
      {tokens} = grammar.tokenizeLine('0x1D306')
      eq tokens[0], '0x1D306', scope: 'constant.numeric.hex.js'

      {tokens} = grammar.tokenizeLine('0X1D306')
      eq tokens[0], '0X1D306', scope: 'constant.numeric.hex.js'

    it "tokenizes binary literals", ->
      {tokens} = grammar.tokenizeLine('0b011101110111010001100110')
      eq tokens[0], '0b011101110111010001100110', scope: 'constant.numeric.binary.js'

      {tokens} = grammar.tokenizeLine('0B011101110111010001100110')
      eq tokens[0], '0B011101110111010001100110', scope: 'constant.numeric.binary.js'

    it "tokenizes octal literals", ->
      {tokens} = grammar.tokenizeLine('0o1411')
      eq tokens[0], '0o1411', scope: 'constant.numeric.octal.js'

      {tokens} = grammar.tokenizeLine('0O1411')
      eq tokens[0], '0O1411', scope: 'constant.numeric.octal.js'

      {tokens} = grammar.tokenizeLine('0010')
      eq tokens[0], '0010', scope: 'constant.numeric.octal.js'

    it "tokenizes decimals", ->
      {tokens} = grammar.tokenizeLine('1234')
      eq tokens[0], '1234', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('5e-10')
      eq tokens[0], '5e-10', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('5E+5')
      eq tokens[0], '5E+5', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('9.')
      eq tokens[0], '9', scope: 'constant.numeric.decimal.js'
      eq tokens[1], '.', scopes: '_ constant.numeric.decimal.js meta.delimiter.decimal.period.js'

      {tokens} = grammar.tokenizeLine('.9')
      eq tokens[0], '.', scopes: '_ constant.numeric.decimal.js meta.delimiter.decimal.period.js'
      eq tokens[1], '9', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('9.9')
      eq tokens[0], '9', scope: 'constant.numeric.decimal.js'
      eq tokens[1], '.', scopes: '_ constant.numeric.decimal.js meta.delimiter.decimal.period.js'
      eq tokens[2], '9', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('.1e-23')
      eq tokens[0], '.', scopes: '_ constant.numeric.decimal.js meta.delimiter.decimal.period.js'
      eq tokens[1], '1e-23', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('1.E3')
      eq tokens[0], '1', scope: 'constant.numeric.decimal.js'
      eq tokens[1], '.', scopes: '_ constant.numeric.decimal.js meta.delimiter.decimal.period.js'
      eq tokens[2], 'E3', scope: 'constant.numeric.decimal.js'

    it "does not tokenize numbers that are part of a variable", ->
      {tokens} = grammar.tokenizeLine('hi$1')
      eq tokens[0], 'hi$1', scope: 'source.js'

      {tokens} = grammar.tokenizeLine('hi_1')
      eq tokens[0], 'hi_1', scope: 'source.js'

  describe "operators", ->
    it "tokenizes them", ->
      operators = ["delete", "in", "of", "instanceof", "new", "typeof", "void"]

      for operator in operators
        {tokens} = grammar.tokenizeLine(operator)
        eq tokens[0], operator, scope: 'keyword.operator.' + operator  + '.js'

    it "tokenizes spread operator", ->
      {tokens} = grammar.tokenizeLine('myFunction(...args);')
      eq tokens[2], '...', scopes: '_ meta.function-call.js meta.arguments.js keyword.operator.spread.js'
      eq tokens[3], 'args', scopes: '_ meta.function-call.js meta.arguments.js'

      {tokens} = grammar.tokenizeLine('[...iterableObj]')
      eq tokens[1], '...', scope: 'keyword.operator.spread.js'
      eq tokens[2], 'iterableObj', scope: 'source.js'

    describe "increment, decrement", ->
      it "tokenizes increment", ->
        {tokens} = grammar.tokenizeLine('i++')
        eq tokens[0], 'i', scope: 'source.js'
        eq tokens[1], '++', scope: 'keyword.operator.increment.js'

      it "tokenizes decrement", ->
        {tokens} = grammar.tokenizeLine('i--')
        eq tokens[0], 'i', scope: 'source.js'
        eq tokens[1], '--', scope: 'keyword.operator.decrement.js'

    describe "conditional ternary", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine('test ? expr1 : expr2')
        eq tokens[0], 'test ', scope: 'source.js'
        eq tokens[1], '?', scope: 'keyword.operator.js'
        eq tokens[2], ' expr1 ', scope: 'source.js'
        eq tokens[3], ':', scope: 'keyword.operator.js'
        eq tokens[4], ' expr2', scope: 'source.js'

    describe "logical", ->
      operators = ["&&", "||", "!"]

      it "tokenizes them", ->
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          eq tokens[0], 'a ', scope: 'source.js'
          eq tokens[1], operator, scope: 'keyword.operator.logical.js'
          eq tokens[2], ' b', scope: 'source.js'

    describe "comparison", ->
      operators = ["<=", ">=", "!=", "!==", "===", "==", "<", ">" ]

      it "tokenizes them", ->
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          eq tokens[0], 'a ', scope: 'source.js'
          eq tokens[1], operator, scope: 'keyword.operator.comparison.js'
          eq tokens[2], ' b', scope: 'source.js'

    describe "bitwise", ->
      it "tokenizes bitwise 'not'", ->
        {tokens} = grammar.tokenizeLine('~a')
        eq tokens[0], '~', scope: 'keyword.operator.bitwise.js'
        eq tokens[1], 'a', scope: 'source.js'

      it "tokenizes them", ->
        operators = ["|", "^", "&"]

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          eq tokens[0], 'a ', scope: 'source.js'
          eq tokens[1], operator, scope: 'keyword.operator.bitwise.js'
          eq tokens[2], ' b', scope: 'source.js'

    describe "arithmetic", ->
      operators = ["*", "/", "-", "%", "+"]

      it "tokenizes them", ->
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          eq tokens[0], 'a ', scope: 'source.js'
          eq tokens[1], operator, scope: 'keyword.operator.js'
          eq tokens[2], ' b', scope: 'source.js'

      it "tokenizes the arithmetic operators when separated by newlines", ->
        for operator in operators
          lines = grammar.tokenizeLines '1\n' + operator + ' 2'
          eq lines[0][0], '1', scope: 'constant.numeric.decimal.js'
          eq lines[1][0], operator, scope: 'keyword.operator.js'
          eq lines[1][2], '2', scope: 'constant.numeric.decimal.js'

    describe "assignment", ->
      it "tokenizes '=' operator", ->
        {tokens} = grammar.tokenizeLine('a = b')
        eq tokens[0], 'a ', scope: 'source.js'
        eq tokens[1], '=', scope: 'keyword.operator.assignment.js'
        eq tokens[2], ' b', scope: 'source.js'

      describe "compound", ->
        it "tokenizes them", ->
          operators = ["+=", "-=", "*=", "/=", "%="]
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            eq tokens[0], 'a ', scope: 'source.js'
            eq tokens[1], operator, scope: 'keyword.operator.assignment.compound.js'
            eq tokens[2], ' b', scope: 'source.js'

        describe "bitwise", ->
          it "tokenizes them", ->
            operators = ["<<=", ">>=", ">>>=", "&=", "^=", "|="]
            for operator in operators
              {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
              eq tokens[0], 'a ', scope: 'source.js'
              eq tokens[1], operator, scope: '_ keyword.operator.assignment.compound.bitwise.js'
              eq tokens[2], ' b', scope: 'source.js'

  describe "constants", ->
    it "tokenizes ALL_CAPS variables as constants", ->
      {tokens} = grammar.tokenizeLine('var MY_COOL_VAR = 42;')
      eq tokens[0], 'var', scope: 'storage.type.var.js'
      eq tokens[1], ' ', scope: 'source.js'
      eq tokens[2], 'MY_COOL_VAR', scope: 'constant.other.js'
      eq tokens[3], ' ', scope: 'source.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'
      eq tokens[5], ' ', scope: 'source.js'
      eq tokens[6], '42', scope: 'constant.numeric.decimal.js'
      eq tokens[7], ';', scope: 'punctuation.terminator.statement.js'

      {tokens} = grammar.tokenizeLine('something = MY_COOL_VAR * 1;')
      eq tokens[0], 'something ', scope: 'source.js'
      eq tokens[1], '=', scope: 'keyword.operator.assignment.js'
      eq tokens[2], ' ', scope: 'source.js'
      eq tokens[3], 'MY_COOL_VAR', scope: 'constant.other.js'
      eq tokens[4], ' ', scope: 'source.js'
      eq tokens[5], '*', scope: 'keyword.operator.js'
      eq tokens[6], ' ', scope: 'source.js'
      eq tokens[7], '1', scope: 'constant.numeric.decimal.js'
      eq tokens[8], ';', scope: 'punctuation.terminator.statement.js'

    it "tokenizes variables declared using `const` as constants", ->
      {tokens} = grammar.tokenizeLine('const myCoolVar = 42;')
      eq tokens[0], 'const', scope: 'storage.modifier.js'
      eq tokens[1], ' ', scope: 'source.js'
      eq tokens[2], 'myCoolVar', scope: 'constant.other.js'
      eq tokens[3], ' ', scope: 'source.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'
      eq tokens[5], ' ', scope: 'source.js'
      eq tokens[6], '42', scope: 'constant.numeric.decimal.js'
      eq tokens[7], ';', scope: 'punctuation.terminator.statement.js'

      lines = grammar.tokenizeLines """
        const a,
        b,
        c
        if(a)
      """
      eq lines[0][0], 'const', scopes: '_ storage.modifier.js'
      eq lines[0][1], ' ', scope: 'source.js'
      eq lines[0][2], 'a', scope: 'constant.other.js'
      eq lines[0][3], ',', scope: 'meta.delimiter.object.comma.js'
      eq lines[1][0], 'b', scope: 'constant.other.js'
      eq lines[1][1], ',', scope: 'meta.delimiter.object.comma.js'
      eq lines[2][0], 'c', scope: 'constant.other.js'
      eq lines[3][0], 'if', scope: 'keyword.control.js'
      eq lines[3][1], '(', scope: 'meta.brace.round.js'
      eq lines[3][2], 'a', scope: 'source.js'
      eq lines[3][3], ')', scope: 'meta.brace.round.js'

      {tokens} = grammar.tokenizeLine('(const hi);')
      eq tokens[0], '(', scope: 'meta.brace.round.js'
      eq tokens[1], 'const', scope: 'storage.modifier.js'
      eq tokens[2], ' ', scope: 'source.js'
      eq tokens[3], 'hi', scope: 'constant.other.js'
      eq tokens[4], ')', scope: 'meta.brace.round.js'
      eq tokens[5], ';', scope: 'punctuation.terminator.statement.js'

      {tokens} = grammar.tokenizeLine('const {first:f,second,...rest} = obj;')
      eq tokens[0], 'const', scope: 'storage.modifier.js'
      eq tokens[1], ' ', scope: 'source.js'
      eq tokens[2], '{', scope: 'meta.brace.curly.js'
      eq tokens[3], 'first', scope: 'source.js'
      eq tokens[4], ':', scope: 'keyword.operator.assignment.js'
      eq tokens[5], 'f', scope: 'constant.other.js'
      eq tokens[6], ',', scope: 'meta.delimiter.object.comma.js'
      eq tokens[7], 'second', scope: 'constant.other.js'
      eq tokens[8], ',', scope: 'meta.delimiter.object.comma.js'
      eq tokens[9], '...', scope: 'keyword.operator.spread.js'
      eq tokens[10], 'rest', scope: 'constant.other.js'
      eq tokens[11], '}', scope: 'meta.brace.curly.js'
      eq tokens[12], ' ', scope: 'source.js'
      eq tokens[13], '=', scope: 'keyword.operator.assignment.js'
      eq tokens[14], ' obj', scope: 'source.js'
      eq tokens[15], ';', scope: 'punctuation.terminator.statement.js'

      {tokens} = grammar.tokenizeLine('const c = /regex/;')
      eq tokens[0], 'const', scope: 'storage.modifier.js'
      eq tokens[1], ' ', scope: 'source.js'
      eq tokens[2], 'c', scope: 'constant.other.js'
      eq tokens[3], ' ', scope: 'source.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'
      eq tokens[5], ' ', scope: 'string.regexp.js'
      eq tokens[6], '/', scopes: '_ string.regexp.js punctuation.definition.string.begin.js'
      eq tokens[7], 'regex', scope: 'string.regexp.js'
      eq tokens[8], '/', scopes: '_ string.regexp.js punctuation.definition.string.end.js'
      eq tokens[9], ';', scope: 'punctuation.terminator.statement.js'

    it "tokenizes variables declared with `const` in for-in and for-of loops", ->
      {tokens} = grammar.tokenizeLine 'for (const elem of array) {'
      eq tokens[0], 'for', scope: 'keyword.control.js'
      eq tokens[1], ' ', scope: 'source.js'
      eq tokens[2], '(', scope: 'meta.brace.round.js'
      eq tokens[3], 'const', scope: 'storage.modifier.js'
      eq tokens[4], ' ', scope: 'source.js'
      eq tokens[5], 'elem', scope: 'constant.other.js'
      eq tokens[6], ' ', scope: 'source.js'
      eq tokens[7], 'of', scope: 'keyword.operator.of.js'
      eq tokens[8], ' array', scope: 'source.js'
      eq tokens[9], ')', scope: 'meta.brace.round.js'

      {tokens} = grammar.tokenizeLine 'for (const name in object) {'
      eq tokens[5], 'name', scope: 'constant.other.js'
      eq tokens[6], ' ', scope: 'source.js'
      eq tokens[7], 'in', scope: 'keyword.operator.in.js'
      eq tokens[8], ' object', scope: 'source.js'

      {tokens} = grammar.tokenizeLine 'const index = 0;'
      eq tokens[0], 'const', scope: 'storage.modifier.js'
      eq tokens[2], 'index', scope: 'constant.other.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'

      {tokens} = grammar.tokenizeLine 'const offset = 0;'
      eq tokens[0], 'const', scope: 'storage.modifier.js'
      eq tokens[2], 'offset', scope: 'constant.other.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'

    it "tokenizes support constants", ->
      {tokens} = grammar.tokenizeLine('awesome = cool.systemLanguage;')
      eq tokens[0], 'awesome ', scope: 'source.js'
      eq tokens[1], '=', scope: 'keyword.operator.assignment.js'
      eq tokens[3], 'cool', scope: 'variable.other.object.js'
      eq tokens[4], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[5], 'systemLanguage', scope: 'support.constant.js'
      eq tokens[6], ';', scope: 'punctuation.terminator.statement.js'

    it "does not tokenize constants when they are object keys", ->
      {tokens} = grammar.tokenizeLine('FOO: 1')
      eq tokens[0], 'FOO', scope: 'source.js'
      eq tokens[1], ':', scope: 'keyword.operator.js'

    it "tokenizes constants in the middle of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? FOO : b')
      eq tokens[3], 'FOO', scope: 'constant.other.js'

    it "tokenizes constants at the end of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? b : FOO')
      eq tokens[5], 'FOO', scope: 'constant.other.js'

  describe "ES6 string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('`hey ${name}`')
      eq tokens[0], '`', scopes: '_ string.quoted.template.js punctuation.definition.string.begin.js'
      eq tokens[1], 'hey ', scope: 'string.quoted.template.js'
      eq tokens[2], '${', scopes: '_ string.quoted.template.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[3], 'name', scopes: '_ string.quoted.template.js source.js.embedded.source'
      eq tokens[4], '}', scopes: '_ string.quoted.template.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[5], '`', scopes: '_ string.quoted.template.js punctuation.definition.string.end.js'

      {tokens} = grammar.tokenizeLine('`hey ${() => {return hi;}}`')
      eq tokens[0], '`', scopes: '_ string.quoted.template.js punctuation.definition.string.begin.js'
      eq tokens[1], 'hey ', scopes: '_ string.quoted.template.js'
      eq tokens[2], '${', scopes: '_ _ source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[3], '(', scopes: '_ _ source.js.embedded.source _ _ punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[4], ')', scopes: '_ _ source.js.embedded.source _ _ punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[6], '=>', scopes: '_ _ source.js.embedded.source _ storage.type.function.arrow.js'
      eq tokens[8], '{', scopes: '_ _ source.js.embedded.source punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[9], 'return', scopes: '_ _ source.js.embedded.source keyword.control.js'
      eq tokens[10], ' hi', scopes: '_ _ source.js.embedded.source'
      eq tokens[11], ';', scopes: '_ _ source.js.embedded.source punctuation.terminator.statement.js'
      eq tokens[12], '}', scopes: '_ _ source.js.embedded.source punctuation.definition.function.body.end.bracket.curly.js'
      eq tokens[13], '}', scopes: '_ _ source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[14], '`', scopes: '_ string.quoted.template.js punctuation.definition.string.end.js'

  describe "ES6 tagged HTML string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('html`hey <b>${name}</b>`')
      eq tokens[0], 'html', scopes: '_ string.quoted.template.html.js entity.name.function.js'
      eq tokens[1], '`', scopes: '_ string.quoted.template.html.js punctuation.definition.string.begin.js'
      eq tokens[2], 'hey <b>', scope: 'string.quoted.template.html.js'
      eq tokens[3], '${', scopes: '_ string.quoted.template.html.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[4], 'name', scopes: '_ string.quoted.template.html.js source.js.embedded.source'
      eq tokens[5], '}', scopes: '_ string.quoted.template.html.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[6], '</b>', scope: 'string.quoted.template.html.js'
      eq tokens[7], '`', scopes: '_ string.quoted.template.html.js punctuation.definition.string.end.js'

  describe "ES6 tagged HTML string templates with expanded function name", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeHTML`hey <b>${name}</b>`')
      eq tokens[0], 'escapeHTML', scopes: '_ string.quoted.template.html.js entity.name.function.js'
      eq tokens[1], '`', scopes: '_ string.quoted.template.html.js punctuation.definition.string.begin.js'
      eq tokens[2], 'hey <b>', scope: 'string.quoted.template.html.js'
      eq tokens[3], '${', scopes: '_ string.quoted.template.html.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[4], 'name', scopes: '_ string.quoted.template.html.js source.js.embedded.source'
      eq tokens[5], '}', scopes: '_ string.quoted.template.html.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[6], '</b>', scope: 'string.quoted.template.html.js'
      eq tokens[7], '`', scopes: '_ string.quoted.template.html.js punctuation.definition.string.end.js'

  describe "ES6 tagged HTML string templates with expanded function name and white space", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeHTML   `hey <b>${name}</b>`')
      eq tokens[0], 'escapeHTML', scopes: '_ string.quoted.template.html.js entity.name.function.js'
      eq tokens[1], '   ', scope: 'string.quoted.template.html.js'
      eq tokens[2], '`', scopes: '_ string.quoted.template.html.js punctuation.definition.string.begin.js'
      eq tokens[3], 'hey <b>', scope: 'string.quoted.template.html.js'
      eq tokens[4], '${', scopes: '_ string.quoted.template.html.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[5], 'name', scopes: '_ string.quoted.template.html.js source.js.embedded.source'
      eq tokens[6], '}', scopes: '_ string.quoted.template.html.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[7], '</b>', scope: 'string.quoted.template.html.js'
      eq tokens[8], '`', scopes: '_ string.quoted.template.html.js punctuation.definition.string.end.js'

  describe "ES6 tagged CSS string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('css`.highlight { border: ${borderSize}; }`')
      eq tokens[0], 'css', scopes: '_ string.quoted.template.css.js entity.name.function.js'
      eq tokens[1], '`', scopes: '_ string.quoted.template.css.js punctuation.definition.string.begin.js'
      eq tokens[2], '.highlight { border: ', scope: 'string.quoted.template.css.js'
      eq tokens[3], '${', scopes: '_ string.quoted.template.css.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[4], 'borderSize', scopes: '_ string.quoted.template.css.js source.js.embedded.source'
      eq tokens[5], '}', scopes: '_ string.quoted.template.css.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[6], '; }', scope: 'string.quoted.template.css.js'
      eq tokens[7], '`', scopes: '_ string.quoted.template.css.js punctuation.definition.string.end.js'

  describe "ES6 tagged CSS string templates with expanded function name", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeCSS`.highlight { border: ${borderSize}; }`')
      eq tokens[0], 'escapeCSS', scopes: '_ string.quoted.template.css.js entity.name.function.js'
      eq tokens[1], '`', scopes: '_ string.quoted.template.css.js punctuation.definition.string.begin.js'
      eq tokens[2], '.highlight { border: ', scope: 'string.quoted.template.css.js'
      eq tokens[3], '${', scopes: '_ string.quoted.template.css.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[4], 'borderSize', scopes: '_ string.quoted.template.css.js source.js.embedded.source'
      eq tokens[5], '}', scopes: '_ string.quoted.template.css.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[6], '; }', scope: 'string.quoted.template.css.js'
      eq tokens[7], '`', scopes: '_ string.quoted.template.css.js punctuation.definition.string.end.js'

  describe "ES6 tagged CSS string templates with expanded function name and white space", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeCSS   `.highlight { border: ${borderSize}; }`')
      eq tokens[0], 'escapeCSS', scopes: '_ string.quoted.template.css.js entity.name.function.js'
      eq tokens[1], '   ', scope: 'string.quoted.template.css.js'
      eq tokens[2], '`', scopes: '_ string.quoted.template.css.js punctuation.definition.string.begin.js'
      eq tokens[3], '.highlight { border: ', scope: 'string.quoted.template.css.js'
      eq tokens[4], '${', scopes: '_ string.quoted.template.css.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[5], 'borderSize', scopes: '_ string.quoted.template.css.js source.js.embedded.source'
      eq tokens[6], '}', scopes: '_ string.quoted.template.css.js source.js.embedded.source punctuation.section.embedded.js'
      eq tokens[7], '; }', scope: 'string.quoted.template.css.js'
      eq tokens[8], '`', scopes: '_ string.quoted.template.css.js punctuation.definition.string.end.js'

  describe "ES6 tagged Relay.QL string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('Relay.QL`fragment on Foo { id }`')
      expect(tokens[0]).toEqual value: 'Relay.QL', scopes: [ 'source.js', 'string.quoted.template.graphql.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.graphql.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[2]).toEqual value: 'fragment on Foo { id }', scopes: ['source.js', 'string.quoted.template.graphql.js']
      expect(tokens[3]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.graphql.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged Relay.QL string templates with interpolation", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('Relay.QL`fragment on Foo { ${myFragment} }`')
      expect(tokens[0]).toEqual value: 'Relay.QL', scopes: [ 'source.js', 'string.quoted.template.graphql.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.graphql.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[2]).toEqual value: 'fragment on Foo { ', scopes: ['source.js', 'string.quoted.template.graphql.js']
      expect(tokens[3]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.graphql.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[4]).toEqual value: 'myFragment', scopes: ['source.js', 'string.quoted.template.graphql.js', 'source.js.embedded.source']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.graphql.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[6]).toEqual value: ' }', scopes: ['source.js', 'string.quoted.template.graphql.js']
      expect(tokens[7]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.graphql.js', 'punctuation.definition.string.end.js']

  describe "ES6 class", ->
    it "tokenizes class", ->
      {tokens} = grammar.tokenizeLine('class MyClass')
      eq tokens[0], 'class', scopes: '_ meta.class.js storage.type.class.js'
      eq tokens[2], 'MyClass', scopes: '_ meta.class.js entity.name.type.js'

      {tokens} = grammar.tokenizeLine('class $abc$')
      eq tokens[2], '$abc$', scopes: '_ meta.class.js entity.name.type.js'

      {tokens} = grammar.tokenizeLine('class $$')
      eq tokens[2], '$$', scopes: '_ meta.class.js entity.name.type.js'

    it "tokenizes class...extends", ->
      {tokens} = grammar.tokenizeLine('class MyClass extends SomeClass')
      eq tokens[0], 'class', scopes: '_ meta.class.js storage.type.class.js'
      eq tokens[2], 'MyClass', scopes: '_ meta.class.js entity.name.type.js'
      eq tokens[4], 'extends', scopes: '_ meta.class.js storage.modifier.js'
      eq tokens[6], 'SomeClass', scopes: '_ meta.class.js entity.name.type.js'

      {tokens} = grammar.tokenizeLine('class MyClass extends $abc$')
      eq tokens[6], '$abc$', scopes: '_ meta.class.js entity.name.type.js'

      {tokens} = grammar.tokenizeLine('class MyClass extends $$')
      eq tokens[6], '$$', scopes: '_ meta.class.js entity.name.type.js'

    it "tokenizes anonymous class", ->
      {tokens} = grammar.tokenizeLine('class extends SomeClass')
      eq tokens[0], 'class', scopes: '_ meta.class.js storage.type.class.js'
      eq tokens[2], 'extends', scopes: '_ meta.class.js storage.modifier.js'
      eq tokens[4], 'SomeClass', scopes: '_ meta.class.js entity.name.type.js'

      {tokens} = grammar.tokenizeLine('class extends $abc$')
      eq tokens[4], '$abc$', scope: 'entity.name.type.js'

      {tokens} = grammar.tokenizeLine('class extends $$')
      eq tokens[4], '$$', scope: 'entity.name.type.js'

    it "tokenizes constructors", ->
      {tokens} = grammar.tokenizeLine('constructor(p1, p2)')
      eq tokens[0], 'constructor', scope: 'entity.name.function.constructor.js'
      eq tokens[1], '(', scopes: '_ meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[2], 'p1', scopes: '_ _ variable.parameter.function.js'
      eq tokens[3], ',', scopes: '_ _ meta.delimiter.object.comma.js'
      eq tokens[5], 'p2', scopes: '_ _ variable.parameter.function.js'
      eq tokens[6], ')', scopes: '_ meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'

  describe "ES6 import", ->
    it "tokenizes import", ->
      {tokens} = grammar.tokenizeLine('import "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], '"', scopes: '_ meta.import.js string.quoted.double.js punctuation.definition.string.begin.js'
      eq tokens[3], 'module-name', scopes: '_ meta.import.js string.quoted.double.js'
      eq tokens[4], '"', scopes: '_ meta.import.js string.quoted.double.js punctuation.definition.string.end.js'
      eq tokens[5], ';', scope: 'punctuation.terminator.statement.js'

    it "tokenizes default import", ->
      {tokens} = grammar.tokenizeLine('import defaultMember from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], 'defaultMember', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[4], 'from', scopes: '_ meta.import.js keyword.control.js'

    it "tokenizes default named import", ->
      {tokens} = grammar.tokenizeLine('import { default as defaultMember } from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.import.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'default', scopes: '_ meta.import.js variable.language.default.js'
      eq tokens[6], 'as', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[8], 'defaultMember', scopes: '_ meta.import.js variable.other.module-alias.js'
      eq tokens[10], '}', scopes: '_ meta.import.js punctuation.definition.modules.end.js'
      eq tokens[12], 'from', scopes: '_ meta.import.js keyword.control.js'

    it "tokenizes named import", ->
      {tokens} = grammar.tokenizeLine('import { member } from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.import.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'member', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[6], '}', scopes: '_ meta.import.js punctuation.definition.modules.end.js'
      eq tokens[8], 'from', scopes: '_ meta.import.js keyword.control.js'

      {tokens} = grammar.tokenizeLine('import { member1 , member2 as alias2 } from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.import.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'member1', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[6], ',', scopes: '_ meta.import.js meta.delimiter.object.comma.js'
      eq tokens[8], 'member2', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[10], 'as', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[12], 'alias2', scopes: '_ meta.import.js variable.other.module-alias.js'
      eq tokens[14], '}', scopes: '_ meta.import.js punctuation.definition.modules.end.js'
      eq tokens[16], 'from', scopes: '_ meta.import.js keyword.control.js'

    it "tokenizes entire module import", ->
      {tokens} = grammar.tokenizeLine('import * as name from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], '*', scopes: '_ meta.import.js variable.language.import-all.js'
      eq tokens[4], 'as', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[6], 'name', scopes: '_ meta.import.js variable.other.module-alias.js'
      eq tokens[8], 'from', scopes: '_ meta.import.js keyword.control.js'

    it "tokenizes `import defaultMember, { member } from 'module-name';`", ->
      {tokens} = grammar.tokenizeLine('import defaultMember, { member } from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], 'defaultMember', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[3], ',', scopes: '_ meta.import.js meta.delimiter.object.comma.js'
      eq tokens[5], '{', scopes: '_ meta.import.js punctuation.definition.modules.begin.js'
      eq tokens[7], 'member', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[9], '}', scopes: '_ meta.import.js punctuation.definition.modules.end.js'
      eq tokens[11], 'from', scopes: '_ meta.import.js keyword.control.js'

    it "tokenizes `import defaultMember, * as alias from 'module-name';", ->
      {tokens} = grammar.tokenizeLine('import defaultMember, * as alias from "module-name";')
      eq tokens[0], 'import', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[2], 'defaultMember', scopes: '_ meta.import.js variable.other.module.js'
      eq tokens[3], ',', scopes: '_ meta.import.js meta.delimiter.object.comma.js'
      eq tokens[5], '*', scopes: '_ meta.import.js variable.language.import-all.js'
      eq tokens[7], 'as', scopes: '_ meta.import.js keyword.control.js'
      eq tokens[9], 'alias', scopes: '_ meta.import.js variable.other.module-alias.js'
      eq tokens[11], 'from', scopes: '_ meta.import.js keyword.control.js'

    it "tokenizes comments in statement", ->
      lines = grammar.tokenizeLines '''
        import /* comment */ {
          member1, // comment
          /* comment */
          member2
        } from "module-name";
      '''
      eq lines[0][2], '/*', scopes: '_ meta.import.js comment.block.js punctuation.definition.comment.js'
      eq lines[0][3], ' comment ', scopes: '_ meta.import.js comment.block.js'
      eq lines[0][4], '*/', scopes: '_ meta.import.js comment.block.js punctuation.definition.comment.js'
      eq lines[1][4], '//', scopes: '_ meta.import.js comment.line.double-slash.js punctuation.definition.comment.js'
      eq lines[1][5], ' comment', scopes: '_ meta.import.js comment.line.double-slash.js'
      eq lines[2][1], '/*', scopes: '_ meta.import.js comment.block.js punctuation.definition.comment.js'
      eq lines[2][2], ' comment ', scopes: '_ meta.import.js comment.block.js'
      eq lines[2][3], '*/', scopes: '_ meta.import.js comment.block.js punctuation.definition.comment.js'

  describe "ES6 export", ->
    it "tokenizes named export", ->
      {tokens} = grammar.tokenizeLine('export var x = 0;')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'var', scope: 'storage.type.var.js'
      eq tokens[3], ' x ', scope: 'source.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'

      {tokens} = grammar.tokenizeLine('export let scopedVariable = 0;')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'let', scope: 'storage.type.var.js'
      eq tokens[3], ' scopedVariable ', scope: 'source.js'
      eq tokens[4], '=', scope: 'keyword.operator.assignment.js'

      {tokens} = grammar.tokenizeLine('export const CONSTANT = 0;')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'const', scope: 'storage.modifier.js'
      eq tokens[4], 'CONSTANT', scope: 'constant.other.js'
      eq tokens[6], '=', scope: 'keyword.operator.assignment.js'

    it "tokenizes named function export", ->
      {tokens} = grammar.tokenizeLine('export function func(p1, p2){}')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[4], 'func', scopes: '_ meta.function.js entity.name.function.js'

    it "tokenizes named class export", ->
      {tokens} = grammar.tokenizeLine('export class Foo {}')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'class', scopes: '_ meta.class.js storage.type.class.js'
      eq tokens[4], 'Foo', scopes: '_ meta.class.js entity.name.type.js'

    it "tokenizes existing variable export", ->
      {tokens} = grammar.tokenizeLine('export { bar };')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.export.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'bar', scopes: '_ meta.export.js variable.other.module.js'
      eq tokens[6], '}', scopes: '_ meta.export.js punctuation.definition.modules.end.js'

      {tokens} = grammar.tokenizeLine('export { bar, foo as alias };')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.export.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'bar', scopes: '_ meta.export.js variable.other.module.js'
      eq tokens[5], ',', scopes: '_ meta.export.js meta.delimiter.object.comma.js'
      eq tokens[7], 'foo', scopes: '_ meta.export.js variable.other.module.js'
      eq tokens[9], 'as', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[11], 'alias', scopes: '_ meta.export.js variable.other.module-alias.js'
      eq tokens[13], '}', scopes: '_ meta.export.js punctuation.definition.modules.end.js'

    it "tokenizes default export", ->
      {tokens} = grammar.tokenizeLine('export default 123;')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], '123', scope: 'constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('export default name;')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], 'name', scopes: '_ meta.export.js variable.other.module.js'

      {tokens} = grammar.tokenizeLine('export { foo as default };')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.export.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'foo', scopes: '_ meta.export.js variable.other.module.js'
      eq tokens[6], 'as', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[8], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[10], '}', scopes: '_ meta.export.js punctuation.definition.modules.end.js'

      {tokens} = grammar.tokenizeLine('''
      export default {
        'prop': 'value'
      };
      ''')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], '{', scopes: '_ meta.brace.curly.js'
      eq tokens[6], "'", scopes: '_ string.quoted.single.js punctuation.definition.string.begin.js'
      eq tokens[7], 'prop', scope: 'string.quoted.single.js'
      eq tokens[8], "'", scopes: '_ string.quoted.single.js punctuation.definition.string.end.js'
      eq tokens[9], ':', scopes: '_ keyword.operator.js'
      eq tokens[11], "'", scopes: '_ string.quoted.single.js punctuation.definition.string.begin.js'
      eq tokens[12], 'value', scopes: '_ string.quoted.single.js'
      eq tokens[13], "'", scopes: '_ string.quoted.single.js punctuation.definition.string.end.js'
      eq tokens[15], '}', scopes: '_ meta.brace.curly.js'

    it "tokenizes default function export", ->
      {tokens} = grammar.tokenizeLine('export default function () {}')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], 'function', scopes: '_ meta.function.js storage.type.function.js'

      {tokens} = grammar.tokenizeLine('export default function func() {}')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], 'function', scopes: '_ meta.function.js storage.type.function.js'

    it "tokenizes comments in statement", ->
      lines = grammar.tokenizeLines '''
        export {
          member1, // comment
          /* comment */
          member2
        };
      '''
      eq lines[1][4], '//', scopes: '_ meta.export.js comment.line.double-slash.js punctuation.definition.comment.js'
      eq lines[1][5], ' comment', scopes: '_ meta.export.js comment.line.double-slash.js'
      eq lines[2][1], '/*', scopes: '_ meta.export.js comment.block.js punctuation.definition.comment.js'
      eq lines[2][2], ' comment ', scopes: '_ meta.export.js comment.block.js'
      eq lines[2][3], '*/', scopes: '_ meta.export.js comment.block.js punctuation.definition.comment.js'

      {tokens} = grammar.tokenizeLine('export {member1, /* comment */ member2} /* comment */ from "module";')
      eq tokens[6], '/*', scopes: '_ meta.export.js comment.block.js punctuation.definition.comment.js'
      eq tokens[7], ' comment ', scopes: '_ meta.export.js comment.block.js'
      eq tokens[8], '*/', scopes: '_ meta.export.js comment.block.js punctuation.definition.comment.js'
      eq tokens[13], '/*', scopes: '_ meta.export.js comment.block.js punctuation.definition.comment.js'
      eq tokens[14], ' comment ', scopes: '_ meta.export.js comment.block.js'
      eq tokens[15], '*/', scopes: '_ meta.export.js comment.block.js punctuation.definition.comment.js'

    it "tokenizes default class export", ->
      {tokens} = grammar.tokenizeLine('export default class {}')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], 'class', scope: 'storage.type.js'
      eq tokens[6], '{', scope: 'punctuation.section.scope.begin.js'
      eq tokens[7], '}', scope: 'punctuation.section.scope.end.js'

      {tokens} = grammar.tokenizeLine('export default class Foo {}')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[4], 'class', scopes: '_ meta.class.js storage.type.class.js'
      eq tokens[6], 'Foo', scopes: '_ meta.class.js entity.name.type.js'

    it "tokenizes re-export", ->
      {tokens} = grammar.tokenizeLine('export { name } from "module-name";')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.export.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'name', scopes: '_ meta.export.js variable.other.module.js'
      eq tokens[6], '}', scopes: '_ meta.export.js punctuation.definition.modules.end.js'
      eq tokens[8], 'from', scopes: '_ meta.export.js keyword.control.js'

      {tokens} = grammar.tokenizeLine('export * from "module-name";')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], '*', scopes: '_ meta.export.js variable.language.import-all.js'
      eq tokens[4], 'from', scopes: '_ meta.export.js keyword.control.js'

      {tokens} = grammar.tokenizeLine('export { default as alias } from "module-name";')
      eq tokens[0], 'export', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[2], '{', scopes: '_ meta.export.js punctuation.definition.modules.begin.js'
      eq tokens[4], 'default', scopes: '_ meta.export.js variable.language.default.js'
      eq tokens[6], 'as', scopes: '_ meta.export.js keyword.control.js'
      eq tokens[8], 'alias', scopes: '_ meta.export.js variable.other.module-alias.js'
      eq tokens[10], '}', scopes: '_ meta.export.js punctuation.definition.modules.end.js'
      eq tokens[12], 'from', scopes: '_ meta.export.js keyword.control.js'

  describe "ES6 yield", ->
    it "tokenizes yield", ->
      {tokens} = grammar.tokenizeLine('yield next')
      eq tokens[0], 'yield', scopes: '_ meta.control.yield.js keyword.control.js'

    it "tokenizes yield*", ->
      {tokens} = grammar.tokenizeLine('yield * next')
      eq tokens[0], 'yield', scopes: '_ meta.control.yield.js keyword.control.js'
      eq tokens[2], '*', scopes: '_ meta.control.yield.js storage.modifier.js'

    it "does not tokenize yield when it is an object key", ->
      {tokens} = grammar.tokenizeLine('yield: 1')
      eq tokens[0], 'yield', scope: 'source.js'
      eq tokens[1], ':', scope: 'keyword.operator.js'

    it "tokenizes yield in the middle of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? yield : b')
      eq tokens[3], 'yield', scopes: '_ meta.control.yield.js keyword.control.js'

    it "tokenizes yield at the end of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? b : yield')
      eq tokens[5], 'yield', scopes: '_ meta.control.yield.js keyword.control.js'

  describe "default: in a switch statement", ->
    it "tokenizes it as a keyword", ->
      {tokens} = grammar.tokenizeLine('default: ')
      eq tokens[0], 'default', scope: 'keyword.control.js'

  describe "functions", ->
    it "tokenizes regular function declarations", ->
      {tokens} = grammar.tokenizeLine('function foo(){}')
      eq tokens[0], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[2], 'foo', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[3], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[4], ')', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[5], '{', scope: 'punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[6], '}', scope: 'punctuation.definition.function.body.end.bracket.curly.js'

      lines = grammar.tokenizeLines '''
        function foo() {
          if(something){ }
        }
      '''
      eq lines[0][0], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq lines[0][2], 'foo', scopes: '_ meta.function.js entity.name.function.js'
      eq lines[0][3], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq lines[0][4], ')', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq lines[0][6], '{', scopes: '_ punctuation.definition.function.body.begin.bracket.curly.js'
      eq lines[1][1], 'if', scopes: '_ keyword.control.js'
      eq lines[1][5], '{', scopes: '_ meta.brace.curly.js'
      eq lines[1][7], '}', scopes: '_ meta.brace.curly.js'
      eq lines[2][0], '}', scopes: '_ punctuation.definition.function.body.end.bracket.curly.js'

      {tokens} = grammar.tokenizeLine('function $abc$(){}')
      eq tokens[2], '$abc$', scopes: '_ meta.function.js entity.name.function.js'

      {tokens} = grammar.tokenizeLine('function $$(){}')
      eq tokens[2], '$$', scopes: '_ meta.function.js entity.name.function.js'

    it "tokenizes anonymous functions", ->
      {tokens} = grammar.tokenizeLine('function (){}')
      eq tokens[0], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[2], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[3], ')', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[4], '{', scope: 'punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[5], '}', scope: 'punctuation.definition.function.body.end.bracket.curly.js'

    it "tokenizes async functions", ->
      {tokens} = grammar.tokenizeLine('async function foo(){}')
      eq tokens[0], 'async', scopes: '_ meta.function.js storage.modifier.async.js'
      eq tokens[2], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[4], 'foo', scopes: '_ meta.function.js entity.name.function.js'

    it "tokenizes functions as object properties", ->
      {tokens} = grammar.tokenizeLine('obj.method = function foo(')
      eq tokens[0], 'obj', scope: 'variable.other.object.js'
      eq tokens[1], '.', scopes: '_ meta.function.js meta.delimiter.method.period.js'
      eq tokens[2], 'method', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[4], '=', scopes: '_ meta.function.js keyword.operator.assignment.js'
      eq tokens[6], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[8], 'foo', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[9], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'

      {tokens} = grammar.tokenizeLine('this.register = function(')
      eq tokens[0], 'this', scope: 'variable.language.js'
      eq tokens[1], '.', scopes: '_ meta.function.js meta.delimiter.method.period.js'
      eq tokens[2], 'register', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[6], 'function', scopes: '_ meta.function.js storage.type.function.js'

      {tokens} = grammar.tokenizeLine('document.getElementById("foo").onclick = function(')
      expect(tokens[8]).toEqual value: '.', scopes: ['source.js', 'meta.function.js', 'meta.delimiter.method.period.js']
      expect(tokens[9]).toEqual value: 'onclick', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[13]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']

    it "tokenizes ES6 method definitions", ->
      {tokens} = grammar.tokenizeLine('f(a, b) {}')
      eq tokens[0], 'f', scopes: '_ meta.function.method.definition.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ meta.function.method.definition.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[2], 'a', scopes: '_ meta.function.method.definition.js meta.parameters.js variable.parameter.function.js'
      eq tokens[3], ',', scopes: '_ meta.function.method.definition.js meta.parameters.js meta.delimiter.object.comma.js'
      eq tokens[5], 'b', scopes: '_ meta.function.method.definition.js meta.parameters.js variable.parameter.function.js'
      eq tokens[6], ')', scopes: '_ meta.function.method.definition.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('async foo(){}')
      eq tokens[0], 'async', scope: 'storage.modifier.js'
      eq tokens[2], 'foo', scopes: '_ meta.function.method.definition.js entity.name.function.js'

      {tokens} = grammar.tokenizeLine('hi({host, root = "./", plugins = [a, "b", "c", d]}) {}')
      eq tokens[0], 'hi', scopes: '_ meta.function.method.definition.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ _ meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[2], '{', scopes: '_ _ _ meta.brace.curly.js'
      eq tokens[3], 'host', scopes: '_ _ _'
      eq tokens[4], ',', scopes: '_ _ _ meta.delimiter.object.comma.js'
      eq tokens[5], ' root ', scopes: '_ _ _'
      eq tokens[6], '=', scopes: '_ _ _ keyword.operator.assignment.js'
      eq tokens[8], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.begin.js'
      eq tokens[9], './', scopes: '_ _ _ string.quoted.double.js'
      eq tokens[10], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.end.js'
      eq tokens[11], ',', scopes: '_ _ _ meta.delimiter.object.comma.js'
      eq tokens[12], ' plugins ', scopes: '_ _ _'
      eq tokens[13], '=', scopes: '_ _ _ keyword.operator.assignment.js'
      eq tokens[15], '[', scopes: '_ _ _ meta.brace.square.js'
      eq tokens[16], 'a', scopes: '_ _ _'
      eq tokens[17], ',', scopes: '_ _ _ meta.delimiter.object.comma.js'
      eq tokens[19], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.begin.js'
      eq tokens[22], ',', scopes: '_ _ _ meta.delimiter.object.comma.js'
      eq tokens[24], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.begin.js'
      eq tokens[28], ' d', scopes: '_ _ _'
      eq tokens[29], ']', scopes: '_ _ _ meta.brace.square.js'
      eq tokens[30], '}', scopes: '_ _ _ meta.brace.curly.js'
      eq tokens[31], ')', scopes: '_ meta.function.method.definition.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('write("){");')
      eq tokens[0], 'write', scopes: '_ meta.function-call.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ _ meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.begin.js'
      eq tokens[3], '){', scopes: '_ _ _ string.quoted.double.js'
      eq tokens[4], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.end.js'
      eq tokens[5], ')', scopes: '_ _ meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq tokens[6], ';', scope: 'punctuation.terminator.statement.js'

    it "tokenizes named function expressions", ->
      {tokens} = grammar.tokenizeLine('var func = function foo(){}')
      eq tokens[0], 'var', scope: 'storage.type.var.js'
      eq tokens[2], 'func', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[4], '=', scopes: '_ meta.function.js keyword.operator.assignment.js'
      eq tokens[6], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[8], 'foo', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[9], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'

    it "tokenizes anonymous function expressions", ->
      {tokens} = grammar.tokenizeLine('var func = function(){}')
      eq tokens[0], 'var', scope: 'storage.type.var.js'
      eq tokens[2], 'func', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[4], '=', scopes: '_ meta.function.js keyword.operator.assignment.js'
      eq tokens[6], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[7], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'

    it "tokenizes functions in object literals", ->
      {tokens} = grammar.tokenizeLine('func: function foo(')
      eq tokens[0], 'func', scopes: '_ meta.function.json.js entity.name.function.js'
      eq tokens[1], ':', scopes: '_ meta.function.json.js keyword.operator.assignment.js'
      eq tokens[3], 'function', scopes: '_ meta.function.json.js storage.type.function.js'
      eq tokens[5], 'foo', scopes: '_ meta.function.json.js entity.name.function.js'
      eq tokens[6], '(', scopes: '_ meta.function.json.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'

      {tokens} = grammar.tokenizeLine('"func": function foo(')
      eq tokens[1], 'func', scopes: '_ meta.function.json.js string.quoted.double.js entity.name.function.js'
      eq tokens[3], ':', scopes: '_ meta.function.json.js keyword.operator.assignment.js'
      eq tokens[5], 'function', scopes: '_ meta.function.json.js storage.type.function.js'
      eq tokens[7], 'foo', scopes: '_ meta.function.json.js entity.name.function.js'
      eq tokens[8], '(', scopes: '_ meta.function.json.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'

    it "tokenizes generator functions", ->
      {tokens} = grammar.tokenizeLine('function* foo(){}')
      eq tokens[0], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[1], '*', scopes: '_ meta.function.js storage.modifier.generator.js'
      eq tokens[3], 'foo', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[4], '(', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[5], ')', scopes: '_ meta.function.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[6], '{', scope: 'punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[7], '}', scope: 'punctuation.definition.function.body.end.bracket.curly.js'

      {tokens} = grammar.tokenizeLine('function *foo(){}')
      eq tokens[2], '*', scopes: '_ meta.function.js storage.modifier.generator.js'

      {tokens} = grammar.tokenizeLine('function *(){}')
      eq tokens[2], '*', scopes: '_ meta.function.js storage.modifier.generator.js'

    it "tokenizes arrow functions", ->
      {tokens} = grammar.tokenizeLine('x => x * x')
      eq tokens[0], 'x', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.function.js'
      eq tokens[2], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'
      eq tokens[3], ' x ', scope: 'source.js'

      {tokens} = grammar.tokenizeLine('() => {}')
      eq tokens[0], '(', scopes: '_ meta.function.arrow.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[1], ')', scopes: '_ meta.function.arrow.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[3], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'
      eq tokens[5], '{', scope: 'punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[6], '}', scope: 'punctuation.definition.function.body.end.bracket.curly.js'

      {tokens} = grammar.tokenizeLine('(p1, p2) => {}')
      eq tokens[0], '(', scopes: '_ meta.function.arrow.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[1], 'p1', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.function.js'
      eq tokens[2], ',', scopes: '_ meta.function.arrow.js meta.parameters.js meta.delimiter.object.comma.js'
      eq tokens[4], 'p2', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.function.js'
      eq tokens[5], ')', scopes: '_ meta.function.arrow.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[7], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'
      eq tokens[9], '{', scope: 'punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[10], '}', scope: 'punctuation.definition.function.body.end.bracket.curly.js'

      lines = grammar.tokenizeLines """
        a = (x,
             y) => {}
      """
      eq lines[1][3], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'

    it "tokenizes stored arrow functions", ->
      {tokens} = grammar.tokenizeLine('var func = (p1, p2) => {}')
      eq tokens[0], 'var', scope: 'storage.type.var.js'
      eq tokens[2], 'func', scopes: '_ meta.function.arrow.js entity.name.function.js'
      eq tokens[4], '=', scopes: '_ meta.function.arrow.js keyword.operator.assignment.js'
      eq tokens[11], ')', scopes: '_ meta.function.arrow.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[13], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'

    it "tokenizes arrow functions as object properties", ->
      {tokens} = grammar.tokenizeLine('Utils.isEmpty = (p1, p2) => {}')
      eq tokens[0], 'Utils', scope: 'variable.other.object.js'
      eq tokens[2], 'isEmpty', scopes: '_ meta.function.arrow.js entity.name.function.js'
      eq tokens[4], '=', scopes: '_ meta.function.arrow.js keyword.operator.assignment.js'
      eq tokens[11], ')', scopes: '_ meta.function.arrow.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[13], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'

    it "tokenizes arrow functions in object literals", ->
      {tokens} = grammar.tokenizeLine('foo: param => {}')
      eq tokens[0], 'foo', scopes: '_ meta.function.arrow.json.js entity.name.function.js'
      eq tokens[1], ':', scopes: '_ meta.function.arrow.json.js keyword.operator.assignment.js'
      eq tokens[3], 'param', scopes: '_ meta.function.arrow.json.js meta.parameters.js variable.parameter.function.js'
      eq tokens[5], '=>', scopes: '_ meta.function.arrow.json.js storage.type.function.arrow.js'

      {tokens} = grammar.tokenizeLine('"foo": param => {}')
      eq tokens[1], 'foo', scopes: '_ meta.function.arrow.json.js string.quoted.double.js entity.name.function.js'
      eq tokens[3], ':', scopes: '_ meta.function.arrow.json.js keyword.operator.assignment.js'
      eq tokens[5], 'param', scopes: '_ meta.function.arrow.json.js meta.parameters.js variable.parameter.function.js'
      eq tokens[7], '=>', scopes: '_ meta.function.arrow.json.js storage.type.function.arrow.js'

    it "tokenizes default parameters", ->
      {tokens} = grammar.tokenizeLine('function multiply(a, b = 1){}')
      eq tokens[7], 'b', scopes: '_ meta.function.js meta.parameters.js variable.parameter.function.js'
      eq tokens[9], '=', scopes: '_ meta.function.js meta.parameters.js keyword.operator.assignment.js'
      eq tokens[11], '1', scopes: '_ meta.function.js meta.parameters.js constant.numeric.decimal.js'

      {tokens} = grammar.tokenizeLine('function callSomething(thing = this.something()) {}')
      eq tokens[4], 'thing', scopes: '_ meta.function.js meta.parameters.js variable.parameter.function.js'
      eq tokens[6], '=', scopes: '_ meta.function.js meta.parameters.js keyword.operator.assignment.js'
      eq tokens[8], 'this', scopes: '_ meta.function.js meta.parameters.js variable.language.js'
      eq tokens[9], '.', scopes: '_ meta.function.js meta.parameters.js meta.method-call.js meta.delimiter.method.period.js'
      eq tokens[10], 'something', scopes: '_ meta.function.js meta.parameters.js meta.method-call.js entity.name.function.js'

    it "tokenizes the rest parameter", ->
      {tokens} = grammar.tokenizeLine('(...args) => args[0]')
      eq tokens[1], '...', scopes: '_ meta.function.arrow.js meta.parameters.js keyword.operator.spread.js'
      eq tokens[2], 'args', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.rest.function.js'

    it "tokenizes illegal parameters", ->
      {tokens} = grammar.tokenizeLine('0abc => {}')
      eq tokens[0], '0abc', scopes: '_ meta.function.arrow.js meta.parameters.js invalid.illegal.identifier.js'
      eq tokens[2], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'

      {tokens} = grammar.tokenizeLine('(0abc) => {}')
      eq tokens[1], '0abc', scopes: '_ meta.function.arrow.js meta.parameters.js invalid.illegal.identifier.js'
      eq tokens[4], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'

  describe "variables", ->
    it "tokenizes 'this'", ->
      {tokens} = grammar.tokenizeLine('this')
      eq tokens[0], 'this', scope: 'variable.language.js'

      {tokens} = grammar.tokenizeLine('this.obj.prototype = new El()')
      eq tokens[0], 'this', scope: 'variable.language.js'

    it "tokenizes 'super'", ->
      {tokens} = grammar.tokenizeLine('super')
      eq tokens[0], 'super', scope: 'variable.language.js'

    it "tokenizes illegal identifiers", ->
      {tokens} = grammar.tokenizeLine('0illegal')
      eq tokens[0], '0illegal', scope: 'invalid.illegal.identifier.js'

      {tokens} = grammar.tokenizeLine('123illegal')
      eq tokens[0], '123illegal', scope: 'invalid.illegal.identifier.js'

      {tokens} = grammar.tokenizeLine('123$illegal')
      eq tokens[0], '123$illegal', scope: 'invalid.illegal.identifier.js'

    describe "objects", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine('obj.prop')
        eq tokens[0], 'obj', scope: 'variable.other.object.js'

        {tokens} = grammar.tokenizeLine('$abc$.prop')
        eq tokens[0], '$abc$', scope: 'variable.other.object.js'

        {tokens} = grammar.tokenizeLine('$$.prop')
        eq tokens[0], '$$', scope: 'variable.other.object.js'

      it "tokenizes illegal objects", ->
        {tokens} = grammar.tokenizeLine('1.prop')
        eq tokens[0], '1', scope: 'invalid.illegal.identifier.js'

        {tokens} = grammar.tokenizeLine('123.prop')
        eq tokens[0], '123', scope: 'invalid.illegal.identifier.js'

        {tokens} = grammar.tokenizeLine('123a.prop')
        eq tokens[0], '123a', scope: 'invalid.illegal.identifier.js'

  describe "function calls", ->
    it "tokenizes function calls", ->
      {tokens} = grammar.tokenizeLine('functionCall()')
      eq tokens[0], 'functionCall', scopes: '_ meta.function-call.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('functionCall(arg1, "test", {a: 123})')
      eq tokens[0], 'functionCall', scopes: '_ meta.function-call.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], 'arg1', scopes: '_ _ meta.arguments.js'
      eq tokens[3], ',', scopes: '_ _ meta.arguments.js meta.delimiter.object.comma.js'
      eq tokens[5], '"', scopes: '_ _ meta.arguments.js string.quoted.double.js punctuation.definition.string.begin.js'
      eq tokens[6], 'test', scopes: '_ _ meta.arguments.js string.quoted.double.js'
      eq tokens[7], '"', scopes: '_ _ meta.arguments.js string.quoted.double.js punctuation.definition.string.end.js'
      eq tokens[8], ',', scopes: '_ _ meta.arguments.js meta.delimiter.object.comma.js'
      eq tokens[10], '{', scopes: '_ _ meta.arguments.js meta.brace.curly.js'
      eq tokens[11], 'a', scopes: '_ _ meta.arguments.js'
      eq tokens[12], ':', scopes: '_ _ meta.arguments.js keyword.operator.js'
      eq tokens[14], '123', scopes: '_ _ meta.arguments.js constant.numeric.decimal.js'
      eq tokens[15], '}', scopes: '_ meta.function-call.js meta.arguments.js meta.brace.curly.js'
      eq tokens[16], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('functionCall((123).toString())')
      eq tokens[1], '(', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], '(', scopes: '_ meta.function-call.js meta.arguments.js meta.brace.round.js'
      eq tokens[3], '123', scopes: '_ meta.function-call.js meta.arguments.js constant.numeric.decimal.js'
      eq tokens[4], ')', scopes: '_ meta.function-call.js meta.arguments.js meta.brace.round.js'
      eq tokens[9], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('$abc$()')
      eq tokens[0], '$abc$', scopes: '_ meta.function-call.js entity.name.function.js'

      {tokens} = grammar.tokenizeLine('$$()')
      eq tokens[0], '$$', scopes: '_ meta.function-call.js entity.name.function.js'

    it "tokenizes function calls when they are arguments", ->
      {tokens} = grammar.tokenizeLine('a(b(c))')
      eq tokens[0], 'a', scopes: '_ meta.function-call.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ _ meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], 'b', scopes: '_ _ _ meta.function-call.js entity.name.function.js'
      eq tokens[3], '(', scopes: '_ _ _ _ meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[4], 'c', scopes: '_ _ _ _ meta.arguments.js'
      eq tokens[5], ')', scopes: '_ _ _ _ meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq tokens[6], ')', scopes: '_ _ meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

    it "tokenizes illegal function calls", ->
      {tokens} = grammar.tokenizeLine('0illegal()')
      eq tokens[0], '0illegal', scopes: '_ meta.function-call.js invalid.illegal.identifier.js'
      eq tokens[1], '(', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

    it "tokenizes illegal arguments", ->
      {tokens} = grammar.tokenizeLine('a(1a)')
      eq tokens[0], 'a', scopes: '_ meta.function-call.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], '1a', scopes: '_ meta.function-call.js meta.arguments.js invalid.illegal.identifier.js'
      eq tokens[3], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('a(123a)')
      eq tokens[2], '123a', scopes: '_ meta.function-call.js meta.arguments.js invalid.illegal.identifier.js'

      {tokens} = grammar.tokenizeLine('a(1.prop)')
      eq tokens[2], '1', scopes: '_ meta.function-call.js meta.arguments.js invalid.illegal.identifier.js'
      eq tokens[3], '.', scopes: '_ meta.function-call.js meta.arguments.js meta.delimiter.property.period.js'
      eq tokens[4], 'prop', scopes: '_ meta.function-call.js meta.arguments.js variable.other.property.js'

    it "tokenizes function declaration as an argument", ->
      {tokens} = grammar.tokenizeLine('a(function b(p) { return p; })')
      eq tokens[0], 'a', scopes: '_ meta.function-call.js entity.name.function.js'
      eq tokens[1], '(', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[2], 'function', scopes: '_ _ _ meta.function.js storage.type.function.js'
      eq tokens[4], 'b', scopes: '_ _ _ meta.function.js entity.name.function.js'
      eq tokens[5], '(', scopes: '_ _ _ meta.function.js meta.parameters.js punctuation.definition.parameters.begin.bracket.round.js'
      eq tokens[6], 'p', scopes: '_ _ _ meta.function.js meta.parameters.js variable.parameter.function.js'
      eq tokens[7], ')', scopes: '_ _ _ meta.function.js meta.parameters.js punctuation.definition.parameters.end.bracket.round.js'
      eq tokens[9], '{', scopes: '_ _ _ punctuation.definition.function.body.begin.bracket.curly.js'
      eq tokens[11], 'return', scopes: '_ _ _ keyword.control.js'
      eq tokens[12], ' p', scopes: '_ _ _'
      eq tokens[13], ';', scopes: '_ _ _ punctuation.terminator.statement.js'
      eq tokens[15], '}', scopes: '_ _ _ punctuation.definition.function.body.end.bracket.curly.js'
      eq tokens[16], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

  describe "method calls", ->
    it "tokenizes method calls", ->
      {tokens} = grammar.tokenizeLine('a.b(1+1)')
      eq tokens[0], 'a', scope: 'variable.other.object.js'
      eq tokens[1], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq tokens[2], 'b', scopes: '_ meta.method-call.js entity.name.function.js'
      eq tokens[3], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[4], '1', scopes: '_ meta.method-call.js meta.arguments.js constant.numeric.decimal.js'
      eq tokens[5], '+', scopes: '_ meta.method-call.js meta.arguments.js keyword.operator.js'
      eq tokens[6], '1', scopes: '_ meta.method-call.js meta.arguments.js constant.numeric.decimal.js'
      eq tokens[7], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('a . b(1+1)')
      eq tokens[2], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq tokens[4], 'b', scopes: '_ meta.method-call.js entity.name.function.js'
      eq tokens[5], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'

      {tokens} = grammar.tokenizeLine('a.$abc$()')
      eq tokens[2], '$abc$', scopes: '_ meta.method-call.js entity.name.function.js'

      {tokens} = grammar.tokenizeLine('a.$$()')
      eq tokens[2], '$$', scopes: '_ meta.method-call.js entity.name.function.js'

      lines = grammar.tokenizeLines """
        gulp.src("./*.js")
          .pipe(minify())
          .pipe(gulp.dest("build"))
      """
      eq lines[0][0], 'gulp', scopes: '_ variable.other.object.js'
      eq lines[0][1], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq lines[0][2], 'src', scopes: '_ meta.method-call.js entity.name.function.js'
      eq lines[0][3], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq lines[0][4], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.begin.js'
      eq lines[0][5], './*.js', scopes: '_ _ _ string.quoted.double.js'
      eq lines[0][6], '"', scopes: '_ _ _ string.quoted.double.js punctuation.definition.string.end.js'
      eq lines[0][7], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq lines[1][1], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq lines[1][2], 'pipe', scopes: '_ meta.method-call.js entity.name.function.js'
      eq lines[1][3], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq lines[1][4], 'minify', scopes: '_ _ _ meta.function-call.js entity.name.function.js'
      eq lines[1][5], '(', scopes: '_ _ _ meta.function-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq lines[1][6], ')', scopes: '_ _ _ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq lines[1][7], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq lines[2][1], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq lines[2][2], 'pipe', scopes: '_ meta.method-call.js entity.name.function.js'
      eq lines[2][3], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq lines[2][4], 'gulp', scopes: '_ _ _ variable.other.object.js'
      eq lines[2][5], '.', scopes: '_ _ _ meta.method-call.js meta.delimiter.method.period.js'
      eq lines[2][6], 'dest', scopes: '_ _ _ meta.method-call.js entity.name.function.js'
      eq lines[2][7], '(', scopes: '_ _ _ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq lines[2][8], '"', scopes: '_ _ _ _ _ string.quoted.double.js punctuation.definition.string.begin.js'
      eq lines[2][9], 'build', scopes: '_ _ _ _ _ string.quoted.double.js'
      eq lines[2][10], '"', scopes: '_ _ _ _ _ string.quoted.double.js punctuation.definition.string.end.js'
      eq lines[2][11], ')', scopes: '_ _ _ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq lines[2][12], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

    describe "built-in methods", ->
      methods    = ["require", "parseInt", "parseFloat", "print"]
      domMethods = ["substringData", "submit", "splitText", "setNamedItem", "setAttribute"]

      for method in methods
        it "tokenizes '#{method}'", ->
          {tokens} = grammar.tokenizeLine('.' + method + '()')
          eq tokens[0], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
          eq tokens[1], method, scopes: '_ meta.method-call.js support.function.js'
          eq tokens[2], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
          eq tokens[3], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      for domMethod in domMethods
        it "tokenizes '#{domMethod}'", ->
          {tokens} = grammar.tokenizeLine('.' + domMethod + '()')
          eq tokens[0], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
          eq tokens[1], domMethod, scopes: '_ meta.method-call.js support.function.dom.js'
          eq tokens[2], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
          eq tokens[3], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

  describe "properties", ->
    it "tokenizes properties", ->
      {tokens} = grammar.tokenizeLine('obj.property')
      eq tokens[0], 'obj', scope: 'variable.other.object.js'
      eq tokens[1], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[2], 'property', scope: 'variable.other.property.js'

      {tokens} = grammar.tokenizeLine('obj.Property')
      eq tokens[0], 'obj', scope: 'variable.other.object.js'
      eq tokens[1], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[2], 'Property', scope: 'variable.other.property.js'

      {tokens} = grammar.tokenizeLine('obj.$abc$')
      eq tokens[2], '$abc$', scope: 'variable.other.property.js'

      {tokens} = grammar.tokenizeLine('obj.$$')
      eq tokens[2], '$$', scope: 'variable.other.property.js'

      {tokens} = grammar.tokenizeLine('a().b')
      eq tokens[2], ')', scopes: '_ meta.function-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'
      eq tokens[3], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[4], 'b', scope: 'variable.other.property.js'

      {tokens} = grammar.tokenizeLine('a.123illegal')
      eq tokens[0], 'a', scope: 'source.js'
      eq tokens[1], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[2], '123illegal', scope: 'invalid.illegal.identifier.js'

    it "tokenizes constant properties", ->
      {tokens} = grammar.tokenizeLine('obj.MY_CONSTANT')
      eq tokens[0], 'obj', scope: 'variable.other.object.js'
      eq tokens[1], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[2], 'MY_CONSTANT', scope: 'constant.other.property.js'

      {tokens} = grammar.tokenizeLine('a.C')
      eq tokens[0], 'a', scope: 'variable.other.object.js'
      eq tokens[1], '.', scope: 'meta.delimiter.property.period.js'
      eq tokens[2], 'C', scope: 'constant.other.property.js'

  describe "strings and functions", ->
    it "doesn't confuse them", ->
      {tokens} = grammar.tokenizeLine("'a'.b(':c(d)')")
      eq tokens[0], "'", scopes: '_ string.quoted.single.js punctuation.definition.string.begin.js'
      eq tokens[1], "a", scopes: '_ string.quoted.single.js'
      eq tokens[2], "'", scopes: '_ string.quoted.single.js punctuation.definition.string.end.js'
      eq tokens[3], ".", scopes: '_ _ meta.delimiter.method.period.js'
      eq tokens[4], "b", scopes: '_ _ entity.name.function.js'
      eq tokens[5], "(", scopes: '_ _ meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[6], "'", scopes: '_ _ _ string.quoted.single.js punctuation.definition.string.begin.js'
      eq tokens[7], ":c(d)", scopes: '_ _ _ string.quoted.single.js'
      eq tokens[8], "'", scopes: '_ _ _ string.quoted.single.js punctuation.definition.string.end.js'
      eq tokens[9], ")", scopes: '_ _ meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      delimsByScope =
        "string.quoted.double.js": '"'
        "string.quoted.single.js": "'"

      for scope, delim of delimsByScope
        {tokens} = grammar.tokenizeLine('a.push(' + delim + 'x' + delim + ' + y + ' + delim + ':function()' + delim + ');')
        eq tokens[2], 'push', scopes: '_ _ support.function.js'
        eq tokens[3], '(', scopes: '_ _ meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
        eq tokens[4], delim, scopes: '_ _ _ ' + scope + ' punctuation.definition.string.begin.js'
        eq tokens[5], 'x', scopes: '_ _ _ ' + scope
        eq tokens[6], delim, scopes: '_ _ _ ' + scope + ' punctuation.definition.string.end.js'
        eq tokens[8], '+', scopes: '_ _ _ keyword.operator.js'
        eq tokens[9], ' y ', scopes: '_ _ _'
        eq tokens[10], '+', scopes: '_ _ _ keyword.operator.js'
        eq tokens[12], delim, scopes: '_ _ _ ' + scope + ' punctuation.definition.string.begin.js'
        eq tokens[13], ':function()', scopes: '_ _ _ ' + scope
        eq tokens[14], delim, scopes: '_ _ _ ' + scope + ' punctuation.definition.string.end.js'
        eq tokens[15], ')', scopes: '_ _ meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

  describe "comments", ->
    it "tokenizes /* */ comments", ->
      {tokens} = grammar.tokenizeLine('/**/')
      eq tokens[0], '/*', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[1], '*/', scopes: '_ comment.block.js punctuation.definition.comment.js'

      {tokens} = grammar.tokenizeLine('/* foo */')
      eq tokens[0], '/*', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[1], ' foo ', scope: 'comment.block.js'
      eq tokens[2], '*/', scopes: '_ comment.block.js punctuation.definition.comment.js'

    it "tokenizes /** */ comments", ->
      {tokens} = grammar.tokenizeLine('/***/')
      eq tokens[0], '/**', scopes: '_ comment.block.documentation.js punctuation.definition.comment.js'
      eq tokens[1], '*/', scopes: '_ comment.block.documentation.js punctuation.definition.comment.js'

      {tokens} = grammar.tokenizeLine('/** foo */')
      eq tokens[0], '/**', scopes: '_ comment.block.documentation.js punctuation.definition.comment.js'
      eq tokens[1], ' foo ', scope: 'comment.block.documentation.js'
      eq tokens[2], '*/', scopes: '_ comment.block.documentation.js punctuation.definition.comment.js'

      {tokens} = grammar.tokenizeLine('/** @mixins */')
      eq tokens[0], '/**', scopes: '_ comment.block.documentation.js punctuation.definition.comment.js'
      eq tokens[2], '@mixins', scopes: '_ comment.block.documentation.js storage.type.class.jsdoc'
      eq tokens[3], ' ', scopes: '_ comment.block.documentation.js'
      eq tokens[4], '*/', scopes: '_ comment.block.documentation.js punctuation.definition.comment.js'

    it "tokenizes JSDoc comment documentation", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} variable this is the description */')
      expect(tokens[4]).toEqual value: '{object}', scopes: ['source.js', 'comment.block.documentation.js', 'other.meta.jsdoc', 'entity.name.type.instance.jsdoc']
      expect(tokens[6]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'other.meta.jsdoc', 'variable.other.jsdoc']
      expect(tokens[8]).toEqual value: 'this is the description ', scopes: ['source.js', 'comment.block.documentation.js', 'other.meta.jsdoc', 'other.description.jsdoc']

    it "tokenizes // comments", ->
      {tokens} = grammar.tokenizeLine('// comment')
      eq tokens[0], '//', scopes: '_ comment.line.double-slash.js punctuation.definition.comment.js'
      eq tokens[1], ' comment', scopes: '_ comment.line.double-slash.js'

    it "tokenizes comments inside constant definitions", ->
      {tokens} = grammar.tokenizeLine('const a, // comment')
      eq tokens[0], 'const', scope: 'storage.modifier.js'
      eq tokens[2], 'a', scope: 'constant.other.js'
      eq tokens[3], ',', scope: 'meta.delimiter.object.comma.js'
      eq tokens[5], '//', scopes: '_ comment.line.double-slash.js punctuation.definition.comment.js'
      eq tokens[6], ' comment', scope: 'comment.line.double-slash.js'

    it "tokenizes comments inside function declarations", ->
      {tokens} = grammar.tokenizeLine('function /* */ foo() /* */ {}')
      eq tokens[0], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq tokens[2], '/*', scopes: '_ meta.function.js comment.block.js punctuation.definition.comment.js'
      eq tokens[4], '*/', scopes: '_ meta.function.js comment.block.js punctuation.definition.comment.js'
      eq tokens[6], 'foo', scopes: '_ meta.function.js entity.name.function.js'
      eq tokens[10], '/*', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[12], '*/', scopes: '_ comment.block.js punctuation.definition.comment.js'

      {tokens} = grammar.tokenizeLine('x => /* */ {}')
      eq tokens[0], 'x', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.function.js'
      eq tokens[2], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'
      eq tokens[4], '/*', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[6], '*/', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[8], '{', scopes: '_ punctuation.definition.function.body.begin.bracket.curly.js'

      {tokens} = grammar.tokenizeLine('.foo = x => /* */ {}')
      eq tokens[1], 'foo', scopes: '_ meta.function.arrow.js entity.name.function.js'
      eq tokens[5], 'x', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.function.js'
      eq tokens[7], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'
      eq tokens[9], '/*', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[11], '*/', scopes: '_ comment.block.js punctuation.definition.comment.js'
      eq tokens[13], '{', scopes: '_ punctuation.definition.function.body.begin.bracket.curly.js'

      lines = grammar.tokenizeLines '''
        function
        // comment
        foo() {}
      '''
      eq lines[0][0], 'function', scopes: '_ meta.function.js storage.type.function.js'
      eq lines[1][0], '//', scopes: '_ meta.function.js comment.line.double-slash.js punctuation.definition.comment.js'
      eq lines[1][1], ' comment', scopes: '_ meta.function.js comment.line.double-slash.js'
      eq lines[2][0], 'foo', scopes: '_ meta.function.js entity.name.function.js'

      lines = grammar.tokenizeLines '''
        x  =>
          // comment
        {}
      '''
      eq lines[0][0], 'x', scopes: '_ meta.function.arrow.js meta.parameters.js variable.parameter.function.js'
      eq lines[0][2], '=>', scopes: '_ meta.function.arrow.js storage.type.function.arrow.js'
      eq lines[1][1], '//', scopes: '_ comment.line.double-slash.js punctuation.definition.comment.js'
      eq lines[1][2], ' comment', scopes: '_ comment.line.double-slash.js'
      eq lines[2][0], '{', scopes: '_ punctuation.definition.function.body.begin.bracket.curly.js'

    it "tokenizes comments inside function parameters correctly", ->
      {tokens} = grammar.tokenizeLine('function test(p1 /*, p2 */) {}')
      eq tokens[6], '/*', scopes: '_ meta.function.js meta.parameters.js comment.block.js punctuation.definition.comment.js'
      eq tokens[7], ', p2 ', scopes: '_ meta.function.js meta.parameters.js comment.block.js'
      eq tokens[8], '*/', scopes: '_ meta.function.js meta.parameters.js comment.block.js punctuation.definition.comment.js'

  describe "console", ->
    it "tokenizes the console keyword", ->
      {tokens} = grammar.tokenizeLine('console')
      eq tokens[0], 'console', scope: 'entity.name.type.object.console.js'

    it "tokenizes console support functions", ->
      {tokens} = grammar.tokenizeLine('console.log()')
      eq tokens[0], 'console', scopes: '_ entity.name.type.object.console.js'
      eq tokens[1], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq tokens[2], 'log', scopes: '_ meta.method-call.js support.function.console.js'
      eq tokens[3], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[4], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

      {tokens} = grammar.tokenizeLine('console . log()')
      eq tokens[0], 'console', scopes: '_ entity.name.type.object.console.js'
      eq tokens[2], '.', scopes: '_ meta.method-call.js meta.delimiter.method.period.js'
      eq tokens[4], 'log', scopes: '_ meta.method-call.js support.function.console.js'
      eq tokens[5], '(', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.begin.bracket.round.js'
      eq tokens[6], ')', scopes: '_ meta.method-call.js meta.arguments.js punctuation.definition.arguments.end.bracket.round.js'

  describe "math", ->
    it "tokenizes the math object", ->
      {tokens} = grammar.tokenizeLine('Math')
      expect(tokens[0]).toEqual value: 'Math', scopes: ['source.js', 'support.class.js']

    it "tokenizes math support functions/properties", ->
      {tokens} = grammar.tokenizeLine('Math.random()')
      expect(tokens[0]).toEqual value: 'Math', scopes: ['source.js', 'support.class.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[2]).toEqual value: 'random', scopes: ['source.js', 'meta.method-call.js', 'support.function.math.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'meta.arguments.js', 'punctuation.definition.arguments.begin.bracket.round.js']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'meta.arguments.js', 'punctuation.definition.arguments.end.bracket.round.js']

      {tokens} = grammar.tokenizeLine('Math.PI')
      expect(tokens[0]).toEqual value: 'Math', scopes: ['source.js', 'support.class.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[2]).toEqual value: 'PI', scopes: ['source.js', 'support.constant.property.math.js']

  describe "indentation", ->
    editor = null

    beforeEach ->
      editor = buildTextEditor()
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
