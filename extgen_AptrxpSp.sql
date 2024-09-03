/* $Header: /ApplicationDB/Stored Procedures/AptrxpSp.sp 65    4/21/17 5:28p Mmarsolo $ */
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
/* $Archive: /ApplicationDB/Stored Procedures/AptrxpSp.sp $
 *
 * SL9.01 65 RS8137 Mmarsolo Fri Apr 21 17:28:10 2017
 * RS8137 - Alter I= messages if returning severity = 16.
 *
 * SL9.01 64 215046 Lqian2 Tue Mar 21 02:11:22 2017
 * Issue 215046, update ETP block.
 *
 * SL9.01 63 211967 pgross Thu May 12 15:03:32 2016
 * Ledger_mst table does not include 'Proj_Trans_Num'
 * post the project transaction prior to creating the journal transaction for the distribution
 *
 * SL9.01 62 RS6770 Ehe Mon Jan 25 01:03:38 2016
 * rs6770 Change code to get and use the aptrx currency instead of vendor.curr_code.  Insert the aptrx currency into aptrxp, export_aptrx, and vch_hdr and for journal posting
 *
 * SL9.01 61 RS7102 jkmalaluan Mon Jan 04 01:39:20 2016
 * RS7102-SyteLineTH
 *
 * SL9.01 60 RS6298 mguan Wed Dec 23 02:28:35 2015
 * RS6298
 *
 * SL9.01 59 202797 pgross Tue Oct 06 10:46:40 2015
 * Seq number in Control Number is incorrect (not continuous) in Journal entries when generated from AP voucher posting
 *
 * SL9.01 58 191173 Ychen1 Thu Mar 12 11:34:10 2015
 * Coding for RS7184
 *
 * SL9.01 57 188420 Ychen1 Sun Feb 15 03:16:19 2015
 * Changes associated with RS7091 Loc - Separate Debit and Credits, + and -
 *
 * SL9.00 56 172058 Cliu Mon Nov 25 03:17:12 2013
 * The Voucher Listing form does not display any information when opened through the G/L Posted Transactions linked forms.
 * Issue:172058
 * Pass @ParmsSite as @from_site to JourpostSp.
 *
 * SL8.04 55 165454 Dmcwhorter Fri Jul 19 14:04:30 2013
 * Voucher will post when Required unit code4 is blank
 * 165454 - Validate the AP acct unit codes.
 *
 * SL8.04 54 164176 Cajones Fri Jun 28 14:16:33 2013
 * update EXTGEN touchpoints
 * Issue 164176
 * Modified Mexican Localizations code to make it more consistent with SyteLine's External Touch Point Standards
 *
 * SL8.04 53 RS5858 Dyang2 Mon Apr 08 03:28:16 2013
 * RS5858: Merge Mexico Country Pack ETP code to original SP.
 *
 * SL8.04 52 154490 Cajones Mon Oct 22 16:16:41 2012
 * Mexican Localizations for AptrxpSp
 * Issue 154490
 * Added touchpoint for Mexican Localizations.
 *
 * SL8.03 51 146372 pgross Thu Jan 12 13:19:49 2012
 * AP journal is not balanced on foreign currency
 * pass Foreign amount, Exchange Rate and Bank Code to GlGainLossSp
 *
 * SL8.03 50 144588 csun Fri Dec 09 02:43:21 2011
 * The checkbox '1099 Reportable' should never be checked for vouchers
 * Issue:144588
 * Don't set AptrxpMisc1099Reportable to 1 after voucher posting, set it to 1after a/p check posting if vendor has a Fed Id Number.
 *
 * SL8.03 49 140852 Ddeng Mon Aug 08 01:37:04 2011
 * The checkbox of  ?1099 Reportable? is not checked in the form ?A/P Posted Transactions Detail?
 * Issue 140852.
 * Set AptrxpMisc1099Reportable to 1 if the Vendor has a Fed Tax Id number.
 *
 * SL8.03 48 140952 pgross Thu Aug 04 14:54:41 2011
 * Notes added on voucher header are not carried over to the GL
 * copy aptrx.txt to a notes record tied to the journal
 *
 * SL8.03 47 134387 pgross Wed Nov 17 16:16:32 2010
 * Voucher Adjustment does not post even though you got sucess message
 * added validation against negative voucher balance
 *
 * SL8.03 46 129820 calagappan Wed Jul 14 18:32:38 2010
 * Voucher linked to project will not post if the Appl Overhead and Appl G&A are not populated on Project Parameters
 * Display error messages returned from executed procedures
 *
 * SL8.02 45 RS4584 Xliang Fri Mar 12 02:41:08 2010
 * RS4584 - Projects - Add stage/status to WBS
 * If WBS status is planned, transactions cannot be entered for Project Tasks that are assigned to the WBS.
 *
 * SL8.02 44 rs4588 Dahn Thu Mar 04 10:12:53 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 43 rs4588 Dahn Wed Mar 03 17:15:57 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 42 RS4438 pcoate Fri Feb 12 10:10:36 2010
 * RS4438 - Added logic to support project and resource level projcost rows.
 *
 * SL8.01 41 121690 pgross Wed Jun 10 11:36:10 2009
 * Syteline is processing and posting transactions with obsolete date
 * check if A/P account is obsolete
 *
 * SL8.01 40 116348 calagappan Thu Jan 22 17:56:30 2009
 * Realized gain/loss entry journal is out of balance when processing AP Voucher Posting.
 * Accumulate running total amount posted based on what is posted to journal.
 *
 * SL8.01 39 107718 Dahn Wed Sep 17 13:29:46 2008
 * Code Cleanup: There is code that needs cleaned up within AptrxpSp related to functionality that appears to have been removed for issue 85902.
 * issue 107718: Code Cleanup
 *
 * SL8.01 38 rs3953 Vlitmano Tue Aug 26 16:38:53 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 37 rs3953 Vlitmano Mon Aug 18 15:04:05 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.01 36 107142 Kkrishna Wed Feb 06 03:53:58 2008
 * Domestic amount in "PO Voucher Register by account Report"  are not matching wit
 * 107142 APAR 109919 
 * Changed the call to CurrCnvtSp to set the Rounding factor to zero.
 * Added code to set @TTmpRate to @AptrxExchRate if @AptrxExchRate is equal to @VchHdrExchRate.
 *
 * SL8.00 35 106965 dgopi Mon Dec 03 08:29:24 2007
 * 2 PO Builder fields and 2 Voucher Builder fields on aptrx are not getting copied to export_aptrx
 * 106965
 * The columns builder_po_orig_site,builder_po_num,builder_voucher_orig_site,builder_voucher 
 * are added to the insert statement to the table export_aptrx.
 *
 * SL8.00 34 100417 Mramakri Wed Mar 21 08:40:28 2007
 * Code Review - SP issues with Voucher Builder
 * MSF 100417 - Corrected indentation
 *
 * SL8.00 33 RS3375 spallavi Wed Mar 14 10:24:23 2007
 * Removed Tabs and alignment made
 *
 * SL8.00 32 RS3117 Kkrishna Wed Feb 28 04:10:04 2007
 * RS3117 removed reference to AcctSrtSp
 *
 * SL8.00 31 RS3375 spallavi Fri Feb 23 09:33:04 2007
 * ForRS3375
 *
 * SL8.00 30 RS2968 nkaleel Fri Feb 23 07:30:46 2007
 * changing copyright information(RS2968)
 *
 * SL8.00 29 98877 pgross Tue Jan 23 11:20:33 2007
 * Run 'Voucher Posting' displays the error '0 A/P Transaction(s) were posted.'.
 * avoid setting vch_hdr.exch_rate to zero
 *
 * SL8.00 28 rs3371 Mkurian Tue Nov 07 06:52:53 2006
 * RS3371
 * References to aptrx.curr_code and export_aptrx.curr_code were removed.
 *
 * SL8.00 27 97346 Clarsco Mon Oct 23 09:09:12 2006
 * Application Lock failurer fails to stop process
 * Fixed Bug 97346
 * Added @Severity Trap following NextControlNumberSp call.
 *
 * SL8.00 26 RS2968 prahaladarao.hs Thu Jul 13 02:34:12 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 25 RS2968 prahaladarao.hs Tue Jul 11 03:38:27 2006
 * RS 2968
 * Name change CopyRight Update.
 *
 * SL8.00 24 95165 pgross Mon Jul 10 14:28:49 2006
 * Manual voucher entered against a voucher pre-register but not posted. User cannot change pre-register status to closed.
 * suppress vch_pr logic in the aptrxDel trigger
 *
 * SL8.00 23 92497 hcl-kumarup Tue Mar 07 07:00:00 2006
 * Voucher posting with variance generates no error if Realized Gain/Loss in the multi-currency parameter is blank
 * Checked in for Issue #92497
 * Applied Return statement after call of GLGainLossSp
 *
 * SL8.00 22 91818 NThurn Mon Jan 09 09:48:06 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.05 21 90282 Hcl-manobhe Wed Dec 28 05:57:22 2005
 * Code Cleanup
 * Issue 90282
 * Call to JourpostISp has been changed to call JourpostSp directly.
 *
 * SL7.05 20 90461 Hcl-singsun Tue Dec 27 06:09:55 2005
 * Add WITH (READUNCOMMITTED) to specific apparms selects
 * Issue #90461
 * Added WITH (READUNCOMMITTED) to apparms selects.
 *
 * SL7.05 19 87416 Hcl-dixichi Thu Oct 27 07:24:26 2005
 * EC VAT report missing transactions in the 'Purch Voucher List' section of the report
 * Checked-in for issue 87416
 * Added code to update tables aptrxp and export_aptrx for the new field tax_date.
 *
 * SL7.05 18 88397 Hcl-chantar Thu Sep 22 03:09:53 2005
 * The Voucher pre-register is creating journals which are not documented in help (Ref APVPV), which leave the general ledger incorrect.
 * Issue 88397:
 * Deleted the call to APJourSp as the same is handled in VchPrChangeStatusSp.
 *
 * SL7.05 17 87258 Coatper Fri May 20 14:10:18 2005
 * AP voucher posting for adjustments adds tax record to voucher tax table and so duplicate the tax adjustment
 * Issue 87258 - Corrected logic to prevent inserting or updating a vch_stax record for adjustment records that have the aptrx.post_from_po = 1.
 *
 * SL7.05 16 87020 Hcl-khurdhe Fri May 20 08:23:35 2005
 * Incorrect NULL comparisons
 * ISSUE # 87020
 * Modified the   Stored Procedure  "AptrxpSp.sp", comparisons "= NULL" has been changed to "IS NULL".
 *
 * SL7.04 15 85902 Hcl-dixichi Tue Feb 01 06:59:55 2005
 * EXTFIN activated - When posting a batch of vendor vouchers, sometimes only a few vouchers come out as XML documents.
 * Checked-in for issue 85902
 *
 * Removed the BGTaskSubmitSp call to submit the ExtFin report.
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE dbo.extgen_AptrxpSp (
  @PVendNum  VendNumType
, @PVoucher  VoucherType
, @PSessionID RowPointerType
, @PostExtFin ListYesNoType OUTPUT
, @ExtFinOperationCounter  OperationCounterType OUTPUT
, @Infobar InfobarType    OUTPUT
) AS

-- Begin of CallALTETPs.exe generated code.
-- Check for existence of alternate definitions (this section was generated and inserted by CallALTETPs.exe):

-- End of alternate definitions code.


-- End of CallALTETPs.exe generated code.

DECLARE
@Severity             INT
, @DomesticAptrxdAmount GenericDecimalType
, @DomesticTaxBasis     GenericDecimalType
, @ProcName sysname
, @EXTGEN_Severity              INT

declare
  @ControlPrefix JourControlPrefixType
, @ControlSite SiteType
, @ControlYear FiscalYearType
, @ControlPeriod FinPeriodType
, @ControlNumber LastTranType
, @OldControlNumber LastTranType

/*RS8518_1, RS8518_2, RS8891, RS9089, RS9255, CSIB_78841*/    
DECLARE     
  @ProductName               ProductNameType
, @FeatureID                 ApplicationFeatureIDType
, @FeatureID1                ApplicationFeatureIDType  
, @FeatureID2                ApplicationFeatureIDType
, @FeatureID3                ApplicationFeatureIDType
, @FeatureID4                ApplicationFeatureIDType
, @FeatureID5                ApplicationFeatureIDType
, @FeatureRS8518_1Active     ListYesNoType
, @FeatureRS8518_2Active     ListYesNoType
, @FeatureRS9089Active       ListYesNoType   
, @FeatureRS8891Active       ListYesNoType
, @FeatureRS9255Active       ListYesNoType
, @FeatureCSIB78841Active    ListYesNoType
, @FeatureInfoBar            InfoBarType    
    
SET @Severity = 0     
SET @ProductName = 'CSI' 
SET @FeatureID = 'RS8518_1'    
SET @FeatureID1 = 'RS8518_2'     
SET @FeatureID2 = 'RS8891'
SET @FeatureID3 = 'RS9089' 
SET @FeatureID4 = 'RS9255' 
SET @FeatureID5 = 'CSIB_78841' 

