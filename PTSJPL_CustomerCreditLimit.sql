/* $Header: /ApplicationDB/Stored Procedures/PTSJPL_CustomerCreditLimit.sp 22    25/3/2021 15:12 $ */
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
/* $Archive: /ApplicationDB/Stored Procedures/PTSJPL_CustomerCreditLimit.sp $
 *
 * 25/3/2021 testing store procedure for custom report
 *
 * $NoKeywords: $
 */
CREATE	OR	alter	PROCEDURE [dbo].[PTSJPL_CustomerCreditLimit](
	@pSource	nvarchar(50) = NULL,
	@pSite      SiteType,
    @pAmt     NUMERIC = NULL,
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
          @pAmt,
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
     @ContextName = 'PTSJPL_CustomerCreditLimit'
   , @SessionID   = @RptSessionID OUTPUT
   , @Site        = @pSite


select 
x.cust_num
, x.cust_seq
, x.name
, x.order_bal
, x.posted_bal
, x.credit_limit
, x.order_credit_limit
, x.curr_code
, x.credit_hold
, CASE WHEN x.available_credit < 0 THEN 1 ELSE 0 END as overlimit
, x.available_credit
, artran.inv_num
, artran.inv_date
, artran.due_date
, artran.inv_amount
, artran.remaining
, artran.overdue
from 
	(
		select 
		cust.cust_num
		, cust.cust_seq
		, ca.name
		, cust.order_bal
		, cust.posted_bal
		, ca.credit_limit
		, ca.order_credit_limit
		, ca.curr_code
		, ca.credit_hold
		, SUM(ca.order_credit_limit	- cust.order_bal - cust.posted_bal - @pAmt) as available_credit
		from dbo.customer_mst as cust
		join dbo.custaddr_mst as ca on ca.cust_num = cust.cust_num and ca.cust_seq = cust.cust_seq and ca.site_ref = cust.site_ref
		where 
		cust.cust_seq = 0 and 
		cust.cust_num = @pCustNum and 
		cust.site_ref = @pSite 
		group by cust.cust_num, cust.cust_seq, ca.name, ca.credit_limit, ca.curr_code, ca.credit_hold,
		cust.order_bal,
		cust.posted_bal,
		ca.order_credit_limit
	) as x
join 
	(
		select 
		y.cust_num
		, y.inv_num
		, y.inv_date
		, y.due_date
		, y.inv_amount
		, (y.inv_amount - y.payment) as remaining
		, y.overdue
		from 
			(
				select 
				art.cust_num
				, art.inv_num
				, art.inv_date
				, art.due_date
				, (art.amount+art.sales_tax) as inv_amount
				, ISNULL((select sum(art2.amount+art2.sales_tax) from artran_mst as art2 where art2.apply_to_inv_num = art.inv_num and art2.type <> 'I' and art2.site_ref = art.site_ref),0) as payment
				, CASE WHEN  DATEDIFF(day, art.due_date, GETDATE())> 0  then 1 else 0 end AS overdue
				from artran_mst as art
				where art.type ='I'
			) as y
		UNION
		select
			art_cp.cust_num
			, art_cp.inv_num
			, art_cp.inv_date
			, art_cp.due_date
			, (art_cp.amount+art_cp.sales_tax) *-1 as inv_amount
			, (art_cp.amount+art_cp.sales_tax) *-1 as remaining
			, 0 as overdue
			from artran_mst as art_cp
			where art_cp.type  in ('C','P') and art_cp.apply_to_inv_num = '0'
	) as artran on artran.cust_num = x.cust_num
where artran.remaining !=0


COMMIT TRANSACTION

EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID