/* $Header: /ApplicationDB/Stored Procedures/InvPostingSp.sp 118   12/19/17 4:58p Mmarsolo $ */
/*
***************************************************************
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
***************************************************************
*/
/* CSI10 Rev CSIB-21368 Nov 13 2019
 * Error Logging Transaction into cci_trans: Violation of PRIMARY KEY constraint 'PK_cci_trans_mst'
 * MSF 252481
 * For EXTSSSCCIInvPostingSp errors: Prefix with SP name.
 */

/* $Archive: /ApplicationDB/Stored Procedures/InvPostingSp.sp $
 *
 * SL9.01 118 234221 Mmarsolo Tue Dec 19 16:58:59 2017
 * 234221  - Update order and posted balance calculations to use trx exch rate for domestic currency customers.
 *
 * SL9.01 117 RS8137 Mmarsolo Fri Apr 21 16:45:05 2017
 * RS8137 - Alter I= messages if returning severity = 16.
 *
 * SL9.01 116 215046 Lqian2 Tue Mar 21 03:40:53 2017
 * Issue 215046, update ETP block.
 *
 * SL9.01 115 224331 Lchen3 Tue Mar 14 01:28:17 2017
 * CO Line Discount Days not calculating correctly according to Billing Terms, for February only after applying SL222542
 * issue 224331
 * change the calculate for discount date.
 *
 * SL9.01 114 222542 Lchen3 Fri Feb 03 00:15:28 2017
 * Customer Order Line Discount Days not calculating correctly according to Billing Terms
 * issue 222542
 * correct the condition for calculate discount date
 *
 * SL9.01 113 208463 jzhou Thu May 05 02:08:04 2016
 * The artran.inv_date should be passed into dbo.GetExchRate as input parameter in CredChkSp.sp.
 * Issue 208463:
 * Add parameter for @InvoiceDate when call GetExchRate.
 *
 * SL9.01 112 207817 Ddeng Mon Apr 25 05:11:01 2016
 * Currency Gain entries missing on 2 reports
 * Issue 207817: Correct the credit and debit amount for gain/loss.
 *
 * SL9.01 111 205736 Cliu Thu Mar 03 22:28:21 2016
 * Unable to view external and internal notes added onto consolidated invoices when added via the Consoldiated Invoices Workbench and then posted onto the customers account.
 * Issue:205736
 * Do not copy the notes to inv_hdr table if the notes exist in this table.
 *
 * SL9.01 110 RS6770 jzhou Wed Mar 02 00:36:36 2016
 * RS6770:
 * Add @UseBuyRate for input paremeters when use function GetExchRate().
 *
 * SL9.01 109 RS7102 nferrer Mon Jan 11 23:44:22 2016
 * RS7102 - Genereated by Light's Tool.
 *
 * SL9.01 108 RS5540 Ehe Wed Dec 30 20:45:27 2015
 * RS5540 Change the YTD to be Domestic amount
 *
 * SL9.01 107 RS7102 jkmalaluan Tue Dec 29 01:24:35 2015
 * RS7102-ServiceManagement_MS
 *
 * SL9.01 106 RS3313 Ddeng Tue Dec 29 01:22:41 2015
 * RS3313 Correct exchange rate for gain/loss.
 *
 * SL9.01 105 RS3313 Ddeng Thu Dec 24 05:32:55 2015
 * RS3313
 *
 * SL9.01 104 RS6298 mguan Wed Dec 23 21:57:22 2015
 * RS6298
 *
 * SL9.01 103 RS7102 jkmalaluan Wed Dec 23 01:38:41 2015
 * RS7102-Service Managemet
 *
 * SL9.01 102 RS3313 Ddeng Wed Dec 23 01:36:31 2015
 * RS3313
 *
 * SL9.01 101 RS3313 Ddeng Wed Dec 23 01:29:06 2015
 * RS3313 Calculate variance when exchange rate is different between invoice and credit/debit meno.
 *
 * SL9.01 100 RS5540 Ehe Mon Dec 21 00:31:29 2015
 * RS5540 Change code to get currency code from the arinv instead of custaddr.curr_code.
 * When inserting artran records use the arinv currency code.When inserting inv_hdr records use the arinv currency code.
 * Add currency to export_arinv.
 * Change logic deciding to adjust progressive bill entries to look at the invoice currency, not the customer currency.
 * When calculating customer posted balance convert the invoice amount to the custaddr currency.
 *
 * SL9.01 99 RS7102 jkmalaluan Thu Dec 10 02:48:49 2015
 * RS7210-ChinaCountryPack to ChinaCountryPack
 *
 * SL9.01 98 RS7102 jkmalaluan Tue Dec 01 08:54:53 2015
 * RS7102
 *
 * SL9.01 97 194215 Dlai Wed Jun 03 05:16:39 2015
 * Issue for RS6200
 * Issue194215 (RS6200) Add logic to operate sales tax from golden tax
 *
 * SL9.01 96 192410 Lchen3 Mon Apr 13 23:16:49 2015
 * Invoice Milestones incorrect on Advance Payments and Retention Code
 * issue 192410
 * correct the update of advanced payment on project when posting the invoice
 *
 * SL9.01 95 RS6737 Igui Mon Mar 30 00:11:21 2015
 * RS6737
 * change 'SyteLineAU' to 'Automotive_Mfg'.
 *
 * SL9.01 94 188420 Ychen1 Thu Feb 26 04:28:10 2015
 * Changes associated with RS7091 Loc - Separate Debit and Credits, + and -
 * Issue 188420:(RS7091) Code washup.Rename variable.
 *
 * SL9.01 93 188420 Ychen1 Sun Feb 15 03:52:49 2015
 * Changes associated with RS7091 Loc - Separate Debit and Credits, + and -
 * Issue 188420:(RS7091)Use value from arinv.cancellation for artran.cancellation.
 * Assign value from arinv.cancellation to new parameter @Cancellation when calling dbo.JourpostSp.
 *
 * SL9.01 92 RS6737 Igui Wed Jan 21 03:18:53 2015
 * RS6737
 * add insert to artran.AU_Payment_ref_num when dbo.IsAddonAvailable('SyteLineAU') = 1
 *
 * SL9.01 91 189245 jzhou Fri Dec 26 04:42:20 2014
 * Reprint option does not reprint internal and external notes for invoice and debit memo
 * Issue 189245:
 * Remove the logic to pop up message.
 *
 * SL9.01 90 188387 Gchang Thu Dec 11 14:24:44 2014
 * SRO Invoices for SROs with deposits not updating customer posted balance correctly
 * 188387 - add logic to update customer order balances with SRO deposit
 *
 * SL9.00 89 183753 Lqian2 Tue Sep 02 03:24:37 2014
 * Data know displaying in subgrid for Receivables
 * Issue 183753, Invoice posting with CO should update slsman to the inv_hdr slsman field.
 *
 * SL9.00 88 170518 Ehe Sun Oct 27 23:25:05 2013
 * Discount date wrongly move to the month end for a Order invoice on AR posted transaction detail when all related discount days are 0 on billing term
 * 170518
 * Change List:
 * Add the logic to set discount date when @DiscDays = 0 And @ProxDiscDay = 0.
 *
 * SL8.04 87 163189 jzhou Mon Jun 24 06:04:59 2013
 * The value of Builer Invoice is NULL at A/R Payment Distributions when the Invoice is generated by Invoice Builder
 * Issue 163189:
 * Add parameter @PostSite.
 * When insert into artran table, also insert the fields builder_inv_orig_site, builder_inv_num, post_site.
 *
 * SL8.04 86 162866 Sxu Tue Jun 04 05:02:03 2013
 * Zero Value Invoice is allocated Control Number
 * Issue 162866 - change the location of SET @IsControlNumberCreated = 1
 *
 * SL8.04 85 162866 Sxu Tue Jun 04 03:31:05 2013
 * Zero Value Invoice is allocated Control Number
 * Issue 162866 - change to call NextControlNumberSp when there is journal entry to created.
 *
 * SL8.04 84 RS5889 gwang Tue Apr 16 06:00:31 2013
 * RS5889 merge code block from Addon Tax Interface, EXTSSSVTXInvPostingSp
 *
 * SL8.04 83 RS5888 Lzhan Tue Mar 26 02:30:53 2013
 * RS5888: corrected module name for FSPM_MS.
 *
 * SL8.04 82 RS5888 Lzhan Thu Mar 14 22:41:42 2013
 * RS5888: added IsAddOnAvailabe logic to control FSP.
 *
 * SL8.04 81 RS2775 Bbai Mon Feb 25 04:38:15 2013
 * RS2775:
 * Remote call if posting invoice across sites.
 *
 * SL8.04 80 RS5566 Cliu Fri Oct 19 01:51:36 2012
 * Call IsAddonAvailable function (rather than checking for the existence of a CCI table) to determine whether to call the CCI SP.
 * RS5566
 *
 * SL8.04 79 150462 sturney Tue Aug 21 13:26:37 2012
 * Customer Discount Not Being Applied
 * Issue 150462
 *
 * SL8.04 78 151044 Phorne Thu Jul 12 16:58:29 2012
 * The field ?Discount Date? is showing the incorrect date for all Billing Terms when its Discount Days > 0
 * Issue 151044 - Corrected Discount Date calculation
 *
 * SL8.03 77 148119 Ltaylor2 Fri May 11 15:06:56 2012
 * 5325 - Pack and Ship design coding
 * Get arinv.shipment_id, insert into artran and export_arinv
 *
 * SL8.03 76 148637 Djackson Fri Apr 20 09:58:38 2012
 * The Disc Date is showing the incorrect date when Discount Day=0, Invoice Day(25) < Prox Discount Day(27)
 * 148637 - DiscDays
 *
 * SL8.03 75 RS4902 Bli2 Sun Dec 26 22:00:47 2010
 * RS 4902 - also roll back the discount ytd for customer if the check is returned
 *
 * SL8.03 74 RS4902 Bli2 Tue Dec 14 01:03:05 2010
 * RS 4902
 *
 * SL8.03 73 RS4902 Bli2 Tue Dec 14 00:58:54 2010
 * RS 4902 - donot update sales_ytd, sales_ptd, posted_bal and last_inv when returned_check flag is 1
 *
 * SL8.02 72 128304 Cajones Tue Mar 16 17:04:08 2010
 * SSS hook needs updated in the InvPostingSp
 * Issue:128304, APAR:128304
 * Updated SSS hooks.
 *
 * SL8.02 71 rs4604 Jbrokl Wed Mar 10 10:54:47 2010
 * RS 4604 - Projects - Add fields for planned and Actual Freight, Misc Charges and total.
 *
 * SL8.02 70 rs4588 Dahn Thu Mar 04 14:36:37 2010
 * rs4588 copyright header changes
 *
 * SL8.01 69 121450 Cajones Fri May 29 15:59:33 2009
 * Add changes required for FS-Plus
 * Issue:121450, APAR:116514
 * Code has been added for FS-Plus.  Infor Incident 2368761 caused a new hook for FS-Plus in InvPostingSp. This hook protects against overlapping order numbers in Service Orders, Contracts, and Customer Orders.
 *
 * SL8.01 68 121258 calagappan Fri May 15 17:53:29 2009
 * Multi-currency progressive billings leaving differences in GL.
 * Create Progressive Bill adjustments when regular or consolidated invoice is posted.
 *
 * SL8.01 67 117020 pcoate Mon Jan 19 14:33:18 2009
 * Invoice BOD trigger errors out.
 * Issue 117020 - Corrected the 3rd parameter passed to the Invoice BOD integration RMC.
 *
 * SL8.01 66 116659 Djackson1 Thu Jan 15 13:11:23 2009
 * 116659 - Add ActionExpression to BOD Parameters
 *
 * SL8.01 65 114046 pgross Fri Oct 10 09:45:30 2008
 * Incorrect total invoice project when perform 'Create Invoice For Advance Payment'.
 * prevent Project Invoices from updating the customer On Order Balance
 *
 * SL8.01 64 107716 Dahn Wed Sep 17 11:25:36 2008
 * Code Cleanup: There is code that needs cleaned up within InvPostingSp related to functionality that appears to have been removed for issue 84553.
 * issue 107716: code clean up
 *
 * SL8.01 63 rs3953 Vlitmano Tue Aug 26 17:05:23 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 62 113274 pcoate Tue Aug 26 14:25:46 2008
 * Issue 113274 - Added logic to handle multiple inv_hdr rows for the same invoice.
 *
 * SL8.01 61 rs3953 Vlitmano Mon Aug 18 15:26:54 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.01 60 109670 Djackson1 Fri Jul 18 09:19:18 2008
 * Invoice XML not being created
 * 109670 BOD initialization Point Change
 *
 * SL8.01 59 RS4088 dgopi Tue May 20 04:38:39 2008
 * RS4088
 *
 * SL8.00 58 98490 ssalahud Wed Jan 02 09:49:56 2008
 * Invoice Distributions not= Posting Report not= Journal Entries - all three have different amounts
 * Issue 98490
 * Backed out changes made for the issue 98268.
 *
 * SL8.00 57 103799 pgross Mon Jul 30 08:19:48 2007
 * A/R Invoices that have currency gain/loss will not post when ExtFin is enabled
 * removed an invalid reference to ExtFinPostArinvd which used to handle Gain/Loss
 *
 * SL8.00 56 103568 hcl-kumarup Tue Jul 17 04:03:24 2007
 * XRef button next to the RMA # in the Order # field in SL7 does not work correctly.
 * Checked-in for issue 103568
 * Added a field "rma" in the INSERT INTO artran statement
 *
 * SL8.00 55 101387 hcl-kumarup Thu Apr 26 03:11:51 2007
 * Back-out fix for issue 100097 / APAR 106694
 * Checked-in for issue 101387
 * Backed-out fix for issue/APAR 100097/106694
 *
 * SL8.00 54 100097 hcl-kumarup Fri Mar 30 07:25:54 2007
 * AR Aging Report, the result in the fully paid Invoice still showing a domestic amount outstanding
 * Checked-in for issue 100097
 * Called up GainLossArSp to get the Gain/Loss amount due change in historical rate for Invoice and its payment
 *
 * SL8.00 53 98268 hcl-kumarup Wed Mar 21 08:49:11 2007
 * Include tax in price rounding problems - Unable to post invoice
 * Checked-in for issue 98268
 * In case of currency palces = 0 the rounding is applied to total credit amount after the totaling of its componets
 *
 * SL8.00 52 RS2968 nkaleel Fri Feb 23 03:10:42 2007
 * changing copyright information
 *
 * SL8.00 51 98847 pgross Fri Jan 26 15:37:56 2007
 * On Order Balance incorrect when do the RMA Credit against the fully shipment order
 * allow negative customer.order_bal
 *
 * SL8.00 50 98781 pgross Fri Jan 19 10:51:24 2007
 * On Order Balance displays negative amt for Over shipment and Post an invoice.
 * disallow negative customer order balance
 *
 * SL8.00 49 rs3371 Mkurian Tue Nov 07 07:34:16 2006
 * RS3371
 * References to arinv.curr_code and export_arinv.curr_code have been removed.
 *
 * SL8.00 48 97346 Clarsco Mon Oct 23 10:25:32 2006
 * Application Lock failurer fails to stop process
 * Fixed Bug 97346
 * Added @Severity Trap following NextControlNumberSp call.
 *
 * SL8.00 47 95933 Hcl-ajain Wed Aug 30 02:09:44 2006
 * Incorrect invoice amt after applied the fix of SL103513, SL103901
 * Issue # 95933
 * Used round function on individual amounts while calculating value of '@ForeignInvTotal ' instead of using round on summation of these values.
 *
 * SL8.00 46 95700 Hcl-ajain Tue Aug 08 09:18:18 2006
 * Invoices improperly distributed with taxes
 * Issue 95700
 * Used Rounding function for @ForeignInvTotal
 *
 * SL8.00 45 RS2968 prahaladarao.hs Tue Jul 11 09:08:55 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 44 93542 madhanprasad.s Mon Jun 19 05:39:55 2006
 * Right > Click Detail options for RMA Order Types does not launch expected information
 * Issue Number : 93542
 * Reverted back the changes made in the checkin with version 42,by removing the 'rma' column insertion into the artran table.
 *
 * SL8.00 43 91554 sivaprasad.b Thu Jun 01 05:16:42 2006
 * invoice number over 10 produces error even when length is set to 12
 * 91554
 * - Changed ISNUMERIC(..) for invoice numbers to dbo.IsInteger(..)
 *
 * SL8.00 42 93542 jabraham Tue May 30 07:16:05 2006
 * Right > Click Detail options for RMA Order Types does not launch expected information
 * ISSUE 93542
 * Added code to insert value of rma field while inserting data into artran table.
 *
 * SL8.00 41 93193 Hcl-dixichi Fri May 26 08:41:25 2006
 * Debit/Credit note not posting in Syteline when using External Financial interface.
 * Checked-in for issue 93193
 * Changed the INSERT statement for export tables (export_arinv,export_arinvd) to use @TSeq for inv_seq.
 *
 * SL8.00 40 93998 flagatta Mon May 01 13:28:01 2006
 * Manually Entered Credit is giving erroneous G/L entries
 * Use currCnvt to calculate @DomesticAmount for header.  93998
 *
 * SL8.00 39 93964 hcl-kumarup Fri Apr 28 06:56:50 2006
 * Distribution total does not match invoice total when using discount percent.
 * Checked in for Issue#93964
 * Set Currency place for Invoice Amount
 *
 * SL7.05 39 93964 hcl-kumarup Fri Apr 28 06:55:17 2006
 * Distribution total does not match invoice total when using discount percent.
 * Checked in for Issue#93964
 * Set Currency place for Invoice Amount
 *
 * SL7.05 38 93373 pgross Wed Mar 22 15:48:47 2006
 * Progressively Billings picking up the default A/P Account instead of A/R and when reversing, is booking entry to Gain/Loss account
 * avoid unbalanced journals when posting a negative invoice
 *
 * SL8.00 37 92052 hcl-kumarup Fri Feb 10 05:42:00 2006
 * AR Dist journal contains value in currency gain loss transaction that should be zero.
 * Checked in for Issue #92052
 * Changed RoundResult parameter value when calling CurrCnvtSp from InvPostingSp
 *
 * SL7.05 35 90527 hcl-amargt Wed Jan 11 06:46:58 2006
 * Attempt to remove inv_ms cursor for performance fix
 * Issue : 90527
 * 1. 'InvMsCrs' cursor replaced with an update statement.
 *
 * SL7.04 34 91818 NThurn Fri Jan 06 11:41:12 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.04 33 90282 Hcl-manobhe Wed Dec 28 05:06:20 2005
 * Code Cleanup
 * Issue 90282
 * Call to JourpostISp has been changed to call JourpostSp directly.
 *
 * SL7.04 32 91110 hcl-singind Mon Dec 26 04:53:37 2005
 * Issue #: 91110.
 * Added "WITH (READUNCOMMITTED)" to co Select Statement.
 *
 * SL7.04 31 88752 hcl-singind Fri Aug 26 07:40:22 2005
 * RS1228 Upgrade Localization for France
 * Issue # 88752.
 * Remove the following call to French stub from the SL7.04 base SP
 * ?IF OBJECT_ID('EXTFRInvPostingSp') IS NOT NULL?
 *
 * SL7.04 30 88654 Hcl-dixichi Wed Aug 24 05:43:38 2005
 * The conversion of the nvarchar value '3050000001' overflow an int column. Maximum integer value exceeded.
 * Checked-in for issue 88654
 * In the function 'Convert' changed the data type from int to bigint to support numeric credit memos greater than 2147483647(the numeric limit for int data type)
 *
 * SL7.04 29 86508 Hcl-sharpar Wed Mar 30 09:15:23 2005
 * Stub calls needed for French Localization
 * issue 86508
 * French Country Pack stub design RS 1249
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[extgen_InvPostingSp] (
  @PSessionID              RowPointerType
, @PCustNum                CustNumType
, @PInvNum                 InvNumType
, @PInvSeq                 ArInvSeqType
, @PJHeaderRowPointer      RowPointerType
, @PostExtFin              ListYesNoType OUTPUT
, @ExtFinOperationCounter  OperationCounterType OUTPUT
, @Infobar                 InfobarType    OUTPUT
, @ToSite                  SiteType = NULL
, @PostSite                SiteType = NULL
)
AS

-- Begin of CallALTETPs.exe generated code.
-- Check for existence of alternate definitions (this section was generated and inserted by CallALTETPs.exe):

-- End of alternate definitions code.


-- End of CallALTETPs.exe generated code.

DECLARE
  @Severity INT
, @ParmsSite SiteType
, @Category LongListType
, @TaxSystem TaxSystemType
, @PolandCountryPackOn  ListYesNoType
, @MexicanCountryPack  ListYesNoType
, @MXProFormaAppStatus ProFormaApprovalStatusType
, @IsPOSProcess           VeryLongListType
SELECT @PolandCountryPackOn = dbo.IsAddonAvailable('PolandCountryPack')
SELECT @MexicanCountryPack = dbo.IsAddonAvailable('MexicanCountryPack')

/* Feature Management RS --Start */
DECLARE     
  @ProductName               ProductNameType      
