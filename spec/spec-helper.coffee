module.exports =
  eq: (token, value, {scopes, scope}) ->
    if scope?
      scopesArr = []
      for key, scope of token.scopes
        scopesArr[key] = token.scopes[key]
      scopesArr[scopesArr.length - 1] = scope

      expect(token).toEqual value: value, scopes: scopesArr
    else if scopes?
      scopesArr = scopes.split(' ')

      if scopesArr.length != token.scopes.length and scopesArr[0] == '_'
          scopesArr[0] = token.scopes[0]
      else
        for key, scope of scopesArr
          scopesArr[key] = token.scopes[key] if scope == '_'

      expect(token).toEqual value: value, scopes: scopesArr
    else
      expect(token).toEqual value: value
