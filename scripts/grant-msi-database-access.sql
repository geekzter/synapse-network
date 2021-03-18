-- Should run in content database
DECLARE @sql VARCHAR(4096)
SELECT @@version

IF NOT EXISTS(SELECT name FROM sys.database_principals WHERE name = '@msi_name')
BEGIN 
	--      Graph Access required to look up user by name
	CREATE USER [@msi_name] FROM EXTERNAL PROVIDER; 
END
--ALTER ROLE db_datareader ADD MEMBER [@msi_name];
EXEC sp_addrolemember N'db_datareader', N'@msi_name'

SELECT name 
FROM sys.sysusers 
WHERE altuid is NULL AND issqluser=0
ORDER BY name asc