, @FeatureID1                ApplicationFeatureIDType     
, @FeatureRS8518_2Active     ListYesNoType    
, @FeatureInfoBar            InfoBarType
, @FeatureID_RS8297          ApplicationFeatureIDType   
, @Feature_RS8297Active      ListYesNoType
    
SET @Severity = 0     
SET @ProductName = 'CSI'

/*RS8518_2*/
SET @FeatureID1 = 'RS8518_2'     
    
EXEC @Severity = dbo.IsFeatureActiveSp     
      @ProductName   = @ProductName      
     ,@FeatureID     = @FeatureID1     
     ,@FeatureActive = @FeatureRS8518_2Active OUTPUT    
     ,@InfoBar       = @FeatureInfoBar OUTPUT    
IF @Severity <> 0
BEGIN
  RETURN @Severity
END
/*RS8518_2*/

/* RS8297 - Adopt Local.Ly - Mexico --Start */  
SET @FeatureID_RS8297 = 'RS8297'   
  
EXEC   @Severity      = IsFeatureActiveSp   
       @ProductName   = @ProductName    
     , @FeatureID     = @FeatureID_RS8297
     , @FeatureActive = @Feature_RS8297Active OUTPUT   
     , @Infobar       = @FeatureInfoBar OUTPUT
     
IF @Severity <> 0
BEGIN
  RETURN @Severity
END
/* RS8297 - Adopt Local.Ly - Mexico --END */

--CSIB_79704 START
DECLARE
  @FeatureIDCSIB_79704                ApplicationFeatureIDType
, @FeatureCSIB_79704Active       ListYesNoType

SET @Severity    = 0
SET @FeatureIDCSIB_79704  = N'CSIB_79704'

EXEC @Severity = dbo.IsFeatureActiveSp
     @ProductName   = @ProductName
   , @FeatureID     = @FeatureIDCSIB_79704
   , @FeatureActive = @FeatureCSIB_79704Active OUTPUT
   , @InfoBar       = @FeatureInfoBar OUTPUT
 
IF @Severity <> 0
    RETURN @Severity
--CSIB_79704 END
/* Feature Management RS --END */ 

DECLARE  
  @PolandCountryPackCSIB_79704On  ListYesNoType
SET @PolandCountryPackCSIB_79704On = CASE WHEN @PolandCountryPackOn = 1 AND @FeatureCSIB_79704Active = 1 THEN 1 ELSE 0 END
    
SELECT TOP 1 @TaxSystem = tax_system FROM tax_system WHERE tax_mode = 'I'
IF @TaxSystem IS NULL
   SELECT TOP 1 @TaxSystem = tax_system FROM tax_system

EXEC   @Severity = dbo.GetVariableSp 'IsPOSProcess' ,'0',0, @IsPOSProcess OUTPUT ,@Infobar OUTPUT
IF @Severity <> 0
  RETURN @Severity   
IF ISNULL(@MexicanCountryPack,0) = 1 /*RS8297*/ AND @Feature_RS8297Active = 1 /*RS8297*/ AND ISNULL(@IsPOSProcess,'0') <> '1'
BEGIN

SET @MXProFormaAppStatus = 'N'

IF EXISTS (SELECT 1 FROM [pro_forma_inv_hdr] WHERE [pro_forma_inv_hdr].[inv_num] = @PInvNum)
    BEGIN
        SELECT @MXProFormaAppStatus = [pro_forma_inv_hdr].[pro_forma_approval_status]
        FROM [pro_forma_inv_hdr]
        WHERE [pro_forma_inv_hdr].[inv_num] = @PInvNum
    END

IF @MXProFormaAppStatus <> 'S'
    BEGIN

        EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
        , 'E=IsCompareNot'
        , '@!Invoice'
        , '@!Registered'

        IF @Severity <> 0
        BEGIN
           Return @Severity
        END

        GOTO ERROR_OUT

    END
END

SELECT @ParmsSite = site FROM parms with (readuncommitted)

SET @Severity = 0
SET @Infobar  = NULL

exec dbo.GetVariableSp
  @VariableName   = 'Category'
, @DefaultValue   = null
, @DeleteVariable = 0
, @VariableValue  = @Category OUTPUT
, @Infobar        = @Infobar OUTPUT

IF @ToSite IS NOT NULL AND @PostSite IS NULL
   SET @PostSite = @ParmsSite

