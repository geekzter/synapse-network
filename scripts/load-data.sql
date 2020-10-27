-----------------------------------------------------------------------------------------------------------------------------------
-- Source: https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/load-data-from-azure-blob-storage-using-copy
-----------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------
-- Create Schema ------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'Date'))
BEGIN
  CREATE TABLE [dbo].[Date]
  (
      [DateID] int NOT NULL,
      [Date] datetime NULL,
      [DateBKey] char(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayOfMonth] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DaySuffix] varchar(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayName] varchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayOfWeek] char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayOfWeekInMonth] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayOfWeekInYear] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayOfQuarter] varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DayOfYear] varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [WeekOfMonth] varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [WeekOfQuarter] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [WeekOfYear] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [Month] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [MonthName] varchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [MonthOfQuarter] varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [Quarter] char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [QuarterName] varchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [Year] char(4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [YearName] char(7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [MonthYear] char(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [MMYYYY] char(6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [FirstDayOfMonth] date NULL,
      [LastDayOfMonth] date NULL,
      [FirstDayOfQuarter] date NULL,
      [LastDayOfQuarter] date NULL,
      [FirstDayOfYear] date NULL,
      [LastDayOfYear] date NULL,
      [IsHolidayUSA] bit NULL,
      [IsWeekday] bit NULL,
      [HolidayUSA] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'Geography'))
BEGIN
  CREATE TABLE [dbo].[Geography]
  (
      [GeographyID] int NOT NULL,
      [ZipCodeBKey] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
      [County] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [City] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [State] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [Country] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [ZipCode] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'HackneyLicense'))
BEGIN
  CREATE TABLE [dbo].[HackneyLicense]
  (
      [HackneyLicenseID] int NOT NULL,
      [HackneyLicenseBKey] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
      [HackneyLicenseCode] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'Medallion'))
BEGIN
  CREATE TABLE [dbo].[Medallion]
  (
      [MedallionID] int NOT NULL,
      [MedallionBKey] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
      [MedallionCode] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'Time'))
BEGIN
  CREATE TABLE [dbo].[Time]
  (
      [TimeID] int NOT NULL,
      [TimeBKey] varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
      [HourNumber] tinyint NOT NULL,
      [MinuteNumber] tinyint NOT NULL,
      [SecondNumber] tinyint NOT NULL,
      [TimeInSecond] int NOT NULL,
      [HourlyBucket] varchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
      [DayTimeBucketGroupKey] int NOT NULL,
      [DayTimeBucket] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'Trip'))
BEGIN
  CREATE TABLE [dbo].[Trip]
  (
      [DateID] int NOT NULL,
      [MedallionID] int NOT NULL,
      [HackneyLicenseID] int NOT NULL,
      [PickupTimeID] int NOT NULL,
      [DropoffTimeID] int NOT NULL,
      [PickupGeographyID] int NULL,
      [DropoffGeographyID] int NULL,
      [PickupLatitude] float NULL,
      [PickupLongitude] float NULL,
      [PickupLatLong] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [DropoffLatitude] float NULL,
      [DropoffLongitude] float NULL,
      [DropoffLatLong] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [PassengerCount] int NULL,
      [TripDurationSeconds] int NULL,
      [TripDistanceMiles] float NULL,
      [PaymentType] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
      [FareAmount] money NULL,
      [SurchargeAmount] money NULL,
      [TaxAmount] money NULL,
      [TipAmount] money NULL,
      [TollsAmount] money NULL,
      [TotalAmount] money NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

IF NOT(EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N'Weather'))
BEGIN
  CREATE TABLE [dbo].[Weather]
  (
      [DateID] int NOT NULL,
      [GeographyID] int NOT NULL,
      [PrecipitationInches] float NOT NULL,
      [AvgTemperatureFahrenheit] float NOT NULL
  )
  WITH
  (
      DISTRIBUTION = ROUND_ROBIN,
      CLUSTERED COLUMNSTORE INDEX
  );
END

-----------------------------------------------------------------------------------------------------------------------------------
-- Load Data ----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.Date))
	BEGIN
    COPY INTO [dbo].[Date]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/Date'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = ',',
      FIELDQUOTE = ''
    )
    OPTION (LABEL = 'COPY : Load [dbo].[Date] - Taxi dataset');
  END

IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.Geography))
	BEGIN
    COPY INTO [dbo].[Geography]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/Geography'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = ',',
      FIELDQUOTE = ''
    )
    OPTION (LABEL = 'COPY : Load [dbo].[Geography] - Taxi dataset');
  END

IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.HackneyLicense))
	BEGIN
    COPY INTO [dbo].[HackneyLicense]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/HackneyLicense'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = ',',
      FIELDQUOTE = ''
    )
    OPTION (LABEL = 'COPY : Load [dbo].[HackneyLicense] - Taxi dataset');
  END

IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.Medallion))
	BEGIN
    COPY INTO [dbo].[Medallion]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/Medallion'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = ',',
      FIELDQUOTE = ''
    )
    OPTION (LABEL = 'COPY : Load [dbo].[Medallion] - Taxi dataset');
  END

IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.Time))
	BEGIN
    COPY INTO [dbo].[Time]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/Time'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = ',',
      FIELDQUOTE = ''
    )
    OPTION (LABEL = 'COPY : Load [dbo].[Time] - Taxi dataset');
  END

IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.Weather))
	BEGIN
    COPY INTO [dbo].[Weather]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/Weather'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = ',',
      FIELDQUOTE = '',
      ROWTERMINATOR='0X0A'
    )
    OPTION (LABEL = 'COPY : Load [dbo].[Weather] - Taxi dataset');
  END

IF NOT(EXISTS (SELECT TOP 1 * FROM dbo.Trip))
	BEGIN
    COPY INTO [dbo].[Trip]
    FROM 'https://nytaxiblob.blob.core.windows.net/2013/Trip2013'
    WITH
    (
      FILE_TYPE = 'CSV',
      FIELDTERMINATOR = '|',
      FIELDQUOTE = '',
      ROWTERMINATOR='0X0A',
      COMPRESSION = 'GZIP'
    )
    OPTION (LABEL = 'COPY : Load [dbo].[Trip] - Taxi dataset');
  END
