/* $Header: /ApplicationDB/Stored Procedures/PTSJPL_ReportCutOffSp.sp 22    25/3/2021 15:12 $ */
/*
*********************
*                                                             *
*                           NOTICE                            *
*                                                             *
*   THIS SOFTWARE IS THE PROPERTY OF AND CONTAINS             *
*   CONFIDENTIAL INFORMATION OF INFOR AND/OR ITS AFFILIATES   *
*   OR SUBSIDIARIES AND SHALL NOT BE DISCLOSED WITHOUT PRIOR  *
*   WRITTEN PERMISSION. LICENSED CUSTOMERS MAY COPY AND       *
*   ADAPT THIS SOFTWARE FOR THEIR OWN USE IN ACCORDANCE WITH  *
*   THE TERMS OF THEIR SOFTWARE LICENSE AGREEMENT.            *
*   ALL OTHER RIGHTS RESERVED.                                *
*                                                             *
*   (c) COPYRIGHT 2010 INFOR.  ALL RIGHTS RESERVED.           *
*   THE WORD AND DESIGN MARKS SET FORTH HEREIN ARE            *
*   TRADEMARKS AND/OR REGISTERED TRADEMARKS OF INFOR          *
*   AND/OR ITS AFFILIATES AND SUBSIDIARIES. ALL RIGHTS        *
*   RESERVED.  ALL OTHER TRADEMARKS LISTED HEREIN ARE         *
*   THE PROPERTY OF THEIR RESPECTIVE OWNERS.                  *
*                                                             *
*********************
*/
/* $Archive: /ApplicationDB/Stored Procedures/PTSJPL_ReportCutOffSp.sp $
 *
 * 25/3/2021 testing store procedure for custom report
 *
 * $NoKeywords: $
 */
CREATE             PROCEDURE [dbo].[extgen_PTSJPL_ReportCutOffSp](
	@pSource	nvarchar(50) = NULL,
	@pSite      SiteType,
    @pEndingDate      DateType,
    @pRemaining     Int = NULL,
    @pStartingDate      DateType,
    @pCustNum CustNumType
)
AS

--SET @pDateFrom = COALESCE(@pDateFrom,GETDATE())
--SET @pDateTo = COALESCE(@pDateTo,GETDATE())
-- Begin of CallALTETPs.exe generated code.
-- Check for existence of alternate definitions (this section was generated and inserted by CallALTETPs.exe):
IF EXISTS (SELECT 1 FROM [optional_module] [om] WHERE ISNULL([om].[is_enabled],0) = 1
AND OBJECT_ID(QUOTENAME(OBJECT_NAME(@@PROCID) + CHAR(95) + [om].[ModuleName])) IS NOT NULL)
BEGIN
   DECLARE @ALTGEN TABLE ([SpName] SYSNAME)
   DECLARE @ALTGEN_SpName SYSNAME
   DECLARE @ALTGEN_Severity int

   INSERT INTO @ALTGEN ([SpName])
   SELECT QUOTENAME(OBJECT_NAME(@@PROCID) + CHAR(95) + [om].[ModuleName])
   FROM [optional_module] [om]
   WHERE ISNULL([om].[is_enabled], 0) = 1 AND
   OBJECT_ID(QUOTENAME(OBJECT_NAME(@@PROCID) + CHAR(95) + [om].[ModuleName])) IS NOT NULL

   WHILE EXISTS (SELECT 1 FROM @ALTGEN)
   BEGIN
      SELECT TOP 1 @ALTGEN_SpName = [SpName]
      FROM @ALTGEN

      -- Invoke the ALT routine, passing in (and out) this routine's parameters:
      EXEC @ALTGEN_Severity = @ALTGEN_SpName
          @pSource,
          @pSite,
          @pEndingDate,
          @pRemaining,
          @pStartingDate,
          @pCustNum 

      -- ALTGEN routine can RETURN 1 to signal that the remainder of this standard routine should now proceed:
      IF @ALTGEN_Severity <> 1
         RETURN @ALTGEN_Severity

      DELETE @ALTGEN WHERE [SpName] = @ALTGEN_SpName
   END
END
-- End of alternate definitions code.


-- End of CallALTETPs.exe generated code.

--  Crystal reports has the habit of setting the isolation level to dirty
-- read, so we'll correct that for this routine now.  Transaction management
-- is also not being provided by Crystal, so a transaction is started here.
BEGIN TRANSACTION
SET XACT_ABORT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- A session context is created so session variables can be used.
DECLARE
   @RptSessionID RowPointerType

