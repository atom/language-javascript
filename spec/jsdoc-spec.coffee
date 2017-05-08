describe "JSDoc grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-javascript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.js")

  describe "inline tags", ->
    it "tokenises tags without descriptions", ->
      {tokens} = grammar.tokenizeLine('/** Text {@link target} text */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[1]).toEqual value: ' Text ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[3]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[4]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[6]).toEqual value: 'target', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[8]).toEqual value: ' text ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[9]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises tags with an embedded trailing description", ->
      {tokens} = grammar.tokenizeLine('/** Text {@linkplain target|Description text} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[1]).toEqual value: ' Text ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[3]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[4]).toEqual value: 'linkplain', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[6]).toEqual value: 'target', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[7]).toEqual value: '|', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.separator.pipe.jsdoc']
      expect(tokens[8]).toEqual value: 'Description text', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** Text {@linkcode target Description text} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[1]).toEqual value: ' Text ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[2]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[3]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[4]).toEqual value: 'linkcode', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[6]).toEqual value: 'target', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[7]).toEqual value: ' Description text', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[10]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises tags with a preceding description", ->
      {tokens} = grammar.tokenizeLine('/** Text [Description text]{@link target} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[1]).toEqual value: ' Text ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[2]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc', 'punctuation.definition.bracket.square.begin.jsdoc']
      expect(tokens[3]).toEqual value: 'Description text', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc']
      expect(tokens[4]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc', 'punctuation.definition.bracket.square.end.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[7]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[9]).toEqual value: 'target', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[12]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** Text [Description text]{@tutorial target|Description} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[1]).toEqual value: ' Text ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[2]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc', 'punctuation.definition.bracket.square.begin.jsdoc']
      expect(tokens[3]).toEqual value: 'Description text', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc']
      expect(tokens[4]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc', 'punctuation.definition.bracket.square.end.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[7]).toEqual value: 'tutorial', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[9]).toEqual value: 'target', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[10]).toEqual value: '|', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.separator.pipe.jsdoc']
      expect(tokens[11]).toEqual value: 'Description', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[12]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[14]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises inline tags which follow block tags", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} variable - this is a {@link linked} description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' - this is a ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[12]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[13]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[15]).toEqual value: 'linked', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[16]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[17]).toEqual value: ' description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[18]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} variable - this is a {@link linked#description}. */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' - this is a ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[12]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[13]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[15]).toEqual value: 'linked#description', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[16]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[17]).toEqual value: '. ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[18]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} variable - this is a [description with a]{@link example}. */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' - this is a ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc', 'punctuation.definition.bracket.square.begin.jsdoc']
      expect(tokens[12]).toEqual value: 'description with a', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'constant.other.description.jsdoc', 'punctuation.definition.bracket.square.end.jsdoc']
      expect(tokens[14]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[15]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[16]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[18]).toEqual value: 'example', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[19]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[20]).toEqual value: '. ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[21]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises inline tags within default @param values", ->
      {tokens} = grammar.tokenizeLine('/** @param {EntityType} [typeHint={@link EntityType.FILE}] */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'EntityType', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'typeHint', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[13]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[14]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[16]).toEqual value: 'EntityType.FILE', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[17]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[18]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[20]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

  describe "block tags", ->
    it "tokenises simple tags", ->
      {tokens} = grammar.tokenizeLine('/** @mixins */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'mixins', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[5]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @global @static */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'global', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[5]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[6]).toEqual value: 'static', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[7]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[8]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @see tags with basic links", ->
      {tokens} = grammar.tokenizeLine('/** @see name#path */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'see', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[5]).toEqual value: 'name#path', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[6]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[7]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @see http://atom.io/ */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'see', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[5]).toEqual value: 'http://atom.io/', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.link.underline.jsdoc']
      expect(tokens[6]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[7]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @see tags with {@link} tags", ->
      {tokens} = grammar.tokenizeLine('/** @see {@link text|Description} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'see', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[7]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[9]).toEqual value: 'text', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[10]).toEqual value: '|', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.separator.pipe.jsdoc']
      expect(tokens[11]).toEqual value: 'Description', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[12]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[14]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @see [Description]{@link name#path} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'see', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '[Description]', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[6]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[7]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc', 'punctuation.definition.inline.tag.jsdoc']
      expect(tokens[8]).toEqual value: 'link', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'storage.type.class.jsdoc']
      expect(tokens[10]).toEqual value: 'name#path', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'variable.other.description.jsdoc']
      expect(tokens[11]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[13]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises tags with type expressions", ->
      {tokens} = grammar.tokenizeLine('/** @const {object} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'const', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[4]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[8]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[9]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @define {object} */')
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'define', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

    it "tokenises unnamed @param tags", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[1]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[8]).toEqual value: ' ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[9]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @param tags", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} variable */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @param tags with a description", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @arg {object} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'arg', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @argument {object} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'argument', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} variable - this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' - this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} $variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '$variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @param tags marked optional", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} [variable] this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[12]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[13]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [ variable ] this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[12]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with unquoted default values", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} [variable=default value] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: 'default value', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [variable = default value] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' default value', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [ variable = default value ] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' default value ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [variable=default.value] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: 'default.value', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with quoted default values", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} [variable="default value"] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '"default value"', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [variable = "default value"] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' "default value"', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [ variable = " default value " ] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' " default value " ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine("/** @param {object} [variable='default value'] this is the description */")
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '\'default value\'', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine("/** @param {object} [variable = 'default value'] this is the description */")
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' \'default value\'', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine("/** @param {object} [ variable = ' default value ' ] this is the description */")
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' \' default value \' ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with objects as default values", ->
      {tokens} = grammar.tokenizeLine('/** @param {Object} [variable={a: "b"}] - An object */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '{a: "b"}', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - An object ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object} [ variable =  {  a : "b"  } ] - An object */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' variable ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '  {  a : "b"  } ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - An object ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object} [variable={}] - Empty object */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '{}', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - Empty object ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object} [  variable  =  {  }  ] - Empty object */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: '  variable  ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '  {  }  ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - Empty object ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with arrays as default values", ->
      {tokens} = grammar.tokenizeLine('/** @param {Array} [variable=[1,2,3]] - An array */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '[1,2,3]', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - An array ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Array} [  variable   = [ 1 , 2 , 3  ] ] - An array */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: '  variable   ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' [ 1 , 2 , 3  ] ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - An array ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Array} [variable=[]] - Empty array */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '[]', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - Empty array ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Array} [  variable  =  [  ]  ] - Empty array */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: '  variable  ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '  [  ]  ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' - Empty array ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with accessor-style names", ->
      {tokens} = grammar.tokenizeLine('/** @param {object} parameter.property this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'parameter.property', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [parameter.property] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'parameter.property', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[12]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [ parameter.property ] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' parameter.property ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[12]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [parameter.property=default value] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'parameter.property', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: 'default value', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [parameter.property = default value] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'parameter.property ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' default value', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {object} [ parameter.property = default value ] this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' parameter.property ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: ' default value ', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[14]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with wildcard types", ->
      {tokens} = grammar.tokenizeLine('/** @param {*} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '*', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      {tokens} = grammar.tokenizeLine('/** @param {?} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '?', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags with qualified types", ->
      {tokens} = grammar.tokenizeLine('/** @param {myNamespace.MyClass} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'myNamespace.MyClass', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {Foo~cb} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Foo~cb', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @param tags with multiple types", ->
      {tokens} = grammar.tokenizeLine('/** @param {function|string} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function|string', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {string[]|number} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'string', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '|number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[12]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {string|number[]} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'string|number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[11]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {(number|function)} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(number|function)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {(string[]|number)} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(string', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '|number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[12]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[14]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {(string|number[])} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(string|number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: ')', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[12]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

    it "tokenises @param tags marked nullable or non-nullable", ->
      {tokens} = grammar.tokenizeLine('/** @param {?number} variable this is the description */')
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '?number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {!number} variable this is the description */')
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '!number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

    it "tokenises @param tags marked as variable-length", ->
      {tokens} = grammar.tokenizeLine('/** @param {...number} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '...number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {...*} remainder */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '...*', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'remainder', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {...?} remainder */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '...?', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'remainder', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @param tags using Google Closure Compiler syntax", ->
      {tokens} = grammar.tokenizeLine('/** @param {number=} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'number=', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {number[]} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[11]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {Foo[].bar} variable this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Foo', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '.bar', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[12]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[14]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @param {Array<number>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array<number>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {Array.<number>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array.<number>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Array<number>|Array<string>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array<number>|Array<string>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Array.<number>|Array.<string>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Array.<number>|Array.<string>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {(Array<number>|Array<string>)} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(Array<number>|Array<string>)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {(Array.<number>|Array.<string>)} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(Array.<number>|Array.<string>)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object<string, number>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object<string, number>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object.<string, number>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object.<string, number>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object<string, number>|Array<number>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object<string, number>|Array<number>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {Object.<string, number>|Array.<number>} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Object.<string, number>|Array.<number>', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: ' this is the description ', scopes: ['source.js', 'comment.block.documentation.js']

      {tokens} = grammar.tokenizeLine('/** @param {(Array<number>|Object<string, number>)} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(Array<number>|Object<string, number>)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {(Array.<number>|Object.<string, number>)} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(Array.<number>|Object.<string, number>)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function()} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function()', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function ()} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function ()', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function ( )} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function ( )', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string)} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string, number)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string, number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(...string)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(...string)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string, ...number)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string, ...number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string, number, ...number)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string, number, ...number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(!string)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(!string)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(?string, !number)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(?string, !number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string[], number=)} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: ', number=)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[12]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function():number} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function():number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string): number} variable this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string): number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @param {function(string) : number} variable this is the description */')
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string) : number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'variable', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']

    it "tokenises @return tags without descriptions", ->
      {tokens} = grammar.tokenizeLine('/** @return {object} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @returns {object} */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'returns', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises @return tags with trailing descriptions", ->
      {tokens} = grammar.tokenizeLine('/** @returns {object} this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'returns', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'this', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[10]).toEqual value: ' is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @return {object} this is the description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'object', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: 'this', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[10]).toEqual value: ' is the description ', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[11]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

      {tokens} = grammar.tokenizeLine('/** @returns {(Something)} */')
      expect(tokens[3]).toEqual value: 'returns', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(Something)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

    it "tokenises @return tags with multiple types", ->
      {tokens} = grammar.tokenizeLine('/** @return {Some|Thing} Something to return */')
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'Some|Thing', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {(String[]|Number[])} Description */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '(String', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: '|Number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[11]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[12]).toEqual value: ')', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[13]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[15]).toEqual value: 'Description', scopes: ['source.js', 'comment.block.documentation.js']
      expect(tokens[17]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']

    it "tokenises function-type @return tags", ->
      {tokens} = grammar.tokenizeLine('/** @return {function()} this is the description */')
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function()', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function ()} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function ()', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function ( )} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function ( )', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string, number)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string, number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(...string)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(...string)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string, ...number)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string, ...number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string, number, ...number)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string, number, ...number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(!string)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(!string)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(?string, !number)} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(?string, !number)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string[], number=)} this is the description */')
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[8]).toEqual value: ']', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[9]).toEqual value: ', number=)', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[10]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function():number} this is the description */')
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function():number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string): number} this is the description */')
      expect(tokens[3]).toEqual value: 'return', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string): number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

      {tokens} = grammar.tokenizeLine('/** @return {function(string) : number} this is the description */')
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'function(string) : number', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']

  describe "when the containing comment ends unexpectedly", ->
    it "terminates any unclosed tags", ->
      {tokens} = grammar.tokenizeLine('/** @param {String */ aa')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'String ', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']
      expect(tokens[8]).toEqual value: ' aa', scopes: ['source.js']

      {tokens} = grammar.tokenizeLine('/** @param {*} [name={value: {a:[{*/}}]}] */')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: '*', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '}', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.end.jsdoc']
      expect(tokens[9]).toEqual value: '[', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[10]).toEqual value: 'name', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[11]).toEqual value: '=', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc', 'keyword.operator.assignment.jsdoc']
      expect(tokens[12]).toEqual value: '{value: {a:[{', scopes: ['source.js', 'comment.block.documentation.js', 'variable.other.jsdoc']
      expect(tokens[13]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']
      expect(tokens[14]).toEqual value: '}}', scopes: ['source.js']
      expect(tokens[15]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[16]).toEqual value: '}', scopes: ['source.js']
      expect(tokens[17]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[19]).toEqual value: '*', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[20]).toEqual value: '/', scopes: ['source.js', 'keyword.operator.js']

      {tokens} = grammar.tokenizeLine('/** @param {string="Foo*/oo"} bar')
      expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.begin.comment.js']
      expect(tokens[2]).toEqual value: '@', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc', 'punctuation.definition.block.tag.jsdoc']
      expect(tokens[3]).toEqual value: 'param', scopes: ['source.js', 'comment.block.documentation.js', 'storage.type.class.jsdoc']
      expect(tokens[5]).toEqual value: '{', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc', 'punctuation.definition.bracket.curly.begin.jsdoc']
      expect(tokens[6]).toEqual value: 'string="Foo', scopes: ['source.js', 'comment.block.documentation.js', 'entity.name.type.instance.jsdoc']
      expect(tokens[7]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.section.end.comment.js']
      expect(tokens[8]).toEqual value: 'oo', scopes: ['source.js']
      expect(tokens[9]).toEqual value: '"', scopes: ['source.js', 'string.quoted.double.js', 'punctuation.definition.string.begin.js']
      expect(tokens[10]).toEqual value: '} bar', scopes: ['source.js', 'string.quoted.double.js', 'invalid.illegal.string.js']
