/*
	sp_configure can only be used in the Instance
	and will refuse to work in the Contained AG context
*/
exec sp_configure 'show advanced',0

reconfigure

