// based on AWS documentation from 
//   https://docs.aws.amazon.com/apigateway/latest/developerguide/use-custom-authorizer.html
// includes changes suggested in
//   https://forums.aws.amazon.com/thread.jspa?threadID=225934&tstart=0

exports.handler =  function(event, context, callback) {
    var token = event.authorizationToken;
    
    // By default, the API_TOKEN is 'aws-lambda-r-api-token' and 
    // must match the value in settings
    var API_TOKEN = 'aws-lambda-r-api-token';

    switch (token.toLowerCase()) {
        case API_TOKEN:
            callback(null, generatePolicy('user', 'Allow', '*'));
            break;
        default:
            callback("Error: Invalid token"); 
    }
};

// Help function to generate an IAM policy
var generatePolicy = function(principalId, effect, resource) {
    var authResponse = {};
    
    authResponse.principalId = principalId;
    if (effect && resource) {
        var policyDocument = {};
        policyDocument.Version = '2012-10-17'; 
        policyDocument.Statement = [];
        var statementOne = {};
        statementOne.Action = 'execute-api:Invoke'; 
        statementOne.Effect = effect;
        statementOne.Resource = resource;
        policyDocument.Statement[0] = statementOne;
        authResponse.policyDocument = policyDocument;
    }
    
    return authResponse;
}