EXEC @Severity = dbo.IsFeatureActiveSp     
      @ProductName   = @ProductName      
     ,@FeatureID     = @FeatureID     
     ,@FeatureActive = @FeatureRS8518_1Active OUTPUT    
     ,@InfoBar       = @FeatureInfoBar OUTPUT 
         
EXEC @Severity = dbo.IsFeatureActiveSp     
      @ProductName   = @ProductName      
     ,@FeatureID     = @FeatureID1     
     ,@FeatureActive = @FeatureRS8518_2Active OUTPUT    
     ,@InfoBar       = @FeatureInfoBar OUTPUT    

EXEC @Severity = dbo.IsFeatureActiveSp
      @ProductName   = @ProductName
     ,@FeatureID     = @FeatureID2
     ,@FeatureActive = @FeatureRS8891Active OUTPUT
     ,@InfoBar       = @FeatureInfoBar OUTPUT

EXEC @Severity = dbo.IsFeatureActiveSp
      @ProductName   = @ProductName
     ,@FeatureID     = @FeatureID3
     ,@FeatureActive = @FeatureRS9089Active OUTPUT
     ,@InfoBar       = @FeatureInfoBar OUTPUT

EXEC @Severity = dbo.IsFeatureActiveSp
      @ProductName   = @ProductName
     ,@FeatureID     = @FeatureID4
     ,@FeatureActive = @FeatureRS9255Active OUTPUT
     ,@InfoBar       = @FeatureInfoBar OUTPUT

EXEC @Severity = dbo.IsFeatureActiveSp
      @ProductName   = @ProductName
     ,@FeatureID     = @FeatureID5
     ,@FeatureActive = @FeatureCSIB78841Active OUTPUT
     ,@InfoBar       = @FeatureInfoBar OUTPUT
/*RS8518_1, RS8518_2, RS8891, RS9089, RS9255, CSIB_78841*/ 

SET @Severity             = 1
SET @DomesticAptrxdAmount = 0
SET @DomesticTaxBasis     = 0
-- Name of current procedure
SET @ProcName = OBJECT_NAME(@@PROCID)

DECLARE
  @CurrparmsCurrCode       CurrCodeType
, @DomCurrencyPlaces       DecimalPlacesType
, @ParmsECReporting        ListYesNoType
, @ParmsCountry            CountryType
, @JournalID               JournalIDType
, @TtCountryRowPointer     RowPointerType
, @TtCountryEcCode         EcCodeType
, @XCountryECCode          EcCodeType
, @XCountryRowPointer      RowPointerType
, @VendorRowPointer        RowPointerType
, @AptrxCurrCode           CurrCodeType
, @VendorLastPurch         DateType
, @VendorPurchYtd          AmountType
, @VendaddrRowPointer      RowPointerType
, @VendaddrCountry         CountryType
, @VendorBankCode          BankCodeType
, @VendorTaxRegNum1        TaxRegNumType     -- Mexico Country Pack Merge
, @TPurchAmt               AmountType
, @TMaxVchSeq              VouchSeqType
, @TDomBal                 AmountType
, @DomesticInvAmt          AmountType
, @TTmpRate                ExchRateType
, @LastSeq                 JournalSeqType
, @TForBal                 AmountType
, @AmountPosted            AmountType
, @TDomInvAmount           AmountType
, @TInvAmount              AmountType
, @TotCr                   AmountType
, @TDistSeq                VchDistSeqType
, @TStaxSeq                StaxSeqType
, @TempStaxDistDate        DateType
, @AptrxpTaxDistDate       DateType
, @CurrentPeriod           FinPeriodType
, @PeriodsRowPointer       RowPointerType
, @UserID                  TokenType
, @TAppostRowPointer       RowPointerType
, @TAppostVendNum          VendNumType
, @TAppostVoucher          VoucherType
, @CreateVchHdr            int
, @TTaxBal                 AmountType
, @TTaxBal2                AmountType
, @TtVchStaxRowPointer     RowPointerType
, @TtVchStaxVoucher        VoucherType
, @TtVchStaxVendNum        VendNumType
, @TtVchStaxSeq            StaxSeqType
, @TaxParmsLastTaxReport1  DateType
, @TempVoucher             NVARCHAR(10)
, @AptrxRowPointer         RowPointerType
, @AptrxInvDate            DateType
, @AptrxDueDate            DateType
, @AptrxDistDate           DateType
, @AptrxType               AptrxTypeType
, @AptrxPurchAmt           AmountType
, @AptrxPreRegister        PreRegisterType
, @AptrxFreight            AmountType
, @AptrxMiscCharges        AmountType
, @AptrxSalesTax           AmountType
, @AptrxSalesTax2          AmountType
, @AptrxVendNum            VendNumType
, @AptrxVoucher            VoucherType
, @AptrxApAcct             AcctType
, @AptrxApAcctUnit1        UnitCode1Type
, @AptrxApAcctUnit2        UnitCode2Type
, @AptrxApAcctUnit3        UnitCode3Type
, @AptrxApAcctUnit4        UnitCode4Type
, @AptrxInvNum             VendInvNumType
, @AptrxInvAmt             AmountType
, @AptrxExchRate           ExchRateType
, @AptrxPostFromPo         ListYesNoType
, @AptrxPoNum              PoNumType
, @AptrxDiscPct            ApDiscType
, @AptrxGrnNum             GrnNumType
, @AptrxNonDiscAmt         AmountType
, @AptrxDueDays            DueDaysType
, @AptrxDiscDays           DiscDaysType
, @AptrxDiscDate           DateType
, @AptrxProxDay            ProxDayType
, @AptrxFixedRate          ListYesNoType
, @AptrxDutyAmt            AmountType
, @AptrxBrokerageAmt       AmountType
, @AptrxInsuranceAmt       AmountType
, @AptrxLocFrtAmt          AmountType
, @AptrxTxt                DescriptionType
, @AptrxRef                ReferenceType
, @AptrxDiscAmt            AmountType
, @AptrxTaxCode1           TaxCodeType
, @AptrxTaxCode2           TaxCodeType
, @AptrxBuilderPoOrigSite  SiteType
, @AptrxBuilderPoNum       BuilderPoNumType
, @AptrxBuilderVoucherOrigSite SiteType
, @AptrxBuilderVoucher     BuilderVoucherType
, @AptrxTaxDate            DateType
, @AptrxFinalTaxDate       DateType
, @AptrxdRowPointer        RowPointerType
, @AptrxdProjNum           ProjNumType
, @AptrxdTaxSystem         TaxSystemType
, @AptrxdTaxCode           TaxCodeType
, @AptrxdTaxCodeE          TaxCodeType
, @AptrxdDistSeq           APDistSeqType
, @AptrxdAmount            AmountType
, @AptrxdAcct              AcctType
, @AptrxdAcctUnit1         UnitCode1Type
, @AptrxdAcctUnit2         UnitCode2Type
, @AptrxdAcctUnit3         UnitCode3Type
, @AptrxdAcctUnit4         UnitCode4Type
, @AptrxdTaskNum           TaskNumType
, @AptrxdCostCode          CostCodeType
, @AptrxdTaxBasis          AmountType
, @XAptrxRowPointer        RowPointerType
, @XAptrxpApAcct           AcctType
, @XAptrxpApAcctUnit1      UnitCode1Type
, @XAptrxpApAcctUnit2      UnitCode2Type
, @XAptrxpApAcctUnit3      UnitCode3Type
, @XAptrxpApAcctUnit4      UnitCode4Type
, @XAptrxpRowPointer       RowPointerType
, @XAptrxpActive           ListYesNoType
, @XAptrxpVendNum          VendNumType
, @XAptrxpVoucher          VoucherType
, @VchPrRowPointer         RowPointerType
, @VchPrStat               VchPrStatusType
, @VchPrVchDate            DateType
, @VchPrVchMatlCost        AmountType
, @VchPrVchFreight         AmountType
, @VchPrVchMiscCharges     AmountType
, @VchPrVchSalesTax        AmountType
, @VchPrVchSalesTax2       AmountType
, @VchHdrRowPointer        RowPointerType
, @VchHdrExchRate          ExchRateType
, @VchHdrInvAmt            AmountType
, @VchHdrEcCode            EcCodeType
, @VchStaxRowPointer       RowPointerType
, @VchStaxVoucher          VoucherType
, @VchStaxVendNum          VendNumType
, @VchStaxSeq              StaxSeqType
, @VchStaxTaxCode          TaxCodeType
, @VchStaxDistDate         DateType
, @VchStaxSalesTax         AmountType
, @VchStaxTaxBasis         AmountType
, @VchStaxStaxAcct         AcctType
, @VchStaxStaxAcctUnit1    UnitCode1Type
, @VchStaxStaxAcctUnit2    UnitCode2Type
, @VchStaxStaxAcctUnit3    UnitCode3Type
, @VchStaxStaxAcctUnit4    UnitCode4Type
, @VchStaxTaxSystem        TaxSystemType
, @VchStaxTaxRate          TaxRateType
, @VchStaxTaxJur           TaxJurType
, @VchStaxTaxCodeE         TaxCodeType
, @VchDistRowPointer       RowPointerType
, @VchDistDistSeq          VchDistSeqType
, @TaxcodeRowPointer       RowPointerType
, @TaxcodeTaxRate          TaxRateType
, @TaxcodeTaxJur           TaxJurType
, @ChartRowPointer         RowPointerType
, @CurrencyPlaces          DecimalPlacesType
, @ApParmsInvDue           ApAgeByType
, @ParmsSite               SiteType        -- Extfin
, @ExtFinSite              SiteType        -- Extfin
, @ExtFinParmsRowPointer   RowPointerType  -- Extfin
, @ExtFinUseExternalAP     ListYesNoType   -- Extfin
, @ExtFinUseExtFin         ListYesNoType   -- Extfin
, @CurrParmsRowPointer     RowPointerType  -- Extfin
, @CurrParmsLossAcct       AcctType        -- Extfin
, @CurrParmsGainAcct       AcctType        -- Extfin
, @CurrParmsLossAcctUnit1  UnitCode1Type   -- Extfin
, @CurrParmsLossAcctUnit2  UnitCode2Type   -- Extfin
, @CurrParmsLossAcctUnit3  UnitCode3Type   -- Extfin
, @CurrParmsLossAcctUnit4  UnitCode4Type   -- Extfin
, @CurrParmsGainAcctUnit1  UnitCode1Type   -- Extfin
, @CurrParmsGainAcctUnit2  UnitCode2Type   -- Extfin
, @CurrParmsGainAcctUnit3  UnitCode3Type   -- Extfin
, @CurrParmsGainAcctUnit4  UnitCode4Type   -- Extfin
, @TGainLossAcct           AcctType        -- Extfin
, @TGainLossAcctUnit1      UnitCode1Type   -- Extfin
, @TGainLossAcctUnit2      UnitCode2Type   -- Extfin
, @TGainLossAcctUnit3      UnitCode3Type   -- Extfin
, @TGainLossAcctUnit4      UnitCode4Type   -- Extfin
, @AptrxIncludesTax        ListYesNoType   -- Extfin
, @AptrxAuthStatus         AuthStatusType  -- Extfin
, @AptrxProxCode           ProxCodeType    -- Extfin
, @AptrxAuthorizer         UserNameType    -- Extfin
, @AptrxdInvNum            VendInvNumType  -- Extfin
, @AptrxdNoteExistsFlag    FlagNyType      -- Extfin
, @AptrxNoteExistsFlag     FlagNyType
, @JournalRowPointer       RowPointerType
, @AptrxpRowPointer        RowPointerType
, @RateIsDivisor           ListYesNoType
, @NoteSubject LongListType
, @AptrxpMisc1099Reportable ListYesNoType
, @AptrxCancellation       ListYesNoType
, @AptrxFiscalRptSystemType FiscalReportingSystemTypeType
, @ProjTransNum ProjTransNumType
, @PolandEnabled            ListYesNoType    
, @MexicanCountryPack       ListYesNoType 
, @StrDate                  NVARCHAR(50)      
, @StrDueDate               NVARCHAR(50)  
, @AptrxPLVendorInvReceiptDate  DateType
, @AptrxPLMulticurrencyInvoice ListYesNoType
, @AptrxPLRelatedDocument VoucherType
, @AptrxPLVendorCategory    CategoryType 
, @PLLongInvNum             LongVendInvNumType
, @PLSADVoucher              VoucherType
, @PLManualVATVoucher        VoucherType

SELECT @PolandEnabled = dbo.IsAddonAvailable('PolandCountryPack')      
SELECT @MexicanCountryPack = dbo.IsAddonAvailable('MexicanCountryPack')

-- Mexico Country Pack Merge
--MAH 0.1
Declare
@Uf_tax_reg_num TaxRegNumType,
@Uf_name NameType,
@Uf_tax_reg_foreing nchar(1),
@Uf_tax_reg_num_type nchar(1),
@Uf_deduction_pct decimal(7,4),
@Uf_country CountryType,
@Uf_diot_trans nchar(2)

