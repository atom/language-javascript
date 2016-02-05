fs = require 'fs'
path = require 'path'
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
        expect(tokens[0].value).toEqual delim
        expect(tokens[0].scopes).toEqual ["source.js", scope, "punctuation.definition.string.begin.js"]
        expect(tokens[1].value).toEqual "x"
        expect(tokens[1].scopes).toEqual ["source.js", scope]
        expect(tokens[2].value).toEqual delim
        expect(tokens[2].scopes).toEqual ["source.js", scope, "punctuation.definition.string.end.js"]

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
        expect(lines[0][0]).toEqual value: delim, scopes: ['source.js', scope, 'punctuation.definition.string.begin.js']
        expect(lines[0][1]).toEqual value: 'line1', scopes: ['source.js', scope, 'invalid.illegal.string.js']
        expect(lines[1][0]).toEqual value: 'line2\\', scopes: ['source.js', scope]
        expect(lines[2][0]).toEqual value: 'line3', scopes: ['source.js', scope]
        expect(lines[2][1]).toEqual value: delim, scopes: ['source.js', scope, 'punctuation.definition.string.end.js']

  describe "keywords", ->
    it "tokenizes with as a keyword", ->
      {tokens} = grammar.tokenizeLine('with')
      expect(tokens[0]).toEqual value: 'with', scopes: ['source.js', 'keyword.control.js']

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
          expect(tokens[0]).toEqual value: keyword, scopes: ['source.js']
          expect(tokens[1]).toEqual value: ':', scopes: ['source.js', 'keyword.operator.js']

        it "tokenizes `#{keyword}` in the middle of ternary expressions", ->
          {tokens} = grammar.tokenizeLine("a ? #{keyword} : b")
          expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
          expect(tokens[3]).toEqual value: keyword, scopes: ['source.js', scope]

        it "tokenizes `#{keyword}` at the end of ternary expressions", ->
          {tokens} = grammar.tokenizeLine("a ? b : #{keyword}")
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.js']
          expect(tokens[5]).toEqual value: keyword, scopes: ['source.js', scope]

  describe "built-in globals", ->
    it "tokenizes built-in classes", ->
      {tokens} = grammar.tokenizeLine('window')
      expect(tokens[0]).toEqual value: 'window', scopes: ['source.js', 'support.class.js']

      {tokens} = grammar.tokenizeLine('window.name')
      expect(tokens[0]).toEqual value: 'window', scopes: ['source.js', 'support.class.js']

      {tokens} = grammar.tokenizeLine('$window')
      expect(tokens[0]).toEqual value: '$window', scopes: ['source.js']

    it "tokenizes built-in variables", ->
      {tokens} = grammar.tokenizeLine('module')
      expect(tokens[0]).toEqual value: 'module', scopes: ['source.js', 'support.variable.js']

      {tokens} = grammar.tokenizeLine('module.prop')
      expect(tokens[0]).toEqual value: 'module', scopes: ['source.js', 'support.variable.js']

  describe "instantiation", ->
    it "tokenizes the new keyword and instance entities", ->
      {tokens} = grammar.tokenizeLine('new something')
      expect(tokens[0]).toEqual value: 'new', scopes: ['source.js', 'meta.class.instance.constructor', 'keyword.operator.new.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js', 'meta.class.instance.constructor']
      expect(tokens[2]).toEqual value: 'something', scopes: ['source.js', 'meta.class.instance.constructor', 'entity.name.type.instance.js']

      {tokens} = grammar.tokenizeLine('new Something')
      expect(tokens[0]).toEqual value: 'new', scopes: ['source.js', 'meta.class.instance.constructor', 'keyword.operator.new.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js', 'meta.class.instance.constructor']
      expect(tokens[2]).toEqual value: 'Something', scopes: ['source.js', 'meta.class.instance.constructor', 'entity.name.type.instance.js']

      {tokens} = grammar.tokenizeLine('new $something')
      expect(tokens[0]).toEqual value: 'new', scopes: ['source.js', 'meta.class.instance.constructor', 'keyword.operator.new.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js', 'meta.class.instance.constructor']
      expect(tokens[2]).toEqual value: '$something', scopes: ['source.js', 'meta.class.instance.constructor', 'entity.name.type.instance.js']

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
      expect(tokens[1]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[2]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[4]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[5]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[6]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[7]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']

    it "tokenizes regular expressions inside ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? /b/ : /c/')
      expect(tokens[ 0]).toEqual value: 'a ', scopes: ['source.js']
      expect(tokens[ 1]).toEqual value: '?', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[ 2]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[ 3]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[ 4]).toEqual value: 'b', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[ 5]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[ 6]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[ 7]).toEqual value: ':', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[ 8]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[ 9]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[10]).toEqual value: 'c', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[11]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']

    it "verifies that regular expressions have explicit count modifiers", ->
      source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'javascript.cson'), 'utf8')
      expect(source.search /{,/).toEqual -1

      source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'regular expressions (javascript).cson'), 'utf8')
      expect(source.search /{,/).toEqual -1

  describe "numbers", ->
    it "tokenizes hexadecimals", ->
      {tokens} = grammar.tokenizeLine('0x1D306')
      expect(tokens[0]).toEqual value: '0x1D306', scopes: ['source.js', 'constant.numeric.hex.js']

      {tokens} = grammar.tokenizeLine('0X1D306')
      expect(tokens[0]).toEqual value: '0X1D306', scopes: ['source.js', 'constant.numeric.hex.js']

    it "tokenizes binary literals", ->
      {tokens} = grammar.tokenizeLine('0b011101110111010001100110')
      expect(tokens[0]).toEqual value: '0b011101110111010001100110', scopes: ['source.js', 'constant.numeric.binary.js']

      {tokens} = grammar.tokenizeLine('0B011101110111010001100110')
      expect(tokens[0]).toEqual value: '0B011101110111010001100110', scopes: ['source.js', 'constant.numeric.binary.js']

    it "tokenizes octal literals", ->
      {tokens} = grammar.tokenizeLine('0o1411')
      expect(tokens[0]).toEqual value: '0o1411', scopes: ['source.js', 'constant.numeric.octal.js']

      {tokens} = grammar.tokenizeLine('0O1411')
      expect(tokens[0]).toEqual value: '0O1411', scopes: ['source.js', 'constant.numeric.octal.js']

      {tokens} = grammar.tokenizeLine('0010')
      expect(tokens[0]).toEqual value: '0010', scopes: ['source.js', 'constant.numeric.octal.js']

    it "tokenizes decimals", ->
      {tokens} = grammar.tokenizeLine('1234')
      expect(tokens[0]).toEqual value: '1234', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('5e-10')
      expect(tokens[0]).toEqual value: '5e-10', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('5E+5')
      expect(tokens[0]).toEqual value: '5E+5', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('9.')
      expect(tokens[0]).toEqual value: '9', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'constant.numeric.decimal.js', 'meta.delimiter.decimal.period.js']

      {tokens} = grammar.tokenizeLine('.9')
      expect(tokens[0]).toEqual value: '.', scopes: ['source.js', 'constant.numeric.decimal.js', 'meta.delimiter.decimal.period.js']
      expect(tokens[1]).toEqual value: '9', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('9.9')
      expect(tokens[0]).toEqual value: '9', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'constant.numeric.decimal.js', 'meta.delimiter.decimal.period.js']
      expect(tokens[2]).toEqual value: '9', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('.1e-23')
      expect(tokens[0]).toEqual value: '.', scopes: ['source.js', 'constant.numeric.decimal.js', 'meta.delimiter.decimal.period.js']
      expect(tokens[1]).toEqual value: '1e-23', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('1.E3')
      expect(tokens[0]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'constant.numeric.decimal.js', 'meta.delimiter.decimal.period.js']
      expect(tokens[2]).toEqual value: 'E3', scopes: ['source.js', 'constant.numeric.decimal.js']

    it "does not tokenize numbers that are part of a variable", ->
      {tokens} = grammar.tokenizeLine('hi$1')
      expect(tokens[0]).toEqual value: 'hi$1', scopes: ['source.js']

      {tokens} = grammar.tokenizeLine('hi_1')
      expect(tokens[0]).toEqual value: 'hi_1', scopes: ['source.js']

  describe "operators", ->
    it "tokenizes them", ->
      operators = ["delete", "in", "of", "instanceof", "new", "typeof", "void"]

      for operator in operators
        {tokens} = grammar.tokenizeLine(operator)
        expect(tokens[0]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.' + operator  + '.js']

    describe "increment, decrement", ->
      it "tokenizes increment", ->
        {tokens} = grammar.tokenizeLine('i++')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '++', scopes: ['source.js', 'keyword.operator.increment.js']

      it "tokenizes decrement", ->
        {tokens} = grammar.tokenizeLine('i--')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '--', scopes: ['source.js', 'keyword.operator.decrement.js']

    describe "conditional ternary", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine('test ? expr1 : expr2')
        expect(tokens[0]).toEqual value: 'test ', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.js', 'keyword.operator.js']
        expect(tokens[2]).toEqual value: ' expr1 ', scopes: ['source.js']
        expect(tokens[3]).toEqual value: ':', scopes: ['source.js', 'keyword.operator.js']
        expect(tokens[4]).toEqual value: ' expr2', scopes: ['source.js']

    describe "logical", ->
      operators = ["&&", "||", "!"]

      it "tokenizes them", ->
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.logical.js']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

      it "tokenizes spread operator", ->
        {tokens} = grammar.tokenizeLine('myFunction(...args);')
        expect(tokens[2]).toEqual value: '...', scopes: ['source.js', 'meta.function-call.js', 'keyword.operator.spread.js']
        expect(tokens[3]).toEqual value: 'args', scopes: ['source.js', 'meta.function-call.js']

        {tokens} = grammar.tokenizeLine('[...iterableObj]')
        expect(tokens[1]).toEqual value: '...', scopes: ['source.js', 'keyword.operator.spread.js']
        expect(tokens[2]).toEqual value: 'iterableObj', scopes: ['source.js']

    describe "comparison", ->
      operators = ["<=", ">=", "!=", "!==", "===", "==", "<", ">" ]

      it "tokenizes them", ->
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.comparison.js']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

    describe "bitwise", ->
      it "tokenizes bitwise 'not'", ->
        {tokens} = grammar.tokenizeLine('~a')
        expect(tokens[0]).toEqual value: '~', scopes: ['source.js', 'keyword.operator.bitwise.js']
        expect(tokens[1]).toEqual value: 'a', scopes: ['source.js']

      it "tokenizes them", ->
        operators = ["|", "^", "&"]

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.bitwise.js']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

    describe "arithmetic", ->
      operators = ["*", "/", "-", "%", "+"]

      it "tokenizes them", ->
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.js']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

      it "tokenizes the arithmetic operators when separated by newlines", ->
        for operator in operators
          lines = grammar.tokenizeLines '1\n' + operator + ' 2'
          expect(lines[0][0]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.decimal.js']
          expect(lines[1][0]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.js']
          expect(lines[1][2]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.decimal.js']

    describe "assignment", ->
      it "tokenizes '=' operator", ->
        {tokens} = grammar.tokenizeLine('a = b')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
        expect(tokens[1]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

      describe "compound", ->
        it "tokenizes them", ->
          operators = ["+=", "-=", "*=", "/=", "%="]
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.assignment.compound.js']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

        describe "bitwise", ->
          it "tokenizes them", ->
            operators = ["<<=", ">>=", ">>>=", "&=", "^=", "|="]
            for operator in operators
              {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
              expect(tokens[0]).toEqual value: 'a ', scopes: ['source.js']
              expect(tokens[1]).toEqual value: operator, scopes: ['source.js', 'keyword.operator.assignment.compound.bitwise.js']
              expect(tokens[2]).toEqual value: ' b', scopes: ['source.js']

  describe "constants", ->
    it "tokenizes ALL_CAPS variables as constants", ->
      {tokens} = grammar.tokenizeLine('var MY_COOL_VAR = 42;')
      expect(tokens[0]).toEqual value: 'var', scopes: ['source.js', 'storage.type.var.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: 'MY_COOL_VAR', scopes: ['source.js', 'constant.other.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[5]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[6]).toEqual value: '42', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[7]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

      {tokens} = grammar.tokenizeLine('something = MY_COOL_VAR * 1;')
      expect(tokens[0]).toEqual value: 'something ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[3]).toEqual value: 'MY_COOL_VAR', scopes: ['source.js', 'constant.other.js']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[5]).toEqual value: '*', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[6]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[7]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[8]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

    it "tokenizes variables declared using `const` as constants", ->
      {tokens} = grammar.tokenizeLine('const myCoolVar = 42;')
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: 'myCoolVar', scopes: ['source.js', 'constant.other.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[5]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[6]).toEqual value: '42', scopes: ['source.js', 'constant.numeric.decimal.js']
      expect(tokens[7]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

      lines = grammar.tokenizeLines """
        const a,
        b,
        c
        if(a)
      """
      expect(lines[0][0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(lines[0][1]).toEqual value: ' ', scopes: ['source.js']
      expect(lines[0][2]).toEqual value: 'a', scopes: ['source.js', 'constant.other.js']
      expect(lines[0][3]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(lines[1][0]).toEqual value: 'b', scopes: ['source.js', 'constant.other.js']
      expect(lines[1][1]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(lines[2][0]).toEqual value: 'c', scopes: ['source.js', 'constant.other.js']
      expect(lines[3][0]).toEqual value: 'if', scopes: ['source.js', 'keyword.control.js']
      expect(lines[3][1]).toEqual value: '(', scopes: ['source.js', 'meta.brace.round.js']
      expect(lines[3][2]).toEqual value: 'a', scopes: ['source.js']
      expect(lines[3][3]).toEqual value: ')', scopes: ['source.js', 'meta.brace.round.js']

      {tokens} = grammar.tokenizeLine('(const hi);')
      expect(tokens[0]).toEqual value: '(', scopes: ['source.js', 'meta.brace.round.js']
      expect(tokens[1]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[3]).toEqual value: 'hi', scopes: ['source.js', 'constant.other.js']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'meta.brace.round.js']
      expect(tokens[5]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

      {tokens} = grammar.tokenizeLine('const {first:f,second,...rest} = obj;')
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.brace.curly.js']
      expect(tokens[3]).toEqual value: 'first', scopes: ['source.js']
      expect(tokens[4]).toEqual value: ':', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[5]).toEqual value: 'f', scopes: ['source.js', 'constant.other.js']
      expect(tokens[6]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(tokens[7]).toEqual value: 'second', scopes: ['source.js', 'constant.other.js']
      expect(tokens[8]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(tokens[9]).toEqual value: '...', scopes: ['source.js', 'keyword.operator.spread.js']
      expect(tokens[10]).toEqual value: 'rest', scopes: ['source.js', 'constant.other.js']
      expect(tokens[11]).toEqual value: '}', scopes: ['source.js', 'meta.brace.curly.js']
      expect(tokens[12]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[13]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[14]).toEqual value: ' obj', scopes: ['source.js']
      expect(tokens[15]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

      {tokens} = grammar.tokenizeLine('const c = /regex/;')
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: 'c', scopes: ['source.js', 'constant.other.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[5]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[6]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[7]).toEqual value: 'regex', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[8]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[9]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

    it "tokenizes variables declared with `const` in for-in and for-of loops", ->
      {tokens} = grammar.tokenizeLine 'for (const elem of array) {'
      expect(tokens[0]).toEqual value: 'for', scopes: ['source.js', 'keyword.control.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[2]).toEqual value: '(', scopes: ['source.js', 'meta.brace.round.js']
      expect(tokens[3]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[5]).toEqual value: 'elem', scopes: ['source.js', 'constant.other.js']
      expect(tokens[6]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[7]).toEqual value: 'of', scopes: ['source.js', 'keyword.operator.of.js']
      expect(tokens[8]).toEqual value: ' array', scopes: ['source.js']
      expect(tokens[9]).toEqual value: ')', scopes: ['source.js', 'meta.brace.round.js']

      {tokens} = grammar.tokenizeLine 'for (const name in object) {'
      expect(tokens[5]).toEqual value: 'name', scopes: ['source.js', 'constant.other.js']
      expect(tokens[6]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[7]).toEqual value: 'in', scopes: ['source.js', 'keyword.operator.in.js']
      expect(tokens[8]).toEqual value: ' object', scopes: ['source.js']

      {tokens} = grammar.tokenizeLine 'const index = 0;'
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'index', scopes: ['source.js', 'constant.other.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']

      {tokens} = grammar.tokenizeLine 'const offset = 0;'
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'offset', scopes: ['source.js', 'constant.other.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']

    it "tokenizes support constants", ->
      {tokens} = grammar.tokenizeLine('awesome = cool.systemLanguage;')
      expect(tokens[0]).toEqual value: 'awesome ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']
      expect(tokens[3]).toEqual value: 'cool', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[4]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[5]).toEqual value: 'systemLanguage', scopes: ['source.js', 'support.constant.js']
      expect(tokens[6]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

    it "does not tokenize constants when they are object keys", ->
      {tokens} = grammar.tokenizeLine('FOO: 1')
      expect(tokens[0]).toEqual value: 'FOO', scopes: ['source.js']
      expect(tokens[1]).toEqual value: ':', scopes: ['source.js', 'keyword.operator.js']

    it "tokenizes constants in the middle of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? FOO : b')
      expect(tokens[3]).toEqual value: 'FOO', scopes: ['source.js', 'constant.other.js']

    it "tokenizes constants at the end of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? b : FOO')
      expect(tokens[5]).toEqual value: 'FOO', scopes: ['source.js', 'constant.other.js']

  describe "ES6 string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('`hey ${name}`')
      expect(tokens[0]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'hey ', scopes: ['source.js', 'string.quoted.template.js']
      expect(tokens[2]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[3]).toEqual value: 'name', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source']
      expect(tokens[4]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[5]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.end.js']

      {tokens} = grammar.tokenizeLine('`hey ${() => {return hi;}}`')
      expect(tokens[0]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'hey ', scopes: ['source.js', 'string.quoted.template.js']
      expect(tokens[2]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'meta.function.arrow.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'meta.function.arrow.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[6]).toEqual value: '=>', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'meta.function.arrow.js', 'storage.type.arrow.js']
      expect(tokens[8]).toEqual value: '{', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'meta.brace.curly.js']
      expect(tokens[9]).toEqual value: 'return', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'keyword.control.js']
      expect(tokens[10]).toEqual value: ' hi', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source']
      expect(tokens[11]).toEqual value: ';', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.terminator.statement.js']
      expect(tokens[12]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'meta.brace.curly.js']
      expect(tokens[13]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[14]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged HTML string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('html`hey <b>${name}</b>`')
      expect(tokens[0]).toEqual value: 'html', scopes: [ 'source.js', 'string.quoted.template.html.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.html.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[2]).toEqual value: 'hey <b>', scopes: ['source.js', 'string.quoted.template.html.js']
      expect(tokens[3]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[4]).toEqual value: 'name', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[6]).toEqual value: '</b>', scopes: ['source.js', 'string.quoted.template.html.js']
      expect(tokens[7]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.html.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged HTML string templates with expanded function name", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeHTML`hey <b>${name}</b>`')
      expect(tokens[0]).toEqual value: 'escapeHTML', scopes: [ 'source.js', 'string.quoted.template.html.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.html.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[2]).toEqual value: 'hey <b>', scopes: ['source.js', 'string.quoted.template.html.js']
      expect(tokens[3]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[4]).toEqual value: 'name', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[6]).toEqual value: '</b>', scopes: ['source.js', 'string.quoted.template.html.js']
      expect(tokens[7]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.html.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged HTML string templates with expanded function name and white space", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeHTML   `hey <b>${name}</b>`')
      expect(tokens[0]).toEqual value: 'escapeHTML', scopes: [ 'source.js', 'string.quoted.template.html.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '   ', scopes: [ 'source.js', 'string.quoted.template.html.js' ]
      expect(tokens[2]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.html.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[3]).toEqual value: 'hey <b>', scopes: ['source.js', 'string.quoted.template.html.js']
      expect(tokens[4]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[5]).toEqual value: 'name', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source']
      expect(tokens[6]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.html.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[7]).toEqual value: '</b>', scopes: ['source.js', 'string.quoted.template.html.js']
      expect(tokens[8]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.html.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged CSS string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('css`.highlight { border: ${borderSize}; }`')
      expect(tokens[0]).toEqual value: 'css', scopes: [ 'source.js', 'string.quoted.template.css.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.css.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[2]).toEqual value: '.highlight { border: ', scopes: ['source.js', 'string.quoted.template.css.js']
      expect(tokens[3]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[4]).toEqual value: 'borderSize', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[6]).toEqual value: '; }', scopes: ['source.js', 'string.quoted.template.css.js']
      expect(tokens[7]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.css.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged CSS string templates with expanded function name", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeCSS`.highlight { border: ${borderSize}; }`')
      expect(tokens[0]).toEqual value: 'escapeCSS', scopes: [ 'source.js', 'string.quoted.template.css.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.css.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[2]).toEqual value: '.highlight { border: ', scopes: ['source.js', 'string.quoted.template.css.js']
      expect(tokens[3]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[4]).toEqual value: 'borderSize', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[6]).toEqual value: '; }', scopes: ['source.js', 'string.quoted.template.css.js']
      expect(tokens[7]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.css.js', 'punctuation.definition.string.end.js']

  describe "ES6 tagged CSS string templates with expanded function name and white space", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('escapeCSS   `.highlight { border: ${borderSize}; }`')
      expect(tokens[0]).toEqual value: 'escapeCSS', scopes: [ 'source.js', 'string.quoted.template.css.js', 'entity.name.function.js' ]
      expect(tokens[1]).toEqual value: '   ', scopes: [ 'source.js', 'string.quoted.template.css.js' ]
      expect(tokens[2]).toEqual value: '`', scopes: [ 'source.js', 'string.quoted.template.css.js', 'punctuation.definition.string.begin.js' ]
      expect(tokens[3]).toEqual value: '.highlight { border: ', scopes: ['source.js', 'string.quoted.template.css.js']
      expect(tokens[4]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[5]).toEqual value: 'borderSize', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source']
      expect(tokens[6]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.css.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[7]).toEqual value: '; }', scopes: ['source.js', 'string.quoted.template.css.js']
      expect(tokens[8]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.css.js', 'punctuation.definition.string.end.js']

  describe "ES6 class", ->
    it "tokenizes class", ->
      {tokens} = grammar.tokenizeLine('class MyClass')
      expect(tokens[0]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[2]).toEqual value: 'MyClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

      {tokens} = grammar.tokenizeLine('class $abc$')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

      {tokens} = grammar.tokenizeLine('class $$')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes class...extends", ->
      {tokens} = grammar.tokenizeLine('class MyClass extends SomeClass')
      expect(tokens[0]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[2]).toEqual value: 'MyClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']
      expect(tokens[4]).toEqual value: 'extends', scopes: ['source.js', 'meta.class.js', 'storage.modifier.js']
      expect(tokens[6]).toEqual value: 'SomeClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

      {tokens} = grammar.tokenizeLine('class MyClass extends $abc$')
      expect(tokens[6]).toEqual value: '$abc$', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

      {tokens} = grammar.tokenizeLine('class MyClass extends $$')
      expect(tokens[6]).toEqual value: '$$', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes anonymous class", ->
      {tokens} = grammar.tokenizeLine('class extends SomeClass')
      expect(tokens[0]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[2]).toEqual value: 'extends', scopes: ['source.js', 'meta.class.js', 'storage.modifier.js']
      expect(tokens[4]).toEqual value: 'SomeClass', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

      {tokens} = grammar.tokenizeLine('class extends $abc$')
      expect(tokens[4]).toEqual value: '$abc$', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

      {tokens} = grammar.tokenizeLine('class extends $$')
      expect(tokens[4]).toEqual value: '$$', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes constructors", ->
      {tokens} = grammar.tokenizeLine('constructor(a, b)')
      expect(tokens[0]).toEqual value: 'constructor', scopes: ['source.js', 'entity.name.function.constructor.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[2]).toEqual value: 'a', scopes: ['source.js', 'variable.parameter.function.js']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.js', 'meta.object.delimiter.js']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[5]).toEqual value: 'b', scopes: ['source.js', 'variable.parameter.function.js']
      expect(tokens[6]).toEqual value: ')', scopes: ['source.js', 'punctuation.definition.parameters.end.js']

  describe "ES6 import", ->
    it "tokenizes import", ->
      {tokens} = grammar.tokenizeLine('import "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '"', scopes: ['source.js', 'meta.import.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[3]).toEqual value: 'module-name', scopes: ['source.js', 'meta.import.js', 'string.quoted.double.js']
      expect(tokens[4]).toEqual value: '"', scopes: ['source.js', 'meta.import.js', 'string.quoted.double.js', 'punctuation.definition.string.end.js']
      expect(tokens[5]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

    it "tokenizes default import", ->
      {tokens} = grammar.tokenizeLine('import defaultMember from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'defaultMember', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[4]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "tokenizes default named import", ->
      {tokens} = grammar.tokenizeLine('import { default as defaultMember } from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'default', scopes: ['source.js', 'meta.import.js', 'variable.language.default.js']
      expect(tokens[6]).toEqual value: 'as', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[8]).toEqual value: 'defaultMember', scopes: ['source.js', 'meta.import.js', 'variable.other.module-alias.js']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.end.js']
      expect(tokens[12]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "tokenizes named import", ->
      {tokens} = grammar.tokenizeLine('import { member } from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'member', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[6]).toEqual value: '}', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.end.js']
      expect(tokens[8]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

      {tokens} = grammar.tokenizeLine('import { member1 , member2 as alias2 } from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'member1', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[6]).toEqual value: ',', scopes: ['source.js', 'meta.import.js', 'meta.delimiter.object.comma.js']
      expect(tokens[8]).toEqual value: 'member2', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[10]).toEqual value: 'as', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[12]).toEqual value: 'alias2', scopes: ['source.js', 'meta.import.js', 'variable.other.module-alias.js']
      expect(tokens[14]).toEqual value: '}', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.end.js']
      expect(tokens[16]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "tokenizes entire module import", ->
      {tokens} = grammar.tokenizeLine('import * as name from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '*', scopes: ['source.js', 'meta.import.js', 'variable.language.import-all.js']
      expect(tokens[4]).toEqual value: 'as', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[6]).toEqual value: 'name', scopes: ['source.js', 'meta.import.js', 'variable.other.module-alias.js']
      expect(tokens[8]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "tokenizes `import defaultMember, { member } from 'module-name';`", ->
      {tokens} = grammar.tokenizeLine('import defaultMember, { member } from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'defaultMember', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.js', 'meta.import.js', 'meta.delimiter.object.comma.js']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[7]).toEqual value: 'member', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[9]).toEqual value: '}', scopes: ['source.js', 'meta.import.js', 'punctuation.definition.modules.end.js']
      expect(tokens[11]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "tokenizes `import defaultMember, * as alias from 'module-name';", ->
      {tokens} = grammar.tokenizeLine('import defaultMember, * as alias from "module-name";')
      expect(tokens[0]).toEqual value: 'import', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'defaultMember', scopes: ['source.js', 'meta.import.js', 'variable.other.module.js']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.js', 'meta.import.js', 'meta.delimiter.object.comma.js']
      expect(tokens[5]).toEqual value: '*', scopes: ['source.js', 'meta.import.js', 'variable.language.import-all.js']
      expect(tokens[7]).toEqual value: 'as', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']
      expect(tokens[9]).toEqual value: 'alias', scopes: ['source.js', 'meta.import.js', 'variable.other.module-alias.js']
      expect(tokens[11]).toEqual value: 'from', scopes: ['source.js', 'meta.import.js', 'keyword.control.js']

    it "tokenizes comments in statement", ->
      lines = grammar.tokenizeLines '''
        import /* comment */ {
          member1, // comment
          /* comment */
          member2
        } from "module-name";
      '''
      expect(lines[0][2]).toEqual value: '/*', scopes: ['source.js', 'meta.import.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(lines[0][3]).toEqual value: ' comment ', scopes: ['source.js', 'meta.import.js', 'comment.block.js']
      expect(lines[0][4]).toEqual value: '*/', scopes: ['source.js', 'meta.import.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(lines[1][4]).toEqual value: '//', scopes: ['source.js', 'meta.import.js', 'comment.line.double-slash.js', 'punctuation.definition.comment.js']
      expect(lines[1][5]).toEqual value: ' comment', scopes: ['source.js', 'meta.import.js', 'comment.line.double-slash.js']
      expect(lines[2][1]).toEqual value: '/*', scopes: ['source.js', 'meta.import.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(lines[2][2]).toEqual value: ' comment ', scopes: ['source.js', 'meta.import.js', 'comment.block.js']
      expect(lines[2][3]).toEqual value: '*/', scopes: ['source.js', 'meta.import.js', 'comment.block.js', 'punctuation.definition.comment.js']

  describe "ES6 export", ->
    it "tokenizes named export", ->
      {tokens} = grammar.tokenizeLine('export var x = 0;')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'var', scopes: ['source.js', 'storage.type.var.js']
      expect(tokens[3]).toEqual value: ' x ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']

      {tokens} = grammar.tokenizeLine('export let scopedVariable = 0;')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'let', scopes: ['source.js', 'storage.type.var.js']
      expect(tokens[3]).toEqual value: ' scopedVariable ', scopes: ['source.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']

      {tokens} = grammar.tokenizeLine('export const CONSTANT = 0;')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[4]).toEqual value: 'CONSTANT', scopes: ['source.js', 'constant.other.js']
      expect(tokens[6]).toEqual value: '=', scopes: ['source.js', 'keyword.operator.assignment.js']

    it "tokenizes named function export", ->
      {tokens} = grammar.tokenizeLine('export function func(p1, p2){}')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[4]).toEqual value: 'func', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[5]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[6]).toEqual value: 'p1', scopes: ['source.js', 'meta.function.js', 'variable.parameter.function.js']
      expect(tokens[7]).toEqual value: ',', scopes: ['source.js', 'meta.function.js', 'meta.object.delimiter.js']
      expect(tokens[9]).toEqual value: 'p2', scopes: ['source.js', 'meta.function.js', 'variable.parameter.function.js']
      expect(tokens[10]).toEqual value: ')', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.end.js']

    it "tokenizes named class export", ->
      {tokens} = grammar.tokenizeLine('export class Foo {}')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[4]).toEqual value: 'Foo', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes existing variable export", ->
      {tokens} = grammar.tokenizeLine('export { bar };')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'bar', scopes: ['source.js', 'meta.export.js', 'variable.other.module.js']
      expect(tokens[6]).toEqual value: '}', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.end.js']

      {tokens} = grammar.tokenizeLine('export { bar, foo as alias };')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'bar', scopes: ['source.js', 'meta.export.js', 'variable.other.module.js']
      expect(tokens[5]).toEqual value: ',', scopes: ['source.js', 'meta.export.js', 'meta.delimiter.object.comma.js']
      expect(tokens[7]).toEqual value: 'foo', scopes: ['source.js', 'meta.export.js', 'variable.other.module.js']
      expect(tokens[9]).toEqual value: 'as', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[11]).toEqual value: 'alias', scopes: ['source.js', 'meta.export.js', 'variable.other.module-alias.js']
      expect(tokens[13]).toEqual value: '}', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.end.js']

    it "tokenizes default export", ->
      {tokens} = grammar.tokenizeLine('export default 123;')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: '123', scopes: ['source.js', 'constant.numeric.decimal.js']

      {tokens} = grammar.tokenizeLine('export default name;')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: 'name', scopes: ['source.js', 'meta.export.js', 'variable.other.module.js']

      {tokens} = grammar.tokenizeLine('export { foo as default };')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'foo', scopes: ['source.js', 'meta.export.js', 'variable.other.module.js']
      expect(tokens[6]).toEqual value: 'as', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[8]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.end.js']

      {tokens} = grammar.tokenizeLine('''
      export default {
        'prop': 'value'
      };
      ''')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: '{', scopes: ['source.js', 'meta.brace.curly.js']
      expect(tokens[6]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.begin.js']
      expect(tokens[7]).toEqual value: "prop", scopes: ['source.js', 'string.quoted.single.js']
      expect(tokens[8]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.end.js']
      expect(tokens[9]).toEqual value: ":", scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[11]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.begin.js']
      expect(tokens[12]).toEqual value: "value", scopes: ['source.js', 'string.quoted.single.js']
      expect(tokens[13]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.end.js']
      expect(tokens[15]).toEqual value: '}', scopes: ['source.js', 'meta.brace.curly.js']

    it "tokenizes default function export", ->
      {tokens} = grammar.tokenizeLine('export default function () {}')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[6]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[7]).toEqual value: ')', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[9]).toEqual value: '{', scopes: ['source.js', 'punctuation.section.scope.begin.js']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'punctuation.section.scope.end.js']

      {tokens} = grammar.tokenizeLine('export default function func() {}')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[6]).toEqual value: 'func', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[7]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[8]).toEqual value: ')', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.end.js']

    it "tokenizes comments in statement", ->
      lines = grammar.tokenizeLines '''
        export {
          member1, // comment
          /* comment */
          member2
        };
      '''
      expect(lines[1][4]).toEqual value: '//', scopes: ['source.js', 'meta.export.js', 'comment.line.double-slash.js', 'punctuation.definition.comment.js']
      expect(lines[1][5]).toEqual value: ' comment', scopes: ['source.js', 'meta.export.js', 'comment.line.double-slash.js']
      expect(lines[2][1]).toEqual value: '/*', scopes: ['source.js', 'meta.export.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(lines[2][2]).toEqual value: ' comment ', scopes: ['source.js', 'meta.export.js', 'comment.block.js']
      expect(lines[2][3]).toEqual value: '*/', scopes: ['source.js', 'meta.export.js', 'comment.block.js', 'punctuation.definition.comment.js']

      {tokens} = grammar.tokenizeLine('export {member1, /* comment */ member2} /* comment */ from "module";')
      expect(tokens[6]).toEqual value: '/*', scopes: ['source.js', 'meta.export.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(tokens[7]).toEqual value: ' comment ', scopes: ['source.js', 'meta.export.js', 'comment.block.js']
      expect(tokens[8]).toEqual value: '*/', scopes: ['source.js', 'meta.export.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(tokens[13]).toEqual value: '/*', scopes: ['source.js', 'meta.export.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(tokens[14]).toEqual value: ' comment ', scopes: ['source.js', 'meta.export.js', 'comment.block.js']
      expect(tokens[15]).toEqual value: '*/', scopes: ['source.js', 'meta.export.js', 'comment.block.js', 'punctuation.definition.comment.js']

    it "tokenizes default class export", ->
      {tokens} = grammar.tokenizeLine('export default class {}')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: 'class', scopes: ['source.js', 'storage.type.js']
      expect(tokens[6]).toEqual value: '{', scopes: ['source.js', 'punctuation.section.scope.begin.js']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'punctuation.section.scope.end.js']

      {tokens} = grammar.tokenizeLine('export default class Foo {}')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[4]).toEqual value: 'class', scopes: ['source.js', 'meta.class.js', 'storage.type.class.js']
      expect(tokens[6]).toEqual value: 'Foo', scopes: ['source.js', 'meta.class.js', 'entity.name.type.js']

    it "tokenizes re-export", ->
      {tokens} = grammar.tokenizeLine('export { name } from "module-name";')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'name', scopes: ['source.js', 'meta.export.js', 'variable.other.module.js']
      expect(tokens[6]).toEqual value: '}', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.end.js']
      expect(tokens[8]).toEqual value: 'from', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']

      {tokens} = grammar.tokenizeLine('export * from "module-name";')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '*', scopes: ['source.js', 'meta.export.js', 'variable.language.import-all.js']
      expect(tokens[4]).toEqual value: 'from', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']

      {tokens} = grammar.tokenizeLine('export { default as alias } from "module-name";')
      expect(tokens[0]).toEqual value: 'export', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.begin.js']
      expect(tokens[4]).toEqual value: 'default', scopes: ['source.js', 'meta.export.js', 'variable.language.default.js']
      expect(tokens[6]).toEqual value: 'as', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']
      expect(tokens[8]).toEqual value: 'alias', scopes: ['source.js', 'meta.export.js', 'variable.other.module-alias.js']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'meta.export.js', 'punctuation.definition.modules.end.js']
      expect(tokens[12]).toEqual value: 'from', scopes: ['source.js', 'meta.export.js', 'keyword.control.js']

  describe "ES6 yield", ->
    it "tokenizes yield", ->
      {tokens} = grammar.tokenizeLine('yield next')
      expect(tokens[0]).toEqual value: 'yield', scopes: ['source.js', 'meta.control.yield.js', 'keyword.control.js']

    it "tokenizes yield*", ->
      {tokens} = grammar.tokenizeLine('yield * next')
      expect(tokens[0]).toEqual value: 'yield', scopes: ['source.js', 'meta.control.yield.js', 'keyword.control.js']
      expect(tokens[2]).toEqual value: '*', scopes: ['source.js', 'meta.control.yield.js', 'storage.modifier.js']

    it "does not tokenize yield when it is an object key", ->
      {tokens} = grammar.tokenizeLine('yield: 1')
      expect(tokens[0]).toEqual value: 'yield', scopes: ['source.js']
      expect(tokens[1]).toEqual value: ':', scopes: ['source.js', 'keyword.operator.js']

    it "tokenizes yield in the middle of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? yield : b')
      expect(tokens[3]).toEqual value: 'yield', scopes: ['source.js', 'meta.control.yield.js', 'keyword.control.js']

    it "tokenizes yield at the end of ternary expressions", ->
      {tokens} = grammar.tokenizeLine('a ? b : yield')
      expect(tokens[5]).toEqual value: 'yield', scopes: ['source.js', 'meta.control.yield.js', 'keyword.control.js']

  describe "default: in a switch statement", ->
    it "tokenizes it as a keyword", ->
      {tokens} = grammar.tokenizeLine('default: ')
      expect(tokens[0]).toEqual value: 'default', scopes: ['source.js', 'keyword.control.js']

  describe "non-anonymous functions", ->
    it "tokenizes regular functions", ->
      {tokens} = grammar.tokenizeLine('function nonAnonymous(){}')
      expect(tokens[0]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[2]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']

      {tokens} = grammar.tokenizeLine('function $abc$(){}')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']

      {tokens} = grammar.tokenizeLine('function $$(){}')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']

    it "tokenizes methods", ->
      {tokens} = grammar.tokenizeLine('Foo.method = function nonAnonymous(')
      expect(tokens[0]).toEqual value: 'Foo', scopes: ['source.js', 'meta.function.js', 'support.class.js']
      expect(tokens[2]).toEqual value: 'method', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'meta.function.js', 'keyword.operator.assignment.js']
      expect(tokens[6]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[8]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[9]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes methods", ->
      {tokens} = grammar.tokenizeLine('f(a, b) {}')
      expect(tokens[0]).toEqual value: 'f', scopes: ['source.js', 'meta.method.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[2]).toEqual value: 'a', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.js', 'meta.method.js', 'meta.object.delimiter.js']
      expect(tokens[5]).toEqual value: 'b', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[6]).toEqual value: ')', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.end.js']

      {tokens} = grammar.tokenizeLine('hi({host, root = "./", plugins = [a, "b", "c", d]}) {}')
      expect(tokens[0]).toEqual value: 'hi', scopes: ['source.js', 'meta.method.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'meta.method.js', 'meta.brace.curly.js']
      expect(tokens[3]).toEqual value: 'host', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[4]).toEqual value: ',', scopes: ['source.js', 'meta.method.js', 'meta.object.delimiter.js']
      expect(tokens[6]).toEqual value: 'root', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[8]).toEqual value: '=', scopes: ['source.js', 'meta.method.js', 'keyword.operator.assignment.js']
      expect(tokens[10]).toEqual value: '"', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[11]).toEqual value: './', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js']
      expect(tokens[12]).toEqual value: '"', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js', 'punctuation.definition.string.end.js']
      expect(tokens[13]).toEqual value: ',', scopes: ['source.js', 'meta.method.js', 'meta.object.delimiter.js']
      expect(tokens[15]).toEqual value: 'plugins', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[17]).toEqual value: '=', scopes: ['source.js', 'meta.method.js', 'keyword.operator.assignment.js']
      expect(tokens[19]).toEqual value: '[', scopes: ['source.js', 'meta.method.js', 'meta.brace.square.js']
      expect(tokens[20]).toEqual value: 'a', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[21]).toEqual value: ',', scopes: ['source.js', 'meta.method.js', 'meta.object.delimiter.js']
      expect(tokens[23]).toEqual value: '"', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[26]).toEqual value: ',', scopes: ['source.js', 'meta.method.js', 'meta.object.delimiter.js']
      expect(tokens[28]).toEqual value: '"', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[33]).toEqual value: 'd', scopes: ['source.js', 'meta.method.js', 'variable.parameter.function.js']
      expect(tokens[34]).toEqual value: ']', scopes: ['source.js', 'meta.method.js', 'meta.brace.square.js']
      expect(tokens[35]).toEqual value: '}', scopes: ['source.js', 'meta.method.js', 'meta.brace.curly.js']
      expect(tokens[36]).toEqual value: ')', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.end.js']

    it "tokenizes functions", ->
      {tokens} = grammar.tokenizeLine('var func = function nonAnonymous(')
      expect(tokens[0]).toEqual value: 'var', scopes: ['source.js', 'storage.type.var.js']
      expect(tokens[2]).toEqual value: 'func', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'meta.function.js', 'keyword.operator.assignment.js']
      expect(tokens[6]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[8]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[9]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes object functions", ->
      {tokens} = grammar.tokenizeLine('foo: function nonAnonymous(')
      expect(tokens[0]).toEqual value: 'foo', scopes: ['source.js', 'meta.function.json.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: ':', scopes: ['source.js', 'meta.function.json.js', 'keyword.operator.assignment.js']
      expect(tokens[3]).toEqual value: 'function', scopes: ['source.js', 'meta.function.json.js', 'storage.type.function.js']
      expect(tokens[5]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.json.js', 'entity.name.function.js']
      expect(tokens[6]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes quoted object functions", ->
      {tokens} = grammar.tokenizeLine('"foo": function nonAnonymous(')
      expect(tokens[1]).toEqual value: 'foo', scopes: ['source.js', 'meta.function.json.js', 'string.quoted.double.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: ':', scopes: ['source.js', 'meta.function.json.js', 'keyword.operator.assignment.js']
      expect(tokens[5]).toEqual value: 'function', scopes: ['source.js', 'meta.function.json.js', 'storage.type.function.js']
      expect(tokens[7]).toEqual value: 'nonAnonymous', scopes: ['source.js', 'meta.function.json.js', 'entity.name.function.js']
      expect(tokens[8]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']

    it "tokenizes async functions", ->
      {tokens} = grammar.tokenizeLine('async function f(){}')
      expect(tokens[0]).toEqual value: 'async', scopes: ['source.js', 'meta.function.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[4]).toEqual value: 'f', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']

      {tokens} = grammar.tokenizeLine('async f(){}')
      expect(tokens[0]).toEqual value: 'async', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'f', scopes: ['source.js', 'meta.method.js', 'entity.name.function.js']

    it "tokenizes arrow functions with params", ->
      {tokens} = grammar.tokenizeLine('(param1,param2)=>{}')
      expect(tokens[0]).toEqual value: '(', scopes: ['source.js', 'meta.function.arrow.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[1]).toEqual value: 'param1', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
      expect(tokens[3]).toEqual value: 'param2', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'meta.function.arrow.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[5]).toEqual value: '=>', scopes: ['source.js', 'meta.function.arrow.js', 'storage.type.arrow.js']

    it "tokenizes stored arrow functions with params", ->
      {tokens} = grammar.tokenizeLine('var func = (param1,param2)=>{}')
      expect(tokens[0]).toEqual value: 'var', scopes: ['source.js', 'storage.type.var.js']
      expect(tokens[2]).toEqual value: 'func', scopes: ['source.js', 'meta.function.arrow.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'meta.function.arrow.js', 'keyword.operator.assignment.js']
      expect(tokens[7]).toEqual value: 'param1', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
      expect(tokens[9]).toEqual value: 'param2', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
      expect(tokens[10]).toEqual value: ')', scopes: ['source.js', 'meta.function.arrow.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[11]).toEqual value: '=>', scopes: ['source.js', 'meta.function.arrow.js', 'storage.type.arrow.js']

    it "tokenizes arrow functions with params stored in object properties", ->
      {tokens} = grammar.tokenizeLine('Utils.isEmpty = (param1, param2) => {}')
      expect(tokens[0]).toEqual value: 'Utils', scopes: ['source.js', 'meta.function.arrow.js', 'support.class.js']
      expect(tokens[2]).toEqual value: 'isEmpty', scopes: ['source.js', 'meta.function.arrow.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '=', scopes: ['source.js', 'meta.function.arrow.js', 'keyword.operator.assignment.js']
      expect(tokens[7]).toEqual value: 'param1', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
      expect(tokens[10]).toEqual value: 'param2', scopes: ['source.js', 'meta.function.arrow.js', 'variable.parameter.function.js']
      expect(tokens[11]).toEqual value: ')', scopes: ['source.js', 'meta.function.arrow.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[13]).toEqual value: '=>', scopes: ['source.js', 'meta.function.arrow.js', 'storage.type.arrow.js']

  describe "variables", ->
    it "tokenizes 'this'", ->
      {tokens} = grammar.tokenizeLine('this')
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.js', 'variable.language.js']

      {tokens} = grammar.tokenizeLine('this.obj.prototype = new El()')
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.js', 'variable.language.js']

    it "tokenizes 'super'", ->
      {tokens} = grammar.tokenizeLine('super')
      expect(tokens[0]).toEqual value: 'super', scopes: ['source.js', 'variable.language.js']

    it "tokenizes illegal identifiers", ->
      {tokens} = grammar.tokenizeLine('0illegal')
      expect(tokens[0]).toEqual value: '0illegal', scopes: ['source.js', 'invalid.illegal.identifier.js']

      {tokens} = grammar.tokenizeLine('123illegal')
      expect(tokens[0]).toEqual value: '123illegal', scopes: ['source.js', 'invalid.illegal.identifier.js']

      {tokens} = grammar.tokenizeLine('123$illegal')
      expect(tokens[0]).toEqual value: '123$illegal', scopes: ['source.js', 'invalid.illegal.identifier.js']

    describe "objects", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine('obj.prop')
        expect(tokens[0]).toEqual value: 'obj', scopes: ['source.js', 'variable.other.object.js']

        {tokens} = grammar.tokenizeLine('$abc$.prop')
        expect(tokens[0]).toEqual value: '$abc$', scopes: ['source.js', 'variable.other.object.js']

        {tokens} = grammar.tokenizeLine('$$.prop')
        expect(tokens[0]).toEqual value: '$$', scopes: ['source.js', 'variable.other.object.js']

      it "tokenizes illegal objects", ->
        {tokens} = grammar.tokenizeLine('1.prop')
        expect(tokens[0]).toEqual value: '1', scopes: ['source.js', 'invalid.illegal.identifier.js']

        {tokens} = grammar.tokenizeLine('123.prop')
        expect(tokens[0]).toEqual value: '123', scopes: ['source.js', 'invalid.illegal.identifier.js']

        {tokens} = grammar.tokenizeLine('123a.prop')
        expect(tokens[0]).toEqual value: '123a', scopes: ['source.js', 'invalid.illegal.identifier.js']

  describe "function calls", ->
    it "tokenizes function calls", ->
      {tokens} = grammar.tokenizeLine('functionCall()')
      expect(tokens[0]).toEqual value: 'functionCall', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('functionCall(arg1, "test", {a: 123})')
      expect(tokens[0]).toEqual value: 'functionCall', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: 'arg1', scopes: ['source.js', 'meta.function-call.js']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.js', 'meta.function-call.js', 'meta.delimiter.object.comma.js']
      expect(tokens[5]).toEqual value: '"', scopes: ['source.js', 'meta.function-call.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[6]).toEqual value: 'test', scopes: ['source.js', 'meta.function-call.js', 'string.quoted.double.js']
      expect(tokens[7]).toEqual value: '"', scopes: ['source.js', 'meta.function-call.js', 'string.quoted.double.js', 'punctuation.definition.string.end.js']
      expect(tokens[8]).toEqual value: ',', scopes: ['source.js', 'meta.function-call.js', 'meta.delimiter.object.comma.js']
      expect(tokens[10]).toEqual value: '{', scopes: ['source.js', 'meta.function-call.js', 'meta.brace.curly.js']
      expect(tokens[11]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js']
      expect(tokens[12]).toEqual value: ':', scopes: ['source.js', 'meta.function-call.js', 'keyword.operator.js']
      expect(tokens[14]).toEqual value: '123', scopes: ['source.js', 'meta.function-call.js', 'constant.numeric.decimal.js']
      expect(tokens[15]).toEqual value: '}', scopes: ['source.js', 'meta.function-call.js', 'meta.brace.curly.js']
      expect(tokens[16]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('functionCall((123).toString())')
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'meta.brace.round.js']
      expect(tokens[3]).toEqual value: '123', scopes: ['source.js', 'meta.function-call.js', 'constant.numeric.decimal.js']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'meta.brace.round.js']
      expect(tokens[9]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('$abc$()')
      expect(tokens[0]).toEqual value: '$abc$', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']

      {tokens} = grammar.tokenizeLine('$$()')
      expect(tokens[0]).toEqual value: '$$', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']

    it "tokenizes function calls when they are arguments", ->
      {tokens} = grammar.tokenizeLine('a(b(c))')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.js', 'meta.function-call.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[4]).toEqual value: 'c', scopes: ['source.js', 'meta.function-call.js', 'meta.function-call.js']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']
      expect(tokens[6]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

    it "tokenizes illegal function calls", ->
      {tokens} = grammar.tokenizeLine('0illegal()')
      expect(tokens[0]).toEqual value: '0illegal', scopes: ['source.js', 'meta.function-call.js', 'invalid.illegal.identifier.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

    it "tokenizes illegal arguments", ->
      {tokens} = grammar.tokenizeLine('a(1a)')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: '1a', scopes: ['source.js', 'meta.function-call.js', 'invalid.illegal.identifier.js']
      expect(tokens[3]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('a(123a)')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: '123a', scopes: ['source.js', 'meta.function-call.js', 'invalid.illegal.identifier.js']
      expect(tokens[3]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('a(1.prop)')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: '1', scopes: ['source.js', 'meta.function-call.js', 'invalid.illegal.identifier.js']
      expect(tokens[3]).toEqual value: '.', scopes: ['source.js', 'meta.function-call.js', 'meta.delimiter.property.period.js']
      expect(tokens[4]).toEqual value: 'prop', scopes: ['source.js', 'meta.function-call.js', 'variable.other.property.js']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

    it "tokenizes function declaration as an argument", ->
      {tokens} = grammar.tokenizeLine('a(function b(p) { return p; })')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: 'function', scopes: ['source.js', 'meta.function-call.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[4]).toEqual value: 'b', scopes: ['source.js', 'meta.function-call.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[5]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[6]).toEqual value: 'p', scopes: ['source.js', 'meta.function-call.js', 'meta.function.js', 'variable.parameter.function.js']
      expect(tokens[7]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'meta.function.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[9]).toEqual value: '{', scopes: ['source.js', 'meta.function-call.js', 'meta.brace.curly.js']
      expect(tokens[11]).toEqual value: 'return', scopes: ['source.js', 'meta.function-call.js', 'keyword.control.js']
      expect(tokens[12]).toEqual value: ' p', scopes: ['source.js', 'meta.function-call.js']
      expect(tokens[13]).toEqual value: ';', scopes: ['source.js', 'meta.function-call.js', 'punctuation.terminator.statement.js']
      expect(tokens[15]).toEqual value: '}', scopes: ['source.js', 'meta.function-call.js', 'meta.brace.curly.js']
      expect(tokens[16]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']

  describe "method calls", ->
    it "tokenizes method calls", ->
      {tokens} = grammar.tokenizeLine('a.b(1+1)')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[4]).toEqual value: '1', scopes: ['source.js', 'meta.method-call.js', 'constant.numeric.decimal.js']
      expect(tokens[5]).toEqual value: '+', scopes: ['source.js', 'meta.method-call.js', 'keyword.operator.js']
      expect(tokens[6]).toEqual value: '1', scopes: ['source.js', 'meta.method-call.js', 'constant.numeric.decimal.js']
      expect(tokens[7]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('a.$abc$()')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']

      {tokens} = grammar.tokenizeLine('a.$$()')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']

      {tokens} = grammar.tokenizeLine('gulp.src("./*.js")')
      expect(tokens[0]).toEqual value: 'gulp', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[2]).toEqual value: 'src', scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[4]).toEqual value: '"', scopes: ['source.js', 'meta.method-call.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[5]).toEqual value: './*.js', scopes: ['source.js', 'meta.method-call.js', 'string.quoted.double.js']
      expect(tokens[6]).toEqual value: '"', scopes: ['source.js', 'meta.method-call.js', 'string.quoted.double.js', 'punctuation.definition.string.end.js']
      expect(tokens[7]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('.pipe(minify())')
      expect(tokens[0]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[1]).toEqual value: 'pipe', scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']
      expect(tokens[2]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[3]).toEqual value: 'minify', scopes: ['source.js', 'meta.method-call.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[4]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']
      expect(tokens[6]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('.pipe(gulp.dest("build"))')
      expect(tokens[0]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[1]).toEqual value: 'pipe', scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']
      expect(tokens[2]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[3]).toEqual value: 'gulp', scopes: ['source.js', 'meta.method-call.js', 'variable.other.object.js']
      expect(tokens[4]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[5]).toEqual value: 'dest', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'entity.name.function.js']
      expect(tokens[6]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[7]).toEqual value: '"', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[8]).toEqual value: 'build', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'string.quoted.double.js']
      expect(tokens[9]).toEqual value: '"', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'string.quoted.double.js', 'punctuation.definition.string.end.js']
      expect(tokens[10]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']
      expect(tokens[11]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

    describe "built-in methods", ->
      methods    = ["require", "parseInt", "parseFloat", "print"]
      domMethods = ["substringData", "submit", "splitText", "setNamedItem", "setAttribute"]

      for method in methods
        it "tokenizes '#{method}'", ->
          {tokens} = grammar.tokenizeLine('.' + method + '()')
          expect(tokens[0]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
          expect(tokens[1]).toEqual value: method, scopes: ['source.js', 'meta.method-call.js', 'support.function.js']
          expect(tokens[2]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
          expect(tokens[3]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

      for domMethod in domMethods
        it "tokenizes '#{domMethod}'", ->
          {tokens} = grammar.tokenizeLine('.' + domMethod + '()')
          expect(tokens[0]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
          expect(tokens[1]).toEqual value: domMethod, scopes: ['source.js', 'meta.method-call.js', 'support.function.dom.js']
          expect(tokens[2]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
          expect(tokens[3]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

  describe "properties", ->
    it "tokenizes properties", ->
      {tokens} = grammar.tokenizeLine('obj.property')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[2]).toEqual value: 'property', scopes: ['source.js', 'variable.other.property.js']

      {tokens} = grammar.tokenizeLine('obj.Property')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[2]).toEqual value: 'Property', scopes: ['source.js', 'variable.other.property.js']

      {tokens} = grammar.tokenizeLine('obj.$abc$')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.js', 'variable.other.property.js']

      {tokens} = grammar.tokenizeLine('obj.$$')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.js', 'variable.other.property.js']

      {tokens} = grammar.tokenizeLine('a().b')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'meta.function-call.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.js', 'meta.function-call.js', 'punctuation.definition.arguments.end.js']
      expect(tokens[3]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[4]).toEqual value: 'b', scopes: ['source.js', 'variable.other.property.js']

      {tokens} = grammar.tokenizeLine('a.123illegal')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[2]).toEqual value: '123illegal', scopes: ['source.js', 'invalid.illegal.identifier.js']

    it "tokenizes constant properties", ->
      {tokens} = grammar.tokenizeLine('obj.MY_CONSTANT')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[2]).toEqual value: 'MY_CONSTANT', scopes: ['source.js', 'constant.other.property.js']

      {tokens} = grammar.tokenizeLine('a.C')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.js', 'variable.other.object.js']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.delimiter.property.period.js']
      expect(tokens[2]).toEqual value: 'C', scopes: ['source.js', 'constant.other.property.js']

  describe "strings and functions", ->
    it "doesn't confuse them", ->
      {tokens} = grammar.tokenizeLine("'a'.b(':c(d)')")
      expect(tokens[0]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: "a", scopes: ['source.js', 'string.quoted.single.js']
      expect(tokens[2]).toEqual value: "'", scopes: ['source.js', 'string.quoted.single.js', 'punctuation.definition.string.end.js']
      expect(tokens[3]).toEqual value: ".", scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[4]).toEqual value: "b", scopes: ['source.js', 'meta.method-call.js', 'entity.name.function.js']
      expect(tokens[5]).toEqual value: "(", scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[6]).toEqual value: "'", scopes: ['source.js', 'meta.method-call.js', 'string.quoted.single.js', 'punctuation.definition.string.begin.js']
      expect(tokens[7]).toEqual value: ":c(d)", scopes: ['source.js', 'meta.method-call.js', 'string.quoted.single.js']
      expect(tokens[8]).toEqual value: "'", scopes: ['source.js', 'meta.method-call.js', 'string.quoted.single.js', 'punctuation.definition.string.end.js']
      expect(tokens[9]).toEqual value: ")", scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

      {tokens} = grammar.tokenizeLine('write("){");')
      expect(tokens[0]).toEqual value: 'write', scopes: ['source.js', 'meta.method.js', 'entity.name.function.js']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[2]).toEqual value: '"', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[3]).toEqual value: '){', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js']
      expect(tokens[4]).toEqual value: '"', scopes: ['source.js', 'meta.method.js', 'string.quoted.double.js', 'punctuation.definition.string.end.js']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.js', 'meta.method.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[6]).toEqual value: ';', scopes: ['source.js', 'punctuation.terminator.statement.js']

      delimsByScope =
        "string.quoted.double.js": '"'
        "string.quoted.single.js": "'"

      for scope, delim of delimsByScope
        {tokens} = grammar.tokenizeLine('a.push(' + delim + 'x' + delim + ' + y + ' + delim + ':function()' + delim + ');')
        expect(tokens[2]).toEqual value: 'push', scopes: ['source.js', 'meta.method-call.js', 'support.function.js']
        expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
        expect(tokens[4]).toEqual value: delim, scopes: ['source.js', 'meta.method-call.js', scope, 'punctuation.definition.string.begin.js']
        expect(tokens[5]).toEqual value: 'x', scopes: ['source.js', 'meta.method-call.js', scope]
        expect(tokens[6]).toEqual value: delim, scopes: ['source.js', 'meta.method-call.js', scope, 'punctuation.definition.string.end.js']
        expect(tokens[8]).toEqual value: '+', scopes: ['source.js', 'meta.method-call.js', 'keyword.operator.js']
        expect(tokens[9]).toEqual value: ' y ', scopes: ['source.js', 'meta.method-call.js' ]
        expect(tokens[10]).toEqual value: '+', scopes: ['source.js', 'meta.method-call.js', 'keyword.operator.js']
        expect(tokens[12]).toEqual value: delim, scopes: ['source.js', 'meta.method-call.js', scope, 'punctuation.definition.string.begin.js']
        expect(tokens[13]).toEqual value: ':function()', scopes: ['source.js', 'meta.method-call.js', scope]
        expect(tokens[14]).toEqual value: delim, scopes: ['source.js', 'meta.method-call.js', scope, 'punctuation.definition.string.end.js']
        expect(tokens[15]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

  describe "comments", ->
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

      {tokens} = grammar.tokenizeLine('/** @mixins */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
      expect(tokens[2]).toEqual value: '@mixins', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[4]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']

    it "tokenizes // comments", ->
      {tokens} = grammar.tokenizeLine('// comment')
      expect(tokens[0]).toEqual value: '//', scopes: ['source.js', 'comment.line.double-slash.js', 'punctuation.definition.comment.js']
      expect(tokens[1]).toEqual value: ' comment', scopes: ['source.js', 'comment.line.double-slash.js']

    it "tokenizes comments inside constant definitions", ->
      {tokens} = grammar.tokenizeLine('const a, // comment')
      expect(tokens[0]).toEqual value: 'const', scopes: ['source.js', 'storage.modifier.js']
      expect(tokens[2]).toEqual value: 'a', scopes: ['source.js', 'constant.other.js']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(tokens[5]).toEqual value: '//', scopes: ['source.js', 'comment.line.double-slash.js', 'punctuation.definition.comment.js']
      expect(tokens[6]).toEqual value: ' comment', scopes: ['source.js', 'comment.line.double-slash.js']

    it "tokenizes comments inside function parameters correctly", ->
      {tokens} = grammar.tokenizeLine('function test(arg1 /*, arg2 */) {}')
      expect(tokens[0]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js', 'meta.function.js']
      expect(tokens[2]).toEqual value: 'test', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[4]).toEqual value: 'arg1', scopes: ['source.js', 'meta.function.js', 'variable.parameter.function.js']
      expect(tokens[5]).toEqual value: ' ', scopes: ['source.js', 'meta.function.js']
      expect(tokens[6]).toEqual value: '/*', scopes: ['source.js', 'meta.function.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(tokens[7]).toEqual value: ', arg2 ', scopes: ['source.js', 'meta.function.js', 'comment.block.js']
      expect(tokens[8]).toEqual value: '*/', scopes: ['source.js', 'meta.function.js', 'comment.block.js', 'punctuation.definition.comment.js']
      expect(tokens[9]).toEqual value: ')', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.end.js']
      expect(tokens[10]).toEqual value: ' ', scopes: ['source.js']
      expect(tokens[11]).toEqual value: '{', scopes: ['source.js', 'punctuation.section.scope.begin.js']
      expect(tokens[12]).toEqual value: '}', scopes: ['source.js', 'punctuation.section.scope.end.js']

      {tokens} = grammar.tokenizeLine('foo: function (/**Bar*/bar){')
      expect(tokens[5]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[6]).toEqual value: '/**', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
      expect(tokens[7]).toEqual value: 'Bar', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js']
      expect(tokens[8]).toEqual value: '*/', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
      expect(tokens[9]).toEqual value: 'bar', scopes: ['source.js', 'meta.function.json.js', 'variable.parameter.function.js']

      {tokens} = grammar.tokenizeLine('function test(bar, // comment')
      expect(tokens[0]).toEqual value: 'function', scopes: ['source.js', 'meta.function.js', 'storage.type.function.js']
      expect(tokens[2]).toEqual value: 'test', scopes: ['source.js', 'meta.function.js', 'entity.name.function.js']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.function.js', 'punctuation.definition.parameters.begin.js']
      expect(tokens[4]).toEqual value: 'bar', scopes: ['source.js', 'meta.function.js', 'variable.parameter.function.js']
      expect(tokens[5]).toEqual value: ',', scopes: ['source.js', 'meta.function.js', 'meta.object.delimiter.js']
      expect(tokens[7]).toEqual value: '//', scopes: ['source.js', 'meta.function.js', 'comment.line.double-slash.js', 'punctuation.definition.comment.js']
      expect(tokens[8]).toEqual value: ' comment', scopes: ['source.js', 'meta.function.js', 'comment.line.double-slash.js']

  describe "console", ->
    it "tokenizes the console keyword", ->
      {tokens} = grammar.tokenizeLine('console')
      expect(tokens[0]).toEqual value: 'console', scopes: ['source.js', 'entity.name.type.object.js.console']

    it "tokenizes console support functions", ->
      {tokens} = grammar.tokenizeLine('console.log()')
      expect(tokens[0]).toEqual value: 'console', scopes: ['source.js', 'meta.method-call.js', 'entity.name.type.object.js.console']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.js', 'meta.method-call.js', 'meta.delimiter.method.period.js']
      expect(tokens[2]).toEqual value: 'log', scopes: ['source.js', 'meta.method-call.js', 'support.function.js.console']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.begin.js']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.js', 'meta.method-call.js', 'punctuation.definition.arguments.end.js']

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