--converted from item/whse06-r.p

EXEC dbo.InitSessionContextSp
     @ContextName = 'PTSJPL_ReportCutOffSp'
   , @SessionID   = @RptSessionID OUTPUT
   , @Site        = @pSite




SELECT
	x.*,
	(CASE WHEN x.type in ('C') AND  apply_to_inv_num  = '0' THEN 
		x.CN
	WHEN x.type in ('D') AND  apply_to_inv_num  = '0' THEN 
		x.invh_price
	WHEN x.type in ('P') AND  apply_to_inv_num  = '0' THEN 
		(x.payment)
	ELSE
		(x.invh_price+x.payment+x.CN+x.debit_memo)
	END) AS remaining, --29
	(CASE WHEN x.type in ('C') AND  apply_to_inv_num  = '0' THEN 
		x.CN
	ELSE
		(x.invh_price) 
	END) AS total_invoice , --30
	1 as query --31
INTO #temp_cutoff FROM (
	SELECT 
		art.acct as account, --1
		art.amount, --2
		art.apply_to_inv_num, --3
		art.co_num, --4
		art.corp_cust as cust_id, --5
		art.CreateDate, -- 6
		art.CreatedBy, --7
		art.curr_code, --8
		(CASE WHEN art.type = 'P' THEN 
			((ISNULL(art.amount,0) + ISNULL(art.sales_tax,0))*-1) 
		WHEN art.type in ('D','C') THEN
			0
		ELSE 
			ISNULL( (select sum(ISNULL(a.amount,0) + ISNULL(a.sales_tax,0))*-1 from artran as a where a.apply_to_inv_num = art.inv_num and a.type = 'P' and (@pEndingDate is null or a.inv_date <= @pEndingDate)  ) ,0) 
		END) AS payment, --9
		(CASE WHEN art.type in ('P','C','D') THEN
			((ISNULL(art.amount,0) + ISNULL(art.sales_tax,0))) 
		ELSE
			ISNULL((select sum(ISNULL(a.amount,0) + ISNULL(a.sales_tax,0)) from artran as a where a.apply_to_inv_num = art.inv_num and a.type in ('P','C','D') and (@pEndingDate is null or a.inv_date <= @pEndingDate) ) ,0)
		END) AS all_payment, -- 10
		(CASE WHEN art.type='D' THEN
			((ISNULL(art.amount,0) + ISNULL(art.sales_tax,0))) 
		WHEN art.type in ('P','C') THEN
			0
		ELSE
			ISNULL((SELECT SUM((ISNULL(x.amount,0) + ISNULL(x.sales_tax,0))) FROM artran as x  where x.apply_to_inv_num = art.apply_to_inv_num  and x.type='D' and (@pEndingDate is null or x.inv_date <= @pEndingDate)),0) 
		END) AS debit_memo, -- 11
		ISNULL(invh.price,0) AS invh_price, -- 12
		(CASE WHEN art.type = 'C' THEN
			((ISNULL(art.amount,0) + ISNULL(art.sales_tax,0))*-1) 
		WHEN art.type in ('P','D') THEN
			0
		ELSE
			ISNULL( (select sum(ISNULL(a.amount,0) + ISNULL(a.sales_tax,0))*-1 from artran as a where a.apply_to_inv_num = art.inv_num and a.type = 'C' and (@pEndingDate is null or a.inv_date <= @pEndingDate) ) ,0) 
		END) AS CN, -- 13
		art.description, --14
		art.due_date, --15
		art.inv_date, -- 16
		art.Uf_ClearingDate, --17
		art.cust_num, -- 18
		cadr.name AS cust_name, --19
		invh.slsman AS invh_slsman, --20
		(SELECT TOP 1 a.Uf_NamaSalesman FROM slsman_mst a WHERE a.slsman = invh.slsman) AS nama_salesman, --21
		(SELECT TOP 1 a.whse FROM co_mst a WHERE a.co_num = invh.co_num) AS co_whse, --22
		(SELECT TOP 1 a.cust_po FROM co_mst a WHERE a.co_num = invh.co_num) AS co_cust_po, --23
		art.shipment_id AS ship_num, --24
		art.sales_tax AS ppn,--25
		art.inv_num, --26
		art.type, --27
		art.inv_seq --28
	FROM artran as art
	LEFT JOIN inv_hdr as invh on [invh].[inv_num] = [art].[inv_num] AND [invh].[inv_seq] = [art].[inv_seq] 
	LEFT JOIN custaddr as cadr on cadr.[cust_num] = art.[cust_num] AND cadr.[cust_seq] = 0
	WHERE ((art.type='I' and (@pEndingDate IS NULL or art.Uf_ClearingDate IS NULL or  art.Uf_ClearingDate > @pEndingDate )) or (art.type='C' and art.apply_to_inv_num = '0' ) or (art.type='D' and art.apply_to_inv_num = '0' and art.inv_seq = '0') or (art.type='P' and art.apply_to_inv_num = '0') or (art.type='P' and art.apply_to_inv_num = '0' and art.inv_num ='0')) and 
	(@pEndingDate IS NULL OR art.inv_date <=@pEndingDate) and (@pCustNum  is null or art.cust_num = @pCustNum )
) x  