declare @tt_vch_stax table (
  voucher VoucherType
, vend_num VendNumType
, seq StaxSeqType
, tax_code TaxCodeType
, tax_system TaxSystemType
, tax_code_e TaxCodeType
, RowPointer RowPointerType
primary key (voucher, vend_num, seq)
, unique (tax_system, tax_code, tax_code_e, RowPointer)
)

SELECT @UserId = UserNames.Userid
FROM UserNames with (readuncommitted)
   WHERE UserNames.UserName = dbo.UserNameSp()

SELECT
  @CurrparmsCurrCode      = currparms.curr_code
, @CurrParmsLossAcct      = currparms.loss_acct
, @CurrParmsGainAcct      = currparms.gain_acct
, @CurrParmsLossAcctUnit1 = currparms.loss_acct_unit1
, @CurrParmsLossAcctUnit2 = currparms.loss_acct_unit2
, @CurrParmsLossAcctUnit3 = currparms.loss_acct_unit3
, @CurrParmsLossAcctUnit4 = currparms.loss_acct_unit4
, @CurrParmsGainAcctUnit1 = currparms.gain_acct_unit1
, @CurrParmsGainAcctUnit2 = currparms.gain_acct_unit2
, @CurrParmsGainAcctUnit3 = currparms.gain_acct_unit3
, @CurrParmsGainAcctUnit4 = currparms.gain_acct_unit4
FROM currparms with (readuncommitted)

SELECT
  @DomCurrencyPlaces = places
FROM currency with (readuncommitted)
WHERE curr_code = @CurrparmsCurrCode

SELECT @ApParmsInvDue = inv_due
   FROM apparms WITH (READUNCOMMITTED)

SELECT
  @ParmsECReporting = parms.ec_reporting
, @ParmsCountry     = parms.country
, @ParmsSite        = parms.site
FROM parms with (readuncommitted)

SELECT TOP 1
 @TaxParmsLastTaxReport1 = last_tax_report_1
FROM TaxParms with (readuncommitted)

SET   @XCountryRowPointer = NULL
if @ParmsEcReporting = 1
SELECT
   @XCountryRowPointer = x_country.RowPointer
   ,@XCountryECCode = x_country.ec_code
FROM country as x_country with (readuncommitted)
   WHERE x_country.country = @ParmsCountry

-- Begin ExtFin changes
SET @ExtFinParmsRowPointer = NULL

SELECT
  @ExtFinParmsRowPointer    = extfin_parms.RowPointer
, @ExtFinUseExternalAP = extfin_parms.use_external_ap
, @ExtFinUseExtFin     = extfin_parms.use_extfin
FROM extfin_parms with (readuncommitted)

IF @ExtFinParmsRowPointer IS NULL
BEGIN
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
   , 'E=NoExistFor'
   , '@extfin_parms'
   RETURN @Severity
END
-- End ExtFin changes

/* LOCK JOURNAL */

SET @JournalID = 'AP Dist'

SET @TAppostVendNum = @PVendNum
SET @TAppostVoucher = @PVoucher

SET @AptrxRowPointer  = NULL
SET @AptrxInvDate     = NULL
SET @AptrxDueDate     = NULL
SET @AptrxDistDate    = NULL
SET @AptrxType        = NULL
SET @AptrxPurchAmt    = 0
SET @AptrxPreRegister = 0
SET @AptrxFreight     = 0
SET @AptrxMiscCharges = 0
SET @AptrxSalesTax    = 0
SET @AptrxSalesTax2   = 0
SET @AptrxVendNum     = NULL
SET @AptrxVoucher     = 0
SET @AptrxApAcct      = NULL
SET @AptrxApAcctUnit1 = NULL
SET @AptrxApAcctUnit2 = NULL
SET @AptrxApAcctUnit3 = NULL
SET @AptrxApAcctUnit4 = NULL
SET @AptrxInvNum      = NULL
SET @AptrxInvAmt      = 0
SET @AptrxNoteExistsFlag = 0
SET @AptrxCancellation = 0
set @AmountPosted = 0

-- CSIB-78841 Voucher Numeration
IF @PolandEnabled = 1 AND  @FeatureCSIB78841Active = 1 
BEGIN
DECLARE 
        @VchNumerationRowPointer    RowPointerType      
        ,@VchNumerationNum  DECIMAL(38, 0)              
        ,@VchNumerationPrefix   VoucherRefNumType       
        ,@VchNumerationStartNum VoucherRefNumType       
        ,@VchNumerationLastNum  VoucherRefNumType       
        ,@VchNumerationEndNum   VoucherRefNumType       
        ,@VchNumerationNextNum  VoucherRefNumType
        ,@APVchVendCategory CategoryType                
        ,@APVchDate DateType                            
        ,@APVchType nvarchar(10)    
        ,@PL_txt2 nvarchar(255)

        SELECT @TAppostVendNum = vend_num               
        ,@APVchType = type
        ,@APVchDate =inv_date
        ,@APVchVendCategory = PL_vendor_category
        FROM  aptrx WITH (UPDLOCK)
        where aptrx.vend_num = @TAppostVendNum
        and   aptrx.voucher = @TAppostVoucher

        if isnull(@APVchVendCategory, '') = '' 
        select @APVchVendCategory = category
        from vendor
        where vend_num = @TAppostVendNum
        
        SELECT @VchNumerationStartNum = start_num
            ,@VchNumerationEndNum = end_num
            ,@VchNumerationLastNum = last_num
            ,@VchNumerationRowPointer = RowPointer
        FROM  PL_voucher_numeration
        WHERE @APVchDate BETWEEN isnull(start_date, dbo.LowDate())
                AND ISNULL(end_date, dbo.HighDate())
            AND vendor_category = @APVchVendCategory
            AND type = @APVchType

        IF @VchNumerationLastNum IS NULL
        BEGIN
            SET @VchNumerationNextNum = @VchNumerationStartNum
        END
        ELSE
        BEGIN
            
            SET @VchNumerationPrefix = dbo.PrefixOnly(@VchNumerationLastNum)
            SET @VchNumerationPrefix = ISNULL(@VchNumerationPrefix, '')
            
            SET @VchNumerationNum = dbo.NumPart(@VchNumerationLastNum) + 1
            SET @VchNumerationNextNum = @VchNumerationPrefix + ltrim(CAST(@VchNumerationNum AS NVARCHAR(12)))
            SET @VchNumerationNextNum = dbo.ExpandkyByType('arinvType', @VchNumerationNextNum)
        END


        UPDATE PL_voucher_numeration
        SET last_num = @VchNumerationNextNum
        WHERE RowPointer = @VchNumerationRowPointer
    
        select @PL_txt2 = txt
        FROM  aptrx WITH (UPDLOCK)
        where aptrx.vend_num = @TAppostVendNum
        and   aptrx.voucher = @TAppostVoucher

        update aptrx 
        set txt = @VchNumerationNextNum
        ,ref = cast(isnull(aptrx.ref, '') + ' ' + isnull(@VchNumerationNextNum,'') as nvarchar(30))
        ,PL_vendor_category = @APVchVendCategory
        FROM  aptrx WITH (UPDLOCK)
        where aptrx.vend_num = @TAppostVendNum
        and   aptrx.voucher = @TAppostVoucher
END
-- CSIB-78841 Voucher Numeration

SELECT
  @AptrxRowPointer   = aptrx.RowPointer
, @AptrxInvDate      = aptrx.inv_date
, @AptrxDueDate      = aptrx.due_date
, @AptrxDistDate     = aptrx.dist_date
, @AptrxType         = aptrx.type
, @AptrxPurchAmt     = aptrx.purch_amt
, @AptrxPreRegister  = aptrx.pre_register
, @AptrxFreight      = aptrx.freight
, @AptrxMiscCharges  = aptrx.misc_charges
, @AptrxSalesTax     = aptrx.sales_tax
, @AptrxSalesTax2    = aptrx.sales_tax_2
, @AptrxVendNum      = aptrx.vend_num
, @AptrxVoucher      = aptrx.voucher
, @AptrxApAcct       = aptrx.ap_acct
, @AptrxApAcctUnit1  = aptrx.ap_acct_unit1
, @AptrxApAcctUnit2  = aptrx.ap_acct_unit2
, @AptrxApAcctUnit3  = aptrx.ap_acct_unit3
, @AptrxApAcctUnit4  = aptrx.ap_acct_unit4
, @AptrxInvNum       = aptrx.inv_num
, @AptrxInvAmt       = aptrx.inv_amt
, @AptrxPostFromPo   = aptrx.post_from_po
, @AptrxExchRate     = aptrx.exch_rate
, @AptrxPoNum        = aptrx.po_num
, @AptrxDiscPct      = aptrx.disc_pct
, @AptrxGrnNum       = aptrx.grn_num
, @AptrxNonDiscAmt   = aptrx.non_disc_amt
, @AptrxDueDays      = aptrx.due_days
, @AptrxDiscDays     = aptrx.disc_days
, @AptrxProxDay      = aptrx.prox_day
, @AptrxFixedRate    = aptrx.fixed_rate
, @AptrxDutyAmt      = aptrx.duty_amt
, @AptrxDiscDate     = aptrx.disc_date       -- Extfin
, @AptrxDiscAmt      = aptrx.disc_amt        -- Extfin
, @AptrxRef          = aptrx.ref             -- Extfin
, @AptrxIncludesTax  = aptrx.includes_tax    -- Extfin
, @AptrxBrokerageAmt = aptrx.brokerage_amt   -- Extfin
, @AptrxInsuranceAmt = aptrx.insurance_amt
, @AptrxLocFrtAmt    = aptrx.loc_frt_amt
, @AptrxTaxCode1     = aptrx.tax_code1       -- Extfin
, @AptrxTaxCode2     = aptrx.tax_code2       -- Extfin
, @AptrxAuthStatus   = aptrx.auth_status     -- Extfin
, @AptrxProxCode     = aptrx.prox_code       -- Extfin
, @AptrxTxt          = aptrx.txt             -- Extfin
, @AptrxAuthorizer   = aptrx.authorizer      -- Extfin
, @AptrxNoteExistsFlag     = aptrx.NoteExistsFlag
, @AptrxBuilderPoOrigSite  = aptrx.builder_po_orig_site
, @AptrxBuilderPoNum       = aptrx.builder_po_num
, @AptrxBuilderVoucherOrigSite = aptrx.builder_voucher_orig_site
, @AptrxBuilderVoucher     = aptrx.builder_voucher
, @AptrxCancellation = aptrx.cancellation
, @AptrxFiscalRptSystemType = aptrx.fiscal_rpt_system_type
, @AptrxCurrCode = aptrx.curr_code
, @AptrxTaxDate     = aptrx.tax_date
, @AptrxPLVendorInvReceiptDate = CASE WHEN @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1 THEN aptrx.PL_vendor_inv_receipt_date ELSE NULL END
, @AptrxPLMulticurrencyInvoice = CASE WHEN @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1 THEN aptrx.PL_multicurrency_invoice ELSE 0 END
, @AptrxPLRelatedDocument = CASE WHEN @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1 THEN aptrx.PL_related_document ELSE NULL END
, @AptrxPLVendorCategory = CASE WHEN @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1 THEN aptrx.PL_vendor_category ELSE NULL END
, @PLLongInvNum = CASE WHEN @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1 THEN aptrx.PL_long_inv_num ELSE NULL END
, @PLSADVoucher         = aptrx.PL_sad_voucher
, @PLManualVATVoucher   = aptrx.PL_manual_vat_voucher 
FROM  aptrx WITH (UPDLOCK)
where aptrx.vend_num = @TAppostVendNum
and   aptrx.voucher = @TAppostVoucher

if @AptrxRowPointer IS NULL
BEGIN
   SET @Infobar = NULL

    EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
               , '@aptrx'
               , '@aptrx.vend_num'
               , @PVendNum

   Return @Severity
END


IF ISNULL(@PolandEnabled, 0) = 1 /*RS8518_2*/ AND  @FeatureRS8518_2Active = 1 /*RS8518_2*/     
BEGIN  
   SET @AptrxFinalTaxDate = @AptrxTaxDate   
   END      
ELSE      
BEGIN      
   SET @AptrxFinalTaxDate = @AptrxDistDate      
END      


if (@AptrxInvDate IS NULL) or (@AptrxInvDate = '')
BEGIN
    SET @Infobar = NULL

    EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare1'
                              , '@aptrx.inv_date'
                              , @AptrxInvDate
                              , '@aptrx'
                              , '@aptrx.voucher'
                              , @AptrxVoucher

   Return @Severity
END

if (@AptrxDueDate IS NULL) or (@AptrxDueDate = '')
BEGIN
   SET @Infobar = NULL

   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare1'
                           , '@aptrx.due_date'
                           , @AptrxDueDate
                           , '@aptrx'
                           , '@aptrx.voucher'
                           , @AptrxVoucher

   Return @Severity
END

EXEC @Severity = dbo.PerGetSp
  @AptrxDistDate
