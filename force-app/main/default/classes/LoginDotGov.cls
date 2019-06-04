global class LoginDotGov extends Auth.AuthProviderPluginClass {
/******************************************************************************************
*  Description: Authentication Provider Custom Plugin built to support Login.gov as
*               a Saleforce Authentication Provider
* Modification Log:
* -----------------------------------------------------------------------------------------
* Mod ID      |   Date       | Mod Author       | Brief Mod Description 
* -----------------------------------------------------------------------------------------
* 0001        |  3/1/2019    | Cary Archiere   | Initial code creation.
*                         
* -----------------------------------------------------------------------------------------
*******************************************************************************************/
  
    // Use this URL for the endpoint that the authentication provider calls back to for configuration.
    public String redirectUrl; 
    
    private String clientId;
    private String acrValue;
    private String nonce;
    private String prompt;  
    private String responseType;
    private String scope; 
    private String state;
    
    // Application redirection to the Login.gov website for authentication and authorization.
    private String authUrl;  
  
    // URI to get the new access token from Login.gov using the GET verb.
    private String accessTokenUrl; 
  
    // Api name for the custom metadata type created for this auth provider.
    private String customMetadataTypeApiName = 'LoginDotGov__mdt'; 
  
    // Api URL to access the user in Login.gov
    private String userAPIUrl; 
  
    // Version of the user api URL to access data from Login.gov
    private String userAPIVersionUrl; 
  
    // variables used for json web token (jwt)
    private Integer exp;
    private String certName;
    private boolean debugOn = true;
    
    //Returns the custom metadata type API name used to hold the Auth Provider settings
    global String getCustomMetadataType() {
      return customMetadataTypeApiName;
    } 
    
    // *************************************************************************
    // Returns the URL where the user is redirected for authentication
    // *************************************************************************
    global PageReference initiate(Map<string,string> 
    authProviderConfiguration, String stateToPropagate) 
    { 
        debugOn=Boolean.valueOf(authProviderConfiguration.get('debug__c')); 
        if (debugOn) {LogEntry('Start: ', 'initiate');}
        
        authUrl = authProviderConfiguration.get('Authorization_Endpoint__c'); 
        acrValue = EncodingUtil.urlEncode(authProviderConfiguration.get('acr_values__c'),'UTF-8');
        clientId = authProviderConfiguration.get('client_id__c'); 
        prompt = authProviderConfiguration.get('prompt__c'); 
        responseType = authProviderConfiguration.get('response_type__c'); 
        redirectUrl = EncodingUtil.urlEncode(authProviderConfiguration.get('redirect_uri__c'),'UTF-8'); 
        if(Test.isRunningTest()){redirectUrl = authProviderConfiguration.get('redirect_uri__c');}
        scope = authProviderConfiguration.get('scope__c'); 
        nonce = generateRandom(32);
        if(Test.isRunningTest()){nonce='testNonce';}
        
        // Build up the authentication request.  This will return a URL to redirect the user 
        
        String url = authUrl + '?'
            + '&acr_values=' + acrValue
            + '&client_id='+ clientId 
            + '&nonce=' + nonce
            + '&prompt=' + prompt
            + '&redirect_uri='+ redirectUrl 
            + '&response_type=' + responseType
            + '&scope=' + scope 
            + '&state=' + stateToPropagate; 
        
        if (debugOn) {LogEntry('AuthURL: ', url);}
        
        return new PageReference(url); 
    } 
    
    // *************************************************************************
    // This is where the callback from Login.gov will be recieved. 
    // 1. Create a signed JWT according to the Login.gov instructions
    // 2. Using the code provided from Login.gov, send a request to the token endpoint
    // 3. Return a Auth.AuthProviderTokenResponse with the token
    // *************************************************************************
    global Auth.AuthProviderTokenResponse handleCallback(Map<string,string> 
    authProviderConfiguration, Auth.AuthProviderCallbackState state ) 
    { 
        debugOn=Boolean.valueOf(authProviderConfiguration.get('debug__c')); 
        if (debugOn) {LogEntry('Start: ' ,'handleCallback');}
        
        clientId = authProviderConfiguration.get('client_id__c'); 
        certName = authProviderConfiguration.get('certificate_name__c');
        accessTokenUrl = authProviderConfiguration.get('Access_Token_Url__c'); 
    
        // Login.gov prepare JWT according to Token section of this doc: https://developers.login.gov/oidc/
        Auth.JWT jwt = new Auth.JWT();
        jwt.setIss(clientId);
        jwt.setSub(clientId); 
        jwt.setAud(accessTokenUrl); 
        Long exp = DateTime.now().getTime() + 30000; // now + 5 minutes
        Map<String, Object> claims = new Map<String, Object>();
        claims.put('exp',exp);
        jwt.setAdditionalClaims(claims);
        logEntry('authJWTasserionString', jwt.toJSONString());

        //Create the object that signs the JWT bearer token
        String signedJWT;
        if(Test.isRunningTest()){
            signedJWT = '{"test":"test"}';
        } else {
            Auth.JWS jws = new Auth.JWS(jwt, certName);
            signedJWT = jws.getCompactSerialization();
        }
        if (debugOn) {logEntry('authJWTasserionSigned', signedJWT);}

        
        // Get the code from the token from the response from the authorization
        Map<String,String> queryParams = state.queryParameters; 
        String code = queryParams.get('code'); 
        String sfdcState = queryParams.get('state'); 
        if (debugOn) {logEntry('AuthRespCode', code);}
        
        // build an http request to post to the token url
        String url = accessTokenUrl;
        String body = 'client_assertion=' + signedJWT
            +'&client_assertion_type='+ EncodingUtil.URLEncode('urn:ietf:params:oauth:client-assertion-type:jwt-bearer','UTF-8')
            +'&code=' + code
            +'&grant_type=authorization_code';
        
        //Http http = new Http(); 
        HttpRequest req = new HttpRequest();    
        req.setEndpoint(url); 
        if (debugOn) {logEntry('tokenRequestURL', url);}
        if (debugOn) {logEntry('tokenRequestBody', body);}

        req.setHeader('Accept','application/json');
        req.setbody(body);
        req.setMethod('POST'); 
    
        Http http = new Http();
        HTTPResponse res = http.send(req); 
        String responseBody = res.getBody(); 
        if (debugOn) {logEntry('tokenResponseBody', responseBody);}
       
        Map<String,Object>responseJson = jsonMap(responseBody);
        
        if (responseJson.containsKey('error')) {
            string e = responseJson.get('error').toString();
            throw new Auth.AuthProviderPluginException(e);
        }
        
        String token = responseJson.get('access_token').toString();
        if (debugOn) {logEntry('access_token', token);}
        
        return new Auth.AuthProviderTokenResponse('LoginDotGov', token, 
        'refreshToken', sfdcState); 
    } 

    // *************************************************************************
    // Constuct an Auth.UserData.  Get user information from user endpoint
    // *************************************************************************    
    global Auth.UserData getUserInfo(Map<string,string> 
    authProviderConfiguration, 
    Auth.AuthProviderTokenResponse response) 
    { 
        debugOn=Boolean.valueOf(authProviderConfiguration.get('debug__c')); 
        if (debugOn) {LogEntry('Start: ', 'getUserInfo');}

        String token = response.oauthToken;
        if (debugOn) {LogEntry('Token: ', token);}

        HttpRequest req = new HttpRequest(); 
        userAPIUrl = authProviderConfiguration.get('API_User_Url__c');
        req.setHeader('Authorization', 'Bearer ' + token); 
        req.setEndpoint(userAPIUrl); 
        req.setHeader('Content-Type','application/json'); 
        req.setMethod('GET'); 
    
        Http http = new Http(); 
        HTTPResponse res = http.send(req); 
        String responseBody = res.getBody(); 

        LogEntry('userBody',responseBody);
        
        Map<String,Object>userInfo = jsonMap(responseBody);
        
        // put together the object to pass to the registration handler
        String id = userInfo.get('sub').toString(); 
        String fname = 'first name'; 
        String lname = 'last name'; 
        String flname = fname + ' ' + lname; 
        String email = userInfo.get('email').toString(); 
        String locale = 'locale'; 
        Map<String,String> provMap = new Map<String,String>(); 
        provMap.put('what1', 'noidea1'); 
        provMap.put('what2', 'noidea2'); 
        
        return new Auth.UserData(id, fname, lname, flname, 
        email, 'what', locale, null, 'LoginDotGov', null, provMap); 
        
    } 

    // *************************************************************************
    // Utility Functions 
    // *************************************************************************    
       
    // generate a random string for the nonce value.
    private static String generateRandom(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;  
    }
    
    //write the value to the debug log in 400 char blocks.
    private void LogEntry(String LogLabel, String LogOutput) {
        
        integer z;
        while (LogOutput.length() >400) {
            system.debug(LogLabel + ':' + LogOutput.substring(0,400));
            z = LogOutput.length() - 400;
            LogOutput = LogOutput.right(z);
        }
        system.debug(LogLabel + ':' + LogOutput);
    }
    
    // deserialize JSON
    private Map<String, Object>  jsonMap(String jsonString) {
        return  (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    }
}