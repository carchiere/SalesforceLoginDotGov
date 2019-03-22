@IsTest
public class LoginDotGovTestClass {
/******************************************************************************************
*  Description: Test Class for Authentication Provider Custom Plugin built to support Login.gov as
*               a Saleforce Authentication Provider
* Modification Log:
* -----------------------------------------------------------------------------------------
* Mod ID      |   Date       | Mod Author       | Brief Mod Description 
* -----------------------------------------------------------------------------------------
* 0001        |  3/21/2019    | Cary Archiere   | Initial code creation.
*                         
* -----------------------------------------------------------------------------------------
*******************************************************************************************/

	private static final String CLIENT_ID = 'testClientId';
	private static final String OAUTH_TOKEN = 'testToken';
	private static final String STATE = 'mocktestState';
	private static final String AUTH_URL = 'http://www.dummy.com/authurl';
	private static final String ACR_VALUES = 'testAcrValue';
	private static final String PROMPT = 'testPrompt';
	private static final String RESPONSE_TYPE = 'testResponseType';    
	private static final String REDIRECT_URI = 'http://www.dummyhost.com/services/authcallback/orgId/Login';   
	private static final String SCOPE = 'testScope';    
	private static final String STATE_TO_PROPOGATE  = 'testState';    
	private static final String ACCESS_TOKEN_URL = 'http://www.dummyhost.com/accessTokenUri'; 
	private static final String REFRESH_TOKEN = 'refreshToken';    
       private static final String PROVIDER = 'LoginDotGov';
       private static final String LOGIN_ID = 'sub';
       private static final String USERNAME = 'testUsername';
       private static final String FIRST_NAME = 'first name';
       private static final String LAST_NAME = 'last name';
       private static final String EMAIL_ADDRESS = 'email@gsa.gov';
       private static final String LOCALE_NAME = 'locale';
       private static final String FULL_NAME = FIRST_NAME + ' ' + LAST_NAME;
       private static final String API_USER_URL = 'www.dummyhost.com/user/api';
       private static final String KEY = 'testKey';

    // mimic the custom metadata type record
       private static Map<String,String> setupAuthProviderConfig () {
           Map<String,String> authProviderConfiguration = new Map<String,String>();

              authProviderConfiguration.put('client_id__c', CLIENT_ID);
              authProviderConfiguration.put('debug__c', 'true');
              authProviderConfiguration.put('Authorization_Endpoint__c', AUTH_URL);
              authProviderConfiguration.put('acr_values__c', ACR_VALUES);  
              authProviderConfiguration.put('client_id__c', CLIENT_ID); 
              authProviderConfiguration.put('prompt__c', PROMPT);        
              authProviderConfiguration.put('response_type__c', RESPONSE_TYPE);        
              authProviderConfiguration.put('redirect_uri__c',REDIRECT_URI);        
              authProviderConfiguration.put('scope__c', SCOPE);        
		authProviderConfiguration.put('certificate_name__c','testCert');
              authProviderConfiguration.put('Access_Token_Url__c', ACCESS_TOKEN_URL);        
              authProviderConfiguration.put('API_User_Url__c',API_USER_URL);        
        
              return authProviderConfiguration;
          
       }