, @CurrentPeriod     OUTPUT
, @PeriodsRowPointer OUTPUT
, @InfoBar           OUTPUT
, @Site = @ParmsSite

IF @Severity <> 0
   Return @Severity

 /* Catch Cancellations not posted prior to upgrade to Syman 2.5 */
 /* 'C' is NOT a member of class 'aptrx.type'; C? will be return @Severityed */
if @AptrxType = 'C'
BEGIN
   SET @Infobar = NULL

    EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare1'
           , '@aptrx.type'
           , '@:AptrxType:C'
           , '@vendor'
           , '@vendor.vend_num'
           , @AptrxVendNum

   Return @Severity
END

SET @VendorRowPointer = NULL

SELECT @VendorLastPurch  = vendor.last_purch
     , @VendorRowPointer = vendor.RowPointer
     , @VendorBankCode   = vendor.bank_code
     , @VendorTaxRegNum1 = vendor.tax_reg_num1
FROM Vendor
WHERE vendor.vend_num = @APtrxVendNum

IF @VendorRowPointer IS NULL
BEGIN
   SET @Infobar = NULL

    EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
               , '@vendor'
               , '@vendor.vend_num'
               , @AptrxVendNum

   Return @Severity
END

-- Mexico Country Pack Merge
-- Checked 1099 Reportable if the Vendor has a Fed Tax Id number
SET @AptrxpMisc1099Reportable = CASE WHEN dbo.IsAddonAvailable('MexicanCountryPack') = 1 
                                     Then CASE WHEN @VendorTaxRegNum1 IS NOT NULL 
                                               THEN 1 
                                               ELSE 0 
                                          END
                                     ELSE 0
                                END
                                       

Select
       @CurrencyPlaces = places
     , @RateIsDivisor = rate_is_divisor
FROM  currency with (readuncommitted)
WHERE curr_code = @AptrxCurrCode

SET @TPurchAmt = @AptrxPurchAmt

IF (@AptrxPreRegister <> 0) AND (@AptrxPreRegister IS NOT NULL)
BEGIN
   SET @VchPrRowPointer     = NULL
   SET @VchPrStat           = NULL
   SELECT
         @VchPrRowPointer     = vch_pr.RowPointer
       , @VchPrStat           = vch_pr.stat
       , @VchPrVchDate        = vch_pr.vch_date
       , @VchPrVchMatlCost    = vch_pr.vch_matl_cost
       , @VchPrVchFreight     = vch_pr.vch_freight
       , @VchPrVchMiscCharges = vch_pr.vch_misc_charges
       , @VchPrVchSalesTax    = vch_pr.vch_sales_tax
       , @VchPrVchSalesTax2   = vch_pr.vch_sales_tax_2
   FROM vch_pr WITH (UPDLOCK)
   where vch_pr.pre_register = @AptrxPreRegister

   if @VchPrRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
                        ,'@vch_pr'
                        , '@vch_pr.pre_register'
                        , @AptrxPreRegister
      Return @Severity
   END

    IF @VchPrStat = 'C'
    BEGIN
      SET @Infobar = NULL

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare1'
                       , '@vch_pr.stat'
                       , '@:VchPrStatus:C'
                       , '@vch_pr'
                       , '@vch_pr.pre_register'
                       , @AptrxPreRegister

     Return @Severity
    END

   exec dbo.DefineVariableSp
     @VariableName  = 'AptrxpPost'
   , @VariableValue = '1'
   , @Infobar       = @Infobar OUTPUT
   
    UPDATE vch_pr Set
         vch_pr.vch_date = @AptrxDistDate
        ,vch_pr.vch_matl_cost = @AptrxPurchAmt
        ,vch_pr.vch_freight = @AptrxFreight
        ,vch_pr.vch_misc_charges = @AptrxMiscCharges
        ,vch_pr.vch_sales_tax = @AptrxSalesTax
        ,vch_pr.vch_sales_tax_2 = @AptrxSalesTax2
        ,vch_pr.stat = 'C'
     WHERE
       vch_pr.pre_register = @AptrxPreRegister
END

/* FIND POSTED VOUCHER RECORD FOR REFERENCE */

SET @XAptrxpRowPointer  = NULL

SELECT TOP 1
      @XAptrxpRowPointer  = x_aptrxp.RowPointer
    , @XAptrxpActive      = x_aptrxp.active
    , @XAptrxpVendNum     = x_aptrxp.vend_num
    , @XAptrxpVoucher     = x_aptrxp.voucher
    , @XAptrxpApAcct      = x_aptrxp.ap_acct
    , @XAptrxpApAcctUnit1 = x_aptrxp.ap_acct_unit1
    , @XAptrxpApAcctUnit2 = x_aptrxp.ap_acct_unit2
    , @XAptrxpApAcctUnit3 = x_aptrxp.ap_acct_unit3
    , @XAptrxpApAcctUnit4 = x_aptrxp.ap_acct_unit4
FROM aptrxp as x_aptrxp with (readuncommitted)
   where
        x_aptrxp.vend_num = @AptrxVendNum
        and x_aptrxp.voucher = @AptrxVoucher
        and x_aptrxp.type = 'V'
     order by x_aptrxp.vend_num asc, x_aptrxp.voucher asc, x_aptrxp.type asc

if @AptrxType = 'V'
BEGIN
   /* VOUCHER */
   if @XAptrxpRowPointer IS NOT NULL
   BEGIN
      SET @Infobar = NULL

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=Exist3'
      , '@aptrx'
      , '@aptrx.vend_num'
      , @XAptrxpVendNum
      , '@aptrx.voucher'
      , @AptrxVoucher
      , '@aptrx.type'
      , '@:AptrxpType:V'

      Return @Severity
   end

   if @VendorLastPurch IS NULL
      SET @VendorLastPurch = @AptrxDistDate
   else
      SET @VendorLastPurch = dbo.MaxDate(@AptrxDistDate,@VendorLastPurch)
end
else
BEGIN
    /* ADJUSTMENT */
     if @XAptrxpRowPointer IS NULL
     BEGIN
      SET @Infobar = NULL

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist3'
      , '@aptrx'
      , '@aptrx.vend_num'
      , @AptrxVendNum
      , '@aptrx.voucher'
      , @AptrxVoucher
      , '@aptrx.type'
      , '@:AptrxpType:A'

      Return @Severity
   END
   if @XAptrxpActive = 0
   BEGIN
      EXEC @Severity = dbo.ApActiveSp
                   @AptrxVendNum
                  ,@AptrxVoucher
                  ,@CurrparmsCurrCode
                  ,@CurrencyPlaces
                  ,@ApParmsInvDue
                  ,NULL
                  ,1
                  ,NULL
                  ,@Infobar OUTPUT
     END
   /* FORCE A/P ACCOUNT TO BE AS ON ORIGINAL VOUCHER */

     UPDATE aptrx SET
       aptrx.ap_acct = @XAptrxpApAcct
      ,aptrx.ap_acct_unit1 = @XAptrxpApAcctUnit1
      ,aptrx.ap_acct_unit2 = @XAptrxpApAcctUnit2
      ,aptrx.ap_acct_unit3 = @XAptrxpApAcctUnit3
      ,aptrx.ap_acct_unit4 = @XAptrxpApAcctUnit4
      WHERE
        aptrx.vend_num = @TAppostVendNum
            and aptrx.voucher = @TAppostVoucher

   /* Update aptrxApAcct variables */
   SET @AptrxApAcct  = @XAptrxpApAcct
   SET @AptrxApAcctUnit1 = @XAptrxpApAcctUnit1
   SET @AptrxApAcctUnit2 = @XAptrxpApAcctUnit2
   SET @AptrxApAcctUnit3 = @XAptrxpApAcctUnit3
   SET @AptrxApAcctUnit4 = @XAptrxpApAcctUnit4

   /* find highest adjustment voucher seq and update it by 1 */

   SELECT
      @TMaxVchSeq = MAX(vouch_seq)
   From  aptrxp with (readuncommitted)
   WHERE vend_num = @XAptrxpVendNum
   AND   voucher  = @XAptrxpVoucher

END /* Adjustment */

if @AptrxType = 'V'
    SET @TMaxVchSeq = 0
else
    SET @TMaxVchSeq =   @TMaxVchSeq + 1

SET @AptrxpRowPointer = NEWID ()

SET @AptrxpTaxDistDate =
    CASE WHEN ISNULL(@PolandEnabled, 0) = 1  /*RS8518_2*/ AND  @FeatureRS8518_2Active = 1 /*RS8518_2*/     
    THEN      
       @AptrxTaxDate         
    ELSE   
       CASE WHEN @TaxParmsLastTaxReport1 IS NOT NULL AND @AptrxDistDate < @TaxParmsLastTaxReport1      
       THEN @TaxParmsLastTaxReport1      
       ELSE @AptrxDistDate END     
    END      

INSERT INTO aptrxp (
   aptrxp.RowPointer,
   aptrxp.vend_num,
   aptrxp.voucher,
   aptrxp.vouch_seq,
   aptrxp.TYPE,
   aptrxp.dist_date,
   aptrxp.tax_date,
   aptrxp.po_num,
   aptrxp.grn_num,
   aptrxp.inv_num,
   aptrxp.inv_date,
   aptrxp.inv_amt,
   aptrxp.non_disc_amt,
   aptrxp.due_days,
   aptrxp.due_date,
   aptrxp.disc_days,
   aptrxp.prox_day,
   aptrxp.disc_date,
   aptrxp.disc_pct,
   aptrxp.disc_amt,
   aptrxp.ap_acct,
   aptrxp.ap_acct_unit1,
   aptrxp.ap_acct_unit2,
   aptrxp.ap_acct_unit3,
   aptrxp.ap_acct_unit4,
   aptrxp.exch_rate,
   aptrxp.tax_code1,
   aptrxp.tax_code2,
   aptrxp.purch_amt,
   aptrxp.fixed_rate,
   aptrxp.misc_charges,
   aptrxp.sales_tax,
   aptrxp.sales_tax_2,
   aptrxp.freight,
   aptrxp.duty_amt,
   aptrxp.brokerage_amt,
   aptrxp.insurance_amt,
   aptrxp.loc_frt_amt,
   aptrxp.txt,
   aptrxp.ref,
   aptrxp.builder_po_orig_site,
   aptrxp.builder_po_num,
   aptrxp.builder_voucher_orig_site,
   aptrxp.builder_voucher,
   aptrxp.misc1099_reportable,
   aptrxp.cancellation,
   aptrxp.fiscal_rpt_system_type,
   aptrxp.curr_code,
   aptrxp.PL_vendor_inv_receipt_date,
   aptrxp.PL_multicurrency_invoice,
   aptrxp.PL_related_document,
   aptrxp.PL_vendor_category,
   aptrxp.PL_long_inv_num,
   aptrxp.PL_sad_voucher
   )
   VALUES (
      @AptrxpRowPointer,
      @AptrxVendNum,
      @AptrxVoucher,
      @TMaxVchSeq,
      @AptrxType,
      @AptrxDistDate,
      @AptrxpTaxDistDate,
      @AptrxPoNum,
      @AptrxGrnNum,
      @AptrxInvNum,
      @AptrxInvDate,
      @AptrxInvAmt,
      @AptrxNonDiscAmt,
      @AptrxDueDays,
      @AptrxDueDate,
      @AptrxDiscDays,
      ISNULL(@AptrxProxDay,0),
      @AptrxDiscDate,
      @AptrxDiscPct,
      @AptrxDiscAmt,
      @AptrxApAcct,
      @AptrxApAcctUnit1,
      @AptrxApAcctUnit2 ,
      @AptrxApAcctUnit3,
      @AptrxApAcctUnit4,
      @AptrxExchRate,
      @AptrxTaxCode1,
      @AptrxTaxCode2,
      @TPurchAmt,
      @AptrxFixedRate,
      @AptrxMiscCharges,
      @AptrxSalesTax,
      @AptrxSalesTax2,
      @AptrxFreight,
      @AptrxDutyAmt,
      @AptrxBrokerageAmt,
      @AptrxInsuranceAmt,
      @AptrxLocFrtAmt,
      @AptrxTxt,
      @AptrxRef,
      @AptrxBuilderPoOrigSite,  
      @AptrxBuilderPoNum ,       
      @AptrxBuilderVoucherOrigSite, 
      @AptrxBuilderVoucher,
      @AptrxpMisc1099Reportable,
      @AptrxCancellation,
      @AptrxFiscalRptSystemType,
      @AptrxCurrCode,
      @AptrxPLVendorInvReceiptDate,
      @AptrxPLMulticurrencyInvoice,
      @AptrxPLRelatedDocument,
      @AptrxPLVendorCategory,
      @PLLongInvNum,
      @PLSADVoucher
   )

