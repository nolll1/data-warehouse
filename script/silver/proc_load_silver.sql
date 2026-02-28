/*
========================================================================================
STORED PROCEDURE: LOAD SILVER LAYER (BRONZE => SILVER)
========================================================================================
SCRIPT PURPOSE:
  THIS STORED PROCEDURE PERFORMS THE ETL (EXTRACT, TRANSFORM, LOAD) PROCESS TO POPULATE
  THE 'SILVER' SCHEMA TABLES FORM THE 'BRONZE' SCHEMA.
  ACTIONS PERFORMED:
  - TRUNCATES THE SILVER TABLES BEFORE LOADING DATA.
  - INSERTS TRANSFORMED AND CLEANED DATA FROM BRONZE INTO SILVER TABLES.

PARAMETERS:
  NONE.
THIS STORED PROCEDURE DOES NOT ACCEPT ANY PARAMETERS OR RETURN ANY VALUES.

USAGE EXAMPLE:
  EXEC SILVER.LOAD_SILVER;
========================================================================================
*/

CREATE OR ALTER PROCEDURE SILVER.LOAD_SILVER AS
BEGIN
	DECLARE @START_TIME DATETIME, @END_TIME DATETIME, @BATCH_START_TIME DATETIME, @BATCH_END_TIME DATETIME;
	BEGIN TRY
		SET @BATCH_START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '====================================================================';
		
		PRINT '--------------------------------------------------------------------';
		PRINT 'LOADING THE CRM TABLES';
		PRINT '--------------------------------------------------------------------';

		SET @START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'TRUNCATING TABLE: SILVER.CRM_CUST_INFO';
		TRUNCATE TABLE SILVER.CRM_CUST_INFO;
		PRINT '====================================================================';
		PRINT '>> INSERTING CLEANED CRM_CUST_INFO DATA INTO THE SILVER LAYER';
		PRINT '====================================================================';
		INSERT INTO SILVER.CRM_CUST_INFO (
			CST_ID,
			CST_KEY,
			CST_FIRSTNAME,
			CST_LASTNAME,
			CST_MARITAL_STATUS,
			CST_GNDR,
			CST_CREATE_DATE)

		SELECT 
		CST_ID,
		CST_KEY,
		TRIM(CST_FIRSTNAME) AS CST_FIRSTNAME,
		TRIM(CST_LASTNAME) AS CST_LASTNAME,
		CASE
			WHEN UPPER(TRIM(CST_MARITAL_STATUS)) = 'S' THEN 'SINGLE'
			WHEN UPPER(TRIM(CST_MARITAL_STATUS)) = 'M' THEN 'MARRIED'
			ELSE 'N/A'
		END AS CST_MARITAL_STATUS,
		CASE
			WHEN UPPER(TRIM(CST_GNDR)) = 'F' THEN 'FEMALE'
			WHEN UPPER(TRIM(CST_GNDR)) = 'M' THEN 'MALE'
			ELSE 'N/A'
		END AS CST_GNDR,
		CST_CREATE_DATE
		FROM(
		SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY CST_ID ORDER BY CST_CREATE_DATE desc) as FLAG
		FROM BRONZE.CRM_CUST_INFO
		WHERE CST_ID IS NOT NULL
		)T
		WHERE FLAG = 1 

		SET @END_TIME = GETDATE();
		PRINT '>> -----------------------------------------------------------------';
		PRINT 'LOADING DURATION:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS VARCHAR) + 'SECONDS';
		PRINT '>> -----------------------------------------------------------------';

		SET @START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'TRUNCATING TABLE: SILVER.CRM_PRD_INFO';
		TRUNCATE TABLE SILVER.CRM_PRD_INFO;
		PRINT '====================================================================';
		PRINT '>> INSERTING CLEANED CRM_PRD_INFO DATA INTO THE SILVER LAYER';
		PRINT '====================================================================';
		INSERT INTO SILVER.CRM_PRD_INFO(
		PRD_ID,
		CAT_ID,
		PRD_KEY,
		PRD_NM,
		PRD_COST,
		PRD_LINE,
		PRD_START_DT,
		PRD_END_DT
		)
		SELECT
		PRD_ID,
		REPLACE(SUBSTRING(PRD_KEY,1, 5), '-', '_') AS CAT_KEY,
		SUBSTRING(PRD_KEY, 7, LEN(PRD_KEY)) AS PRD_KEY,
		PRD_NM,
		ISNULL(PRD_COST,0) AS PRD_COST,
		CASE UPPER(TRIM(PRD_LINE)) -- UPPER AND TRIM IS USED FOR JUST INCASE, DONT REALLY NEED IT HERE
			WHEN 'M' THEN 'MOUNTAIN'
			WHEN 'R' THEN 'ROAD'
			WHEN 'S' THEN 'OTHER SALES'
			WHEN 'T' THEN 'TOURING'
			ELSE 'N/A'
		END AS PRD_LINE,
		CAST(PRD_START_DT AS DATE),
		CAST(LEAD(PRD_START_DT) OVER(PARTITION BY PRD_KEY ORDER BY PRD_START_DT)-1 AS DATE) AS PRD_END_DT
		FROM BRONZE.CRM_PRD_INFO;

		SET @END_TIME = GETDATE();
		PRINT '>> -----------------------------------------------------------------';
		PRINT 'LOADING DURATION:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS VARCHAR) + 'SECONDS';
		PRINT '>> -----------------------------------------------------------------';

		SET @START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'TRUNCATING TABLE: SILVER.CRM_SALES_DETAILS';
		TRUNCATE TABLE SILVER.CRM_SALES_DETAILS;
		PRINT '====================================================================';
		PRINT '>> INSERTING CLEANED CRM_SALES_DETAILS DATA INTO THE SILVER LAYER';
		PRINT '====================================================================';
		WITH CTE_SLS_SALES AS (
		SELECT
			SLS_ORD_NUM,
			SLS_PRD_KEY,
			SLS_CUST_ID,
			SLS_ORDER_DT,
			SLS_SHIP_DT,
			SLS_DUE_DT,
			SLS_SALES,
			SLS_QUANTITY,
			CASE
				WHEN SLS_PRICE IS NULL OR SLS_PRICE <= 0 THEN SLS_SALES/NULLIF(SLS_QUANTITY,0)
				ELSE SLS_PRICE
			END AS SLS_PRICE
		FROM BRONZE.CRM_SALES_DETAILS
		)

		INSERT INTO SILVER.CRM_SALES_DETAILS(
			SLS_ORD_NUM,
			SLS_PRD_KEY,
			SLS_CUST_ID,
			SLS_ORDER_DT,
			SLS_SHIP_DT,
			SLS_DUE_DT,
			SLS_SALES,
			SLS_QUANTITY,
			SLS_PRICE
		)

		SELECT
		SLS_ORD_NUM,
		SLS_PRD_KEY,
		SLS_CUST_ID,
		CASE 
			WHEN SLS_ORDER_DT IS NULL OR SLS_ORDER_DT = 0 
				THEN NULL
			ELSE TRY_CAST(CAST(SLS_ORDER_DT AS VARCHAR) AS DATE)
		END AS SLS_ORDER_DT,
		CASE
			WHEN SLS_SHIP_DT IS NULL OR SLS_SHIP_DT = 0 
				THEN NULL
			ELSE TRY_CAST(CAST(SLS_SHIP_DT AS VARCHAR) AS DATE)
		END AS SLS_SHIP_DT,
		CASE
			WHEN SLS_DUE_DT IS NULL OR SLS_DUE_DT = 0 
				THEN NULL
			ELSE TRY_CAST(CAST(SLS_DUE_DT AS VARCHAR) AS DATE)
		END AS SLS_DUE_DT,
		SLS_PRICE * SLS_QUANTITY AS SLS_SALES,
		SLS_QUANTITY,
		SLS_PRICE
		FROM CTE_SLS_SALES;

		SET @END_TIME = GETDATE();
		PRINT '>> -----------------------------------------------------------------';
		PRINT 'LOADING DURATION:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS VARCHAR) + 'SECONDS';
		PRINT '>> -----------------------------------------------------------------';

		PRINT '--------------------------------------------------------------------';
		PRINT 'LOADING THE ERP TABLES';
		PRINT '--------------------------------------------------------------------';

		SET @START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'TRUNCATING TABLE: SILVER.ERP_CUST_AZ12';
		TRUNCATE TABLE SILVER.ERP_CUST_AZ12;
		PRINT '====================================================================';
		PRINT '>> INSERTING CLEANED ERP_CUST_AZ12 DATA INTO THE SILVER LAYER';
		PRINT '====================================================================';
		INSERT INTO SILVER.ERP_CUST_AZ12(
			CID,
			BDATE,
			GEN
		)
		SELECT
		CASE
			WHEN LEFT(CID, 3) = 'NAS' THEN SUBSTRING(CID, 4, LEN(CID))
			ELSE CID
		END AS CID,
		CASE 
			WHEN BDATE > GETDATE() THEN NULL
			ELSE BDATE
		END AS BDATE,
		CASE
			WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'FEMALE'
			WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'MALE'
			ELSE 'N/A'
		END AS GEN
		FROM BRONZE.ERP_CUST_AZ12;

		SET @END_TIME = GETDATE();
		PRINT '>> -----------------------------------------------------------------';
		PRINT 'LOADING DURATION:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS VARCHAR) + 'SECONDS';
		PRINT '>> -----------------------------------------------------------------';

		SET @START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'TRUNCATING TABLE: SILVER.ERP_LOC_A101';
		TRUNCATE TABLE SILVER.ERP_LOC_A101;
		PRINT '====================================================================';
		PRINT '>> INSERTING CLEANED ERP_LOC_A101 DATA INTO THE SILVER LAYER';
		PRINT '====================================================================';
		INSERT INTO SILVER.ERP_LOC_A101(
			CID,
			CNTRY
		)
		SELECT
		REPLACE(CID, '-', '') AS CID,
		CASE
			WHEN TRIM(CNTRY) IN ('USA', 'US') THEN 'United States'
			WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
			WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'N/A'
			ELSE TRIM(CNTRY)
		END AS CNTRY
		FROM BRONZE.ERP_LOC_A101;

		SET @END_TIME = GETDATE();
		PRINT '>> -----------------------------------------------------------------';
		PRINT 'LOADING DURATION:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS VARCHAR) + 'SECONDS';
		PRINT '>> -----------------------------------------------------------------';

		SET @START_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT 'TRUNCATING TABLE: SILVER.ERP_PX_CAT_G1V2';
		TRUNCATE TABLE SILVER.ERP_PX_CAT_G1V2;
		PRINT '====================================================================';
		PRINT '>> INSERTING CLEANED ERP_PX_CAT_G1V2 DATA INTO THE SILVER LAYER';
		PRINT '====================================================================';
		INSERT INTO SILVER.ERP_PX_CAT_G1V2(
		ID,
		CAT,
		SUBCAT,
		MAINTENANCE
		)
		SELECT
		ID,
		CAT,
		SUBCAT,
		MAINTENANCE
		FROM BRONZE.ERP_PX_CAT_G1V2;

		SET @END_TIME = GETDATE();
		PRINT '>> -----------------------------------------------------------------';
		PRINT 'LOADING DURATION:' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS VARCHAR) + 'SECONDS';
		PRINT '>> -----------------------------------------------------------------';

		SET @BATCH_END_TIME = GETDATE();
		PRINT '====================================================================';
		PRINT '>> LOADING SILVER LAYER IS COMPLETED';
		PRINT 'TOTAL BATCH LOAD DURATION: ' + CAST (DATEDIFF (SECOND, @BATCH_START_TIME, @BATCH_END_TIME) AS NVARCHAR) + 'SECONDS';
		PRINT '====================================================================';
	END TRY

	BEGIN CATCH
		PRINT '====================================================================';
		PRINT ' ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '====================================================================';
	END CATCH
END;
