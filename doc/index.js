console.log('Loading function');

exports.handler =  (event, context) => {
    var token = event.authorizationToken;
    // Call oauth provider, crack jwt token, etc.
    // In this example, the token is treated as the status for simplicity.

    switch (token) {
        case 'allow':
            context.succeed(generatePolicy('user', 'Allow','*'));
            break;
        case 'deny':
            context.succeed(generatePolicy('user', 'Deny', event.methodArn));
            break;
        case 'unauthorized':
            context.fail("Unauthorized");   // Return a 401 Unauthorized response
            break;
        default:
            context.fail("Error: Invalid token"); 
    }
};

var generatePolicy = function(principalId, effect, resource) {
    var authResponse = {};
    
    authResponse.principalId = principalId;
    if (effect && resource) {
        var policyDocument = {};
        policyDocument.Version = '2012-10-17'; // default version
        policyDocument.Statement = [];
        var statementOne = {};
        statementOne.Action = 'execute-api:Invoke'; // default action
        statementOne.Effect = effect;
        statementOne.Resource = resource;
        policyDocument.Statement[0] = statementOne;
        authResponse.policyDocument = policyDocument;
    }
    
    // Can optionally return a context object of your choosing.
    authResponse.context = {};
    authResponse.context.stringKey = "stringval";
    authResponse.context.numberKey = 123;
    authResponse.context.booleanKey = true;
    return authResponse;
}