IF @AptrxNoteExistsFlag > 0
BEGIN -- copy notes
   EXEC @Severity = dbo.CopyNotesSp
     'aptrx'
   , @AptrxRowPointer
   , 'aptrxp'
   , @AptrxpRowPointer

   if @Severity <> 0
      RETURN @Severity
      
   EXEC @Severity = dbo.CopyNotesSp
     'aptrx'
   , @AptrxRowPointer
   , 'aptrxp_all'
   , @AptrxpRowPointer

   if @Severity <> 0
      RETURN @Severity
END -- copy notes


SET @VchHdrRowPointer = NULL
SET @VchHdrExchRate = 1
SET @VchHdrInvAmt = 0
SELECT
    @VchHdrRowPointer = vch_hdr.RowPointer
   ,@VchHdrExchRate = vch_hdr.exch_rate
   ,@VchHdrInvAmt = vch_hdr.inv_amt
FROM  vch_hdr WITH (UPDLOCK)
WHERE vch_hdr.voucher = @AptrxVoucher
and   vch_hdr.vend_num = @AptrxVendNum

IF @VchHdrRowPointer IS NULL
BEGIN
     SET @Infobar = NULL

   if @AptrxPostFromPo = 1
      EXEC dbo.MsgAppSp @Infobar OUTPUT, 'I=NoExist2'
          , '@vch_hdr'
          , '@vch_hdr.vend_num'
          , @AptrxVendNum
          , '@vch_hdr.voucher'
          , @AptrxVoucher

   insert into vch_hdr (vend_num, voucher, curr_code)
   values(@AptrxVendNum, @AptrxVoucher, @AptrxCurrCode)
END

insert into @tt_vch_stax
SELECT voucher, vend_num, seq, tax_code, tax_system, tax_code_e, RowPointer
FROM vch_stax with (readuncommitted)
where vch_stax.voucher = @AptrxVoucher
and vch_stax.vend_num = @AptrxVendNum

/* Check to see if we need to convert currency */

SET @TTmpRate = @VchHdrExchRate
if @AptrxCurrCode = @CurrparmsCurrCode
   SET @DomesticInvAmt = @VchHdrInvAmt
else
BEGIN
   exec @Severity = dbo.CurrCnvtSp
            @AptrxCurrCode
         , 0
         , 1
         , 0
         , @AptrxFinalTaxDate
         , NULL
         , 0
         , NULL
         , NULL
         , @TTmpRate         OUTPUT
         , @Infobar         OUTPUT
         , @VchHdrInvAmt
         , @DomesticInvAmt   OUTPUT
         , @Site = @ParmsSite
         , @DomCurrCode = @CurrparmsCurrCode

   IF @Severity <> 0
      RETURN @Severity
END

SET @TDomBal = @DomesticInvAmt

SET @TTmpRate = @AptrxExchRate

if @AptrxCurrCode = @CurrparmsCurrCode
   SET @DomesticInvAmt = @AptrxInvAmt
else
BEGIN

   exec @Severity = dbo.CurrCnvtSp
            @AptrxCurrCode
         , 0
         , 1
         , 0
         , @AptrxFinalTaxDate
         , NULL
         , 0
         , NULL
         , NULL
         , @TTmpRate         OUTPUT
         , @Infobar         OUTPUT
         , @AptrxInvAmt
         , @DomesticInvAmt   OUTPUT
         , @Site = @ParmsSite
         , @DomCurrCode = @CurrparmsCurrCode

   IF @Severity <> 0
      RETURN @Severity
END

SET @TForBal = @VchHdrInvAmt + @AptrxInvAmt
SET @TDomBal = @TDomBal + @DomesticInvAmt

IF(@AptrxExchRate = @VchHdrExchRate)
   SET @TTmpRate = @AptrxExchRate
ELSE IF(@TDomBal <> 0) and @TForBal != 0
begin
   if @TDomBal > 0 and @TForBal < 0
   begin
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare<'
      , '@!bal'
      , '0'

      EXEC dbo.MsgAppSp @Infobar OUTPUT, 'I=WillSet1'
      , '@!bal'
      , @TForBal
      , '@aptrx'
      , '@aptrx.voucher'
      , @AptrxVoucher
      return @Severity
   end
   SET @TTmpRate = case when @RateIsDivisor=0 then @TForBal / @TDomBal else @TDomBal / @TForBal end
end
ELSE
   SET @TTmpRate = @AptrxExchRate

SET @VchHdrInvAmt = @VchHdrInvAmt + @AptrxInvAmt

UPDATE vch_hdr SET
      type      =   @AptrxType,
      dist_date =   @AptrxDistDate,
      po_num    =   @AptrxPoNum,
      inv_num   =   @AptrxInvNum,
      inv_date  =   @AptrxInvDate,
      inv_amt   =   @VchHdrInvAmt,
      disc_pct  =   @AptrxDiscPct,
      ap_acct   =   @AptrxApAcct,
      ap_acct_unit1 =   @AptrxApAcctUnit1,
      ap_acct_unit2 =   @AptrxApAcctUnit2,
      ap_acct_unit3 =   @AptrxApAcctUnit3,
      ap_acct_unit4 =   @AptrxApAcctUnit4,
      vouch_seq     =   @TMaxVchSeq,
      exch_rate     =   @TTmpRate
      WHERE
         vend_num =  @AptrxVendNum and
         voucher  =  @AptrxVoucher

/* SET EC-CODE OF 'BOUGHT-FROM' VENDOR */
if @ParmsECReporting = 1
BEGIN
     SET @VendaddrRowPointer = NULL
     SET @VendaddrCountry    = NULL

   SELECT
        @VendaddrRowPointer = vendaddr.RowPointer,
        @VendaddrCountry    = vendaddr.country
     FROM vendaddr
         WHERE vend_num = @AptrxVendNum

   if @ParmsCountry <> @VendaddrCountry
   BEGIN
      SET @TtCountryRowPointer = NULL
      SET @TtCountryEcCode     = NULL

      SELECT
        @TtCountryRowPointer = country.RowPointer,
        @TtCountryEcCode     = country.ec_code
      FROM country with (readuncommitted)
      where country.country = @VendaddrCountry

      SET @VchHdrEcCode =
         CASE WHEN @XCountryRowPointer IS NULL or
            (@XCountryRowPointer IS NOT NULL and
             @TtCountryEcCode <> @XCountryECCode)
                then @TtCountryEcCode else ''END

      UPDATE vch_hdr SET
        ec_code = @VchHdrEcCode
        WHERE
         vend_num =    @AptrxVendNum and
         voucher  =    @AptrxVoucher
   END
END
/* A/P Credit */
if @DomesticInvAmt <> 0.0
BEGIN
   UPDATE vendor SET
       vendor.purch_ytd = vendor.purch_ytd + @DomesticInvAmt
      ,vendor.last_purch = @VendorLastPurch
          WHERE vendor.vend_num = @APtrxVendNum

   SET @ChartRowPointer = NULL

   SELECT
     @ChartRowPointer = chart.RowPointer
   FROM chart with (readuncommitted)
       where chart.acct = @AptrxApAcct

   if @ChartRowPointer IS NULL or @AptrxApAcct is null
   BEGIN

      SET @Infobar = NULL

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
                 , '@chart'
                 , '@chart.acct'
                 , @AptrxApAcct

      Return @Severity
   END

   EXEC @Severity = dbo.ChkAcctSp
     @acct = @AptrxApAcct,
     @date = @AptrxDistDate,
     @Infobar = @Infobar OUTPUT

   IF @Severity<>0
      RETURN @Severity

   EXEC @Severity = dbo.ChkUnitSp
                 @AptrxApAcct
               , @AptrxApAcctUnit1
               , @AptrxApAcctUnit2
               , @AptrxApAcctUnit3
               , @AptrxApAcctUnit4
               , @InfoBar OUTPUT

   IF @Severity<>0
         RETURN @Severity


   SET @TDomInvAmount = - ROUND(@DomesticInvAmt, @DomCurrencyPlaces)
   SET @AmountPosted  = @TDomInvAmount
   SET @TInvAmount = - @AptrxInvAmt

   set @ControlSite = @ParmsSite
   exec @Severity = dbo.NextControlNumberSp
     @JournalId = @JournalId
   , @TransDate = @AptrxDistDate
   , @ControlPrefix = @ControlPrefix output
   , @ControlSite = @ControlSite output
   , @ControlYear = @ControlYear output
   , @ControlPeriod = @ControlPeriod output
   , @ControlNumber = @ControlNumber output
   , @OldControlNumber = @OldControlNumber output
   , @Infobar = @Infobar OUTPUT

   IF @Severity <> 0
      return @Severity

   EXEC @Severity = dbo.JourpostSp
     @id         = @JournalID
   , @trans_date = @AptrxDistDate
   , @acct       = @AptrxApAcct
   , @acct_unit1 = @AptrxApAcctUnit1
   , @acct_unit2 = @AptrxApAcctUnit2
   , @acct_unit3 = @AptrxApAcctUnit3
   , @acct_unit4 = @AptrxApAcctUnit4
   , @amount     = @TDomInvAmount
   , @ref        = @AptrxRef
   , @vend_num   = @AptrxVendNum
   , @inv_num    = @AptrxInvNum
   , @voucher    = @AptrxVoucher
   , @from_site  = @ParmsSite
   , @ref_type   = @AptrxType
   , @vouch_seq  = @TMaxVchSeq
   , @bank_code  = @VendorBankCode
   , @curr_code  = @AptrxCurrCode
   , @exch_rate =  @AptrxExchRate
   , @for_amount = @TInvAmount
   , @ControlPrefix = @ControlPrefix
   , @ControlSite = @ControlSite
   , @ControlYear = @ControlYear
   , @ControlPeriod = @ControlPeriod
   , @ControlNumber = @ControlNumber
   , @Cancellation = @AptrxCancellation
   , @last_seq   = @LastSeq      OUTPUT
   , @Infobar    = @Infobar      OUTPUT

IF @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1
BEGIN
   SET @JournalRowPointer = NULL

   SELECT @JournalRowPointer = journal.RowPointer FROM journal
      WHERE journal.id = @JournalID AND journal.seq = @LastSeq
   
   IF @JournalRowPointer IS NOT NULL
      UPDATE journal SET PL_long_inv_num = @PLLongInvNum
         WHERE rowpointer = @JournalRowPointer AND inv_num IS NULL
END

   IF @AptrxNoteExistsFlag > 0
   or @AptrxTxt is not null
   BEGIN -- copy notes
      SET @JournalRowPointer = NULL
      SELECT
        @JournalRowPointer = journal.RowPointer
      FROM journal
      WHERE journal.id = @JournalID and
            journal.seq = @LastSeq

      if @JournalRowPointer IS NOT NULL
      BEGIN
         if @AptrxNoteExistsFlag = 1
         begin
            EXEC @Severity = dbo.CopyNotesSp
             'aptrx'
            , @AptrxRowPointer
            , 'journal'
            , @JournalRowPointer

            if @Severity <> 0
               goto EOF
         end

         if @AptrxTxt is not null
         begin
            if @NoteSubject is null
               set @NoteSubject = dbo.StringOf('@aptrx.txt')
            exec @Severity = dbo.CU_NotesSp
              @TableName         = 'journal'
            , @RefRowPointer     = @JournalRowPointer
            , @TypeNote          = 'Specific'
            , @NoteFlag          = 1
            , @NoteDesc          = @NoteSubject
            , @NoteContent       = @AptrxTxt
            , @ObjectNoteToken   = null
            , @SystemNoteToken   = null
            , @UserNoteToken     = null
            , @SpecificNoteToken = null
            if @Severity <> 0
               goto EOF
            if @AptrxNoteExistsFlag = 0
               update journal
               set NoteExistsFlag = 1
               where RowPointer = @JournalRowPointer
               and NoteExistsFlag = 0
         end
      END
   END -- copy notes
END  /* A/P Credit */


