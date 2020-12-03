-- Turn on EKM providers in SQL
-- Enable advanced options.  
USE master;  
GO  

EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  

-- Enable EKM provider  
EXEC sp_configure 'EKM provider enabled', 1;  
GO  
RECONFIGURE;  

-- This is the install from 
-- https://download.microsoft.com/download/8/0/9/809494F2-BAC9-4388-AD07-7EAF9745D77B/1033_15.0.2000.367/SQLServerConnectorforMicrosoftAzureKeyVault.msi
-- Path Cannot be more than 256 characters
CREATE CRYPTOGRAPHIC PROVIDER AzureKeyVault_EKM
FROM FILE = 'C:\Program Files\SQL Server Connector for Microsoft Azure Key Vault\Microsoft.AzureKeyVaultService.EKM.dll';  
GO  

-- Create Key in Registry
-- SQL Server Cryptographic Provider and give sql server serivce
--		full control on the key.


-- Create credential that will be used to open the key vault
-- and will be added to the login created.
USE master;  
CREATE CREDENTIAL sysadmin_ekm_cred
    WITH IDENTITY = 'DBAduckKeyVault',                            -- for public Azure
    -- WITH IDENTITY = 'ContosoEKMKeyVault.vault.usgovcloudapi.net', -- for Azure Government
    -- WITH IDENTITY = 'ContosoEKMKeyVault.vault.azure.cn',          -- for Azure China 21Vianet
    -- WITH IDENTITY = 'ContosoEKMKeyVault.vault.microsoftazure.de', -- for Azure Germany
    SECRET = 'e15ab6196e674f5e9ba791e47941c6482.CPwMx4a9ReB8Qi__~~m8yY00Mi8x2JEj'
FOR CRYPTOGRAPHIC PROVIDER AzureKeyVault_EKM;  

-- Add the credential to the SQL Server administrator's domain login
ALTER LOGIN [dbaduck\dbaduck]  
ADD CREDENTIAL sysadmin_ekm_cred;


-- Create Asymmetric Key from EKM (Key Vault)
-- This key will be created from the one 
-- you created in Key vault
CREATE ASYMMETRIC KEY EKMSampleASYKey
FROM PROVIDER [AzureKeyVault_EKM]  
WITH PROVIDER_KEY_NAME = 'DBAduckKey',  
CREATION_DISPOSITION = OPEN_EXISTING; 


--Create a Login that will associate the asymmetric key to this login
CREATE LOGIN TDE_Login
FROM ASYMMETRIC KEY EKMSampleASYKey;


--Now drop the credential mapping from the original association
ALTER LOGIN [dbaduck\dbaduck]
DROP CREDENTIAL sysadmin_ekm_cred;


--Now add the credential mapping to the new login for TDE
ALTER LOGIN TDE_Login
ADD CREDENTIAL sysadmin_ekm_cred;

--Create a test database that will be encrypted with the Azure key vault key
CREATE DATABASE TestTDE

--Create an ENCRYPTION KEY using the ASYMMETRIC KEY (EKMSampleASYKey)
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER ASYMMETRIC KEY EKMSampleASYKey;

--Enable TDE by setting ENCRYPTION ON
ALTER DATABASE TestTDE
SET ENCRYPTION ON; 


-- CLEAN UP ALL the stuff
USE Master
ALTER DATABASE [TestTDE] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [TestTDE]

ALTER LOGIN [TDE_Login] DROP CREDENTIAL [sysadmin_ekm_cred]
DROP LOGIN [TDE_Login]

DROP CREDENTIAL [sysadmin_ekm_cred]  

USE MASTER
DROP ASYMMETRIC KEY [EKMSampleASYKey]
DROP CRYPTOGRAPHIC PROVIDER [AzureKeyVault_EKM]


