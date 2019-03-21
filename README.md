# SFDX  App
Salesforce Custom Auth Provider Plugin for Login.Gov
## Dev, Build and Test


## Resources
Class: LoginDotGov.cls
Class: LoginDotGovTestClass.cls
MDT: LoginDotGov_mdt

## Description of Files and Directories
Auth Provider Plugin designed to allow Login.gov as an IDP for Salesforce. Once Deployed do the following:
1. Create or upload a certificate in Salesforce.  Setup->Security->Certificatate and Key Management
2. Setup an app with Login.gov.  Use the certificate created in step 1.
3. Create a remote site setting for Login.gov's endpoint
4. Create a new Auth Provider - you should see LoginDotGov as a choice.
5. Create a new Registration Handler according to your needs.  Use this class as the Registration Handler for the Auth Provider setup.  (You can choose to have one auto created in the Auth Provider Setup)  
6. For native MyDomain Salesforce login, check the new Auth Provider as an option under the My Domain Authentication Configruation.  For other uses, such as a community, use the URL's provided in the Auth Provdier configuation.  

## Issues


