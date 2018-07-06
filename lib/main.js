exports.activate = function() {
  atom.grammars.addInjectionPoint('javascript', {
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

  atom.grammars.addInjectionPoint('javascript', {
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
}