-- Begin ExtFin changes
IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAP = 1
BEGIN
SET @Infobar = NULL

    IF @PostExtFin = 0
    BEGIN
      EXEC @Severity = dbo.GetAPBatchCounterSp @ExtFinOperationCounter output
                                             ,@Infobar OUTPUT
    END

    IF @Severity <> 0
      goto EOF
    INSERT INTO export_aptrx (
                export_aptrx.ap_batch_id,
                --export_aptrx.batch_seq,
                export_aptrx.vend_num,
                export_aptrx.voucher,
                export_aptrx.type,
                export_aptrx.dist_date,
                export_aptrx.tax_date,
                export_aptrx.po_num,
                export_aptrx.inv_num,
                export_aptrx.inv_date,
                export_aptrx.inv_amt,
                export_aptrx.non_disc_amt,
                export_aptrx.due_days,
                export_aptrx.due_date,
                export_aptrx.disc_days,
                export_aptrx.disc_date,
                export_aptrx.disc_pct,
                export_aptrx.disc_amt,
                export_aptrx.ap_acct,
                export_aptrx.ref,
                export_aptrx.post_from_po,
                export_aptrx.txt,
                export_aptrx.prox_day,
                export_aptrx.exch_rate,
                export_aptrx.includes_tax,
                export_aptrx.purch_amt,
                export_aptrx.misc_charges,
                export_aptrx.sales_tax,
                export_aptrx.sales_tax_2,
                export_aptrx.freight,
                export_aptrx.duty_amt,
                export_aptrx.brokerage_amt,
                export_aptrx.insurance_amt,
                export_aptrx.loc_frt_amt,
                export_aptrx.tax_code1,
                export_aptrx.tax_code2,
                export_aptrx.ap_acct_unit1,
                export_aptrx.ap_acct_unit2,
                export_aptrx.ap_acct_unit3,
                export_aptrx.ap_acct_unit4,
                export_aptrx.auth_status,
                export_aptrx.fixed_rate,
                export_aptrx.prox_code,
                export_aptrx.grn_num,
                export_aptrx.NoteExistsFlag,
                export_aptrx.pre_register,
                export_aptrx.authorizer,
                export_aptrx.builder_po_orig_site,
                export_aptrx.builder_po_num,
                export_aptrx.builder_voucher_orig_site,
                export_aptrx.builder_voucher,
                export_aptrx.cancellation,
                export_aptrx.fiscal_rpt_system_type,
                export_aptrx.curr_code
          )
   VALUES (
      @ExtFinOperationCounter,

      @AptrxVendNum,
      @AptrxVoucher,
      @AptrxType,
      @AptrxDistDate,
      @AptrxpTaxDistDate,
      @AptrxPoNum,
      @AptrxInvNum,
      @AptrxInvDate,
      @AptrxInvAmt,
      @AptrxNonDiscAmt,
      @AptrxDueDays,
      @AptrxDueDate,
      @AptrxDiscDays,
      @AptrxDiscDate,
      @AptrxDiscPct,
      @AptrxDiscAmt,
      @AptrxApAcct,
      @AptrxRef,
      @AptrxPostFromPo,
      @AptrxTxt,
      @AptrxProxDay,
      @AptrxExchRate,
      @AptrxIncludesTax,
      @TPurchAmt,
      @AptrxMiscCharges,
      @AptrxSalesTax,
      @AptrxSalesTax2,
      @AptrxFreight,
      @AptrxDutyAmt,
      @AptrxBrokerageAmt,
      @AptrxInsuranceAmt,
      @AptrxLocFrtAmt,
      @AptrxTaxCode1,
      @AptrxTaxCode2,
      @AptrxApAcctUnit1,
      @AptrxApAcctUnit2 ,
      @AptrxApAcctUnit3,
      @AptrxApAcctUnit4,
      @AptrxAuthStatus,
      @AptrxFixedRate,
      @AptrxProxCode,
      @AptrxGrnNum,
      @AptrxNoteExistsFlag,
      @AptrxPreRegister,
      @AptrxAuthorizer,
      @AptrxBuilderPoOrigSite,  
      @AptrxBuilderPoNum ,       
      @AptrxBuilderVoucherOrigSite, 
      @AptrxBuilderVoucher,
      @AptrxCancellation,
      @AptrxFiscalRptSystemType,
      @AptrxCurrCode
   )

End

-- End ExtFin changes

/* Debits */

SET @VchStaxRowPointer    = NULL
SET @VchStaxVoucher       = 0
SET @VchStaxVendNum       = NULL
SET @VchStaxSeq           = 0
SET @VchStaxTaxCode       = NULL
SET @VchStaxDistDate      = NULL
SET @VchStaxSalesTax      = 0
SET @VchStaxTaxBasis      = 0
SET @VchStaxStaxAcct      = NULL
SET @VchStaxStaxAcctUnit1 = NULL
SET @VchStaxStaxAcctUnit2 = NULL
SET @VchStaxStaxAcctUnit3 = NULL
SET @VchStaxStaxAcctUnit4 = NULL
SET @VchStaxTaxSystem     = 0
SET @VchStaxTaxRate       = 0
SET @VchStaxTaxJur        = NULL
SET @VchStaxTaxCodeE      = NULL

SELECT TOP 1
      @VchStaxRowPointer    = vch_stax.RowPointer
    , @VchStaxVoucher       = vch_stax.voucher
    , @VchStaxVendNum       = vch_stax.vend_num
    , @VchStaxSeq           = vch_stax.seq
    , @VchStaxTaxCode       = vch_stax.tax_code
    , @VchStaxDistDate      = vch_stax.dist_date
    , @VchStaxSalesTax      = vch_stax.sales_tax
    , @VchStaxTaxBasis      = vch_stax.tax_basis
    , @VchStaxStaxAcct      = vch_stax.stax_acct
    , @VchStaxStaxAcctUnit1 = vch_stax.stax_acct_unit1
    , @VchStaxStaxAcctUnit2 = vch_stax.stax_acct_unit2
    , @VchStaxStaxAcctUnit3 = vch_stax.stax_acct_unit3
    , @VchStaxStaxAcctUnit4 = vch_stax.stax_acct_unit4
    , @VchStaxTaxSystem     = vch_stax.tax_system
    , @VchStaxTaxRate       = vch_stax.tax_rate
    , @VchStaxTaxJur        = vch_stax.tax_jur
    , @VchStaxTaxCodeE      = vch_stax.tax_code_e
FROM vch_stax with (readuncommitted)
    WHERE
       vch_stax.voucher  = @AptrxVoucher and
       vch_stax.vend_num = @AptrxVendNum
ORDER BY vch_stax.voucher desc,vch_stax.vend_num desc, vch_stax.seq desc

SET @VchDistRowPointer = NULL
SELECT TOP 1
  @VchDistRowPointer = vch_dist.RowPointer
, @VchDistDistSeq = vch_dist.dist_seq
FROM vch_dist with (readuncommitted)
WHERE
   vch_dist.voucher  = @AptrxVoucher and
   vch_dist.vend_num = @AptrxVendNum
ORDER BY vch_dist.voucher desc, vch_dist.vend_num desc, vch_dist.dist_seq desc

SET @TotCr = 0
SET @TDistSeq = CASE WHEN
                  @VchDistRowPointer IS NOT NULL
               then @VchDistDistSeq
               else
               0 END

SET @TStaxSeq = CASE WHEN
                     @VchStaxRowPointer IS NOT NULL
                then @VchStaxSeq
                else
                0       END
SET @TTaxBal     = 0
SET @TTaxBal2    = 0

DECLARE AptrxdCrs CURSOR LOCAL STATIC FOR
SELECT
     aptrxd.RowPointer
   , aptrxd.dist_seq
   , aptrxd.proj_num
   , aptrxd.tax_system
   , aptrxd.tax_code
   , aptrxd.tax_code_e
   , aptrxd.amount
   , aptrxd.task_num
   , aptrxd.cost_code
   , aptrxd.acct
   , aptrxd.acct_unit1
   , aptrxd.acct_unit2
   , aptrxd.acct_unit3
   , aptrxd.acct_unit4
   , aptrxd.tax_basis
   , aptrxd.inv_num             --Extfin
   , aptrxd.NoteExistsFlag      --Extfin
   -- Mexico Country Pack Merge
   , aptrxd.MX_tax_reg_num --MAH 0.1
   , aptrxd.MX_vendor_name --MAH 0.1
   , aptrxd.MX_foreign_tax_reg_num --MAH 0.1
   , aptrxd.MX_tax_reg_num_type --MAH 0.1
   , aptrxd.MX_ietu_deduction_pct --MAH 0.1
   , aptrxd.MX_iso_country_code --MAH 0.1
   , aptrxd.MX_diot_trans_type --MAH 0.1
   , aptrxd.Uf_nomor_plat --developer edit
   , aptrxd.Uf_employee --developer edit
FROM aptrxd WITH (UPDLOCK)
WHERE aptrxd.vend_num = @AptrxVendNum AND
     aptrxd.voucher = @AptrxVoucher
ORDER BY aptrxd.vend_num, aptrxd.voucher, aptrxd.dist_seq
 
Declare @nomorPlat varchar(50) --developer edit
Declare @employee varchar(175) --developer edit

OPEN AptrxdCrs
WHILE @Severity = 0
BEGIN
   FETCH AptrxdCrs INTO
         @AptrxdRowPointer
       , @AptrxdDistSeq
       , @AptrxdProjNum
       , @AptrxdTaxSystem
       , @AptrxdTaxCode
       , @AptrxdTaxCodeE
       , @AptrxdAmount
       , @AptrxdTaskNum
       , @AptrxdCostCode
       , @AptrxdAcct
       , @AptrxdAcctUnit1
       , @AptrxdAcctUnit2
       , @AptrxdAcctUnit3
       , @AptrxdAcctUnit4
       , @AptrxdTaxBasis
       , @AptrxdInvNum         --Extfin
       , @AptrxdNoteExistsFlag --Extfin
       -- Mexico Country Pack Merge
       , @Uf_tax_reg_num    --MAH 0.1
       , @Uf_name           --MAH 0.1
       , @Uf_tax_reg_foreing--MAH 0.1
       , @Uf_tax_reg_num_type--MAH 0.1
       , @Uf_deduction_pct --MAH 0.1
       , @Uf_country --MAH 0.1
       , @Uf_diot_trans --MAH 0.1
       , @nomorPlat --developer edit
       , @employee --developer edit
   IF @@FETCH_STATUS = -1
       BREAK

   -- Check WBS Status
   EXEC @Severity = dbo.CheckWBSStatusSp
         @ParentSP = @ProcName
        ,@ProjNum  =    @AptrxdProjNum
        ,@ProjTaskNum = @AptrxdTaskNum
        ,@ProjMsNum = NULL
        ,@Voucher = @PVoucher
        ,@Infobar = @Infobar OUTPUT
   
   IF @Severity != 0 
      goto EOF

   if @AptrxCurrCode = @CurrparmsCurrCode
      SET @DomesticAptrxdAmount = @AptrxdAmount
   else
   BEGIN
      EXEC @Severity = dbo.CurrCnvtSp
            @AptrxCurrCode
         , 0
         , 1
         , 1
         , @AptrxFinalTaxDate
         , NULL
         , 0
         , NULL
         , NULL
         , @AptrxExchRate   OUTPUT
         , @Infobar         OUTPUT
         , @AptrxdAmount
         , @DomesticAptrxdAmount   OUTPUT
         , @Site = @ParmsSite
         , @DomCurrCode = @CurrparmsCurrCode

      IF @Severity <> 0
         goto EOF
   END

   SET @TotCr = @TotCr + @AptrxdAmount

   if @DomesticAptrxdAmount <> 0.0
   BEGIN
      SET @ChartRowPointer = NULL
      SELECT
          @ChartRowPointer = chart.RowPointer
      FROM chart with (readuncommitted)
         WHERE chart.acct = @AptrxdAcct

      if @ChartRowPointer IS NULL or @AptrxdAcct IS NULL
      BEGIN
         SET @Infobar = NULL

         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
         , '@chart'
         , '@chart.acct'
         , @AptrxdAcct

         goto EOF
      END

      EXEC @Severity = dbo.ChkAcctSp
        @acct = @AptrxdAcct,
        @date = @AptrxDistDate,
        @Infobar = @Infobar OUTPUT

      IF @Severity<>0
         goto EOF

      EXEC @Severity = dbo.ChkUnitSp
             @acct     = @AptrxdAcct
            ,@p_unit1 = @AptrxdAcctUnit1
            ,@p_unit2 = @AptrxdAcctUnit2
            ,@p_unit3 = @AptrxdAcctUnit3
            ,@p_unit4 = @AptrxdAcctUnit4
            ,@InfoBar = @infoBar OUTPUT
      IF @Severity<>0
         goto EOF

      if @ControlNumber is null
      begin
         set @ControlSite = @ParmsSite
         exec @Severity = dbo.NextControlNumberSp
           @JournalId = @JournalId
         , @TransDate = @AptrxDistDate
         , @ControlPrefix = @ControlPrefix output
         , @ControlSite = @ControlSite output
         , @ControlYear = @ControlYear output
         , @ControlPeriod = @ControlPeriod output
         , @ControlNumber = @ControlNumber output
         , @OldControlNumber = @OldControlNumber output
         , @Infobar = @Infobar OUTPUT

         IF @Severity <> 0
            goto EOF
      end

      SET @ProjTransNum = NULL
      if (@AptrxdProjNum <> '') and (@AptrxdProjNum IS NOT NULL)
      BEGIN
         SET @TempVoucher = cast(@AptrxVoucher AS NVARCHAR(10))
         EXEC @Severity = dbo.ProjTranSp
           @PProjNum = @AptrxdProjNum
         , @PTaskNum = @AptrxdTaskNum
         , @PSeq = 0
         , @PType = 'T'
         , @PCostCode = @AptrxdCostCode
         , @PTransNum = NULL    /* Matltrans Number */
         , @PTransDate = @AptrxDistDate
         , @PAmount = @DomesticAptrxdAmount
         , @PTransType = 'A'
         , @PItem = ''   /* Item */
         , @PQty = 0    /* Qty */
         , @PTotCost = 0    /* Total Cost */
         , @PTotMatlCost = 0    /* Matl Cost */
         , @PTotLbrCost = 0    /* Labr Cost */
         , @PTotFovhdCost = 0    /* Fix Ovhd Cost */
         , @PTotVovhdCost = 0    /* Var Ovhd Cost */
         , @PTotOutCost = 0    /* Outside Cost */
         , @PEmpNum = NULL   /* Employee Number */
         , @PPayType = NULL   /* Pay Type */
         , @PShift = NULL   /* Shift */
         , @PAHrs = 0    /* Total Hours */
         , @PPrRate = 0    /* Payroll Hourly Rate */
         , @PProjRate = 0    /* Project Hourly Rate */
         , @PRefType = 'V'
         , @PRefNum = @TempVoucher
         , @PRefLineSuf = 0    /* Ref Line Suf */
         , @PRefRelease = 0    /* Ref Release */
         , @PAcctUnit1 = NULL    /* Unit Code 1 */
         , @PAcctUnit2 = NULL    /* Unit Code 2 */
         , @PAcctUnit3 = NULL    /* Unit Code 3 */
         , @PAcctUnit4 = NULL    /* Unit Code 4 */
         , @PRefStr = @AptrxRef
         , @ControlPrefix = @ControlPrefix
         , @ControlSite = @ControlSite
         , @ControlYear = @ControlYear
         , @ControlPeriod = @ControlPeriod
         , @ControlNumber = @ControlNumber
         , @InfoBar = @InfoBar OUTPUT
         , @ProjTransNum = @ProjTransNum output

         if @Severity <> 0
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=CmdFailed3'
                   , '@%post'
                   , '@aptrxd'
                   , '@aptrxd.vend_num'
                   , @AptrxVendNum
                   , '@aptrxd.voucher'
                   , @AptrxVoucher
                   , '@aptrxd.proj_num'
                   , @AptrxdProjNum
            goto EOF
         END
      END

      EXEC @Severity = dbo.extgen_JourpostSp
        @id         = @JournalID
      , @trans_date = @AptrxDistDate
      , @acct       = @AptrxdAcct
      , @acct_unit1 = @AptrxdAcctUnit1
      , @acct_unit2 = @AptrxdAcctUnit2
      , @acct_unit3 = @AptrxdAcctUnit3
      , @acct_unit4 = @AptrxdAcctUnit4
      , @amount     = @DomesticAptrxdAmount
      , @ref        = @AptrxRef
      , @vend_num   = @AptrxVendNum
      , @inv_num    = @AptrxInvNum
      , @voucher    = @AptrxVoucher
      , @from_site  = @ParmsSite      
      , @ref_type   = @AptrxType
      , @vouch_seq  = @TMaxVchSeq
      , @bank_code  = @VendorBankCode
      , @curr_code  = @AptrxCurrCode
      , @exch_rate =  @AptrxExchRate
      , @for_amount = @AptrxdAmount
      , @ControlPrefix = @ControlPrefix
      , @ControlSite = @ControlSite
      , @ControlYear = @ControlYear
      , @ControlPeriod = @ControlPeriod
      , @ControlNumber = @ControlNumber
      , @Cancellation = @AptrxCancellation
      , @last_seq   = @LastSeq      OUTPUT
      , @Infobar    = @Infobar      OUTPUT
      , @proj_trans_num = @ProjTransNum
      , @nomorPlat= @nomorPlat   -- developer edit
      , @employee = @employee -- developer edit


