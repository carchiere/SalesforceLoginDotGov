global class LoginDotGovRegHandler implements Auth.RegistrationHandler {
/******************************************************************************************
*  Description: Registration Handler for Authentication Provider Custom Plugin built to support Login.gov as
*               a Saleforce Authentication Provider
* Modification Log:
* -----------------------------------------------------------------------------------------
* Mod ID      |   Date       | Mod Author       | Brief Mod Description 
* -----------------------------------------------------------------------------------------
* 0001        |  6/3/2019    | Cary Archiere   | Initial code creation.
*                         
* -----------------------------------------------------------------------------------------
*******************************************************************************************/
/***************************************
This is a sample of a Registration Handler class.  Modify to specific needs.ApexPages. 
*****************************************/

    class LoginDogGovRegHandlerException extends Exception{}

    global User createUser(Id portalId, Auth.UserData data){
    // Query for the user by email address and return user object
        try {
            User u = [Select Id from User where email = :data.email];
            return u;
        }
        catch(Exception e) {
            throw new LoginDotGovRegHandler.LoginDogGovRegHandlerException('User was not found');
        }

    }

/* These method are part of the interface but are not used */
    global boolean canCreateUser(Auth.UserData data) {
        //TODO: Check whether we want to allow creation of a user with this data
        //Set<String> s = new Set<String>{'usernamea', 'usernameb', 'usernamec'};
        //if(s.contains(data.username)) {
        //return true;
        //}
        return false;
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        User u = new User(id=userId);
        //TODO: Customize the username. Must be 80 characters or less.
        //u.username = data.username + '@myorg.com';
        u.email = data.email;
        u.lastName = data.lastName;
        u.firstName = data.firstName;
        //String alias = data.username;
        //Alias must be 8 characters or less
        //if(alias.length() > 8) {
        //alias = alias.substring(0, 8);
        //}
         //u.alias = alias;
        update(u);
    }


}