    // test initiate
    static testMethod void testInitiateMethod() {
       
           Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
           LoginDotGov LoginDotGovCls = new LoginDotGov();
           LoginDotGovCls.redirectUrl = authProviderConfiguration.get('redirect_uri__c');
           
        	String url = authProviderConfiguration.get('Authorization_Endpoint__c') 
            + '&acr_values=' + authProviderConfiguration.get('acr_values__c')
            + '&client_id='+ authProviderConfiguration.get('client_id__c') 
            + '&nonce=' + 'testNonce'
            + '&prompt=' + authProviderConfiguration.get('prompt__c')
            + '&redirect_uri='+ authProviderConfiguration.get('redirect_uri__c') 
            + '&response_type=' + authProviderConfiguration.get('response_type__c')
            + '&scope=' + authProviderConfiguration.get('scope__c') 
            + '&state=' + STATE_TO_PROPOGATE; 
           PageReference expectedUrl =  new PageReference(url);
           PageReference actualUrl = LoginDotGovCls.initiate(authProviderConfiguration, STATE_TO_PROPOGATE);
           System.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl());
       }
   
    // test handleCallBack
    static testMethod void testHandleCallback() {
           Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
           LoginDotGov LoginDotGovCls = new LoginDotGov();
           LoginDotGovCls.redirectUrl = authProviderConfiguration.get('redirect_uri__c');

           Test.setMock(HttpCalloutMock.class, new LoginTokenMockHttpResponseGenerator());

           Map<String,String> queryParams = new Map<String,String>();
           queryParams.put('code','code');
           queryParams.put('state',authProviderConfiguration.get('State_c'));
           Auth.AuthProviderCallbackState cbState = new Auth.AuthProviderCallbackState(null,null,queryParams);
           Auth.AuthProviderTokenResponse actualAuthProvResponse = LoginDotGovCls.handleCallback(authProviderConfiguration, cbState);
           Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse('LoginDotGov', OAUTH_TOKEN, REFRESH_TOKEN, null);
           
           System.assertEquals(expectedAuthProvResponse.provider, actualAuthProvResponse.provider);
           System.assertEquals(expectedAuthProvResponse.oauthToken, actualAuthProvResponse.oauthToken);
           System.assertEquals(expectedAuthProvResponse.oauthSecretOrRefreshToken, actualAuthProvResponse.oauthSecretOrRefreshToken);
           System.assertEquals(expectedAuthProvResponse.state, actualAuthProvResponse.state);
           

    }
      
    // test getUserInfo
    static testMethod void testGetUserInfo() {
           Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
           LoginDotGov LoginDotGovCls = new LoginDotGov();
           LoginDotGovCls.redirectUrl = authProviderConfiguration.get('redirect_uri__c');
                      
           Test.setMock(HttpCalloutMock.class, new LoginUserMockHttpResponseGenerator());

           Auth.AuthProviderTokenResponse response = new Auth.AuthProviderTokenResponse(PROVIDER, OAUTH_TOKEN ,'sampleOauthSecret', STATE);
           Auth.UserData actualUserData = LoginDotGovCls.getUserInfo(authProviderConfiguration, response) ;
           
           Map<String,String> provMap = new Map<String,String>();
           provMap.put('key1', 'value1');
           provMap.put('key2', 'value2');
                     
           Auth.UserData expectedUserData = new Auth.UserData(LOGIN_ID, FIRST_NAME, LAST_NAME, FULL_NAME, EMAIL_ADDRESS,
                          null, LOCALE_NAME, null, PROVIDER, null, provMap);
          
           System.assertNotEquals(expectedUserData,null);
           System.assertEquals(expectedUserData.firstName, actualUserData.firstName);
           System.assertEquals(expectedUserData.lastName, actualUserData.lastName);
           System.assertEquals(expectedUserData.fullName, actualUserData.fullName);
           System.assertEquals(expectedUserData.email, actualUserData.email);
           System.assertEquals(expectedUserData.username, actualUserData.username);
           System.assertEquals(expectedUserData.locale, actualUserData.locale);
           System.assertEquals(expectedUserData.provider, actualUserData.provider);
           System.assertEquals(expectedUserData.siteLoginUrl, actualUserData.siteLoginUrl);
    }
    
   
   // implementing a mock http response generator 
	// response for token call
    public  class LoginTokenMockHttpResponseGenerator implements HttpCalloutMock {
    	public HTTPResponse respond(HTTPRequest req) {     
        	// Create a fake response
        	HttpResponse res = new HttpResponse();
        	res.setHeader('Content-Type', 'application/json');
        	res.setBody('{"access_token":"testToken"}');
        	res.setStatusCode(200);
        	return res;
    	}
   
  }
    
    // response for user info call
	public  class LoginUserMockHttpResponseGenerator implements HttpCalloutMock {
    	public HTTPResponse respond(HTTPRequest req) {
       
        	// Create a fake response
        	HttpResponse res = new HttpResponse();
        	res.setHeader('Content-Type', 'application/json');
        	res.setBody('{"sub":"sub","iss":"issue","email":"email@gsa.gov","email_verified":true}');
        	res.setStatusCode(200);
        	return res;
    	}
   
  }

}