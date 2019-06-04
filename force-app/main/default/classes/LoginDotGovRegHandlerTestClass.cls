@isTest
public class LoginDotGovRegHandlerTestClass {
    /******************************************************************************************
*  Description: Test Class for Authentication Provider Custom Plugin RegHandler built to support Login.gov as
*               a Saleforce Authentication Provider.  This is a sample and would need to change w/ changes
*               to the RegHandler
* Modification Log:
* -----------------------------------------------------------------------------------------
* Mod ID      |   Date       | Mod Author       | Brief Mod Description 
* -----------------------------------------------------------------------------------------
* 0001        |  6/4/2019    | Cary Archiere   | Initial code creation.
*                         
* -----------------------------------------------------------------------------------------
*******************************************************************************************/
    static testMethod void testCreateUser() {
        // create a test user
        String alias = 'testuser@LoginDotGov.org';
        User u = new User();
        Profile p = [SELECT Id FROM profile WHERE name='Standard User'];
        u.username = alias;
        u.email = 'testuser@example.org';
        u.lastName = 'testLast';
        u.firstName = 'testFirst';
        alias = alias.substring(0, 8);
        u.alias = alias;
        u.languagelocalekey = 'en_US';
        u.localesidkey = 'en_US';
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'America/Los_Angeles';
        u.profileId = p.Id;
        insert (u);

        LoginDotGovRegHandler regHandler = new LoginDotGovRegHandler();
        Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
        'testFirst testLast', 'testuser@example.org', null, 'testuserlong', 'en_US', 'facebook',
        null, new Map<String, String>{'language' => 'en_US'});
        User authUser = regHandler.createUser(null, sampleData);
        System.assertEquals('testuser@LoginDotGov.org', u.userName);
        System.assertEquals('testuser@example.org', u.email);
        System.assertEquals('testLast', u.lastName);
        System.assertEquals('testFirst', u.firstName);
        System.assertEquals('testuser', u.alias);
    }
}