INSERT INTO #temp_cutoff SELECT
	x.*,
	(x.payment+x.CN+x.debit_memo) AS remaining ,
	(0) AS total_invoice,
	3 AS query
FROM (
	SELECT 
		art2.acct AS account,
		0 AS amount,
		-- art.amount,
		art2.apply_to_inv_num,
		art2.co_num,
		art2.corp_cust AS cust_id,
		art2.CreateDate,
		art2.CreatedBy,
		art2.curr_code,
		CASE WHEN art2.type = 'P' THEN
			(ISNULL(((ISNULL(art2.amount,0) + ISNULL(art2.sales_tax,0))*-1) ,0))
		ELSE 
			0
		END AS payment,
		(ISNULL( (select sum(ISNULL(a.amount,0) + ISNULL(a.sales_tax,0)) from artran as a where a.apply_to_inv_num = art.inv_num and a.type in ('P','C','D')
		AND (@pEndingDate is null or a.inv_date <= @pEndingDate) ) ,0)) AS all_payment,
		CASE WHEN art2.type = 'D' THEN
			(ISNULL( ((ISNULL(art2.amount,0) + ISNULL(art2.sales_tax,0))) ,0))
		ELSE 
			0
		END AS debit_memo,
		0 AS invh_price,
		-- ISNULL(invh.price,0) as invh_price,
		CASE WHEN art2.type = 'C' THEN
			(ISNULL( ((ISNULL(art2.amount,0) + ISNULL(art2.sales_tax,0))*-1) ,0)) 
		ELSE 
			0
		END AS CN,
		art2.description,
		art2.due_date,
		art2.inv_date,
		art.Uf_ClearingDate,
		art2.cust_num,
		cadr.name AS cust_name,
		invh.slsman AS invh_slsman,
		(SELECT TOP 1 a.Uf_NamaSalesman FROM slsman_mst a WHERE a.slsman = invh.slsman) AS nama_salesman,
		(SELECT TOP 1 a.whse FROM co_mst a WHERE a.co_num = invh.co_num) AS co_whse,
		(SELECT TOP 1 a.cust_po FROM co_mst a WHERE a.co_num = invh.co_num) AS co_cust_po,
		art2.shipment_id AS ship_num,
		0 AS ppn,
		-- art.sales_tax as ppn,
		art2.inv_num,
		art2.type,
		art2.inv_seq
	FROM artran as art
	-- INNER JOIN #temp_cutoff as tmp on tmp.type = 'I' and art.type='I' and art.inv_num != tmp.inv_num 
	INNER JOIN artran as art2 on (art2.type IN ('C','P','D')  and (@pEndingDate IS NULL or  art2.inv_date <= @pEndingDate ) and (@pEndingDate IS NULL or art2.Uf_ClearingDate IS NULL or  art.Uf_ClearingDate > @pEndingDate )  ) and art.inv_num = art2.apply_to_inv_num
	LEFT JOIN inv_hdr as invh on [invh].[inv_num] = [art].[inv_num] AND [invh].[inv_seq] = [art].[inv_seq] 
	LEFT JOIN custaddr as cadr on cadr.[cust_num] = art.[cust_num] AND cadr.[cust_seq] = 0
	WHERE (art.type='I'and (( art.Uf_ClearingDate IS NOT NULL  and  art.inv_date < @pEndingDate and art.Uf_ClearingDate  < @pEndingDate) or (@pEndingDate is NOT null AND art.inv_date > @pEndingDate ) ) ) and (@pCustNum  is null or art.cust_num = @pCustNum )   
) x  

SELECT * FROM #temp_cutoff ORDER BY cust_num,inv_date
    
DROP table #temp_cutoff;



COMMIT TRANSACTION

EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID