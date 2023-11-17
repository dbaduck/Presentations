/* 
	This login will be created in the instance master 
	because you are just connected to the instance.
*/
CREATE LOGIN [OutsideAGMaster] WITH PASSWORD=N'23PASS23!'

/* 
	This login will be created in the AG master but 
	doesn't work when you simply USE database
	But when you do a new query from object explorer
	into the SQLAG_master database it will be like
	you are in the Contained AG.
*/
CREATE LOGIN [OutsideAGContainedMaster] WITH PASSWORD=N'23PASS23!'

/*
	Try to connect to the instance with Contained login
*/
/* 
	Try to connect to the listener with the instance login
*/