IF @PolandEnabled = 1 AND @FeatureCSIB78841Active = 1
BEGIN
   SET @JournalRowPointer = NULL
   
   SELECT @JournalRowPointer = journal.RowPointer FROM journal
      WHERE journal.id = @JournalID and journal.seq = @LastSeq

   IF @JournalRowPointer IS NOT NULL
      UPDATE journal SET PL_long_inv_num = @PLLongInvNum
         WHERE rowpointer = @JournalRowPointer AND inv_num IS NULL
END

      IF @AptrxdNoteExistsFlag > 0
      or @AptrxTxt is not null
      BEGIN -- copy notes
         SET @JournalRowPointer = NULL
         SELECT
            @JournalRowPointer = journal.RowPointer
         FROM journal
         WHERE journal.id = @JournalID and
               journal.seq = @LastSeq

         if @JournalRowPointer IS NOT NULL
         BEGIN
            if @AptrxdNoteExistsFlag = 1
            begin
               EXEC @Severity = dbo.CopyNotesSp
                 'aptrxd'
               , @AptrxdRowPointer
               , 'journal'
               , @JournalRowPointer

               if @Severity <> 0
                  goto EOF
            end

            if @AptrxTxt is not null
            begin
               if @NoteSubject is null
                  set @NoteSubject = dbo.StringOf('@aptrx.txt')
               exec @Severity = dbo.CU_NotesSp
                 @TableName         = 'journal'
               , @RefRowPointer     = @JournalRowPointer
               , @TypeNote          = 'Specific'
               , @NoteFlag          = 1
               , @NoteDesc          = @NoteSubject
               , @NoteContent       = @AptrxTxt
               , @ObjectNoteToken   = null
               , @SystemNoteToken   = null
               , @UserNoteToken     = null
               , @SpecificNoteToken = null
               if @Severity <> 0
                  goto EOF
               if @AptrxdNoteExistsFlag = 0
                  update journal
                  set NoteExistsFlag = 1
                  where RowPointer = @JournalRowPointer
                  and NoteExistsFlag = 0
            end
         END
      END -- copy notes
      SET @AmountPosted = @AmountPosted + @DomesticAptrxdAmount

      SET @TDistSeq = @TDistSeq + 1
      
      -- Mexico Country Pack Merge
      if dbo.IsAddonAvailable('MexicanCountryPack') = 1
      begin
         --MAH
         IF (@Uf_tax_reg_num_type = 'T' AND @Uf_tax_reg_num IS NULL)
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=TaxRegNumInvalid'
            goto EOF
         END
         --MAH
         IF (@Uf_tax_reg_num_type = 'T' AND @Uf_name IS NULL)
         BEGIN
            SET @Infobar = 'Se requiere nombre de tercero.'
            SET @Severity = 16
            goto EOF
         END
         
         INSERT INTO vch_dist (
            vend_num,
            voucher,
            dist_seq,
            acct,
            acct_unit1,
            acct_unit2,
            acct_unit3,
            acct_unit4,
            vch_dist.amt,
            MX_tax_reg_num, --MAH 0.1
            MX_vendor_name, --MAH 0.1
            MX_foreign_tax_reg_num, --MAH 0.1
            MX_tax_reg_num_type,--MAH 0.1
            MX_diot_trans_type,--MAH 0.1
            MX_ietu_deduction_pct, --MAH 0.1
            MX_iso_country_code --MAH 0.1
         )
         Values (
            @AptrxVendNum,
            @AptrxVoucher,
            @TDistSeq,
            @AptrxdAcct,
            @AptrxdAcctUnit1,
            @AptrxdAcctUnit2,
            @AptrxdAcctUnit3,
            @AptrxdAcctUnit4,
            @DomesticAptrxdAmount,
            @Uf_tax_reg_num, --MAH 0.1
              @Uf_name, --MAH 0.1
              @Uf_tax_reg_foreing, --MAH 0.1
              @Uf_tax_reg_num_type, --MAH 0.1
              @Uf_diot_trans, --MAH 0.1
              @Uf_deduction_pct, --MAH 0.1
              @Uf_country --MAH 0.1
         )
      end
      else
      begin
         INSERT INTO vch_dist (
            vend_num,
            voucher,
            dist_seq,
            acct,
            acct_unit1,
            acct_unit2,
            acct_unit3,
            acct_unit4,
            vch_dist.amt
         )
         Values (
            @AptrxVendNum,
            @AptrxVoucher,
            @TDistSeq,
            @AptrxdAcct,
            @AptrxdAcctUnit1,
            @AptrxdAcctUnit2,
            @AptrxdAcctUnit3,
            @AptrxdAcctUnit4,
            @DomesticAptrxdAmount
         )
      end
   END /* if domestic-aptrxd-amount <> 0.0 */

   IF @AptrxdTaxSystem = 1
      SET @TTaxBal  = @TTaxBal + @AptrxdAmount
   ELSE IF @AptrxdTaxSystem = 2
      SET @TTaxBal2 = @TTaxBal2 + @AptrxdAmount

            
    DECLARE @ApRef  RowpointerType = NULL

    IF @FeatureRS9089Active = 1
        SET @ApRef = @AptrxpRowPointer

   /* Save the tax records for all vouchers and for only adjustments that are
      posted from a PO (i.e. that were created via PO Receiving).  */
   IF (@AptrxdTaxSystem <> 0) AND (@AptrxdTaxSystem IS NOT NULL) AND
      (@AptrxPostFromPO = 0 OR @AptrxType <> 'A')
   BEGIN
      --EXEC Catbert.SLDevEnv_App.dbo.SQLTraceSp 'Into save tax records.', 'thoblo'

      SELECT TOP 1
        @TtVchStaxRowPointer = RowPointer
      , @TtVchStaxVoucher = voucher
      , @TtVchStaxVendNum = vend_num
      , @TtVchStaxSeq = seq
      FROM @tt_vch_stax
      WHERE tax_system = @AptrxdTaxSystem
      and ISNULL(tax_code, NCHAR(1)) = ISNULL(@AptrxdTaxCode, NCHAR(1))
      and ISNULL(tax_code_e, NCHAR(1)) = ISNULL(@AptrxdTaxCodeE, NCHAR(1))
      ORDER BY vend_num, voucher, seq

      IF @TtVchStaxRowPointer IS NOT NULL
      BEGIN
         SELECT
           @VchStaxRowPointer    = vch_stax.RowPointer
         , @VchStaxVoucher       = vch_stax.voucher
         , @VchStaxVendNum       = vch_stax.vend_num
         , @VchStaxSeq           = vch_stax.seq
         , @VchStaxTaxCode       = vch_stax.tax_code
         , @VchStaxDistDate      = vch_stax.dist_date
         , @VchStaxSalesTax      = vch_stax.sales_tax
         , @VchStaxTaxBasis      = vch_stax.tax_basis
         , @VchStaxStaxAcct      = vch_stax.stax_acct
         , @VchStaxStaxAcctUnit1 = vch_stax.stax_acct_unit1
         , @VchStaxStaxAcctUnit2 = vch_stax.stax_acct_unit2
         , @VchStaxStaxAcctUnit3 = vch_stax.stax_acct_unit3
         , @VchStaxStaxAcctUnit4 = vch_stax.stax_acct_unit4
         , @VchStaxTaxSystem     = vch_stax.tax_system
         , @VchStaxTaxRate       = vch_stax.tax_rate
         , @VchStaxTaxJur        = vch_stax.tax_jur
         , @VchStaxTaxCodeE      = vch_stax.tax_code_e
         FROM vch_stax WITH (UPDLOCK)
         WHERE vch_stax.voucher = @TtVchStaxVoucher
         and vch_stax.vend_num = @TtVchStaxVendNum
         and vch_stax.seq = @TtVchStaxSeq

         DELETE @tt_vch_stax
         where voucher = @TtVchStaxVoucher
         and vend_num = @TtVchStaxVendNum
         and seq = @TtVchStaxSeq
      END

      if @AptrxCurrCode = @CurrParmsCurrCode
         SET @DomesticTaxBasis = @AptrxdTaxBasis
      else
      BEGIN
         EXEC @Severity = dbo.CurrCnvtSp
           @AptrxCurrCode
         , 0
         , 1
         , 1
         , @AptrxFinalTaxDate
         , NULL
         , 0
         , NULL
         , NULL
         , @AptrxExchRate   OUTPUT
         , @Infobar         OUTPUT
         , @AptrxdTaxBasis
         , @DomesticTaxBasis   OUTPUT
         , @Site = @ParmsSite
         , @DomCurrCode = @CurrparmsCurrCode

         IF @Severity<>0
         goto EOF
      END

      SET @TaxcodeRowPointer = NULL
      SELECT
        @TaxcodeRowPointer = taxcode.RowPointer
      , @TaxcodeTaxRate = taxcode.tax_rate
      , @TaxcodeTaxJur = taxcode.tax_jur
      FROM  taxcode with (readuncommitted)
      where taxcode.tax_system  = @AptrxdTaxSystem
      AND   taxcode.tax_code_type = 'R'
      AND   taxcode.tax_code      = @AptrxdTaxCode

      if @TaxcodeRowPointer IS NULL
      BEGIN
         SET @Infobar = NULL

         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist3'
         , '@taxcode'
         , '@taxcode.tax_system'
         , @AptrxdTaxSystem
         , '@taxcode.tax_code_type'
         , '@:TaxCodeType:R'
         , '@taxcode.tax_code'
         , @AptrxdTaxCode

         goto EOF
      END

      SET @TempStaxDistDate =
          CASE WHEN @TaxParmsLastTaxReport1 IS NOT NULL AND @AptrxDistDate < @TaxParmsLastTaxReport1
               THEN @TaxParmsLastTaxReport1
               ELSE @AptrxDistDate
          END

      Declare    @MX_TDistSeq                VchDistSeqType
               , @MX_TMaxVchSeq              VouchSeqType
      
      SET @MX_TDistSeq = null
      SET @MX_TMaxVchSeq = null
      
      if dbo.IsAddonAvailable('MexicanCountryPack') = 1 
      begin
         set @MX_TDistSeq = @TDistSeq
         set @MX_TMaxVchSeq = @TMaxVchSeq
      end

      IF @VchStaxRowPointer IS NULL or @AptrxType = 'A'
      BEGIN
         Set @TStaxSeq = @TStaxSeq + 1
         
         DECLARE @PLSADVendNum VendNumType
		 SELECT top 1 @PLSADVendNum = vend_num from aptrxp where voucher = @PLSADVoucher
        
         -- Insert more columns for Mexico Country Pack
         INSERT INTO vch_stax (
               voucher,
               vend_num,
               seq,
               tax_code,
               dist_date,
               sales_tax,
               tax_basis,
               stax_acct,
               stax_acct_unit1,
               stax_acct_unit2,
               stax_acct_unit3,
               stax_acct_unit4,
               tax_system,
               tax_rate,
               tax_jur,
               tax_code_e,
               MX_dist_seq, --MAH
               MX_vouch_seq,  --MAH
               ap_ref_rowpointer
               )
               Values (
               @AptrxVoucher,
               CASE WHEN ISNULL(@PLSADVoucher, '') <> '' AND @FeatureCSIB78841Active = 1 AND @PolandEnabled = 1 THEN 
                    @PLSADVendNum ELSE @AptrxVendNum END,
               @TStaxSeq,
               @AptrxdTaxCode,
               @TempStaxDistDate,
               @DomesticAptrxdAmount,
               @DomesticTaxBasis,
               @AptrxdAcct,
               @AptrxdAcctUnit1,
               @AptrxdAcctUnit2,
               @AptrxdAcctUnit3,
               @AptrxdAcctUnit4,
               @AptrxdTaxSystem,
               @TaxcodeTaxRate,
               @TaxcodeTaxJur,
               @AptrxdTaxCodeE,
               @MX_TDistSeq,  --MAH
               @MX_TMaxVchSeq,  --MAH
               @ApRef
               )
      END
      ELSE
      BEGIN
         UPDATE vch_stax
         SET
         tax_code = @AptrxdTaxCode,
         dist_date = @TempStaxDistDate,
         -- Fix to issue 5026
         sales_tax = CASE WHEN @AptrxType = 'V'
                          THEN @DomesticAptrxdAmount
                          ELSE ISNULL(@VchStaxSalesTax, 0) + @DomesticAptrxdAmount
                     END,
         tax_basis = CASE WHEN @AptrxType = 'V'
                          THEN @DomesticTaxBasis
                          ELSE ISNULL(@VchStaxTaxBasis, 0) + @DomesticTaxBasis
                     END,
         stax_acct = @AptrxdAcct,
         stax_acct_unit1 = @AptrxdAcctUnit1,
         stax_acct_unit2 = @AptrxdAcctUnit2,
         stax_acct_unit3 = @AptrxdAcctUnit3,
         stax_acct_unit4 = @AptrxdAcctUnit4,
         tax_system = @AptrxdTaxSystem,
         tax_rate = @TaxcodeTaxRate,
         tax_jur = @TaxcodeTaxJur,
         tax_code_e = @AptrxdTaxCodeE,
         MX_dist_seq = @MX_TDistSeq       --MAH
         WHERE
         voucher = @TtVchStaxVoucher and
         vend_num = @TtVchStaxVendNum and
         seq =  @TtVchStaxSeq

         IF @FeatureRS9089Active = 1
         BEGIN
            UPDATE vch_stax
            SET 
                ap_ref_rowpointer = @AptrxpRowPointer
            WHERE
                voucher = @TtVchStaxVoucher and
                vend_num = @TtVchStaxVendNum and
                seq =  @TtVchStaxSeq
         END 

      END
   END /* IF (@AptrxdTaxSystem <> 0) AND (@AptrxdTaxSystem IS NOT NULL) ... */
   
    IF ISNULL(@PLManualVATVoucher, '') <> '' AND @FeatureCSIB78841Active = 1 AND @PolandEnabled = 1
        BEGIN
          UPDATE vch_stax 
            SET PL_orig_tax_code = tax_code, 
                tax_code = 'NPVZ' 
            WHERE voucher = @PLManualVATVoucher
        END

    IF @FeatureRS9089Active = 1  AND @AptrxPostFromPO = 1 AND @AptrxType= 'A'
    BEGIN  
        UPDATE vch_stax  
        SET   
            ap_ref_rowpointer = @ApRef  
        WHERE  
            ap_ref_rowpointer = @AptrxRowPointer
    END

   -- Begin ExtFin changes
   IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAP = 1
   BEGIN
   INSERT INTO export_aptrxd (
   export_aptrxd.ap_batch_id,
   export_aptrxd.vend_num,
   export_aptrxd.voucher,
   export_aptrxd.dist_seq,
   export_aptrxd.acct,
   export_aptrxd.amount,
   export_aptrxd.inv_num,
   export_aptrxd.tax_code,
   export_aptrxd.tax_basis,
   export_aptrxd.tax_system,
   export_aptrxd.tax_code_e,
   export_aptrxd.acct_unit1,
   export_aptrxd.acct_unit2,
   export_aptrxd.acct_unit3,
   export_aptrxd.acct_unit4,
   export_aptrxd.proj_num,
   export_aptrxd.task_num,
   export_aptrxd.cost_code,
   export_aptrxd.NoteExistsFlag
   )
   VALUES (
       @ExtFinOperationCounter
      ,@TAppostVendNum
      ,@TAppostVoucher
      ,@AptrxdDistSeq
      ,@AptrxdAcct
      ,@AptrxdAmount
      ,@AptrxdInvNum
      ,@AptrxdTaxCode
      ,@AptrxdTaxBasis
      ,@AptrxdTaxSystem
      ,@AptrxdTaxCodeE
      ,@AptrxdAcctUnit1
      ,@AptrxdAcctUnit2
      ,@AptrxdAcctUnit3
      ,@AptrxdAcctUnit4
      ,@AptrxdProjNum
      ,@AptrxdTaskNum
      ,@AptrxdCostCode
      ,@AptrxdNoteExistsFlag
   )
   End
   -- End ExtFin changes
   
   IF OBJECT_ID(N'dbo.ZMX_PostMXAptrxdValuesSp') IS NOT NULL
   BEGIN
        EXEC @EXTGEN_Severity = dbo.ZMX_PostMXAptrxdValuesSp
             @AptrxVendNum,
             @AptrxVoucher,
             @AptrxPostFromPo,
             @AptrxType,
             @AptrxdDistSeq,
             @TDistSeq,
             @TStaxSeq,
             @TMaxVchSeq,
             @Infobar OUTPUT
           
        IF @EXTGEN_Severity <> 1
            Return @EXTGEN_Severity  
   END
   
   IF @PolandEnabled = 1 AND @FeatureRS8891Active = 1 /*RS8891*/
   BEGIN
      IF @AptrxType = N'A'
      BEGIN
         INSERT INTO vch_procedural_marking
         (voucher, vouch_seq, vat_procedural_marking_id)
         SELECT @AptrxVoucher, @TMaxVchSeq, vpm.vat_procedural_marking_id
         FROM vch_procedural_marking vpm
         WHERE vpm.voucher = @AptrxVoucher AND vpm.vouch_seq = 0
            AND NOT EXISTS (SELECT 1 FROM vch_procedural_marking
            WHERE voucher = @AptrxVoucher AND vouch_seq = @TMaxVchSeq
               AND vat_procedural_marking_id = vpm.vat_procedural_marking_id)
      END
   END
   
   DELETE aptrxd
   WHERE  aptrxd.vend_num = @AptrxVendNum
   AND    aptrxd.voucher  = @AptrxVoucher
   AND    aptrxd.dist_seq = @AptrxdDistSeq
