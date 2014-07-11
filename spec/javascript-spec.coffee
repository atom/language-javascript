describe "Javascript grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-javascript")

    runs ->
      grammar = atom.syntax.grammarForScopeName("source.js")

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

  describe "regular expressions", ->
    it "tokenizes regular expressions", ->
      {tokens} = grammar.tokenizeLine('/test/')
      expect(tokens[0]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[2]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']

    it "tokenizes regular expressions inside arrays", ->
      {tokens} = grammar.tokenizeLine('[/test/]')
      expect(tokens[0]).toEqual value: '[', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[1]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[2]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[3]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[4]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']
      
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
