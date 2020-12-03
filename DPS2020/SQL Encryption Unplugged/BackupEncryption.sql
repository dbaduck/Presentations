-- Ensure that there is a Master Key
SELECT * FROM sys.symmetric_keys

-- If not then you can create one
-- CREATE MASTER KEY ENCRYPTION BY PASSWORD='Instance1_ThisIsALongPassword!'

-- Create your Backup Certificate
CREATE CERTIFICATE MyBackupCert
WITH SUBJECT = 'My Backup Cert',
EXPIRY_DATE = '20990101'

-- Now you can backup the database with encryption
BACKUP DATABASE [DBA] TO  
DISK = N'C:\SQLBACKUP\DBA.bak' 
WITH FORMAT, 
	INIT,  
	MEDIANAME = N'New Media',  
	NAME = N'DBA-Full Database Backup', 
	COMPRESSION, 
	ENCRYPTION(ALGORITHM = AES_256, SERVER CERTIFICATE = [MyBackupCert]),  
	STATS = 10

