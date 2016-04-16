{eq} = require './spec-helper'

describe "Regular Expression Replacement grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-javascript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.js.regexp.replacement")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.js.regexp.replacement"

  describe "basic strings", ->
    it "tokenizes with no extra scopes", ->
      {tokens} = grammar.tokenizeLine('Hello [world]. (hi to you)')
      eq tokens[0], 'Hello [world]. (hi to you)', scope: 'source.js.regexp.replacement'

  describe "escaped characters", ->
    it "tokenizes with as an escape character", ->
      {tokens} = grammar.tokenizeLine('\\n')
      eq tokens[0], '\\n', scope: 'constant.character.escape.backslash.regexp.replacement'

    it "tokenizes '$$' as an escaped '$' character", ->
      {tokens} = grammar.tokenizeLine('$$')
      eq tokens[0], '$$', scope: 'constant.character.escape.dollar.regexp.replacement'

    it "doesn't treat '\\$' as an escaped '$' character", ->
      {tokens} = grammar.tokenizeLine('\\$')
      eq tokens[0], '\\$', scope: 'source.js.regexp.replacement'

    it "tokenizes '$$1' as an escaped '$' character followed by a '1' character", ->
      {tokens} = grammar.tokenizeLine('$$1')
      eq tokens[0], '$$', scope: 'constant.character.escape.dollar.regexp.replacement'
      eq tokens[1], '1', scope: 'source.js.regexp.replacement'

  describe "Numeric placeholders", ->
    it "doesn't tokenize $0 as a variable", ->
      {tokens} = grammar.tokenizeLine('$0')
      eq tokens[0], '$0', scope: 'source.js.regexp.replacement'

    it "doesn't tokenize $00 as a variable", ->
      {tokens} = grammar.tokenizeLine('$00')
      eq tokens[0], '$00', scope: 'source.js.regexp.replacement'

    it "tokenizes $1 as a variable", ->
      {tokens} = grammar.tokenizeLine('$1')
      eq tokens[0], '$1', scope: 'variable.regexp.replacement'

    it "tokenizes $01 as a variable", ->
      {tokens} = grammar.tokenizeLine('$01')
      eq tokens[0], '$01', scope: 'variable.regexp.replacement'

    it "tokenizes $3 as a variable", ->
      {tokens} = grammar.tokenizeLine('$3')
      eq tokens[0], '$3', scope: 'variable.regexp.replacement'

    it "tokenizes $10 as a variable", ->
      {tokens} = grammar.tokenizeLine('$10')
      eq tokens[0], '$10', scope: 'variable.regexp.replacement'

    it "tokenizes $99 as a variable", ->
      {tokens} = grammar.tokenizeLine('$99')
      eq tokens[0], '$99', scope: 'variable.regexp.replacement'

    it "doesn't tokenize the third numberic character in '$100' as a variable", ->
      {tokens} = grammar.tokenizeLine('$100')
      eq tokens[0], '$10', scope: 'variable.regexp.replacement'
      eq tokens[1], '0', scope: 'source.js.regexp.replacement'

    describe "Matched sub-string placeholder", ->
      it "tokenizes $& as a variable", ->
        {tokens} = grammar.tokenizeLine('$&')
        eq tokens[0], '$&', scope: 'variable.regexp.replacement'

    describe "Preceeding portion placeholder", ->
      it "tokenizes $` as a variable", ->
        {tokens} = grammar.tokenizeLine('$`')
        eq tokens[0], '$`', scope: 'variable.regexp.replacement'

    describe "Following portion placeholder", ->
      it "tokenizes $' as a variable", ->
        {tokens} = grammar.tokenizeLine('$\'')
        eq tokens[0], '$\'', scope: 'variable.regexp.replacement'