END
CLOSE      AptrxdCrs
DEALLOCATE AptrxdCrs  /* for each symix.aptrxd of aptrx: */

IF @FeatureRS9255Active = 1 AND EXISTS (SELECT TOP 1 1 FROM vch_item WHERE ap_ref_rowpointer = @AptrxRowPointer)
BEGIN
    UPDATE vch_item
    SET 
        ap_ref_rowpointer = @AptrxpRowPointer
    WHERE
        ap_ref_rowpointer = @AptrxRowPointer
END 

IF @Severity <> 0
   GOTO EOF

EXEC @Severity = dbo.AptrxpValidateTaxesSp @TTaxBal
                            , @CurrencyPlaces
                            , @AptrxSalesTax
                            , @AptrxVendNum
                            , @AptrxVoucher
                            , @TTaxBal2
                            , @AptrxSalesTax2
                            , @TotCr
                            , @AptrxInvAmt
                            , @InfoBar OUTPUT

IF @Severity <> 0
   goto EOF

if @AmountPosted <> 0.0
BEGIN
   SET @AmountPosted = @AmountPosted * (-1)
   EXEC @Severity = dbo.GlGainLossSp
                      @PTransDate          = @AptrxDistDate
                     , @PAmount            = @AmountPosted
                     , @PCurrCode          = @AptrxCurrCode
                     , @PRef               = @AptrxRef
                     , @PVendNum           = @AptrxVendNum
                     , @PInvNum            = @AptrxInvNum
                     , @PVoucher           = @AptrxVoucher
                     , @PId                = @JournalID
                     , @Infobar            = @InfoBar output
                     , @ControlPrefix      = @ControlPrefix
                     , @ControlSite        = @ControlSite
                     , @ControlYear        = @ControlYear
                     , @ControlPeriod      = @ControlPeriod
                     , @ControlNumber      = @ControlNumber
   , @ExchRate = @AptrxExchRate
   , @BankCode = @VendorBankCode
   , @ForAmount = 0
IF @Severity <> 0
   goto EOF
END

-- Begin Extfin changes
IF @ExtFinUseExtFin = 1 AND @ExtFinUseExternalAP = 1
   BEGIN
     SET @PostExtFin = 1
    END
--end Extfin changes

exec dbo.DefineVariableSp
  @VariableName  = 'UpdateVchPrStat'
, @VariableValue = '0'
, @Infobar       = @Infobar OUTPUT

DELETE aptrx 
WHERE  aptrx.vend_num    = @TAppostVendNum
and    aptrx.voucher     = @TAppostVoucher
            
exec dbo.UndefineVariableSp
  @VariableName = 'UpdateVchPrStat'
, @Infobar      = @Infobar OUTPUT

IF EXISTS (SELECT 1 FROM tt_appost
           WHERE  tt_appost.SessionID = @PSessionID and
                  tt_appost.vend_num  = @TAppostVendNum and
                  tt_appost.voucher   = @TAppostVoucher and
                  tt_appost.printed   = 0)
   -- Mark the record as posted, Let print delete
   UPDATE tt_appost
      SET tt_appost.posted = 1
           WHERE  tt_appost.SessionID = @PSessionID and
                  tt_appost.vend_num  = @TAppostVendNum and
                  tt_appost.voucher   = @TAppostVoucher
ELSE -- record printed, delete
   DELETE tt_appost
           WHERE  tt_appost.SessionID = @PSessionID and
                  tt_appost.vend_num  = @TAppostVendNum and
                  tt_appost.voucher   = @TAppostVoucher

/* Trigger SupplierInvoice ReplDoc if Poland Country Pack is enabled */
SET @StrDate = CONVERT(NVARCHAR(50), FORMAT(dbo.GetSiteDate(GETDATE()), 'yyyy-MM-ddThh:mm:ssZ'))
SET @StrDueDate = CONVERT(NVARCHAR(50), FORMAT(@AptrxDueDate, 'yyyy-MM-ddThh:mm:ssZ'))

IF (@PolandEnabled = 1 /*RS8518_2*/ AND  @FeatureRS8518_1Active = 1 /*RS8518_1*/) OR ISNULL(@MexicanCountryPack,0) = 1
BEGIN
    EXEC @Severity = dbo.RemoteMethodForReplicationTargetsSp
        @IdoName      = 'SP!'
      , @MethodName   = 'TriggerSupplierInvoiceSyncSp'
      , @Infobar      = @Infobar OUTPUT
      , @Parm1Value   = @PVoucher
      , @Parm2Value   = @PVendNum
      , @Parm3Value   = @StrDate
      , @Parm4Value   = @StrDueDate
      , @Parm5Value   = @TMaxVchSeq
      , @Parm6Value   = 'Add'
END

EOF:

if @Severity != 0
and @ControlNumber is not null
   EXEC dbo.ResetUnusedControlNumberSp
     @ControlNumber    = @ControlNumber
   , @ControlPrefix    = @ControlPrefix
   , @ControlSite      = @ControlSite
   , @ControlYear      = @ControlYear
   , @ControlPeriod    = @ControlPeriod
   , @OldControlNumber = @OldControlNumber
   , @Infobar          = @Infobar --OUTPUT

return @Severity