IF @ParmsSite = @ToSite OR @ToSite IS NULL
BEGIN
   DECLARE
     @AmountToPost         GenericDecimalType
   , @ForAmtToPost         GenericDecimalType
   , @CurrentPeriod        FinPeriodType
   , @PeriodsRowPointer    RowPointerType
   , @FindCustNum          CustNumType
   , @FindCustSeq          CustSeqType
   , @TSeq                 ArinvSeqType
   , @TotCr                AmountType
   , @DomesticArinvdAmount GenericDecimalType
   , @TId                  JournalIdType
   , @AmountPosted         GenericDecimalType
   , @ForeignInvTotal      GenericDecimalType
   , @DomesticInvTotal     GenericDecimalType
   , @Adjust               GenericDecimalType
   , @DomesticAmount       GenericDecimalType
   , @DomesticDisc         GenericDecimalType
   , @TInvStaxSeq          GenericNoType
   , @GainLossAmount       GenericDecimalType
   , @IsOrderForProject    ListYesNoType
   , @AuExtPaymentRefNum   AU_PaymentRefNumType
   , @AuPaymentRefType     AU_PaymentRefTypeType
   , @EdiCoNum             CoNumType
   , @EdiCustPo            CustPoType
   , @ForeignExchRate      ExchRateType
   , @InfobarLoc           InfobarType

   SET @TInvStaxSeq          = 0
   SET @AmountToPost         = 0
   SET @ForAmtToPost         = 0
   set @IsOrderForProject    = 0
   SET @DomesticDisc         = 0
   SET @AuExtPaymentRefNum   = NULL
   SET @AuPaymentRefType     = NULL

   DECLARE
     @ShipCustaddrRowPointer RowPointerType
   , @ShipCustaddrState      StateType
   , @TaxparmsRowPointer     RowPointerType
   , @TaxparmsLastTaxReport1 DateType
   , @ArparmsRowPointer      RowPointerType
   , @ArparmsDiscAcct        AcctType
   , @ParmsRowPointer        RowPointerType
   , @ParmsEcReporting       ListYesNoType
   , @ParmsCountry           CountryType
   , @ArinvRowPointer        RowPointerType
   , @ArinvAcct              AcctType
   , @ArinvCustNum           CustNumType
   , @ArinvInvNum            InvNumType
   , @ArinvInvDate           DateType
   , @ArinvDueDate           DateType
   , @ArinvType              ArinvTypeType
   , @ArinvPostFromCo        ListYesNoType
   , @ArinvInvSeq            ArInvSeqType
   , @ArinvNoteExistsFlag    FlagNyType
   , @ArinvCoNum             CoNumType
   , @ArinvDoNum             DoNumType
   , @ArinvAcctUnit1         UnitCode1Type
   , @ArinvAcctUnit2         UnitCode2Type
   , @ArinvAcctUnit3         UnitCode3Type
   , @ArinvAcctUnit4         UnitCode4Type
   , @ArinvDescription       DescriptionType
   , @ArinvAmount            AmountType
   , @ArinvMiscCharges       AmountType
   , @ArinvSalesTax          AmountType
   , @ArinvSalesTax2         AmountType
   , @ArinvFreight           AmountType
   , @ArinvExchRate          ExchRateType
   , @ArinvFixedRate         ListYesNoType
   , @ArinvPayType           CustPayTypeType
   , @ArinvRef               ReferenceType
   , @ArinvTermsCode         TermsCodeType
   , @ArinvUseExchRate       ListYesNoType
   , @ArinvTaxCode1          TaxCodeType
   , @ArinvTaxCode2          TaxCodeType
   , @ArinvReturnedCheck     ListYesNoType
   , @ArinvShipmentId        ShipmentIdType
   , @ArinvCurrCode          CurrCodeType
   , @ArinvCNComment         CNCommentType
   , @ArinvTaxDate           DateType
   , @ChartRowPointer        RowPointerType
   , @ChartAcct              AcctType
   , @CustomerRowPointer     RowPointerType
   , @CustomerOrderBal       AmountType
   , @CustomerPostedBal      AmountType
   , @CustomerSalesYtd       AmountType
   , @CustomerSalesPtd       AmountType
   , @CustomerDiscYtd        AmountType
   , @CustomerLastInv        DateType
   , @CustaddrRowPointer     RowPointerType
   , @CustaddrCorpCust       CustNumType
   , @CustaddrCountry        CountryType
   , @CustaddrCurrCode       CurrCodeType
   , @CustaddrCorpCred       ListYesNoType
   , @CurrencyRowPointer     RowPointerType
   , @CurrencyPlaces         DecimalPlacesType
   , @CurrencyRateIsDivisor  ListYesNoType
   , @InvHdrRowPointer       RowPointerType
   , @InvHdrCoNum            CoNumType
   , @InvHdrCustNum          CustNumType
   , @InvHdrCustSeq          CustSeqType
   , @InvHdrInvSeq           InvSeqType
   , @InvHdrInvNum           InvNumType
   , @InvHdrInvDate          DateType
   , @InvHdrTaxDate          DateType
   , @InvHdrTermsCode        TermsCodeType
   , @InvHdrUseExchRate      ListYesNoType
   , @InvHdrTaxCode1         TaxCodeType
   , @InvHdrTaxCode2         TaxCodeType
   , @InvHdrMiscCharges      AmountType
   , @InvHdrFreight          AmountType
   , @InvHdrPrice            AmountType
   , @InvHdrState            StateType
   , @InvHdrBillType         BillingTypeType
   , @InvHdrEcCode           EcCodeType
   , @InvHdrExchRate         ExchRateType
   , @InvHdrNoteExists       FlagNyType
   , @CoRowPointer           RowPointerType
   , @CoCustNum              CustNumType
   , @CoCustSeq              CustSeqType
   , @CohRowPointer          RowPointerType
   , @CohCustNum             CustNumType
   , @CohCustSeq             CustSeqType
   , @ArtranRowPointer       RowPointerType
   , @ArtranInvNum           InvNumType
   , @ArtranCustNum          CustNumType
   , @ArtranActive           ListYesNoType
   , @ArtranInvSeq           ArInvSeqType
   , @ArtranNoteExistFlag    FlagNyType
   , @ArtranDiscDate         DateType
   , @ArtranIssueDate        DateType
   , @ArtranDiscAmt          AmountType
   , @ArtranType             ArtranTypeType
   , @ArtranCoNum            CoNumType
   , @ArtranDoNum            DoNumType
   , @ArtranInvDate          DateType
   , @ArtranDueDate          DateType
   , @ArtranAcct             AcctType
   , @ArtranAcctUnit1        UnitCode1Type
   , @ArtranAcctUnit2        UnitCode2Type
   , @ArtranAcctUnit3        UnitCode3Type
   , @ArtranAcctUnit4        UnitCode4Type
   , @ArtranDescription      DescriptionType
   , @ArtranCorpCust         CustNumType
   , @ArtranPostFromCo       ListYesNoType
   , @ArtranFixedRate        ListYesNoType
   , @ArtranPayType          CustPayTypeType
   , @ArtranAmount           AmountType
   , @ArtranMiscCharges      AmountType
   , @ArtranSalesTax         AmountType
   , @ArtranSalesTax2        AmountType
   , @ArtranFreight          AmountType
   , @ArtranNoteExistsFlag   FlagNyType
   , @ArtranRef              ReferenceType
   , @ArtranExchRate         ExchRateType
   , @ArtranShipmentId       ShipmentIdType
   , @TermsRowPointer        RowPointerType
   , @TermsDiscDays          DiscDaysType
   , @TermsDiscPct           ApDiscType
   , @ProjInvHdrRowPointer   RowPointerType
   , @CountryRowPointer      RowPointerType
   , @CountryEcCode          EcCodeType
   , @XCountryRowPointer     RowPointerType
   , @XCountryEcCode         EcCodeType
   , @ArinvdRowPointer       RowPointerType
   , @ArinvdRefNum           CoNumType
   , @ArinvdRefLineSuf       CoLineType
   , @ArinvdRefRelease       CoReleaseType
   , @ArinvdDistSeq          ArDistSeqType
   , @ArinvdAmount           AmountType
   , @ArinvdAcct             AcctType
   , @ArinvdAcctUnit1        UnitCode1Type
   , @ArinvdAcctUnit2        UnitCode2Type
   , @ArinvdAcctUnit3        UnitCode3Type
   , @ArinvdAcctUnit4        UnitCode4Type
   , @ArinvdTaxSystem        TaxSystemType
   , @ArinvdTaxBasis         AmountType
   , @ArinvdTaxCode          TaxCodeType
   , @ArinvdTaxCodeE         TaxCodeType
   , @TaxcodeRowPointer      RowPointerType
   , @TaxcodeTaxRate         TaxRateType
   , @TaxcodeTaxJur          TaxJurType
   , @InvStaxInvNum          InvNumType
   , @InvStaxInvSeq          InvSeqType
   , @InvStaxSeq             StaxSeqType
   , @InvStaxInvDate         DateType
   , @InvStaxTaxCode         TaxCodeType
   , @InvStaxStaxAcct        AcctType
   , @InvStaxStaxAcctUnit1   UnitCode1Type
   , @InvStaxStaxAcctUnit2   UnitCode2Type
   , @InvStaxStaxAcctUnit3   UnitCode3Type
   , @InvStaxStaxAcctUnit4   UnitCode4Type
   , @InvStaxSalesTax        AmountType
   , @InvStaxCustNum         CustNumType
   , @InvStaxCustSeq         CustSeqType
   , @InvStaxTaxBasis        AmountType
   , @InvStaxTaxSystem       TaxSystemType
   , @InvStaxTaxRate         TaxRateType
   , @InvStaxTaxJur          TaxJurType
   , @InvStaxTaxCodeE        TaxCodeType
   , @ExtFinSite             SiteType        -- Extfin
   , @ExtFinParmsRowPointer  RowPointerType  -- Extfin
   , @ExtFinUseExternalAR    ListYesNoType   -- Extfin
   , @ExtFinUseExtFin        ListYesNoType   -- Extfin
   , @ArinvRma               ListYesNoType   -- Extfin
   , @ArinvDraftPrintFlag    ListYesNoType   -- Extfin
   , @ArinvdInvSeq           ArInvSeqType    -- Extfin
   , @ArinvdRefType          RefTypeOType    -- Extfin
   , @ExtFinRowPointer        RowPointerType       -- Extfin
   , @ArinvdNoteExistsFlag    FlagNyType           -- Extfin
   , @LastSeq     JournalSeqType
   , @JournalRowPointer   RowPointerType
   , @ArinvApprovalStatus ListPendingApprovedRejectedType
   , @ArinvApplyToInvNum  InvNumType
   , @ArinvBuilderInvOrigSite  SiteType
   , @ArinvBuilderInvNum       BuilderInvNumType
   , @ArtranBuilderInvOrigSite SiteType
   , @ArtranBuilderInvNum      BuilderInvNumType
   , @ArtranPostSite           SiteType
   , @CoSlsman                 SlsmanType
   , @ArinvCancellation        ListYesNoType
   , @ArinvCNVatInvNum         InvNumType
   , @ArinvCNStaxSalesTax      AmountType
   , @InvStaxSeqFirst          ArInvSeqType
   , @InvStaxSalesTaxSum       AmountType
   , @Inv_GainLossAmt          AmountType
   , @ApplyToInvExchRate       ExchRateType
   , @TaxMode                  TaxModeType
   , @PLManualVATInvoice InvNumType

   DECLARE
     @ControlPrefix JourControlPrefixType
   , @ControlSite SiteType
   , @ControlYear FiscalYearType
   , @ControlPeriod FinPeriodType
   , @ControlNumber LastTranType
   , @OutOfPeriod         INT  
   , @Closed              ListYesNoType  
   , @FiscalYear          FiscalYearType  


   DECLARE
      @UseMultipleDueDates ListYesNoType
    , @MultiTermsRowPointer RowPointerType
    , @TotDueDateAmounts AmountType
    , @TotArinvAmount AmountType
    , @ExportBatchID  OperationCounterType
    , @ExportBatchSeq OperationCounterType
    , @ArTermsDueCustNum CustNumType
    , @ArTermsDueInvNum  InvNumType
    , @ArTermsDueInvSeq  InvSeqType
    , @ArTermsDueSeq     SequenceType
    , @ArTermsDueDueDate DateType
    , @ArTermsDuePercent TermsPercentType
    , @ArTermsDueAmount  AmountType

   DECLARE
     @ProjNum                ProjNumType
   , @AdvPmtDeductedAmt      AmountType
   , @AdvPmtToBeDeductedAmt  AmountType
   , @RowPointer             RowPointerType
   , @ARExistsFlag           ListYesNoType

   , @CurrparmsCurrCode CurrCodeType
   , @CurrparmsGainAcct AcctType
   , @CurrparmsGainAcctUnit1 UnitCode1Type
   , @CurrparmsGainAcctUnit2 UnitCode2Type
   , @CurrparmsGainAcctUnit3 UnitCode3Type
   , @CurrparmsGainAcctUnit4 UnitCode4Type
   , @CurrparmsLossAcct AcctType
   , @CurrparmsLossAcctUnit1 UnitCode1Type
   , @CurrparmsLossAcctUnit2 UnitCode2Type
   , @CurrparmsLossAcctUnit3 UnitCode3Type
   , @CurrparmsLossAcctUnit4 UnitCode4Type
   , @CurracctRowPointer RowPointerType
   , @CurracctGainAcct AcctType
   , @CurracctGainAcctUnit1 UnitCode1Type
   , @CurracctGainAcctUnit2 UnitCode2Type
   , @CurracctGainAcctUnit3 UnitCode3Type
   , @CurracctGainAcctUnit4 UnitCode4Type
   , @CurracctLossAcct AcctType
   , @CurracctLossAcctUnit1 UnitCode1Type
   , @CurracctLossAcctUnit2 UnitCode2Type
   , @CurracctLossAcctUnit3 UnitCode3Type
   , @CurracctLossAcctUnit4 UnitCode4Type
   , @GainLossAcct AcctType
   , @GainLossUnit1 UnitCode1Type
   , @GainLossUnit2 UnitCode2Type
   , @GainLossUnit3 UnitCode3Type
   , @GainLossUnit4 UnitCode4Type

   DECLARE
      @adv_pmt_deducted_amt_total        AmtTotType
    , @adv_pmt_to_be_deducted_amt_total  AmtTotType
    , @adv_pmt_invoiced_amt_total        AmtTotType

   DECLARE
      @proxdiscday int
    , @ProxDiscMonthToForward int
    , @IsCNOn                 INT

   DECLARE @SSSFSInclSROInOnOrdBal   ListYesNoType   -- SSS added
   DECLARE @IsControlNumberCreated   ListYesNoType

   SET @SSSFSInclSROInOnOrdBal = 1   -- SSS added
   SET @ARExistsFlag = 0
   SET @TId = 'AR Dist'
   SET @IsControlNumberCreated = 0
   SET @InvStaxSalesTaxSum = 0

   SELECT
     @CurrparmsCurrCode      = currparms.curr_code
   , @CurrparmsGainAcct      = currparms.gain_acct
   , @CurrparmsGainAcctUnit1 = currparms.gain_acct_unit1
   , @CurrparmsGainAcctUnit2 = currparms.gain_acct_unit2
   , @CurrparmsGainAcctUnit3 = currparms.gain_acct_unit3
   , @CurrparmsGainAcctUnit4 = currparms.gain_acct_unit4
   , @CurrparmsLossAcct      = currparms.loss_acct
   , @CurrparmsLossAcctUnit1 = currparms.loss_acct_unit1
   , @CurrparmsLossAcctUnit2 = currparms.loss_acct_unit2
   , @CurrparmsLossAcctUnit3 = currparms.loss_acct_unit3
   , @CurrparmsLossAcctUnit4 = currparms.loss_acct_unit4
   FROM currparms WITH (READUNCOMMITTED)

   SELECT @IsCNOn = dbo.IsAddonAvailable('ChinaCountryPack')
   SET @TaxparmsRowPointer     = NULL
   SET @TaxparmsLastTaxReport1 = NULL

   SELECT
     @TaxparmsRowPointer     = taxparms.RowPointer
   , @TaxparmsLastTaxReport1 = taxparms.last_tax_report_1
   FROM taxparms

   IF @TaxparmsRowPointer IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExistFor'
      , '@taxparms'
      GOTO ERROR_OUT
   END

   SET @ArparmsRowPointer = NULL

   SELECT
    @ArparmsRowPointer = arparms.RowPointer
   ,@ArparmsDiscAcct   = arparms.disc_acct
   FROM arparms

   IF @ArparmsRowPointer IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExistFor'
      , '@arparms'
      GOTO ERROR_OUT
   END

   SET @ParmsRowPointer  = NULL

   SELECT
     @ParmsRowPointer  = parms.RowPointer
   , @ParmsEcReporting = parms.ec_reporting
   , @ParmsCountry     = parms.country
   , @ParmsSite        = parms.site
   FROM parms

   IF @ParmsRowPointer IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExistFor'
      , '@parms'
      GOTO ERROR_OUT
   END

   -- Begin ExtFin changes
   SET @ExtFinParmsRowPointer = NULL

   SELECT
     @ExtFinParmsRowPointer = extfin_parms.RowPointer
   --, @ExtFinSite            = extfin_parms.extfin_site
   , @ExtFinUseExternalAR   = extfin_parms.use_external_ar
   , @ExtFinUseExtFin       = extfin_parms.use_extfin
   FROM extfin_parms

   IF @ExtFinParmsRowPointer IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExistFor'
      , '@extfin_parms'
      GOTO ERROR_OUT
   END
   -- End ExtFin changes

   SET @ArinvRowPointer = NULL

   IF (dbo.IsInteger(@PInvNum)=1 AND CONVERT(BIGINT,@PInvNum)=0)
      SET @PInvNum = '0'

   SELECT
     @ArinvRowPointer      = arinv.RowPointer
   , @ArinvAcct            = arinv.acct
   , @ArinvCustNum         = arinv.cust_num
   , @ArinvInvNum          = arinv.inv_num
   , @ArinvInvDate         = arinv.inv_date
   , @ArinvDueDate         = arinv.due_date
   , @ArinvType            = arinv.type
   , @ArinvPostFromCo      = arinv.post_from_co
   , @ArinvInvSeq          = arinv.inv_seq
   , @ArinvCoNum           = arinv.co_num
   , @ArinvDoNum           = arinv.do_num
   , @ArinvAcctUnit1       = arinv.acct_unit1
   , @ArinvAcctUnit2       = arinv.acct_unit2
   , @ArinvAcctUnit3       = arinv.acct_unit3
   , @ArinvAcctUnit4       = arinv.acct_unit4
   , @ArinvDescription     = arinv.description
   , @ArinvAmount          = arinv.amount
   , @ArinvMiscCharges     = arinv.misc_charges
   , @ArinvSalesTax        = arinv.sales_tax
   , @ArinvSalesTax2       = arinv.sales_tax_2
   , @ArinvFreight         = arinv.freight
   , @ArinvExchRate        = arinv.exch_rate
   , @ArinvFixedRate       = arinv.fixed_rate
   , @ArinvPayType         = arinv.pay_type
   , @ArinvRef             = arinv.ref
   , @ArinvTermsCode       = arinv.terms_code
   , @ArinvUseExchRate     = arinv.use_exch_rate
   , @ArinvTaxCode1        = arinv.tax_code1
   , @ArinvTaxCode2        = arinv.tax_code2
   , @ArinvNoteExistsFlag  = arinv.NoteExistsFlag
   , @ArinvRma             = arinv.rma              -- Extfin
   , @ArinvDraftPrintFlag  = arinv.draft_print_flag -- Extfin
   , @ArinvApprovalStatus  = arinv.approval_status  -- Extfin
   , @ArinvApplyToInvNum   = arinv.apply_to_inv_num
   , @ArinvReturnedCheck   = arinv.returned_check
   , @ArinvShipmentId      = arinv.shipment_id
   , @ArinvBuilderInvOrigSite = arinv.builder_inv_orig_site
   , @ArinvBuilderInvNum   = arinv.builder_inv_num
   , @ArinvCancellation    = arinv.cancellation
   , @ArinvCNVatInvNum     = arinv.CN_vat_inv_num
   , @ArinvCNStaxSalesTax  = arinv.CN_vat_sales_tax
   , @ArinvCurrCode        = arinv.curr_code
   , @ArinvCNComment       = arinv.CN_comment
   , @ArinvTaxDate         = arinv.tax_date
   , @PLManualVATInvoice   = PL_manual_vat_invoice
   FROM arinv WITH (UPDLOCK)
   WHERE arinv.cust_num = @PCustNum
   AND   arinv.inv_num  = @PInvNum
   AND   arinv.inv_seq  = @PInvSeq

   IF @ArinvRowPointer IS NULL
   BEGIN
      EXEC dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExist3'
      , '@arinv'
      , '@arinv.cust_num'
      , @PCustNum
      , '@arinv.inv_num'
      , @PInvNum
      , '@arinv.inv_seq'
      , @PInvSeq

      GOTO ERROR_OUT
   END

   SET @AmountPosted = 0

   SET @ChartRowPointer = NULL

   SELECT
     @ChartRowPointer = chart.RowPointer
   FROM chart
   WHERE chart.acct = @ArinvAcct

   IF @ChartRowPointer IS NULL OR @ArinvAcct IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExistFor3'
                       , '@chart'
                       , '@arinv'
                       , '@arinv.cust_num'
                       , @ArinvCustNum
                       , '@arinv.inv_num'
                       , @ArinvInvNum
                       , '@arinv.acct'
                       , @ArinvAcct

      GOTO ERROR_OUT
   END

   SELECT @ApplyToInvExchRate = artran.exch_rate
   FROM artran
   WHERE artran.cust_num = @ArinvCustNum
   AND   artran.inv_num  = @ArinvApplyToInvNum
   AND   artran.type = 'I'

   EXEC @Severity = dbo.PerGetSp
                      @Date              = @ArinvInvDate
                    , @CurrentPeriod     = @CurrentPeriod     OUTPUT
                    , @PeriodsRowPointer = @PeriodsRowPointer OUTPUT
                    , @Site              = @ParmsSite
                    , @Infobar           = @Infobar           OUTPUT

   IF @Severity <> 0
      GOTO ERROR_OUT

      EXEC @Severity = dbo.CheckPermissionOnTransDateSp  
               @PTransDate    = @ArinvInvDate
             , @OutOfPeriod   = @OutOfPeriod OUTPUT
             , @Closed        = @Closed  OUTPUT
             , @FiscalYear    = @FiscalYear OUTPUT
             , @TransPeriod   = @CurrentPeriod OUTPUT
             , @Infobar       = @Infobar OUTPUT

      IF  @Closed = 1
      BEGIN
         EXEC @Severity = dbo.MsgAppSp
                           @Infobar OUTPUT,
                           'E=IsCompare2',
                           '@periods.closed',
                           '@:ListYesNo:1',
                           '@periods',
                           '@periods.fiscal_year',
                           @FiscalYear,
                           '@:periods_seq.sequence_by:P',
                           @CurrentPeriod
         GOTO ERROR_OUT
      END

   SET @CustomerRowPointer = NULL

   SELECT
     @CustomerRowPointer = customer.RowPointer
   , @CustomerSalesYtd   = customer.sales_ytd
   , @CustomerSalesPtd   = customer.sales_ptd
   , @CustomerLastInv    = customer.last_inv
   , @CustomerOrderBal   = customer.order_bal
   , @CustomerPostedBal  = customer.posted_bal
   , @CustomerDiscYtd    = customer.disc_ytd
   FROM customer WITH (UPDLOCK)
   WHERE customer.cust_num = @ArinvCustNum
   AND   customer.cust_seq = 0

   IF @CustomerRowPointer IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExistFor2'
                       , '@customer'
                       , '@arinv'
                       , '@arinv.cust_num'
                       , @ArinvCustNum
                       , '@arinv.inv_num'
                       , @ArinvInvNum

      GOTO ERROR_OUT
   END

   SET @CustaddrRowPointer = NULL

   SELECT
     @CustaddrRowPointer = custaddr.RowPointer
   , @CustaddrCorpCust   = custaddr.corp_cust
   , @CustaddrCountry    = custaddr.country
   , @CustaddrCurrCode   = custaddr.curr_code
   , @CustaddrCorpCred   = custaddr.corp_cred
   FROM custaddr
   WHERE custaddr.cust_num = @ArinvCustNum
   AND   custaddr.cust_seq = 0

   IF @CustaddrRowPointer IS NULL
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExistFor2'
                       , '@custaddr'
                       , '@arinv'
                       , '@arinv.cust_num'
                       , @ArinvCustNum
                       , '@arinv.inv_num'
                       , @ArinvInvNum

      GOTO ERROR_OUT
   END

   SET @CurrencyRowPointer = NULL

   SELECT
     @CurrencyRowPointer    = currency.RowPointer
   , @CurrencyPlaces        = currency.places
   , @CurrencyRateIsDivisor = currency.rate_is_divisor
   FROM currency
   WHERE currency.curr_code = @ArinvCurrCode

   IF @CurrencyRowPointer IS NULL
   BEGIN
      EXEC dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExist1'
      , '@currency'
      , '@currency.curr_code'
      , @CustaddrCurrCode
      GOTO ERROR_OUT
   END

   IF LTrim(RTrim(@ArinvApplyToInvNum)) = '0'
   BEGIN
      SET @ShipCustaddrRowPointer = NULL

      SELECT
        @ShipCustaddrRowPointer = custaddr.RowPointer
      , @ShipCustaddrState      = custaddr.state
      FROM custaddr
      WHERE custaddr.cust_num = @ArinvCustNum
      AND   custaddr.cust_seq = 0

      IF @ShipCustaddrRowPointer IS NULL
      BEGIN
         EXEC dbo.MsgAppSp @Infobar OUTPUT
         , 'E=NoExist2'
         , '@custaddr'
         , '@custaddr.cust_num'
         , @ArinvCustNum
         , '@custaddr.cust_seq'
         , 0
         GOTO ERROR_OUT
      END
   END
   ELSE
   BEGIN -- lookup the shipto
      SET @InvHdrRowPointer = NULL

      SELECT TOP 1
        @InvHdrRowPointer = inv_hdr.RowPointer
      , @InvHdrCoNum      = inv_hdr.co_num
      , @InvHdrCustNum    = inv_hdr.cust_num
      , @InvHdrCustSeq    = inv_hdr.cust_seq
      , @InvHdrInvSeq     = inv_hdr.inv_seq
      FROM inv_hdr
      WHERE inv_hdr.inv_num = @ArinvInvNum
      AND   inv_hdr.co_num IS NOT NULL

      IF @InvHdrRowPointer IS NULL  -- This invoice not from an order
      BEGIN
         SET @ShipCustaddrRowPointer = NULL

         SELECT
           @ShipCustaddrRowPointer = custaddr.RowPointer
         , @ShipCustaddrState      = custaddr.state
         FROM custaddr
         WHERE custaddr.cust_num = @ArinvCustNum
         AND   custaddr.cust_seq = 0

         IF @ShipCustaddrRowPointer IS NULL
         BEGIN
            EXEC dbo.MsgAppSp @Infobar OUTPUT
            , 'E=NoExist2'
            , '@custaddr'
            , '@custaddr.cust_num'
            , @ArinvCustNum
            , '@custaddr.cust_seq'
            , 0
            GOTO ERROR_OUT
         END
      END -- IF @InvHdrRowPointer IS NULL
      ELSE
      BEGIN
         SET @CoRowPointer = NULL        
         
         IF (dbo.IsAddonAvailable('ServiceManagement') = 1 OR dbo.IsAddonAvailable('ServiceManagementM') = 1
            OR dbo.IsAddonAvailable('ServiceManagement_MS') = 1 OR dbo.IsAddonAvailable('ServiceManagementM_MS') = 1)
         BEGIN


            EXEC @Severity = dbo.EXTSSSFSInvPostingSp
                       @ArinvInvNum
                     , @CoRowPointer OUTPUT
                     , @CoCustNum OUTPUT
                     , @CoCustSeq OUTPUT
                     , @Infobar OUTPUT
                     , @SSSFSInclSROInOnOrdBal OUTPUT
         END

         IF @CoRowPointer IS NULL
         BEGIN
            SELECT
              @CoRowPointer = co.RowPointer
            , @CoCustNum    = co.cust_num
            , @CoCustSeq    = co.cust_seq
            FROM co WITH (READUNCOMMITTED)
            WHERE co.co_num = @InvHdrCoNum
         END

         IF @CoRowPointer IS NOT NULL
         BEGIN
            SET @FindCustNum = @CoCustNum
            SET @FindCustSeq = @CoCustSeq
         END
         ELSE
         BEGIN
            SET @CohRowPointer = NULL

            SELECT
              @CohRowPointer = coh.RowPointer
            , @CohCustNum    = coh.cust_num
            , @CohCustSeq    = coh.cust_seq
            FROM coh
            WHERE coh.co_num = @InvHdrCoNum

            IF @CohRowPointer IS NOT NULL
            BEGIN
               SET @FindCustNum = @CohCustNum
               SET @FindCustSeq = @CohCustSeq
            END
            ELSE
            BEGIN
               SET @FindCustNum = @InvHdrCustNum
               SET @FindCustSeq = @InvHdrCustSeq
            END
         END -- ELSE @CoRowPointer

         SET @ShipCustaddrRowPointer = NULL
         SET @ShipCustaddrState      = NULL

         SELECT
           @ShipCustaddrRowPointer = custaddr.RowPointer
         , @ShipCustaddrState      = custaddr.state
         FROM custaddr
         WHERE custaddr.cust_num = @FindCustNum
         AND   custaddr.cust_seq = @FindCustSeq

         IF @ShipCustaddrRowPointer IS NULL
         BEGIN
            EXEC dbo.MsgAppSp @Infobar OUTPUT
            , 'E=NoExist2'
            , '@custaddr'
            , '@custaddr.cust_num'
            , @FindCustNum
            , '@custaddr.cust_seq'
            , @FindCustSeq
            GOTO ERROR_OUT
         END
         
   IF ISNULL(@PolandCountryPackOn, 0) = 1 /*RS8518_2*/ AND  @FeatureRS8518_2Active = 1 /*RS8518_2*/    
         BEGIN
         
            UPDATE inv_hdr
            SET inv_hdr.tax_date = @ArinvTaxDate
            WHERE inv_hdr.inv_num = @ArinvInvNum
            AND inv_hdr.inv_seq = @ArinvInvSeq
            
            UPDATE inv_item
            SET inv_item.tax_date = @ArinvTaxDate
            WHERE inv_item.inv_num = @ArinvInvNum
            AND inv_item.inv_seq = @ArinvInvSeq
            
         END

      END -- ELSE @InvHdrRowPointer
   END -- Lookup the Shipto

   IF dbo.IsAddonAvailable('TaxInterface') = 1
   and isnull(@Category, '') != 'Chargeback'
   BEGIN
      DECLARE
        @SessionId           RowPointerType
      , @ReleaseTmpTaxTables FlagNyType

      SET @SessionId = dbo.SessionIDSp()
      EXEC @Severity = dbo.UseTmpTaxTablesSp @SessionId, @ReleaseTmpTaxTables OUTPUT, @Infobar OUTPUT

      IF @ArinvTaxCode1 IN ('EXTUSE','EXTRNL','EXTMFG')  AND @ArinvPostFromCO = 0
      BEGIN
         EXEC @Severity = dbo.TaxBaseSp
                          @PInvType       = 'AR'
                        , @PType          = 'I'
                        , @PTaxCode1      = @ArinvTaxCode1
                        , @PTaxCode2      = @ArinvTaxCode2
                        , @PAmount        = @ArinvAmount
                        , @PAmountToApply = 0
                        , @PUndiscAmount  = @ArinvAmount
                        , @PUWsPrice      = NULL
                        , @PTaxablePrice  = NULL
                        , @PQtyInvoiced   = NULL
                        , @PCurrCode      = @ArinvCurrCode
                        , @PInvDate       = @ArinvInvDate
                        , @PExchRate      = @ArinvExchRate
                        --@CalledFrom     = NULL
                        --@tpsProcessId   = NULL
                        , @Infobar        = @Infobar OUTPUT
                        , @pRefType       = 'ARP'
                        , @pHdrPtr        = @ArinvRowPointer
                        , @pLineRefType   = NULL
                        , @pLinePtr       = NULL

         IF @Severity <> 0
            GOTO ERROR_OUT

         EXEC @Severity = dbo.TaxCalcSp
                          @PInvType      = 'AR'
                        , @PTaxCode1     = @ArinvTaxCode1
                        , @PTaxCode2     = @ArinvTaxCode2
                        , @PFreight      = @ArinvFreight
                        , @PFrtTaxCode1  = NULL
                        , @PFrtTaxCode2  = NULL
                        , @PMisc         = @ArinvMiscCharges
                        , @PMiscTaxCode1 = NULL
                        , @PMiscTaxCode2 = NULL
                        , @PInvDate      = @ArinvInvDate
                        , @PTermsCode    = @ArinvTermsCode
                        , @PUseExchRate  = @ArinvUseExchRate
                        , @PCurrCode     = @ArinvCurrCode
                        , @PPlaces       = @CurrencyPlaces
                        , @PExchRate     = @ArinvExchRate
                        , @PSalesTax1    = @ArinvSalesTax  OUTPUT
                        , @PSalesTax2    = @ArinvSalesTax2 OUTPUT
                        , @Infobar       = @Infobar        OUTPUT
                        , @pRefType      = 'ARP'
                        , @pHdrPtr       = @ArinvRowPointer

         IF @Severity <> 0
            GOTO ERROR_OUT

      END

      IF @ReleaseTmpTaxTables = 1
         EXEC dbo.ReleaseTmpTaxTablesSp @SessionId

      IF @Severity <> 0
            GOTO ERROR_OUT

   END

   -- VALIDATE Invoice Number, Credit , Debit Memo Number
   SET @ArtranRowPointer = NULL
   SET @ArtranCustNum    = NULL

   SELECT TOP 1
   @ArtranRowPointer = artran.RowPointer
   , @ArtranInvNum     = artran.inv_num
   , @ArtranCustNum    = artran.cust_num
   , @ArtranActive     = artran.active
   , @ArtranInvSeq     = artran.inv_seq
   FROM artran
   WHERE artran.inv_num = @ArinvInvNum
   IF @ArtranRowPointer IS NOT NULL OR (dbo.IsInteger(@ArinvInvNum) = 1 and convert(BIGINT, @ArinvInvNum) <= 0)
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                  , 'E=CmdFailed'
                  , '@%post'

      IF @ArinvType = 'I'
           EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                  , 'E=Exist2'
                  , '@artran'
                  , '@artran.inv_num'
                  , @ArtranInvNum
                  , '@artran.cust_num'
                  , @ArtranCustNum
      ELSE IF @ArinvType = 'C'
           EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                  , 'E=Exist2'
                  , '@artran'
                  , '@artran.credit_memo'
                  , @ArtranInvNum
                  , '@artran.cust_num'
                  , @ArtranCustNum
      ELSE IF @ArinvType = 'D'
           EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                  , 'E=Exist2'
                  , '@artran'
                  , '@artran.debit_memo'
                  , @ArtranInvNum
                  , '@artran.cust_num'
                  , @ArtranCustNum

      GOTO ERROR_OUT
   END

   IF ( LTrim(RTrim(@ArinvApplyToInvNum)) <> '0' AND LTrim(RTrim(@ArinvApplyToInvNum)) <> '-1' ) and @ArinvType <> 'I'-- Non-open C/D
   BEGIN
      SET @ArtranRowPointer = NULL

      SELECT TOP 1
        @ArtranRowPointer = artran.RowPointer
      , @ArtranInvNum     = artran.inv_num
      , @ArtranCustNum    = artran.cust_num
      , @ArtranActive     = artran.active
      , @ArtranInvSeq     = artran.inv_seq
      FROM artran
      WHERE artran.cust_num = @ArinvCustNum
      AND   artran.inv_num  = @ArinvApplyToInvNum

      SET @ARExistsFlag = dbo.DefinedValue('ARWarningFlag')

      IF @ArtranRowPointer IS NULL AND (@ARExistsFlag is NULL OR @ARExistsFlag=0)
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                          , 'E=NoExistFor2'
                          , '@artran'
                          , '@arinv'
                          , '@arinv.cust_num'
                          , @ArinvCustNum
                          , '@arinv.inv_num'
                          , @ArinvApplyToInvNum

         SET @Severity = 4
         GOTO ERROR_OUT
      END

      IF ISNULL(@ArtranActive,0) = 0
      BEGIN
         EXEC @Severity = dbo.ARActiveSp
                            @pInvNum = @ArtranInvNum
                          , @CustNum = @PCustNum
                          , @pActive = 1
                          , @pMsg    = 0 -- Never give an error
                          , @Site = @ParmsSite
                          , @BatchUpdate = 0 -- tell sub-procedure to perform update
                          , @infobar = @Infobar OUTPUT

         IF @Severity <> 0
            GOTO ERROR_OUT
      END

   END -- ELSE IF @ArinvApplyToInvNum <> 0

   SET @TSeq = 0

   -- INITIALIZING VARS FOR TABLE INSERT
   SELECT
     @ArtranDiscDate   = NULL
   , @ArtranIssueDate  = NULL
   , @ArtranDiscAmt    = (0)

   SET @ArtranCustNum        = @ArinvCustNum
   SET @ArtranInvNum         = @ArinvInvNum
   SET @ArtranInvSeq         = @TSeq
   SET @ArtranType           = @ArinvType
   SET @ArtranCoNum          = @ArinvCoNum
   SET @ArtranDoNum          = @ArinvDoNum
   SET @ArtranInvDate        = @ArinvInvDate
   SET @ArtranDueDate        = CASE WHEN @ArinvType = 'C'
                                  THEN @ArinvInvDate
                                  ELSE @ArinvDueDate
                               END
   SET @ArtranAcct           = @ArinvAcct
   SET @ArtranAcctUnit1      = @ArinvAcctUnit1
   SET @ArtranAcctUnit2      = @ArinvAcctUnit2
   SET @ArtranAcctUnit3      = @ArinvAcctUnit3
   SET @ArtranAcctUnit4      = @ArinvAcctUnit4
   SET @ArtranDescription    = @ArinvDescription
   SET @ArtranAmount         = @ArinvAmount
   SET @ArtranMiscCharges    = @ArinvMiscCharges
   SET @ArtranSalesTax       = @ArinvSalesTax
   SET @ArtranSalesTax2      = @ArinvSalesTax2
   SET @ArtranFreight        = @ArinvFreight
   SET @ArtranExchRate       = @ArinvExchRate
   SET @ArtranCorpCust       = @CustaddrCorpCust
   SET @ArtranPostFromCo     = @ArinvPostFromCo
   SET @ArtranFixedRate      = @ArinvFixedRate
   SET @ArtranPayType        = @ArinvPayType
   SET @ArtranRef            = @ArinvRef
   SET @ArtranNoteExistsFlag = @ArinvNoteExistsFlag
   SET @ArtranShipmentId     = @ArinvShipmentId
   SET @ArtranBuilderInvOrigSite = @ArinvBuilderInvOrigSite
   SET @ArtranBuilderInvNum  = @ArinvBuilderInvNum
   SET @ArtranPostSite       = @PostSite

   IF @ArinvType = 'I' OR @ArinvType = 'D'
   BEGIN
      SET @TermsRowPointer = NULL

      SELECT
        @TermsRowPointer = terms.RowPointer
      , @TermsDiscDays   = terms.disc_days
      , @TermsDiscPct    = terms.disc_pct
      , @ProxDiscDay     = terms.prox_disc_day
      , @ProxDiscMonthToForward = terms.prox_disc_month_to_forward
      FROM terms
      WHERE terms.terms_code = @ArinvTermsCode

      IF @TermsRowPointer IS NOT NULL AND (@TermsDiscDays != 0 or @ProxDiscDay != 99)
      BEGIN
        IF @TermsDiscDays != 0
        BEGIN
          SET @ArtranDiscDate = DATEADD( DAY, @TermsDiscDays, @ArinvInvDate )
        END
        ELSE
        BEGIN
          SET @ArtranDiscDate = @ArinvInvDate
          IF @ProxDiscDay < DATEPART (DAY, @ArtranDiscDate)
            SET @ArtranDiscDate = dbo.StartOfNextMonth(@ArtranDiscDate)

           SET @ArtranDiscDate = DATEADD(MONTH, @ProxDiscMonthToForward, @ArtranDiscDate)
           SET @ArtranDiscDate = DATEADD( DAY, (@ProxDiscDay - DATEPART (DAY, @ArtranDiscDate)), @ArtranDiscDate)
        END

        SET @ArtranDiscAmt  = ROUND(@ArinvAmount * @TermsDiscPct / 100, @CurrencyPlaces)
      END
      ELSE
        SET @ArtranDiscDate = @ArinvInvDate

   END

   IF @ArinvPostFromCo = 1
      SET @ArtranIssueDate = @ArinvInvDate

   IF dbo.IsAddonAvailable('Automotive_Mfg') = 1
   BEGIN
      SELECT @AuPaymentRefType = cust_tp.AU_payment_ref_type
        FROM cust_tp
       WHERE cust_tp.cust_num = @ArtranCustNum AND cust_tp.cust_seq = 0

      IF @AuPaymentRefType = 'D' OR @AuPaymentRefType = 'I'
      BEGIN
         IF NOT EXISTS (SELECT 1 FROM inv_item
                             INNER JOIN edi_co ON edi_co.sym_co_num = inv_item.co_num AND edi_co.posted = 1 AND edi_co.cust_num = @ArtranCustNum
                             WHERE inv_item.inv_num = @ArtranInvNum )
         BEGIN
            SET @AuPaymentRefType = NULL
         END
      END
      ELSE
      BEGIN
         --insert AU_payment_ref_num from edi_co
         SELECT @AuExtPaymentRefNum = edi_co. AU_ext_payment_ref_num,
                 @AuPaymentRefType = cust_tp.AU_payment_ref_type,
                 @EdiCoNum = edi_co.CO_NUM,
                 @EdiCustPo = edi_co.cust_po
         FROM edi_co
         INNER JOIN cust_tp ON edi_co.cust_num = cust_tp.cust_num
         WHERE edi_co.sym_co_num = @ArtranCoNum and edi_co.posted = 1
      END

      IF @AuPaymentRefType = 'O'
         SET @AuExtPaymentRefNum = @EdiCoNum
      ELSE IF @AuPaymentRefType = 'I'
         SET @AuExtPaymentRefNum = @ArtranInvNum
      ELSE IF @AuPaymentRefType = 'D'
         SET @AuExtPaymentRefNum = @ArtranDoNum
      ELSE IF @AuPaymentRefType = 'C'
         SET @AuExtPaymentRefNum = @EdiCustPo
      ELSE IF @AuPaymentRefType = 'E'
         SET @AuExtPaymentRefNum = @AuExtPaymentRefNum
      ELSE
         SET @AuExtPaymentRefNum = NULL
   END

   INSERT INTO artran (
     disc_date
   , cust_num
   , inv_num
   , inv_seq
   , type
   , co_num
   , do_num
   , inv_date
   , due_date
   , acct
   , acct_unit1
   , acct_unit2
   , acct_unit3
   , acct_unit4
   , description
   , amount
   , misc_charges
   , sales_tax
   , sales_tax_2
   , tax_code1
   , tax_code2
   , freight
   , exch_rate
   , corp_cust
   , post_from_co
   , fixed_rate
   , pay_type
   , ref
   , NoteExistsFlag
   , disc_amt
   , issue_date
   , approval_status
   , apply_to_inv_num
   , rma
   , shipment_id
   , builder_inv_orig_site
   , builder_inv_num
   , post_site
   , AU_payment_ref_num
   , cancellation
   , curr_code
   , PL_manual_vat_invoice
   )
   VALUES (
     @ArtranDiscDate
   , @ArtranCustNum
   , @ArtranInvNum
   , @ArtranInvSeq
   , @ArtranType
   , @ArtranCoNum
   , @ArtranDoNum
   , @ArtranInvDate
   , @ArtranDueDate
   , @ArtranAcct
   , @ArtranAcctUnit1
   , @ArtranAcctUnit2
   , @ArtranAcctUnit3
   , @ArtranAcctUnit4
   , @ArtranDescription
   , @ArtranAmount
   , @ArtranMiscCharges
   , CASE WHEN @ISCNoN = 1 THEN ISNULL(@ArinvCNStaxSalesTax,@ArtranSalesTax) ELSE @ArtranSalesTax END
   , @ArtranSalesTax2
   , @ArinvTaxCode1
   , @ArinvTaxCode2
   , @ArtranFreight
   , @ArtranExchRate
   , @ArtranCorpCust
   , @ArtranPostFromCo
   , @ArtranFixedRate
   , @ArtranPayType
   , @ArtranRef
   , @ArtranNoteExistsFlag
   , @ArtranDiscAmt
   , @ArtranIssueDate
   , @ArinvApprovalStatus
   , @ArinvApplyToInvNum
   , @ArinvRma
   , @ArtranShipmentId
   , @ArtranBuilderInvOrigSite
   , @ArtranBuilderInvNum
   , @ArtranPostSite
   , @AuExtPaymentRefNum
   , @ArinvCancellation
   , @ArinvCurrCode
   , @PLManualVATInvoice 
   )

   SET @Severity = @@Error
   IF @Severity <> 0
      GOTO ERROR_OUT

   -- Copy the Notes to artran
   SET @ArtranRowPointer = NULL

   SELECT
      @ArtranRowPointer = artran.RowPointer
   FROM artran
   WHERE artran.cust_num   = @ArtranCustNum
   AND   artran.inv_num    = @ArtranInvNum
   AND   artran.inv_seq    = @ArtranInvSeq
   AND   artran.check_seq  = 0

   IF @ArtranRowPointer IS NULL
   BEGIN
      EXEC dbo.MsgAppSp @Infobar OUTPUT
      , 'E=NoExist4'
      , '@artran'
      , '@artran.cust_num'
      , @ArtranCustNum
      , '@artran.inv_num'
      , @ArtranInvNum
      , '@artran.inv_seq'
      , @ArtranInvSeq
      , '@artran.check_seq'
      , 0
      GOTO ERROR_OUT
   END

   EXEC @Severity = dbo.CopyNotesSp
                      @FromObject     = 'arinv'
                    , @FromRowPointer = @ArinvRowPointer
                    , @ToObject       = 'artran'
                    , @ToRowPointer   = @ArtranRowPointer

   IF @Severity <> 0
      GOTO ERROR_OUT
   -- If Finance Charges then Set the value of these variable so that the inv_stax record can be created
   If (LTrim(RTrim(@ArinvApplyToInvNum))) = '-1'
   BEGIN
      SET @InvHdrInvSeq  = 0
      SET @InvHdrInvNum  = @ArtranInvNum
   END

   IF @ArinvApplyToInvNum = '0' AND (@ArtranType = 'C' OR @ArtranType = 'O')
   BEGIN
      INSERT INTO artran_open (
        RowPointer
      , cust_num
      , inv_num
      , inv_seq
      , type
      , inv_date
      , exch_rate
      , amount
      , due_date
      , disc_amt
      , recpt_date
      , curr_code
      , misc_charges
      ) VALUES (
        @ArtranRowPointer
      , @ArtranCustNum
      , @ArtranInvNum
      , @ArtranInvSeq
      , @ArtranType
      , @ArtranInvDate
      , @ArtranExchRate
      , @ArtranAmount
      , @ArtranDueDate
      , @ArtranDiscAmt
      , @ArtranDueDate
      , @ArinvCurrCode
      , 0
      )
   END
   -- IF NOT POSTING FROM CO, NOR POSTING FINANCE CHARGE CR/DR,
   -- CREATE inv-hdr/inv-stax RECORDS
   IF (LTrim(RTrim(@ArinvApplyToInvNum)) = '0' or (LTrim(RTrim(@ArinvApplyToInvNum)) <> '-1' and LTrim(RTrim(@ArinvApplyToInvNum)) <> '-2')) AND ISNULL(@ArinvPostFromCo,0) = 0
   BEGIN
      SET @TSeq             = @ArtranInvSeq
      SET @InvHdrRowPointer = NULL
      SET @InvHdrNoteExists = 0

      SELECT
        @InvHdrRowPointer = inv_hdr.RowPointer
      , @InvHdrCoNum      = inv_hdr.co_num
      , @InvHdrCustNum    = inv_hdr.cust_num
      , @InvHdrCustSeq    = inv_hdr.cust_seq
      , @InvHdrInvSeq     = inv_hdr.inv_seq
      , @InvHdrNoteExists = inv_hdr.NoteExistsFlag
      FROM inv_hdr
      WHERE inv_hdr.inv_num = @ArtranInvNum
      AND   inv_hdr.inv_seq = @TSeq

      IF @InvHdrRowPointer IS NOT NULL AND @InvHdrNoteExists = 0
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                          , 'E=ExistForIsAndIs1'
                          , '@inv_hdr'
                          , '@inv_hdr.inv_num'
                          , @ArtranInvNum
                          , '@inv_hdr.inv_seq'
                          , @TSeq
                          , '@arinv'
                          , '@arinv.cust_num'
                          , @ArinvCustNum

         GOTO ERROR_OUT
      END -- IF @InvHdrRowPointer IS NOT NULL
      ELSE
      BEGIN
         SET @ProjInvHdrRowPointer = NULL

         SELECT
          @ProjInvHdrRowPointer = proj_inv_hdr.RowPointer
         FROM proj_inv_hdr
         WHERE proj_inv_hdr.inv_num = @ArtranInvNum

         SET @InvHdrInvNum      = @ArtranInvNum
         SET @InvHdrInvSeq      = @TSeq
         SET @InvHdrCustNum     = @ArtranCustNum
         SET @InvHdrCustSeq     = 0
         SET @InvHdrCoNum       = @ArtranCoNum
         SET @InvHdrInvDate     = @ArtranInvDate
         
         --Get TaxDate from Arinv if PolandCountryPack is ON    
         SET @InvHdrTaxDate =    
            CASE WHEN ISNULL(@PolandCountryPackOn, 0) = 1 /*RS8518_2*/ AND  @FeatureRS8518_2Active = 1 /*RS8518_2*/  
            THEN    
               @ArinvTaxDate 
            ELSE
               CASE WHEN @ArtranInvDate < @TaxparmsLastTaxReport1    
               AND @TaxparmsLastTaxReport1 IS NOT NULL    
               THEN @TaxparmsLastTaxReport1    
               ELSE @ArtranInvDate END   
            END  
  
         
         SET @InvHdrTermsCode    = @ArinvTermsCode
         SET @InvHdrUseExchRate  = @ArinvUseExchRate
         SET @InvHdrTaxCode1     = @ArinvTaxCode1
         SET @InvHdrTaxCode2     = @ArinvTaxCode2
         SET @InvHdrMiscCharges  = CASE WHEN @ArtranType = 'C'
                                      THEN @ArtranMiscCharges * -1
                                      ELSE @ArtranMiscCharges
                                   END
         SET @InvHdrFreight      = CASE WHEN @ArinvType = 'C'
                                      THEN @ArtranFreight * -1
                                      ELSE @ArtranFreight
                                   END
         SET @InvHdrPrice        = (@ArtranAmount      +
                                    @ArtranMiscCharges +
                                    @ArtranFreight     +
                                    @ArtranSalesTax    +
                                    @ArtranSalesTax2) *
                                   (CASE WHEN @ArtranType = 'C'
                                      THEN -1
                                      ELSE 1
                                    END)
         SET @InvHdrState        = @ShipCustaddrState
         SET @InvHdrBillType     = CASE WHEN @ProjInvHdrRowPointer IS NOT NULL
                                      THEN 'J'
                                      ELSE 'A'
                                   END
         SET @InvHdrExchRate     = @ArtranExchRate
         SET @InvHdrEcCode       = NULL

         SELECT @CoSlsman = slsman FROM co WHERE co_num = @InvHdrCoNum

         INSERT INTO inv_hdr (
           inv_num
         , inv_seq
         , cust_num
         , cust_seq
         , co_num
         , inv_date
         , tax_date
         , terms_code
         , use_exch_rate
         , tax_code1
         , tax_code2
         , misc_charges
         , freight
         , price
         , state
         , bill_type
         , exch_rate
         , ec_code
         , slsman
         , CN_vat_inv_num
         , curr_code
         , CN_comment
         )
         VALUES (
           @InvHdrInvNum
         , @InvHdrInvSeq
         , @InvHdrCustNum
         , @InvHdrCustSeq
         , @InvHdrCoNum
         , @InvHdrInvDate
         , @InvHdrTaxDate
         , @InvHdrTermsCode
         , @InvHdrUseExchRate
         , @InvHdrTaxCode1
         , @InvHdrTaxCode2
         , @InvHdrMiscCharges
         , @InvHdrFreight
         , @InvHdrPrice
         , @InvHdrState
         , @InvHdrBillType
         , @InvHdrExchRate
         , @InvHdrEcCode
         , @CoSlsman
         , CASE WHEN @IsCNOn = 1 THEN @ArinvCNVatInvNum ELSE NULL END
         , @ArinvCurrCode
         , @ArinvCNComment
         )

          END -- IF @InvHdrRowPointer IS NULL

      SET @TInvStaxSeq = 0

      -- SET EC-CODE OF 'BILL-TO' CUSTOMER
      IF @ParmsEcReporting = 1
      BEGIN

         IF @ParmsCountry <> @CustaddrCountry
         BEGIN
            -- Export?
            SET @CountryRowPointer = NULL
            SET @CountryEcCode     = NULL

            SELECT
              @CountryRowPointer = country.RowPointer
            , @CountryEcCode     = country.ec_code
            FROM country
            WHERE country.country = @CustaddrCountry

            SET @XCountryRowPointer = NULL
            SET @XCountryEcCode     = NULL

            SELECT
              @XCountryRowPointer = country.RowPointer
            , @XCountryEcCode     = country.ec_code
            FROM country
            WHERE country.country = @ParmsCountry

            SET @InvHdrEcCode = CASE WHEN
                                   (@CountryRowPointer IS NOT NULL AND
                                    @XCountryRowPointer IS NULL)
                                OR (@CountryRowPointer IS NOT NULL  AND
                                    @XCountryRowPointer IS NOT NULL AND
                                    @CountryEcCode <> @XCountryEcCode)
                                       THEN @CountryEcCode
                                       ELSE NULL
                                END

            IF @CountryEcCode IS NOT NULL
            BEGIN
               UPDATE inv_hdr
                  SET ec_code = @InvHdrEcCode
               WHERE inv_hdr.inv_num = @InvHdrInvNum
               AND   inv_hdr.inv_seq = @InvHdrInvSeq

               SET @Severity = @@ERROR
               IF @Severity <> 0
                  GOTO ERROR_OUT
            END -- IF @CountryEcCode IS NOT NULL

         END -- IF @ParmsCountry <> @CustaddrCountry

      END -- IF @ParmsEcReporting = 1
   END -- IF @ArinvInvNum >= 0 AND @ArinvPostFromCo = 0
   ELSE
   BEGIN
      IF @IsCNOn = 1 AND @ArinvPostFromCo = 1
      BEGIN
         UPDATE inv_hdr SET CN_vat_inv_num = @ArinvCNVatInvNum, CN_comment = @ArinvCNComment
         WHERE inv_num = @PInvNum AND inv_seq = @PInvSeq
      END
   END

   -- Copy the Notes to inv_hdr
   IF @ArinvNoteExistsFlag > 0
   BEGIN
     SET @InvHdrRowPointer = NULL

     SELECT
       @InvHdrRowPointer = inv_hdr.RowPointer
     FROM inv_hdr
     WHERE inv_hdr.inv_num = @ArtranInvNum
     AND   inv_hdr.inv_seq = @TSeq

     IF @InvHdrRowPointer IS NOT NULL
     BEGIN
        UPDATE inv_hdr
        SET NoteExistsFlag = 1
        WHERE inv_hdr.inv_num = @ArtranInvNum
        AND   inv_hdr.inv_seq = @TSeq

        EXEC @Severity = dbo.CopyNotesSp
                           @FromObject     = 'arinv'
                         , @FromRowPointer = @ArinvRowPointer
                         , @ToObject       = 'inv_hdr'
                         , @ToRowPointer   = @InvHdrRowPointer

        IF @Severity <> 0
           GOTO ERROR_OUT
     END

   END

   -- Start Advance Payment
   SELECT @ProjNum = proj_inv_hdr.proj_num,
          @RowPointer = proj_inv_hdr.RowPointer
   FROM proj_inv_hdr
      JOIN proj ON proj_inv_hdr.proj_num = proj.proj_num
   WHERE proj_inv_hdr.inv_num = @ArtranInvNum
      AND proj.type = 'P'

   IF @RowPointer IS NOT NULL
   BEGIN
      set @IsOrderForProject = 1
      SET @adv_pmt_deducted_amt_total        = 0
      SET @adv_pmt_to_be_deducted_amt_total  = 0
      SET @adv_pmt_invoiced_amt_total        = 0

      SELECT
         @adv_pmt_deducted_amt_total = @adv_pmt_deducted_amt_total + CASE WHEN (inv_ms.create_invoice_for_adv_pmt = 0
                                                                            AND inv_ms.adv_pmt_deduction_amt > 0 AND (proj_inv_item.amount##1 - proj_inv_item.inv_amt) > 0 )
                                                                          THEN inv_ms.adv_pmt_deduction_amt
                                                                          ELSE 0
                                                                      END
       , @adv_pmt_to_be_deducted_amt_total = @adv_pmt_to_be_deducted_amt_total - CASE WHEN (inv_ms.create_invoice_for_adv_pmt = 0
                                                                                        AND inv_ms.adv_pmt_deduction_amt > 0 AND (proj_inv_item.amount##1 - proj_inv_item.inv_amt) > 0)
                                                                                      THEN inv_ms.adv_pmt_deduction_amt
                                                                                      ELSE 0
                                                                                  END
       , @adv_pmt_invoiced_amt_total = @adv_pmt_invoiced_amt_total + CASE WHEN (inv_ms.create_invoice_for_adv_pmt <> 0)
                                                                          THEN proj_inv_item.amount##1 - isnull(proj_inv_item.amount##2,0) + isnull(proj_inv_item.amount##3,0) + isnull(proj_inv_item.amount##4,0)
                                                                          ELSE 0
                                                                      END
      FROM proj_inv_item
      INNER JOIN inv_ms ON inv_ms.inv_ms_num = proj_inv_item.inv_ms_num
                       AND inv_ms.proj_num   = proj_inv_item.proj_num      
      WHERE proj_inv_item.proj_num = @ProjNum
        AND proj_inv_item.inv_num  = @ArtranInvNum

      UPDATE proj
      SET adv_pmt_deducted_amt       = adv_pmt_deducted_amt       + @adv_pmt_deducted_amt_total
        , adv_pmt_to_be_deducted_amt = adv_pmt_to_be_deducted_amt + @adv_pmt_to_be_deducted_amt_total
        , adv_pmt_invoiced_amt       = adv_pmt_invoiced_amt       + @adv_pmt_invoiced_amt_total
      WHERE proj.proj_num = @ProjNum
        AND proj.type = 'P'

   END
   -- End Advance Payment

   -- Begin ExtFin changes
   IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAR = 1
   BEGIN
   SET @Infobar = NULL

       IF @PostExtFin = 0
       BEGIN
         EXEC @Severity = dbo.GetARBatchCounterSp
                                                @ExtFinOperationCounter output
                                                 ,@Infobar OUTPUT
       END

         IF @Severity <> 0
          GOTO ERROR_OUT
   INSERT INTO export_arinv(
                            export_arinv.ar_batch_id,
                            --export_arinv.batch_seq,
                            export_arinv.cust_num,
                            export_arinv.inv_num,
                            export_arinv.inv_seq,
                            export_arinv.type,
                            export_arinv.co_num,
                            export_arinv.inv_date,
                            export_arinv.due_date,
                            export_arinv.acct,
                            export_arinv.amount,
                            export_arinv.misc_charges,
                            export_arinv.sales_tax,
                            export_arinv.freight,
                            export_arinv.ref,
                            export_arinv.terms_code,
                            export_arinv.description,
                            export_arinv.post_from_co,
                            export_arinv.exch_rate,
                            export_arinv.sales_tax_2,
                            export_arinv.use_exch_rate,
                            export_arinv.tax_code1,
                            export_arinv.tax_code2,
                            export_arinv.acct_unit1,
                            export_arinv.acct_unit2,
                            export_arinv.acct_unit3,
                            export_arinv.acct_unit4,
                            export_arinv.fixed_rate,
                            export_arinv.rma,
                            export_arinv.pay_type,
                            export_arinv.draft_print_flag,
                            export_arinv.do_num,
                            export_arinv.NoteExistsFlag,
                            export_arinv.approval_status,
                            export_arinv.apply_to_inv_num,
                            export_arinv.returned_check,
                            export_arinv.shipment_id,
                            export_arinv.cancellation,
                            export_arinv.curr_code,
                            export_arinv.tax_date
                          )
                   VALUES (
                            @ExtFinOperationCounter
                            ,@ArinvCustNum
                            ,@ArinvInvNum
                            ,@TSeq
                            ,@ArinvType
                            ,@ArinvCoNum
                            ,@ArinvInvDate
                            ,@ArinvDuedate
                            ,@ArinvAcct
                            ,@ArinvAmount
                            ,@ArinvMiscCharges
                            ,@ArinvSalesTax
                            ,@ArinvFreight
                            ,@ArinvRef
                            ,@ArinvTermsCode
                            ,@ArinvDescription
                            ,@ArinvPostFromCo
                            ,@ArinvExchRate
                            ,@ArinvSalesTax2
                            ,@ArinvUseExchRate
                            ,@ArinvTaxCode1
                            ,@ArinvTaxCode2
                            ,@ArinvAcctUnit1
                            ,@ArinvAcctUnit2
                            ,@ArinvAcctUnit3
                            ,@ArinvAcctUnit4
                            ,@ArinvFixedRate
                            ,@ArinvRma
                            ,@ArinvPayType
                            ,@ArinvDraftPrintFlag
                            ,@ArinvDoNum
                            ,@ArinvNoteExistsFlag
                            ,@ArinvApprovalStatus
                            ,@ArinvApplyToInvNum
                            ,@ArinvReturnedCheck
                            ,@ArinvShipmentId
                            ,@ArinvCancellation
                            ,@ArinvCurrCode
                            ,@ArinvTaxDate
                           )
   End
   -- End ExtFin changes

   --Multiple due date check starting

   SELECT @UseMultipleDueDates = terms.use_multi_due_dates
        , @MultiTermsRowPointer = terms.RowPointer
   FROM terms
   WHERE terms.terms_code = @ArinvTermsCode

   IF @UseMultipleDueDates = 1 AND @ArinvType <> 'C'
   BEGIN
      SELECT @TotDueDateAmounts = SUM(ar_terms_due.amount)
      FROM ar_terms_due
      WHERE ar_terms_due.cust_num = @ArinvCustNum
         AND ar_terms_due.inv_num = @ArinvInvNum
         AND ar_terms_due.inv_seq = @ArinvInvSeq

      SET @TotArinvAmount = @ArinvAmount + @ArinvMiscCharges + @ArinvFreight + @ArinvSalesTax + @ArinvSalesTax2
      IF @TotDueDateAmounts <> @TotArinvAmount
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                          , 'E=InvAmtNotMatching'
                          , @ArinvInvNum
         GOTO ERROR_OUT
      END
      ELSE
      BEGIN
         IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAR = 1
         BEGIN
            SELECT @ExportBatchID = export_arinv.ar_batch_id
                 , @ExportBatchSeq = export_arinv.batch_seq
            FROM export_arinv
            WHERE export_arinv.cust_num = @ArinvCustNum
               AND export_arinv.inv_num = @ArinvInvNum
               AND export_arinv.inv_seq = @ArinvInvSeq

            INSERT INTO export_ar_terms_due (
               export_ar_terms_due.ar_batch_id
             , export_ar_terms_due.batch_seq
             , export_ar_terms_due.cust_num
             , export_ar_terms_due.inv_num
             , export_ar_terms_due.inv_seq
             , export_ar_terms_due.seq
             , export_ar_terms_due.due_date
             , export_ar_terms_due.terms_percent
             , export_ar_terms_due.amount
            )
            SELECT @ExportBatchID
             , @ExportBatchSeq
             , ar_terms_due.cust_num
             , ar_terms_due.inv_num
             , ar_terms_due.inv_seq
             , ar_terms_due.seq
             , ar_terms_due.due_date
             , ar_terms_due.terms_percent
             , ar_terms_due.amount
            FROM ar_terms_due
            WHERE ar_terms_due.cust_num = @ArinvCustNum
               AND ar_terms_due.inv_num = @ArinvInvNum
               AND ar_terms_due.inv_seq = @ArinvInvSeq
         END
      END
   END
   --Multiple due date check ending

   set @ControlSite = @ParmsSite

   -- Credits
   SET @TotCr = 0

   DECLARE ArinvdCrs CURSOR LOCAL STATIC FOR
   SELECT
     arinvd.RowPointer
   , arinvd.ref_num
   , arinvd.ref_line_suf
   , arinvd.ref_release
   , arinvd.dist_seq
   , arinvd.amount
   , arinvd.acct
   , arinvd.acct_unit1
   , arinvd.acct_unit2
   , arinvd.acct_unit3
   , arinvd.acct_unit4
   , arinvd.tax_system
   , arinvd.tax_code
   , arinvd.tax_basis
   , arinvd.tax_code_e
   , arinvd.inv_seq      -- Extfin
   , arinvd.ref_type     -- Extfin
   , arinvd.NoteExistsFlag -- Extfin
   , arinvd.Uf_nomor_plat -- developer edit
   FROM arinvd
   WHERE arinvd.cust_num = @ArinvCustNum
   AND   arinvd.inv_num  = @ArinvInvNum
   AND   arinvd.inv_seq  = @ArinvInvSeq

Declare @nomorPlat varchar(50) --developer edit

   OPEN ArinvdCrs
   WHILE @Severity = 0
   BEGIN
      FETCH ArinvdCrs INTO
        @ArinvdRowPointer
      , @ArinvdRefNum
      , @ArinvdRefLineSuf
      , @ArinvdRefRelease
      , @ArinvdDistSeq
      , @ArinvdAmount
      , @ArinvdAcct
      , @ArinvdAcctUnit1
      , @ArinvdAcctUnit2
      , @ArinvdAcctUnit3
      , @ArinvdAcctUnit4
      , @ArinvdTaxSystem
      , @ArinvdTaxCode
      , @ArinvdTaxBasis
      , @ArinvdTaxCodeE
      , @ArinvdInvSeq     -- Extfin
      , @ArinvdRefType    -- Extfin
      , @ArinvdNoteExistsFlag --Extfin
      , @nomorPlat --developer edit
      IF @@FETCH_STATUS = -1
         BREAK

      IF ISNULL(@ArinvdAmount,0) <> 0
      BEGIN
         SET @ChartRowPointer = NULL

         SELECT
           @ChartRowPointer = chart.RowPointer
         FROM chart
         WHERE chart.acct = @ArinvdAcct

         IF @ChartRowPointer IS NULL
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                             , 'E=NoExistFor4'
                             , '@chart'
                             , '@arinvd'
                             , '@arinvd.cust_num'
                             , @ArinvCustNum
                             , '@arinvd.inv_num'
                             , @ArinvInvNum
                             , '@arinvd.dist_seq'
                             , @ArinvdDistSeq
                             , '@arinvd.acct'
                             , @ArinvdAcct

            GOTO ERROR_OUT
         END

         EXEC @Severity = dbo.ChkAcctSp
                            @acct    = @ArinvdAcct
                          , @date    = @ArinvInvDate
                          , @Infobar = @Infobar OUTPUT

         IF @Severity <> 0
            GOTO ERROR_OUT

         SET @ArinvdAmount = Round(@ArinvdAmount,@CurrencyPlaces)
         SET @TotCr = @TotCr + @ArinvdAmount

         EXEC @Severity = dbo.CurrcnvtSp
                           @CurrCode     = @ArinvCurrCode
                         , @FromDomestic = 0  -- To Domestic
                         , @UseBuyRate   = 0  -- Selling Rate
                         , @RoundResult  = 1  -- Use Rounding Factor
                         , @Date         = NULL
                         , @Infobar      = @Infobar              OUTPUT
                         , @Amount1      = @ArinvdAmount
                         , @Result1      = @DomesticArinvdAmount OUTPUT
                         , @TRate        = @ArinvExchRate        OUTPUT
                         , @Site = @ParmsSite

   -- save the discount amount for returned check
         IF @ArinvReturnedCheck = 1
         AND @ArparmsDiscAcct = @ArinvdAcct
         Begin
            SET @DomesticDisc = @DomesticArinvdAmount
         End

         IF @Severity <> 0
            GOTO ERROR_OUT

         SET @AmountToPost = CASE WHEN @ArinvType = 'C'
                                THEN @DomesticArinvdAmount
                                ELSE @DomesticArinvdAmount * -1
                             END

         SET @ForAmtToPost = CASE WHEN @ArinvType = 'C'
                                THEN @ArinvdAmount
                                ELSE @ArinvdAmount * -1
                             END

         EXEC @Severity = dbo.ChkUnitSp
                            @acct    = @ArinvdAcct
                          , @p_unit1 = @ArinvdAcctUnit1
                          , @p_unit2 = @ArinvdAcctUnit2
                          , @p_unit3 = @ArinvdAcctUnit3
                          , @p_unit4 = @ArinvdAcctUnit4
                          , @Infobar = @Infobar OUTPUT

         IF @Severity <> 0
            GOTO ERROR_OUT

         IF @IsControlNumberCreated = 0 AND @AmountToPost <> 0
         BEGIN
            EXEC @Severity = dbo.NextControlNumberSp
            @JournalId = @TId
            , @TransDate = @ArinvInvDate
            , @ControlPrefix = @ControlPrefix output
            , @ControlSite = @ControlSite output
            , @ControlYear = @ControlYear output
            , @ControlPeriod = @ControlPeriod output
            , @ControlNumber = @ControlNumber output
            , @Infobar = @Infobar OUTPUT
            IF @Severity  <> 0
               GOTO ERROR_OUT
            ELSE
               SET @IsControlNumberCreated = 1
         END

         SET @AmountPosted = @AmountPosted + @AmountToPost

         EXEC @Severity = dbo.extgen_JourpostSp
                          @id                = @TId
                        , @trans_date        = @ArinvInvDate
                        , @acct              = @ArinvdAcct
                        , @acct_unit1        = @ArinvdAcctUnit1
                        , @acct_unit2        = @ArinvdAcctUnit2
                        , @acct_unit3        = @ArinvdAcctUnit3
                        , @acct_unit4        = @ArinvdAcctUnit4
                        , @amount            = @AmountToPost
                        , @ref               = @ArinvRef
                        , @vend_num          = @ArinvCustNum
                        , @voucher           = @ArinvInvNum
                        , @ref_type          = @ArinvType
                        , @ref_num           = @ArinvdRefNum
                        , @ref_line_suf      = @ArinvdRefLineSuf
                        , @ref_release       = @ArinvdRefRelease
                        , @vouch_seq         = @TSeq
                        , @curr_code         = @ArinvCurrCode
                        , @for_amount        = @ForAmtToPost
                        , @exch_rate         = @ArinvExchRate
                        , @ControlPrefix     = @ControlPrefix
                        , @ControlSite       = @ControlSite
                        , @ControlYear       = @ControlYear
                        , @ControlPeriod     = @ControlPeriod
                        , @ControlNumber     = @ControlNumber
                        , @Cancellation      = @ArinvCancellation
                        , @last_seq          = @LastSeq OUTPUT
                        , @Infobar           = @Infobar OUTPUT
                        , @nomorPlat= @nomorPlat

         IF @Severity  <> 0
            GOTO ERROR_OUT

         --Initial invoice gain/loss.
         SET @Inv_GainLossAmt = 0

         --Calculate the invoice gain/loss of distribution when exchange rate is different between invoice and debit/credit.
         IF @ArinvExchRate <> @ApplyToInvExchRate
         BEGIN
            IF @CurrencyRateIsDivisor = 0
               SET @Inv_GainLossAmt = ROUND(@ForAmtToPost / @ApplyToInvExchRate - @ForAmtToPost / @ArinvExchRate, @CurrencyPlaces)
            ELSE
               SET @Inv_GainLossAmt = ROUND(@ForAmtToPost * @ApplyToInvExchRate - @ForAmtToPost * @ArinvExchRate, @CurrencyPlaces)

            SET @CurracctRowPointer = NULL
            SELECT
              @CurracctRowPointer    = curracct.RowPointer
            , @CurracctGainAcct      = curracct.gain_acct
            , @CurracctGainAcctUnit1 = curracct.gain_acct_unit1
            , @CurracctGainAcctUnit2 = curracct.gain_acct_unit2
            , @CurracctGainAcctUnit3 = curracct.gain_acct_unit3
            , @CurracctGainAcctUnit4 = curracct.gain_acct_unit4
            , @CurracctLossAcct      = curracct.loss_acct
            , @CurracctLossAcctUnit1 = curracct.loss_acct_unit1
            , @CurracctLossAcctUnit2 = curracct.loss_acct_unit2
            , @CurracctLossAcctUnit3 = curracct.loss_acct_unit3
            , @CurracctLossAcctUnit4 = curracct.loss_acct_unit4
            FROM curracct WITH (READUNCOMMITTED)
            WHERE curracct.curr_code = @ArinvCurrCode

            IF @CurracctRowPointer IS NOT NULL
            BEGIN -- found curracct

               IF @Inv_GainLossAmt < 0 -- GAIN
               BEGIN -- @Inv_GainLossAmt < 0
                  SET @ChartRowPointer = NULL
                  SET @ChartAcct       = NULL

                  SELECT
                    @ChartRowPointer = chart.RowPointer
                  , @ChartAcct       = chart.acct
                  FROM chart WITH (READUNCOMMITTED)
                  WHERE chart.acct = @CurracctGainAcct

                  IF @ChartRowPointer IS NULL OR @ChartAcct IS NULL
                  BEGIN
                     SET @ChartRowPointer = NULL
                     SET @ChartAcct       = NULL

                     SELECT
                       @ChartRowPointer = chart.RowPointer
                     , @ChartAcct       = chart.acct
                     FROM chart WITH (READUNCOMMITTED)
                     WHERE chart.acct = @CurrparmsGainAcct

                     IF @ChartRowPointer IS NOT NULL AND @ChartAcct IS NOT NULL
                     BEGIN
                        SET @GainLossAcct  = @CurrparmsGainAcct
                        SET @GainLossUnit1 = @CurrparmsGainAcctUnit1
                        SET @GainLossUnit2 = @CurrparmsGainAcctUnit2
                        SET @GainLossUnit3 = @CurrparmsGainAcctUnit3
                        SET @GainLossUnit4 = @CurrparmsGainAcctUnit4
                     END
                  END
                  ELSE
                  BEGIN
                     SET @GainLossAcct  = @CurracctGainAcct
                     SET @GainLossUnit1 = @CurracctGainAcctUnit1
                     SET @GainLossUnit2 = @CurracctGainAcctUnit2
                     SET @GainLossUnit3 = @CurracctGainAcctUnit3
                     SET @GainLossUnit4 = @CurracctGainAcctUnit4
                  END
               END -- @Inv_GainLossAmt < 0
               ELSE
               BEGIN -- @Inv_GainLossAmt > 0 -- LOSS
                  SET @ChartRowPointer = NULL
                  SET @ChartAcct       = NULL

                  SELECT
                    @ChartRowPointer = chart.RowPointer
                  , @ChartAcct       = chart.acct
                  FROM chart WITH (READUNCOMMITTED)
                  WHERE chart.acct = @CurracctLossAcct

                  IF @ChartRowPointer IS NULL OR @ChartAcct IS NULL
                  BEGIN
                     SET @ChartRowPointer = NULL
                     SET @ChartAcct       = NULL

                     SELECT
                       @ChartRowPointer = chart.RowPointer
                     , @ChartAcct       = chart.acct
                     FROM chart WITH (READUNCOMMITTED)
                     WHERE chart.acct = @CurrparmsLossAcct

                     IF @ChartRowPointer IS NOT NULL and @ChartAcct IS NOT NULL
                     BEGIN
                        SET @GainLossAcct  = @CurrparmsLossAcct
                        SET @GainLossUnit1 = @CurrparmsLossAcctUnit1
                        SET @GainLossUnit2 = @CurrparmsLossAcctUnit2
                        SET @GainLossUnit3 = @CurrparmsLossAcctUnit3
                        SET @GainLossUnit4 = @CurrparmsLossAcctUnit4
                     END
                  END
                  ELSE
                  BEGIN
                     SET @GainLossAcct  = @CurracctLossAcct
                     SET @GainLossUnit1 = @CurracctLossAcctUnit1
                     SET @GainLossUnit2 = @CurracctLossAcctUnit2
                     SET @GainLossUnit3 = @CurracctLossAcctUnit3
                     SET @GainLossUnit4 = @CurracctLossAcctUnit4
                  END
               END -- @Inv_GainLossAmt > 0

            END -- found curracct
            ELSE
            BEGIN -- Didn't find curracct
               IF @Inv_GainLossAmt < 0 -- GAIN
               BEGIN
                  SET @ChartRowPointer = NULL
                  SET @ChartAcct       = NULL

                  SELECT
                    @ChartRowPointer = chart.RowPointer
                  , @ChartAcct       = chart.acct
                  FROM chart WITH (READUNCOMMITTED)
                  WHERE chart.acct = @CurrparmsGainAcct

                  IF @ChartRowPointer IS NOT NULL and @ChartAcct IS NOT NULL
                  BEGIN
                     SET @GainLossAcct  = @CurrparmsGainAcct
                     SET @GainLossUnit1 = @CurrparmsGainAcctUnit1
                     SET @GainLossUnit2 = @CurrparmsGainAcctUnit2
                     SET @GainLossUnit3 = @CurrparmsGainAcctUnit3
                     SET @GainLossUnit4 = @CurrparmsGainAcctUnit4
                  END
               END
               ELSE
               BEGIN
                  SET @ChartRowPointer = NULL
                  SET @ChartAcct       = NULL

                  SELECT
                    @ChartRowPointer = chart.RowPointer
                  , @ChartAcct       = chart.acct
                  FROM chart WITH (READUNCOMMITTED)
                  WHERE chart.acct = @CurrparmsLossAcct

                  IF @ChartRowPointer IS NOT NULL and @ChartAcct IS NOT NULL
                  BEGIN
                     SET @GainLossAcct  = @CurrparmsLossAcct
                     SET @GainLossUnit1 = @CurrparmsLossAcctUnit1
                     SET @GainLossUnit2 = @CurrparmsLossAcctUnit2
                     SET @GainLossUnit3 = @CurrparmsLossAcctUnit3
                     SET @GainLossUnit4 = @CurrparmsLossAcctUnit4
                  END
               END

            END -- Didn't find curracct

            IF @ChartRowPointer IS NULL OR @ChartAcct IS NULL
            BEGIN -- Couldn't find a valid account
               IF @Inv_GainLossAmt < 0
               BEGIN
                  SET @Infobar = NULL
                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare'
                                 , '@parms.site'
                                 , @ParmsSite
                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistFor1'
                                 , '@chart'
                                 , '@parms'
                                 , '@currparms.gain_acct'
                                 , @CurrparmsGainAcct
                  GOTO ERROR_OUT
               END
               ELSE
               BEGIN
                  SET @Infobar = NULL
                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare'
                                 , '@parms.site'
                                 , @ParmsSite
                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistFor1'
                                 , '@chart'
                                 , '@parms'
                                 , '@currparms.loss_acct'
                                 , @CurrparmsLossAcct
                  GOTO ERROR_OUT
               END
            END -- Couldn't find a valid account

            EXEC @Severity = dbo.ChkUnitSp
                 @GainLossAcct
               , @GainLossUnit1
               , @GainLossUnit2
               , @GainLossUnit3
               , @GainLossUnit4
               , @Infobar OUTPUT

            IF @Severity <> 0
               GOTO ERROR_OUT

            SET @AmountPosted = @AmountPosted + @Inv_GainLossAmt
            --Log the journal for invoice gain/loss of distribution.
            EXEC @Severity = dbo.JourpostSp
                 @id                = @TId
               , @trans_date        = @ArinvInvDate
               , @acct              = @GainLossAcct
               , @acct_unit1        = @GainLossUnit1
               , @acct_unit2        = @GainLossUnit2
               , @acct_unit3        = @GainLossUnit3
               , @acct_unit4        = @GainLossUnit4
               , @amount            = @Inv_GainLossAmt
               , @ref               = 'ARX'
               , @vend_num          = @ArinvCustNum
               , @voucher           = @ArinvInvNum
               , @ref_type          = 'X'
               , @ref_num           = @ArinvdRefNum
               , @ref_line_suf      = @ArinvdRefLineSuf
               , @ref_release       = @ArinvdRefRelease
               , @vouch_seq         = @TSeq
               , @curr_code         = @CurrparmsCurrCode
               , @for_amount        = @Inv_GainLossAmt
               , @exch_rate         = 1
               , @ControlPrefix     = @ControlPrefix
               , @ControlSite       = @ControlSite
               , @ControlYear       = @ControlYear
               , @ControlPeriod     = @ControlPeriod
               , @ControlNumber     = @ControlNumber
               , @Cancellation      = @ArinvCancellation
               , @last_seq          = @LastSeq OUTPUT
               , @Infobar           = @Infobar OUTPUT

            IF @Severity  <> 0
               GOTO ERROR_OUT
         END -- IF @ArinvExchRate <> @ApplyToInvExchRate

         IF @ArinvdNoteExistsFlag > 0
         BEGIN -- copy notes
            SET @JournalRowPointer = NULL
            SELECT
              @JournalRowPointer = journal.RowPointer
            FROM journal
            WHERE journal.id = @TId and
            journal.seq = @LastSeq

            if @JournalRowPointer IS NOT NULL
            BEGIN
               EXEC @Severity = dbo.CopyNotesSp
                                'arinvd'
                              , @ArinvdRowPointer
                              , 'journal'
                              , @JournalRowPointer

               if @Severity <> 0
                  GOTO ERROR_OUT
            END
         END -- copy notes

      END -- IF @ArinvdAmount <> 0

      IF ISNULL(@ArinvPostFromCo,0) = 0 AND
         ISNULL(@ArinvdTaxSystem,0) <> 0
      BEGIN
         SET @TaxcodeRowPointer = NULL
         SELECT @TaxMode = tax_mode FROM tax_system WHERE tax_system = @ArinvdTaxSystem
         SELECT
           @TaxcodeRowPointer = taxcode.RowPointer
         , @TaxcodeTaxRate    = taxcode.tax_rate
         , @TaxcodeTaxJur     = taxcode.tax_jur
         FROM taxcode
         WHERE taxcode.tax_system    = @ArinvdTaxSystem
         AND   taxcode.tax_code_type = CASE WHEN @ArinvdTaxCode = 'EXTRNL' AND @TaxMode = 'I' THEN 'E' ElSE 'R' END
         AND   taxcode.tax_code      = @ArinvdTaxCode

         IF @TaxcodeRowPointer IS NULL
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                             , 'E=NoExistFor4'
                             , '@taxcode'
                             , '@arinvd'
                             , '@arinvd.cust_num'
                             , @ArinvCustNum
                             , '@arinvd.inv_num'
                             , @ArinvInvNum
                             , '@arinvd.dist_seq'
                             , @ArinvdDistSeq
                             , '@arinvd.tax_code'
                             , @ArinvdTaxCode

            GOTO ERROR_OUT
         END

         SET @TInvStaxSeq   = @TInvStaxSeq + 1

         SET @InvStaxInvNum        = @InvHdrInvNum
         SET @InvStaxInvSeq        = @InvHdrInvSeq
         SET @InvStaxSeq           = @TInvStaxSeq
         SET @InvStaxInvDate       =
               CASE WHEN (@TaxparmsLastTaxReport1 IS NOT NULL AND
                          @InvHdrInvDate < @TaxparmsLastTaxReport1)
                  THEN @TaxparmsLastTaxReport1
                  ELSE @InvHdrInvDate
               END
         SET @InvStaxTaxCode       = @ArinvdTaxCode
         SET @InvStaxStaxAcct      = @ArinvdAcct
         SET @InvStaxStaxAcctUnit1 = @ArinvdAcctUnit1
         SET @InvStaxStaxAcctUnit2 = @ArinvdAcctUnit2
         SET @InvStaxStaxAcctUnit3 = @ArinvdAcctUnit3
         SET @InvStaxStaxAcctUnit4 = @ArinvdAcctUnit4
         SET @InvStaxSalesTax      = CASE WHEN @ArinvType = 'C'
                                        THEN @ArinvdAmount * -1
                                        ELSE @ArinvdAmount
                                     END
         SET @InvStaxCustNum       = @InvHdrCustNum
         SET @InvStaxCustSeq       = @InvHdrCustSeq
         SET @InvStaxTaxBasis      = CASE WHEN @ArinvType = 'C'
                                        THEN @ArinvdTaxBasis * -1
                                        ELSE @ArinvdTaxBasis
                                     END
         SET @InvStaxTaxSystem     = @ArinvdTaxSystem
         SET @InvStaxTaxRate       = @TaxcodeTaxRate
         SET @InvStaxTaxJur        = @TaxcodeTaxJur
         SET @InvStaxTaxCodeE      = @ArinvdTaxCodeE

         INSERT INTO inv_stax (
           inv_stax.inv_num
         , inv_stax.inv_seq
         , inv_stax.seq
         , inv_stax.inv_date
         , inv_stax.tax_code
         , inv_stax.stax_acct
         , inv_stax.stax_acct_unit1
         , inv_stax.stax_acct_unit2
         , inv_stax.stax_acct_unit3
         , inv_stax.stax_acct_unit4
         , inv_stax.sales_tax
         , inv_stax.cust_num
         , inv_stax.cust_seq
         , inv_stax.tax_basis
         , inv_stax.tax_system
         , inv_stax.tax_rate
         , inv_stax.tax_jur
         , inv_stax.tax_code_e
         )
         VALUES (
           @InvStaxInvNum
         , @InvStaxInvSeq
         , @InvStaxSeq
         , @InvStaxInvDate
         , @InvStaxTaxCode
         , @InvStaxStaxAcct
         , @InvStaxStaxAcctUnit1
         , @InvStaxStaxAcctUnit2
         , @InvStaxStaxAcctUnit3
         , @InvStaxStaxAcctUnit4
         , @InvStaxSalesTax
         , @InvStaxCustNum
         , @InvStaxCustSeq
         , @InvStaxTaxBasis
         , @InvStaxTaxSystem
         , @InvStaxTaxRate
         , @InvStaxTaxJur
         , @InvStaxTaxCodeE
         )

         SET @Severity = @@Error
         IF @Severity <> 0
            GOTO ERROR_OUT

      END -- IF @ArinvPostFromCo = 0 AND @ArinvdTaxSystem <> 0
      IF @IsCNOn = 1 AND @ArinvPostFromCo = 1
      BEGIN
         SET @InvStaxSalesTax  = CASE WHEN @ArinvType = 'C'
                                 THEN @ArinvdAmount * -1
                                 ELSE @ArinvdAmount
                                 END
      END
      -- Begin ExtFin changes
      IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAR = 1
      BEGIN
      INSERT INTO export_arinvd (
                  export_arinvd.ar_batch_id,
                  --export_arinvd.batch_seq,
                  export_arinvd.cust_num,
                  export_arinvd.inv_num,
                  export_arinvd.inv_seq,
                  export_arinvd.dist_seq,
                  export_arinvd.acct,
                  export_arinvd.amount,
                  export_arinvd.tax_code,
                  export_arinvd.tax_basis,
                  export_arinvd.tax_system,
                  export_arinvd.tax_code_e,
                  export_arinvd.ref_type,
                  export_arinvd.ref_num,
                  export_arinvd.ref_line_suf,
                  export_arinvd.ref_release,
                  export_arinvd.acct_unit1,
                  export_arinvd.acct_unit2,
                  export_arinvd.acct_unit3,
                  export_arinvd.acct_unit4
                  --export_arinvd.NoteExistsFlag
               )
              VALUES (
                  @ExtFinOperationCounter

                  ,@ArinvCustNum
                  ,@ArinvInvNum
                  ,@TSeq
                  ,@ArinvdDistSeq
                  ,@ArinvdAcct
                  ,@ArinvdAmount
                  ,@ArinvdTaxCode
                  ,@ArinvdTaxBasis
                  ,@ArinvdTaxSystem
                  ,@ArinvdTaxCodeE
                  ,@ArinvdRefType
                  ,@ArinvdRefNum
                  ,@ArinvdRefLineSuf
                  ,@ArinvdRefRelease
                  ,@ArinvdAcctUnit1
                  ,@ArinvdAcctUnit2
                  ,@ArinvdAcctUnit3
                  ,@ArinvdAcctUnit4
                )
      END
      -- End ExtFin changes
      DELETE
      FROM arinvd
      WHERE arinvd.cust_num = @ArinvCustNum
      AND   arinvd.inv_num  = @ArinvInvNum
      AND   arinvd.inv_seq  = @ArinvInvSeq
      AND   arinvd.dist_seq = @ArinvdDistSeq

      SET @Severity = @@ERROR
      IF @Severity <> 0
         GOTO ERROR_OUT
   END
   CLOSE      ArinvdCrs
   DEALLOCATE ArinvdCrs

   IF @IsCNOn = 1
   BEGIN
      SELECT @InvStaxSalesTaxSum = SUM(sales_tax)
            ,@InvStaxSeqFirst    = MIN(seq)
      FROM inv_stax
      WHERE inv_num = @ArinvInvNum AND inv_seq = @ArinvInvSeq
        AND tax_system = @TaxSystem

      SET @InvStaxSalesTaxSum  = @ArinvCNStaxSalesTax - @InvStaxSalesTaxSum
   END

   IF @InvStaxSalesTaxSum <> 0 AND @InvStaxSalesTaxSum IS NOT NULL AND @IsCNOn = 1
   BEGIN
      UPDATE inv_stax SET sales_tax = ISNULL(sales_tax,0) + @InvStaxSalesTaxSum
      WHERE inv_stax.inv_num  = @ArinvInvNum
      AND   inv_stax.inv_seq  = @ArinvInvSeq
      AND   inv_stax.seq      = @InvStaxSeqFirst
   END

   -- Begin ExtFin changes
   IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAR = 1
      BEGIN
       SET @PostExtFin = 1
     END
   -- End ExtFin changes

   EXEC @Severity = dbo.CurrcnvtSp
                     @CurrCode     = @ArinvCurrCode
                   , @FromDomestic = 0  -- To Domestic
                   , @UseBuyRate   = 0  -- Selling Rate
                   , @RoundResult  = 1  -- Use Rounding Factor
                   , @Date         = NULL
                   , @Infobar      = @Infobar        OUTPUT
                   , @Amount1      = @ArinvAmount
                   , @Result1      = @DomesticAmount OUTPUT
                   , @TRate        = @ArinvExchRate  OUTPUT
                   , @Site = @ParmsSite

   IF @Severity <> 0
      GOTO ERROR_OUT

   SET @ForeignInvTotal = ROUND(@ArinvAmount,@CurrencyPlaces) +
                          ROUND(@ArinvMiscCharges,@CurrencyPlaces)+
                          CASE WHEN @ISCNoN = 1 AND @ArinvCNStaxSalesTax IS NOT NULL
                          THEN (ROUND(@ArinvCNStaxSalesTax,@CurrencyPlaces))
                          ELSE (ROUND(@ArinvSalesTax,@CurrencyPlaces) +
                          ROUND(@ArinvSalesTax2,@CurrencyPlaces))END +
                          ROUND(@ArinvFreight,@CurrencyPlaces)

   IF @TotCr <> @ForeignInvTotal
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=IsCompare<>2'
                       , '@arinvd.amount'
                       , @ForeignInvTotal
                       , '@arinv'
                       , '@arinv.cust_num'
                       , @ArinvCustNum
                       , '@arinv.inv_num'
                       , @ArinvInvNum

      GOTO ERROR_OUT
   END

   EXEC @Severity = dbo.CurrcnvtSp
                     @CurrCode     = @ArinvCurrCode
                   , @FromDomestic = 0  -- To Domestic
                   , @UseBuyRate   = 0  -- Selling Rate
                   , @RoundResult  = 1  -- Use Rounding Factor
                   , @Date         = NULL
                   , @Infobar      = @Infobar          OUTPUT
                   , @Amount1      = @ForeignInvTotal
                   , @Result1      = @DomesticInvTotal OUTPUT
                   , @TRate        = @ArinvExchRate    OUTPUT
                   , @Site = @ParmsSite

   IF @Severity <> 0
      GOTO ERROR_OUT

   -- A/R Debit
   SET @AmountToPost = CASE WHEN @ArinvType = 'C'
                          THEN @DomesticInvTotal * -1
                          ELSE @DomesticInvTotal
                       END
   SET @ForAmtToPost = CASE WHEN @ArinvType = 'C'
                          THEN @ForeignInvTotal * -1
                          ELSE @ForeignInvTotal
                       END

   EXEC @Severity = dbo.ChkUnitSp
                      @acct    = @ArinvAcct
                    , @p_unit1 = @ArinvAcctUnit1
                    , @p_unit2 = @ArinvAcctUnit2
                    , @p_unit3 = @ArinvAcctUnit3
                    , @p_unit4 = @ArinvAcctUnit4
                    , @Infobar = @Infobar OUTPUT

   IF @Severity <> 0
      GOTO ERROR_OUT

   IF @IsControlNumberCreated = 0 AND @AmountToPost <> 0
   BEGIN
      EXEC @Severity = dbo.NextControlNumberSp
      @JournalId = @TId
      , @TransDate = @ArinvInvDate
      , @ControlPrefix = @ControlPrefix output
      , @ControlSite = @ControlSite output
      , @ControlYear = @ControlYear output
      , @ControlPeriod = @ControlPeriod output
      , @ControlNumber = @ControlNumber output
      , @Infobar = @Infobar OUTPUT
      IF @Severity  <> 0
         GOTO ERROR_OUT
      ELSE
         SET @IsControlNumberCreated = 1
   END

   SET @AmountPosted = @AmountPosted + @AmountToPost
   
   EXEC @Severity = dbo.JourpostSp
                    @id                = @TId
                  , @trans_date        = @ArinvInvDate
                  , @acct              = @ArinvAcct
                  , @acct_unit1        = @ArinvAcctUnit1
                  , @acct_unit2        = @ArinvAcctUnit2
                  , @acct_unit3        = @ArinvAcctUnit3
                  , @acct_unit4        = @ArinvAcctUnit4
                  , @amount            = @AmountToPost
                  , @ref               = @ArinvRef
                  , @vend_num          = @ArinvCustNum
                  , @voucher           = @ArinvInvNum
                  , @ref_type          = @ArinvType
                  , @vouch_seq         = @TSeq
                  , @curr_code         = @ArinvCurrCode
                  , @for_amount        = @ForAmtToPost
                  , @exch_rate         = @ArinvExchRate
                  , @ControlPrefix     = @ControlPrefix
                  , @ControlSite       = @ControlSite
                  , @ControlYear       = @ControlYear
                  , @ControlPeriod     = @ControlPeriod
                  , @ControlNumber     = @ControlNumber
                  , @Cancellation      = @ArinvCancellation
                  , @last_seq          = @LastSeq OUTPUT
                  , @Infobar           = @Infobar OUTPUT

   IF @Severity  <> 0
      GOTO ERROR_OUT

   --Initial invoice gain/loss
   SET @Inv_GainLossAmt = 0
   --Calculate invoice gain/loss when exchange rate is between invoice and credit/debit.
   IF @ArinvExchRate <> @ApplyToInvExchRate
   BEGIN
      IF @CurrencyRateIsDivisor = 0
         SET @Inv_GainLossAmt = ROUND(@ForAmtToPost / @ApplyToInvExchRate - @ForAmtToPost / @ArinvExchRate, @CurrencyPlaces)
      ELSE
         SET @Inv_GainLossAmt = ROUND(@ForAmtToPost * @ApplyToInvExchRate - @ForAmtToPost * @ArinvExchRate, @CurrencyPlaces)

      SET @AmountPosted = @AmountPosted + @Inv_GainLossAmt

      EXEC @Severity = dbo.JourpostSp
                       @id                = @TId
                     , @trans_date        = @ArinvInvDate
                     , @acct              = @ArinvAcct
                     , @acct_unit1        = @ArinvAcctUnit1
                     , @acct_unit2        = @ArinvAcctUnit2
                     , @acct_unit3        = @ArinvAcctUnit3
                     , @acct_unit4        = @ArinvAcctUnit4
                     , @amount            = @Inv_GainLossAmt
                     , @ref               = 'ARX'
                     , @vend_num          = @ArinvCustNum
                     , @voucher           = @ArinvInvNum
                     , @ref_type          = 'X'
                     , @vouch_seq         = @TSeq
                     , @curr_code         = @CurrparmsCurrCode
                     , @for_amount        = @Inv_GainLossAmt
                     , @exch_rate         = 1
                     , @ControlPrefix     = @ControlPrefix
                     , @ControlSite       = @ControlSite
                     , @ControlYear       = @ControlYear
                     , @ControlPeriod     = @ControlPeriod
                     , @ControlNumber     = @ControlNumber
                     , @Cancellation      = @ArinvCancellation
                     , @last_seq          = @LastSeq OUTPUT
                     , @Infobar           = @Infobar OUTPUT

      IF @Severity  <> 0
         GOTO ERROR_OUT
   END

   IF @ArtranNoteExistsFlag > 0
   BEGIN -- copy notes
      SET @JournalRowPointer = NULL
      SELECT
        @JournalRowPointer = journal.RowPointer
      FROM journal
      WHERE journal.id = @TId and
      journal.seq = @LastSeq

      if @JournalRowPointer IS NOT NULL
      BEGIN
         EXEC @Severity = dbo.CopyNotesSp
                          'artran'
                        , @ArtranRowPointer
                        , 'journal'
                        , @JournalRowPointer

         if @Severity <> 0
            GOTO ERROR_OUT
      END
   END -- copy notes

   -- Evaluate to create adjustment entries if progressive bills have been created if
   -- 1. this invoice is posted from CO and
   -- 2. customer currency is not the same as domestic currency
   IF @ArinvPostFromCo = 1 AND
      @ArinvCurrCode <> @CurrparmsCurrCode
   BEGIN
      EXEC @Severity = dbo.ProgBillAdjustmentSp
                       @InvNum           = @ArinvInvNum
                     , @InvSeq           = @ArinvInvSeq
                     , @InvDate          = @ArinvInvDate
                     , @CustNum          = @ArinvCustNum
                     , @CustaddrCurrCode = @ArinvCurrCode
                     , @ArinvType        = @ArinvType
                     , @ArinvExchRate    = @ArinvExchRate
                     , @TId              = @TId
                     , @ControlPrefix    = @ControlPrefix
                     , @ControlSite      = @ControlSite
                     , @ControlYear      = @ControlYear
                     , @ControlPeriod    = @ControlPeriod
                     , @ControlNumber    = @ControlNumber
                     , @AmountPosted     = @AmountPosted OUTPUT
                     , @Infobar          = @Infobar OUTPUT
                     , @IsControlNumberCreated = @IsControlNumberCreated
                     , @ArinvInvDate     = @ArinvInvDate

      IF @Severity <> 0
         GOTO ERROR_OUT
   END -- IF @ArinvPostFromCo = 1

   -- POST CURRENCY GAIN/LOSS DUE TO ROUNDOFF
   IF @AmountPosted <> 0.0
   BEGIN
      SET @GainLossAmount = @AmountPosted * -1

      IF @IsControlNumberCreated = 0 AND @GainLossAmount <> 0
      BEGIN
         EXEC @Severity = dbo.NextControlNumberSp
         @JournalId = @TId
         , @TransDate = @ArinvInvDate
         , @ControlPrefix = @ControlPrefix output
         , @ControlSite = @ControlSite output
         , @ControlYear = @ControlYear output
         , @ControlPeriod = @ControlPeriod output
         , @ControlNumber = @ControlNumber output
         , @Infobar = @Infobar OUTPUT
         IF @Severity  <> 0
            GOTO ERROR_OUT
         ELSE
            SET @IsControlNumberCreated = 1
      END
      -- Note output value for @Endtrans not used. Always recalculated in posting
      EXEC @Severity = dbo.GLGainLossSp
                         @PAmount            = @GainLossAmount
                       , @PCurrCode          = @ArinvCurrCode
                       , @PRef               = @ArinvRef
                       , @PId                = @TId
                       , @PTransDate         = @ArinvInvDate
                       , @PVendNum           = @ArinvCustNum
                       , @PVoucher           = @ArinvInvNum
                        , @ControlPrefix = @ControlPrefix
                        , @ControlSite = @ControlSite
                        , @ControlYear = @ControlYear
                        , @ControlPeriod = @ControlPeriod
                        , @ControlNumber = @ControlNumber
                       , @Infobar            = @Infobar      OUTPUT
      , @ExchRate = @ArinvExchRate
      , @ForAmount = 0

      IF @Severity  <> 0
         GOTO ERROR_OUT
   END

IF @PolandCountryPackCSIB_79704On = 1
BEGIN
    IF EXISTS (SELECT 1
        FROM arinv
        WHERE
            inv_num = @PInvNum
            AND inv_seq = @PInvSeq
            AND PL_internal_inv_type IS NOT NULL    )
    BEGIN

        declare @ArinvDistAmt AmountType,
        @ArinvDistAmtNonPosted AmountType,
        @InvType CHAR(2)

        IF EXISTS (SELECT 1
            FROM arinv 
            WHERE
                inv_num = @PInvNum
                AND inv_seq = @PInvSeq
                AND PL_internal_inv_type IS NOT NULL    )

            SELECT    @InvType = PL_internal_inv_type
            FROM arinv 
            WHERE inv_num = @PInvNum
                AND inv_seq = @PInvSeq

            exec [PLPostOtherInvoiceSp] @PInvNum, @infobar 

            --Unused
            SELECT
                @ArinvDistAmt = 0,
                @ArinvDistAmtNonPosted = 0,
                @ArinvTaxDate = tax_date
            FROM
                arinv WITH (UPDLOCK)
            WHERE
                arinv.cust_num = @PCustNum
                AND arinv.inv_num = @PInvNum
                AND arinv.inv_seq = @PInvSeq


            DELETE FROM
                arinvd
            WHERE
                arinvd.cust_num = @ArinvCustNum
                AND arinvd.inv_num = @ArinvInvNum
                AND arinvd.inv_seq = @ArinvInvSeq
                AND arinvd.dist_seq = @ArinvdDistSeq

            DELETE FROM
                arinv
            WHERE
                arinv.cust_num = @PCustNum
                AND arinv.inv_num = @PInvNum
                AND arinv.inv_seq = @PInvSeq 

            UPDATE
                dbo.PL_internal_inv_hdr
            SET
                internal_inv_status = 'P'
            WHERE
                inv_num = @PInvNum
        
            delete from PL_unposted_inv_hdr  where inv_num = @PInvNum
            delete from PL_unposted_inv_item where inv_num = @PInvNum
    END
END
   IF (dbo.IsAddonAvailable('ServiceManagement') = 1 OR dbo.IsAddonAvailable('ServiceManagementM') = 1
      OR dbo.IsAddonAvailable('ServiceManagement_MS') = 1 OR dbo.IsAddonAvailable('ServiceManagementM_MS') = 1)
   BEGIN

      DECLARE
        @PrepaidAmt              AmountType
      , @PrepaidAmtDom           AmountType
      , @PromotionalDiscount     AmountType
      , @PromotionalDiscountDom  AmountType

      --  Get the prepaid amount (SRO deposits applied to the invoice)
      SELECT
        @PrepaidAmt = SUM(depapp.deposit_amt)
      FROM fs_sro_inv_hdr sroinv (NOLOCK)
      INNER JOIN fs_deposit_app depapp (NOLOCK)
      ON depapp.inv_num = sroinv.inv_num
      INNER JOIN fs_deposit dep (NOLOCK)
      ON dep.cust_num = depapp.cust_num
      AND dep.check_num = depapp.check_num
      AND dep.bank_code = depapp.bank_code
      AND (dep.sro_num = depapp.sro_num OR (dep.sro_num IS NULL AND depapp.sro_num IS NULL))
      WHERE sroinv.inv_num = @ArinvInvNum
      AND sroinv.cust_num = @ArinvCustNum
      AND sroinv.prepaid_amt <> 0
      AND dep.bank_code IS NOT NULL -- Exclude deposits that is promotional discount (fs_deposit.bank_code is null) that did not go through AR Payment.

      -- promotional discount didn't go through A/R Payment so posted balance was not updated by A/R Payment Posting routine
      SELECT
        @PromotionalDiscount = SUM(depapp.deposit_amt)
      FROM fs_sro_inv_hdr sroinv (NOLOCK)
      INNER JOIN fs_deposit_app depapp (NOLOCK)
      ON depapp.inv_num = sroinv.inv_num
      INNER JOIN fs_deposit dep (NOLOCK)
      ON dep.cust_num = depapp.cust_num
      AND dep.check_num = depapp.check_num
      AND (dep.sro_num = depapp.sro_num OR (dep.sro_num IS NULL AND depapp.sro_num IS NULL))
      WHERE sroinv.inv_num = @ArinvInvNum
      AND sroinv.cust_num = @ArinvCustNum
      AND sroinv.prepaid_amt <> 0
      AND dep.bank_code IS NULL
      AND depapp.bank_code IS NULL

      SET @PrepaidAmt = ISNULL(@PrepaidAmt, 0)
      SET @PromotionalDiscount = ISNULL(@PromotionalDiscount, 0)

      IF @PrepaidAmt <> 0 OR @PromotionalDiscount <> 0
      BEGIN
         -- Sales Ytd and Sales Ptd is based on domestic currency so need to convert the prepaid amount into domestic currency
         EXEC @Severity = dbo.CurrcnvtSp
                          @CurrCode     = @ArinvCurrCode
                        , @FromDomestic = 0  -- To Domestic
                        , @UseBuyRate   = 0  -- Selling Rate
                        , @RoundResult  = 1  -- Use Rounding Factor
                        , @Date         = NULL
                        , @Infobar      = @Infobar        OUTPUT
                        , @Amount1      = @PrepaidAmt
                        , @Result1      = @PrepaidAmtDom  OUTPUT
                        , @TRate        = @ArinvExchRate  OUTPUT
                        , @Site         = @ParmsSite

         EXEC @Severity = dbo.CurrcnvtSp
                          @CurrCode     = @ArinvCurrCode
                        , @FromDomestic = 0  -- To Domestic
                        , @UseBuyRate   = 0  -- Selling Rate
                        , @RoundResult  = 1  -- Use Rounding Factor
                        , @Date         = NULL
                        , @Infobar      = @Infobar                  OUTPUT
                        , @Amount1      = @PromotionalDiscount
                        , @Result1      = @PromotionalDiscountDom   OUTPUT
                        , @TRate        = @ArinvExchRate            OUTPUT
                        , @Site         = @ParmsSite

         -- prepaid amount (sro deposits) will need to be added back when updating customer balances as arinv amount does not include sro deposit amount
         SET @CustomerOrderBal = CASE WHEN @SSSFSInclSROInOnOrdBal = 1 THEN CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode THEN @CustomerOrderBal - @PrepaidAmtDom - @PromotionalDiscountDom ELSE @CustomerOrderBal - @PrepaidAmt - @PromotionalDiscount END
                                      ELSE @CustomerOrderBal
                                 END
         SET @CustomerPostedBal = @CustomerPostedBal + CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode THEN @PrepaidAmtDom ELSE @PrepaidAmt END
         SET @CustomerSalesYtd  = @CustomerSalesYtd  + @PrepaidAmtDom + @PromotionalDiscountDom
         SET @CustomerSalesPtd  = @CustomerSalesPtd  + @PrepaidAmtDom + @PromotionalDiscountDom

      END

   END

   SELECT TOP 1
                       @ForeignExchRate =
                           CASE WHEN TRateD = 1 THEN TRate
                                WHEN TRateD = 0 AND NOT TRate = 0 THEN 1/TRate
                           END
                      , @infobarloc = InfoBar
                      , @Severity = CASE WHEN InfoBar IS NULL THEN 0 ELSE 16 END
    FROM [dbo].[2CurrCnvt]
                         (
                            @ArinvCurrCode --From
                          , 0, 0
                          , @ArinvInvDate --date
                          , default, default, default, default, default
                          , @CustAddrCurrCode --To
                          , default, default
                          , 1 --Amount
                          , default, default, default, default, default, default, default, default, default, default, default, default, default, default
                          )
   IF @Severity != 0
     SET @InfoBar = CASE WHEN @Infobar IS NULL THEN @InfobarLoc ELSE @Infobar + @InfobarLoc END

   IF @ArinvType = 'C'
   BEGIN
      SET @CustomerOrderBal = CASE WHEN @ArinvPostFromCo = 1 and @IsOrderForProject = 0
                                          AND @SSSFSInclSROInOnOrdBal = 1   -- SSS added
                                     THEN @CustomerOrderBal +
                                         CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                                                 THEN @DomesticInvTotal
                                                 ELSE @ForeignExchRate * @ForeignInvTotal
                                         END
                                   ELSE @CustomerOrderBal
                              END

      SET @CustomerPostedBal = @CustomerPostedBal -
          CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                 THEN @DomesticInvTotal
                 ELSE @ForeignExchRate * @ForeignInvTotal
          END
      SET @CustomerSalesYtd  = @CustomerSalesYtd  -  @DomesticAmount
      SET @CustomerSalesPtd  = @CustomerSalesPtd  -  @DomesticAmount

      IF ISNULL(@CustaddrCorpCred,0) = 1
      BEGIN
         SET @Adjust = CASE WHEN ISNULL(@ArinvPostFromCo,0) = 1 and @IsOrderForProject = 0
                            THEN CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                                        THEN @DomesticInvTotal
                                      ELSE @ForeignInvTotal * @ForeignExchRate
                                 END
                            ELSE 0.0
                       END

         EXEC @Severity = dbo.UpdCorpObalSp
                            @CorpCustNum = @CustaddrCorpCust
                          , @Adjust      =  @Adjust
                          , @Operator    = 'ADD'
                          , @Message     = @Infobar OUTPUT

         IF @Infobar IS NOT NULL
            SET @Severity = 16

         IF @Severity <> 0
            GOTO ERROR_OUT

         SET @Adjust = CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                              THEN @DomesticInvTotal
                            ELSE @ForeignInvTotal * @ForeignExchRate
                       END
         EXEC @Severity = dbo.UpdPbalSp
                            @CorpCustNum = @CustaddrCorpCust
                          , @Adjust      = @Adjust
                          , @Operator    = 'SUBTRACT'
                          , @Message     = @Infobar OUTPUT

         IF @Infobar IS NOT NULL
            SET @Severity = 16

         IF @Severity <> 0
            GOTO ERROR_OUT
      END
   END -- IF @ArinvType = 'C'
   ELSE
   BEGIN -- DR/INV
      SET @CustomerOrderBal  = CASE WHEN @ArinvPostFromCo = 1 and @IsOrderForProject = 0
                                     AND @SSSFSInclSROInOnOrdBal = 1   -- SSS added
                                  THEN @CustomerOrderBal - CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                                                                  THEN @DomesticInvTotal
                                                                ELSE @ForeignExchRate * @ForeignInvTotal
                                                            END
                                  ELSE @CustomerOrderBal
                               END

      SET @CustomerPostedBal = @CustomerPostedBal + CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                                                           THEN @DomesticInvTotal
                                                           ELSE (@ForeignExchRate * @ForeignInvTotal)
                                                    END
      SET @CustomerSalesYtd  = @CustomerSalesYtd  + @DomesticAmount
      SET @CustomerSalesPtd  = @CustomerSalesPtd  + @DomesticAmount

      IF ISNULL(@CustaddrCorpCred,0) = 1
      BEGIN
         SET @Adjust = CASE WHEN ISNULL(@ArinvPostFromCo,0) = 1 and @IsOrderForProject = 0
                              THEN CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                                          THEN @DomesticInvTotal
                                          ELSE @ForeignInvTotal * @ForeignExchRate
                                   END
                            ELSE 0.0
                       END

         EXEC @Severity = dbo.UpdCorpObalSp
                            @CorpCustNum = @CustaddrCorpCust
                          , @Adjust      = @Adjust
                          , @Operator    = 'SUBTRACT'
                          , @Message     = @Infobar OUTPUT

         IF @Infobar IS NOT NULL
            SET @Severity = 16

         IF @Severity <> 0
            GOTO ERROR_OUT

         SET @Adjust = CASE WHEN @CustaddrCurrCode = @CurrparmsCurrCode
                              THEN @DomesticInvTotal
                              ELSE @ForeignInvTotal * @ForeignExchRate
                       END
         EXEC @Severity = dbo.UpdPbalSp
                            @CorpCustNum = @CustaddrCorpCust
                          , @Adjust      = @Adjust
                          , @Operator    = 'ADD'
                          , @Message     = @Infobar OUTPUT

         IF @Infobar IS NOT NULL
            SET @Severity = 16

         IF @Severity <> 0
            GOTO ERROR_OUT
      END
   END -- ELSE DR/INV

   IF @CustomerLastInv < @ArinvInvDate OR @CustomerLastInv IS NULL
      SET @CustomerLastInv = @ArinvInvDate

   -- Update Customer
   If @ArinvReturnedCheck <> 1
   Begin
     UPDATE customer
     SET customer.sales_ytd  = @CustomerSalesYtd
       , customer.sales_ptd  = @CustomerSalesPtd
       , customer.last_inv   = @CustomerLastInv
       , customer.order_bal  = @CustomerOrderBal
       , customer.posted_bal = @CustomerPostedBal
     WHERE customer.cust_num = @ArinvCustNum
     AND   customer.cust_seq = 0
   End
   Else
   Begin
     SET @CustomerDiscYtd = @CustomerDiscYtd - @DomesticDisc
     UPDATE customer
     SET customer.order_bal  = @CustomerOrderBal
       , customer.posted_bal = @CustomerPostedBal
       , customer.disc_ytd   = @CustomerDiscYtd
     WHERE customer.cust_num = @ArinvCustNum
     AND   customer.cust_seq = 0
   End

   SET @Severity = @@ERROR
   IF @Severity <> 0
      GOTO ERROR_OUT

   -- Delete Arinv
   DELETE arinv
   WHERE arinv.cust_num = @PCustNum
   AND   arinv.inv_num  = @PInvNum
   AND   arinv.inv_seq  = @PInvSeq

   SET @Severity = @@ERROR
   IF @Severity <> 0
      GOTO ERROR_OUT

   --Build a Bod
   DECLARE @ActionExpression NVARCHAR(60)
   SET @ActionExpression = 'Replace' --Unable to determine if Add or Replace
   
   IF ISNULL(@MexicanCountryPack,0) = 1 /*RS8297*/ AND @Feature_RS8297Active = 1 /*RS8297*/ AND ISNULL(@IsPOSProcess,'0') <> '1'
   BEGIN
       DECLARE @ProFormaInvNum InvNumType
       
       SELECT TOP 1 @ProFormaInvNum = [pro_forma_inv_hdr].[pro_forma_inv_num]
        FROM [pro_forma_inv_hdr]
        WHERE [pro_forma_inv_hdr].[inv_num] = @PInvNum     

       IF @ArinvType IN('C','D','I')
          EXEC @Severity  = dbo.RemoteMethodForReplicationTargetsSp
               @IdoName      = 'SP!'
             , @MethodName   = 'TriggerInvoiceMXSyncSp'
             , @Infobar      = @Infobar OUTPUT
             , @Parm1Value   = @ProFormaInvNum
             , @Parm2Value   = 0
             , @Parm3Value   = @ActionExpression

   END
   ELSE
   BEGIN

       IF @ArinvType IN('C','D','I')
          EXEC @Severity  = dbo.RemoteMethodForReplicationTargetsSp
               @IdoName      = 'SP!'
             , @MethodName   = 'TriggerInvoiceSyncSp'
             , @Infobar      = @Infobar OUTPUT
             , @Parm1Value   = @PInvNum
             , @Parm2Value   = @PInvSeq
             , @Parm3Value   = @ActionExpression
   END
   
   IF @Severity <> 0
      GOTO ERROR_OUT

   IF dbo.IsAddonAvailable('CreditCardInterface') = 1
   BEGIN
      IF OBJECT_ID('dbo.EXTSSSCCIInvPostingSp') IS NOT NULL
      BEGIN


         EXEC @Severity = dbo.EXTSSSCCIInvPostingSp
                          @PInvNum
                        , @Infobar OUTPUT
         IF @Severity <> 0
            BEGIN
            IF @Infobar IS NULL
               SET @Infobar = 'EXTSSSCCIInvPostingSp ERROR: @Infobar IS NULL'
            ELSE
               SET @Infobar = 'EXTSSSCCIInvPostingSp ERROR: ' + @Infobar
            GOTO ERROR_OUT
        END
      END
   END

   IF EXISTS (SELECT 1 FROM tt_arpost
              WHERE tt_arpost.SessionID = @PSessionID
              AND   tt_arpost.cust_num  = @PCustNum
              AND   tt_arpost.inv_num   = @PInvNum
              AND   tt_arpost.inv_seq   = @PInvSeq
              AND   tt_arpost.printed   = 0)
      -- Mark the record as posted, Let print delete
      UPDATE tt_arpost
         SET tt_arpost.posted = 1
      WHERE tt_arpost.SessionID = @PSessionID
      AND   tt_arpost.cust_num  = @PCustNum
      AND   tt_arpost.inv_num   = @PInvNum
      AND   tt_arpost.inv_seq   = @PInvSeq
   ELSE -- record printed, delete
      DELETE tt_arpost
      WHERE tt_arpost.SessionID = @PSessionID
      AND   tt_arpost.cust_num  = @PCustNum
      AND   tt_arpost.inv_num   = @PInvNum
      AND   tt_arpost.inv_seq   = @PInvSeq

   SET @Severity = @@Error

   IF @Severity <> 0
      GOTO ERROR_OUT
END
ELSE
BEGIN
   EXEC @Severity   = dbo.RemoteMethodCallSp
           @Site       = @ToSite
         , @IdoName    = NULL
         , @MethodName = 'InvPostingSp'
         , @Infobar    = @Infobar OUTPUT
         , @Parm1Value = @PSessionID
         , @Parm2Value = @PCustNum
         , @Parm3Value = @PInvNum
         , @Parm4Value = @PInvSeq
         , @Parm5Value = @PJHeaderRowPointer
         , @Parm6Value = @PostExtFin
         , @Parm7Value = @ExtFinOperationCounter
         , @Parm8Value = @Infobar
         , @Parm9Value = @ToSite
         , @Parm10Value = @PostSite

   IF EXISTS (SELECT 1 FROM tt_arpost
              WHERE tt_arpost.SessionID = @PSessionID
              AND   tt_arpost.cust_num  = @PCustNum
              AND   tt_arpost.inv_num   = @PInvNum
              AND   tt_arpost.inv_seq   = @PInvSeq
              AND   tt_arpost.printed   = 0)
      -- Mark the record as posted, Let print delete
      UPDATE tt_arpost
         SET tt_arpost.posted = 1
      WHERE tt_arpost.SessionID = @PSessionID
      AND   tt_arpost.cust_num  = @PCustNum
      AND   tt_arpost.inv_num   = @PInvNum
      AND   tt_arpost.inv_seq   = @PInvSeq
   ELSE -- record printed, delete
      DELETE tt_arpost
      WHERE tt_arpost.SessionID = @PSessionID
      AND   tt_arpost.cust_num  = @PCustNum
      AND   tt_arpost.inv_num   = @PInvNum
      AND   tt_arpost.inv_seq   = @PInvSeq

   IF @Severity <> 0
      GOTO ERROR_OUT
END

IF @PolandCountryPackCSIB_79704On = 1
BEGIN
    IF isnull(@PLManualVATInvoice, '') <> ''
    BEGIN
        update inv_stax 
        set PL_orig_tax_code = tax_code 
        ,tax_code = 'NPVZ'
        where inv_num = @PLManualVATInvoice 
    END

    IF isnull(@PLManualVATInvoice, '') <> '' and isnull(@ArinvdTaxSystem, '') <> '' and isnull(@ArinvdTaxCode, '') <> ''
    BEGIN
        update inv_stax 
        set inv_num = @PLManualVATInvoice 
        ,seq = (select max(seq) from inv_stax where inv_num = @PLManualVATInvoice) + seq
        where inv_num = @PInvNum  
    END
END

RETURN @Severity

ERROR_OUT:
--  Save the error message for return if this routine is called remotely.
EXEC dbo.RemoteInfobarSaveSp @Infobar
RETURN @Severity


