exports.activate = function() {
  if (!atom.grammars.addInjectionPoint) return

  atom.grammars.addInjectionPoint('source.js', {
    type: 'call_expression',

    language (callExpression) {
      const {firstChild} = callExpression
      if (firstChild.type === 'identifier') {
        return firstChild.text
      }
    },

    content (callExpression) {
      const {lastChild} = callExpression
      if (lastChild.type === 'template_string') {
        return lastChild
      }
    }
  })

  atom.grammars.addInjectionPoint('source.js', {
    type: 'assignment_expression',

    language (callExpression) {
      const {firstChild} = callExpression
      if (firstChild.type === 'member_expression') {
        if (firstChild.lastChild.text === 'innerHTML') {
          return 'html'
        }
      }
    },

    content (callExpression) {
      const {lastChild} = callExpression
      if (lastChild.type === 'template_string') {
        return lastChild
      }
    }
  })

  atom.grammars.addInjectionPoint('source.js', {
    type: 'regex_pattern',
    language (regex) { return 'regex' },
    content (regex) { return regex }
  })
}
