/* $Header: /ApplicationDB/Stored Procedures/JourpostSp.sp 34    3/21/17 3:45a Lqian2 $ */
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
/* $Archive: /ApplicationDB/Stored Procedures/JourpostSp.sp $
 *
 * SL9.01 34 215046 Lqian2 Tue Mar 21 03:45:30 2017
 * Issue 215046, update ETP block.
 *
 * SL9.01 33 217177 Lchen3 Fri Jul 22 03:30:30 2016
 * Unable to post credit memo
 * issue 217177
 * correct the data type for voucher when insert into journal table
 *
 * SL9.01 32 216432 pgross Tue Jul 12 14:22:37 2016
 * Request to pull 216076 back into 8.03.10
 * do not compress information when compression is disabled
 *
 * SL9.01 31 216076 pgross Wed Jul 06 10:45:28 2016
 * Control Prefix: XX and Control Site:XXX and Control Year: XXXX and Control Period:X and Control Number: XXXX exists
 * compression is now consistent across the three methods
 *
 * SL9.01 30 RS6298 mguan Wed Dec 23 22:02:56 2015
 * RS6298
 *
 * SL9.01 29 188420 Ychen1 Sun Feb 15 03:15:12 2015
 * Changes associated with RS7091 Loc - Separate Debit and Credits, + and -
 * Issue 188420:(RS7091) Add new input parameter for @Cancellation. Assign it to journal.cancellation.
 *
 * SL9.00 28 172188 Cajones Wed Dec 11 10:19:16 2013
 * Filter by Voucher number is not working
 * Issue 172188
 * -Added code to lookup the coparms.inv_num_length value and to use this value to expand the journal.voucher value to the correct length for AP Dist and PO Dist Journals
 *
 * SL8.04 27 161980 Cajones Thu May 30 10:19:45 2013
 * Filter by Voucher number is not working
 * Issue 161980
 * Added code to expand the journal.voucher field using InvNumVoucherType.
 *
 * SL8.02 26 rs4324 Jbrokl Thu Mar 25 02:37:47 2010
 * RS 4324 Added proj_trans_num updates for Journal & Ledger: Project Labor Transaction Details
 *
 * SL8.02 25 rs4588 Dahn Thu Mar 04 14:58:48 2010
 * rs4588 copyright header changes
 *
 * SL8.01 24 122032 pgross Tue Jul 07 11:24:15 2009
 * Excessive time to complete Generate Landed Cost Voucher when "Generate Voucher" button is used for Vendor with more than 1200 PO lines
 * try to minimize database access
 *
 * SL8.01 23 rs3953 Vlitmano Tue Aug 26 17:07:00 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 22 rs3953 Vlitmano Mon Aug 18 15:28:49 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.00 21 RS2968 nkaleel Fri Feb 23 03:54:44 2007
 * changing copyright information
 *
 * SL8.00 20 RS2968 prahaladarao.hs Tue Jul 11 09:52:57 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 19 94969 Clarsco Thu Jun 22 11:27:18 2006
 * Add application lock to Error Messaging to Next2SubKeySp
 * Bug 94969
 * Added  RETURN @Severity statements following both NextJournalIdSp calls.
 *
 * SL8.00 18 93132 flagatta Thu Mar 09 15:16:58 2006
 * Fix to JourPostSp code cleanup
 * Put a default value on for_amount.  93132
 *
 * SL8.00 17 91818 NThurn Mon Jan 09 10:31:55 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.05 16 90282 Hcl-manobhe Wed Dec 28 03:53:07 2005
 * Code Cleanup
 * Issue 90282
 * The logic of getting the value of currparms.curr_code when a NULL curr_code parameter is passed from JourpostISp is moved into JourpostSp.
 *
 * SL7.05 15 91135 hcl-nautami Wed Dec 28 00:48:51 2005
 * Issue# 91135:
 * Added 'WITH (READUNCOMMITTED)' to prparms selects
 *
 * SL7.04 14 90269 Hcl-tayamoh Mon Nov 28 13:57:14 2005
 * 90269
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE dbo.extgen_JourpostSp (
     @id              JournalIdType
   , @trans_num       MatlTransNumType = 0
   , @trans_date      DateType
   , @acct            AcctType
   , @acct_unit1      UnitCode1Type = NULL
   , @acct_unit2      UnitCode2Type = NULL
   , @acct_unit3      UnitCode3Type = NULL
   , @acct_unit4      UnitCode4Type = NULL
   , @amount          AmountType
   , @ref             ReferenceType = NULL
   , @vend_num        VendNumType = NULL
   , @inv_num         VendInvNumType = NULL
   , @voucher         InvNumVoucherType = '0'
   , @check_num       GlCheckNumType = 0
   , @check_date      DateType = NULL
   , @from_site       SiteType = NULL
   , @ref_type        AnyRefTypeType = NULL
   , @ref_num         AnyRefNumType = NULL
   , @ref_line_suf    AnyRefLineType = 0
   , @ref_release     AnyRefReleaseType = 0
   , @vouch_seq       VouchSeqType = 0
   , @bank_code       BankCodeType = NULL
   , @curr_code       CurrCodeType = NULL
   , @for_amount      AmountType = @amount
   , @exch_rate       ExchRateType = 1
   , @reverse         ListYesNoType = 0
   , @ControlPrefix   JourControlPrefixType = null
   , @ControlSite     SiteType = null
   , @ControlYear     FiscalYearType = null
   , @ControlPeriod   FinPeriodType = null
   , @ControlNumber   LastTranType = null
   , @last_seq        JournalSeqType = null OUTPUT
   , @Infobar         InfobarType   OUTPUT
   , @BufferJournal   RowPointerType = null
   , @DomCurrCode     CurrCodeType = NULL
   , @DomCurrPlaces   DecimalPlacesType = NULL
   , @proj_trans_num  ProjTransNumType = NULL
   , @Cancellation    ListYesNoType = 0
   , @comp_level      JournalCompLevelType = null
   , @compress        ListYesNoType = null
   , @InvNumLength    InvNumLength = null
   , @THPaymentNumber PaymentNumberType = NULL
   , @nomorPlat varchar(50) = NULL --developer edit
)
AS


-- End of CallALTETPs.exe generated code.

if @BufferJournal is null
   SET @BufferJournal = dbo.DefinedValue('JournalDeferred')

DECLARE
   @Severity          INT,
   @places            DecimalPlacesType,
   @t_comp_level      ListYesNoType,
   @prm_curr_code     CurrCodeType

declare
  @RefControlPrefix JourControlPrefixType
, @RefControlSite SiteType
, @RefControlYear FiscalYearType
, @RefControlPeriod FinPeriodType
, @RefControlNumber LastTranType
, @GetDate  DateType

DECLARE @ThailandCountryPack ListYesNoType

SET @ThailandCountryPack = dbo.IsAddonAvailable('ThailandCountryPack')
if @ThailandCountryPack = 1
begin

   DECLARE @ProductName ProductNameType
           , @FeatureRS8071 ApplicationFeatureIDType
           , @FeatureRS8071Active ListYesNoType
           , @FeatureInfoBar InfoBarType

   SET @ProductName = N'CSI'
   SET @FeatureRS8071 = N'RS8071'

   EXEC @Severity = dbo.IsFeatureActiveSp
        @ProductName = @ProductName
      , @FeatureID = @FeatureRS8071
      , @FeatureActive = @FeatureRS8071Active OUTPUT
      , @InfoBar = @FeatureInfoBar OUTPUT

   IF @Severity <> 0
       RETURN @Severity

   SET @ThailandCountryPack = @FeatureRS8071Active
end
SET @ThailandCountryPack = ISNULL(@ThailandCountryPack, 0)

SET @GetDate = getdate() -- dummy place holder

SET @Infobar = NULL
set @Severity = 0
set @places = @DomCurrPlaces
set @prm_curr_code = @DomCurrCode

IF @curr_code IS NULL
   SELECT TOP 1
   @curr_code = curr_code
   FROM dbo.currparms with (readuncommitted)
-- don't create zero amount journal records
IF @amount = 0
   return 0

if @places is null or @prm_curr_code is null
   SELECT
      @places            = cur.places,
      @prm_curr_code     = prm.curr_code
   FROM  dbo.currparms prm with (readuncommitted), currency cur with (readuncommitted)
   WHERE cur.curr_code = prm.curr_code AND prm.parm_key = 0

   SELECT @amount = round(@amount, @places)
   -- check to see if the amount rounded to zero
   IF @amount = 0
      return 0

   IF @curr_code IS NULL
      SELECT @curr_code = @prm_curr_code

   SET @comp_level = NULL

   IF @id = 'SF Dist'
   begin
      if @compress is null
         select @comp_level = case when sfcparms.sfdist_comp_level != 'N' then sfcparms.sfdist_comp_level end
         , @compress = sfcparms.sfdist_comp
         , @ref = case when sfcparms.sfdist_comp = 1 then 'SF' else @ref end
         from  dbo.sfcparms with (readuncommitted)
      else if @compress = 1
         set @ref = 'SF'
   end
   else if @id = 'IC Dist'
   begin
      if @compress is null
         select @comp_level = case when invparms.icdist_comp_level != 'N' then invparms.icdist_comp_level end
         , @compress = invparms.icdist_comp
         , @ref = case when invparms.icdist_comp = 1 then 'IC' else @ref end
         from  dbo.invparms with (readuncommitted)
      else if @compress = 1
         set @ref = 'IC'
   end
   else if @id = 'CO Dist'
   begin
      if @compress is null
         select @comp_level = case when coparms.codist_comp_level != 'N' then coparms.codist_comp_level end
         , @compress = coparms.codist_comp
         , @ref = case when coparms.codist_comp = 1 then 'CO' else @ref end
         from  dbo.coparms with (readuncommitted)
      else if @compress = 1
         set @ref = 'CO'
   end
   else if @id = 'PO Dist'
   begin
      if @compress is null
         select @comp_level = case when poparms.podist_comp_level != 'N' then poparms.podist_comp_level end
         , @compress = poparms.podist_comp
         , @ref = case when poparms.podist_comp = 1 then 'PO' else @ref end
         from  dbo.poparms with (readuncommitted)
      else if @compress = 1
         set @ref = 'PO'
   end
   else IF @id = 'PR Dist'
   begin
      if @compress is null
         SELECT @comp_level = case when prparms.prdist_comp_level != 'N' then prparms.prdist_comp_level end
         , @compress = prparms.compress
         FROM  dbo.prparms WITH (READUNCOMMITTED)
         WHERE prparms_key = 0
      else if @compress = 1
         set @ref = 'PR'
   end
   else
      set @compress = 0

   SET @last_seq = -1            -- @last_seq = -1 indicates that a new record must be inserted into journal

if @compress = 1
begin
   set @BufferJournal = null
   IF @comp_level = 'R'
   BEGIN
      SELECT @last_seq = ISNULL((SELECT MAX(seq)
                              FROM  dbo.journal
                              WHERE id = @id
                                    and acct = @acct
                                    and datediff(dd, trans_date, @trans_date) = 0
                                    and isnull(acct_unit1, '') = isnull(@acct_unit1, '')
                                    and isnull(acct_unit2, '') = isnull(@acct_unit2, '')
                                    and isnull(acct_unit3, '') = isnull(@acct_unit3, '')
                                    and isnull(acct_unit4, '') = isnull(@acct_unit4, '') ), -1)

      SET @t_comp_level = 1
   END
   ELSE IF @comp_level = 'A'
   BEGIN
      SELECT @last_seq = ISNULL((SELECT MAX(seq)
                              FROM  dbo.journal
                              WHERE id = @id
                                    and acct = @acct
                                    and datediff(dd, trans_date, @trans_date) = 0), -1)
      SET @t_comp_level = 0
   END
end
else if (@id = 'AP Dist' OR @id = 'PO Dist')
and @InvNumLength is null
   SELECT TOP 1
     @InvNumLength = coparms.inv_num_length
   FROM  dbo.coparms with (readuncommitted)

if @BufferJournal is not null
and @last_seq = -1
begin
   IF OBJECT_ID('tmp_mass_journal') IS NULL
      -- Verify that the Snapshot table exists
      exec @Severity = dbo.CreateDynamicTableSp
       @pTable  = 'tmp_mass_journal',
       @Infobar = @Infobar output,
       @pColumns = '*'

   select @last_seq = max(seq) + 1
   from tmp_mass_journal with (readuncommitted)
   where ProcessId = @BufferJournal
   and id = @Id

   if @last_seq is null
      set @last_seq = 1

   -- when adding columns here, add the same columns to JournalImmediateSp
   INSERT INTO  dbo.tmp_mass_journal
   (ProcessId
   , id
   , seq
   , trans_date
   , acct
   , acct_unit1
   , acct_unit2
   , acct_unit3
   , acct_unit4
   , dom_amount
   , ref
   , vend_num
   , inv_num
   , voucher
   , check_num
   , check_date
   , from_site
   , matl_trans_num
   , ref_type
   , ref_num
   , ref_line_suf
   , ref_release
   , vouch_seq
   , bank_code
   , curr_code
   , for_amount
   , exch_rate
   , reverse
   , control_prefix
   , control_site
   , control_year
   , control_period
   , control_number
   , ref_control_prefix
   , ref_control_site
   , ref_control_year
   , ref_control_period
   , ref_control_number
   , proj_trans_num
   -- required columns inherited from journal
   , InWorkflow
   , RowPointer
   , RecordDate
   , CreateDate
   , UpdatedBy
   , CreatedBy
   , NoteExistsFlag
   , cancellation
   , TH_payment_number
    )
   VALUES
   (@BufferJournal
   , @id
   , @last_seq
   , @trans_date
   , @acct
   , @acct_unit1
   , @acct_unit2
   , @acct_unit3
   , @acct_unit4
   , @amount
   , @ref
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @vend_num END
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @inv_num END
   , case when @id = 'PR Dist' then @voucher
      when @compress = 1 then '0'
      when @id in ('AP Dist', 'PO Dist') then dbo.ExpandKy(@InvNumLength, @voucher)
      else @voucher
      end
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @check_num END
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @check_date END
   , @from_site
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @trans_num END
   , @ref_type
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @ref_num END
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @ref_line_suf END
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @ref_release END
   , CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @vouch_seq END
   , @bank_code
   , CASE WHEN @compress=1 THEN @Prm_curr_code ELSE @curr_code END
   , CASE WHEN @compress=1 THEN @amount ELSE @for_amount END
   , CASE WHEN @compress=1 THEN 1 ELSE @exch_rate END
   , @reverse
   , case when @compress = 0 then @ControlPrefix end
   , case when @compress = 0 then @ControlSite end
   , case when @compress = 0 then @ControlYear end
   , case when @compress = 0 then @ControlPeriod end
   , case when @compress = 0 then @ControlNumber end
   , case when @compress = 0 then isnull(@RefControlPrefix, @ControlPrefix) end
   , case when @compress = 0 then isnull(@RefControlSite, @ControlSite) end
   , case when @compress = 0 then isnull(@RefControlYear, @ControlYear) end
   , case when @compress = 0 then isnull(@RefControlPeriod, @ControlPeriod) end
   , case when @compress = 0 then isnull(@RefControlNumber, @ControlNumber) end
   , @proj_trans_num
   , 0
   , newid()
   , @GetDate
   , @GetDate
   , ''
   , ''
   , 0
   , @Cancellation
   , CASE WHEN @ThailandCountryPack = 1 THEN @THPaymentNumber ELSE NULL END
    )

end
else IF @last_seq = -1  -- create new journal entry
BEGIN
   EXEC @Severity = dbo.NextJournalIdSp
    @Id        = @Id
  , @Increment = 1
  , @Seq       = @last_seq OUTPUT
  , @Infobar   = @Infobar  OUTPUT

  IF @Severity <> 0
      RETURN @Severity

-- edited by developer
   DECLARE @InsertedRowPointer Table(RowPointer uniqueidentifier)

   INSERT INTO  dbo.journal
      (id,
       seq,
       trans_date,
       acct ,
       acct_unit1,
       acct_unit2,
       acct_unit3,
       acct_unit4,
       dom_amount,
       ref,
       vend_num ,
       inv_num ,
       voucher ,
       check_num ,
       check_date ,
       from_site ,
       matl_trans_num,
       ref_type ,
       ref_num ,
       ref_line_suf ,
       ref_release ,
       vouch_seq ,
       bank_code ,
       curr_code ,
       for_amount ,
       exch_rate,
       reverse
     , control_prefix
     , control_site
     , control_year
     , control_period
     , control_number
     , ref_control_prefix
     , ref_control_site
     , ref_control_year
     , ref_control_period
     , ref_control_number
     , proj_trans_num
     , cancellation
     , TH_payment_number
       )
   OUTPUT INSERTED.RowPointer INTO @InsertedRowPointer -- edited by developer
   VALUES
      (@id,
       @last_seq,
       @trans_date,
       @acct,
       CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit1 ELSE NULL END,
       CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit2 ELSE NULL END,
       CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit3 ELSE NULL END,
       CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit4 ELSE NULL END,
       @amount,
       @ref,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @vend_num END,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @inv_num END,
       case when @id = 'PR Dist' then @voucher
         when @compress = 1 then '0'
         when @id in ('AP Dist', 'PO Dist') then dbo.ExpandKy(@InvNumLength, @voucher)
         else @voucher
         end,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @check_num END,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @check_date END,
       @from_site ,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @trans_num END,
       @ref_type ,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN NULL ELSE @ref_num END,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @ref_line_suf END,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @ref_release END,
       CASE WHEN @compress = 1 and @id <> 'PR Dist' THEN 0 ELSE @vouch_seq END,
       @bank_code ,
       CASE WHEN @compress=1 THEN @Prm_curr_code ELSE @curr_code END,
       CASE WHEN @compress=1 THEN @amount ELSE @for_amount END,
       CASE WHEN @compress=1 THEN 1 ELSE @exch_rate END,
       @reverse
   , case when @compress = 0 then @ControlPrefix end
   , case when @compress = 0 then @ControlSite end
   , case when @compress = 0 then @ControlYear end
   , case when @compress = 0 then @ControlPeriod end
   , case when @compress = 0 then @ControlNumber end
   , case when @compress = 0 then isnull(@RefControlPrefix, @ControlPrefix) end
   , case when @compress = 0 then isnull(@RefControlSite, @ControlSite) end
   , case when @compress = 0 then isnull(@RefControlYear, @ControlYear) end
   , case when @compress = 0 then isnull(@RefControlPeriod, @ControlPeriod) end
   , case when @compress = 0 then isnull(@RefControlNumber, @ControlNumber) end
   , @proj_trans_num
   , @Cancellation
   , CASE WHEN @ThailandCountryPack = 1 THEN @THPaymentNumber ELSE NULL END
       ) 

-- edited by developer
-- add attribute value nomor plat to journal entries
IF @id = 'AP Dist' And @acct = '614002'
BEGIN 
   INSERT INTO dbo.dim_attribute_override (value, attribute, subscriber_object_rowpointer,subscriber_object_name)
   SELECT
     @nomorPlat,
      'AnalysisAttribute01',
      irp.RowPointer,
   'Ledger'
   FROM
      @InsertedRowPointer as irp;
END
ELSE IF @id = 'AR Dist' And @acct = '614002'
BEGIN
   INSERT INTO dbo.dim_attribute_override (value, attribute, subscriber_object_rowpointer,subscriber_object_name)
   SELECT
     @nomorPlat,
      'AnalysisAttribute01',
      irp.RowPointer,
   'Ledger'
   FROM
      @InsertedRowPointer as irp;
END

    SET @Severity = @@ERROR
    IF @Severity <> 0
       RETURN @Severity
END  -- end create new journal entry
ELSE
BEGIN
   UPDATE  dbo.journal
   SET trans_date = @trans_date,
       acct = @acct,
       acct_unit1 =  CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit1 ELSE NULL END,
       acct_unit2 =  CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit2 ELSE NULL END,
       acct_unit3 =  CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit3 ELSE NULL END,
       acct_unit4 =  CASE WHEN @compress <> 1 OR (@compress =1 AND @t_comp_level =1)  THEN @acct_unit4 ELSE NULL END,
       dom_amount = ISNULL(dom_amount, 0.0) + @amount,
       ref = @ref,
       vend_num = CASE WHEN @id <> 'PR Dist' THEN NULL ELSE @vend_num END,
       inv_num = CASE WHEN @id <> 'PR Dist' THEN NULL ELSE @inv_num END,
       voucher = case when @id = 'PR Dist' then @voucher
         when @compress = 1 then '0'
         when @id in ('AP Dist', 'PO Dist') then dbo.ExpandKy(@InvNumLength, @voucher)
         else @voucher
         end,
       check_num = CASE WHEN @id <> 'PR Dist' THEN 0 ELSE @check_num END,
       check_date  = CASE WHEN @id <> 'PR Dist' THEN NULL ELSE @check_date END,
       from_site = @from_site,
       matl_trans_num = CASE WHEN @id <> 'PR Dist' THEN 0 ELSE @trans_num END,
       ref_type = @ref_type ,
       ref_num = CASE WHEN @id <> 'PR Dist' THEN NULL ELSE @ref_num END,
       ref_line_suf = CASE WHEN @id <> 'PR Dist' THEN 0 ELSE @ref_line_suf END,
       ref_release = CASE WHEN @id <> 'PR Dist' THEN 0 ELSE @ref_release END,
       vouch_seq  = CASE WHEN @id <> 'PR Dist' THEN 0 ELSE @vouch_seq END,
       bank_code = @bank_code ,
       curr_code = CASE WHEN @compress=1 THEN @Prm_curr_code ELSE @curr_code END,
       for_amount = CASE WHEN @compress=1 THEN ISNULL(dom_amount, 0.0) + @amount ELSE for_amount + @for_amount END,
       exch_rate = CASE WHEN @compress=1 THEN 1 ELSE @exch_rate END,
       reverse = @reverse
     , control_prefix = case when @compress = 0 then @ControlPrefix end
     , control_site = case when @compress = 0 then @ControlSite end
     , control_year = case when @compress = 0 then @ControlYear end
     , control_period = case when @compress = 0 then @ControlPeriod end
     , control_number = case when @compress = 0 then @ControlNumber end
     , ref_control_prefix = case when @compress = 0 then @RefControlPrefix end
     , ref_control_site = case when @compress = 0 then @RefControlSite end
     , ref_control_year = case when @compress = 0 then @RefControlYear end
     , ref_control_period = case when @compress = 0 then @RefControlPeriod end
     , ref_control_number = case when @compress = 0 then @RefControlNumber end
     , proj_trans_num = @proj_trans_num
     , TH_payment_number = CASE WHEN @ThailandCountryPack = 1 THEN @THPaymentNumber ELSE NULL END
   WHERE id = @id and seq = @last_seq

   SET @Severity = @@ERROR
   IF @Severity <> 0
      RETURN @Severity
END

-- Still TODO : add code for notes

RETURN @Severity
