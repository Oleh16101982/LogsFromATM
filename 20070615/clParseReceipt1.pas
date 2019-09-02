unit clParseReceipt1;

interface
uses
	Windows, SysUtils, Variants, Classes, clLogAcceptor1 , ADODB, DB , activeX , comobj;
const
		UNREALDOUBLE : Double = -999999999.99;
   	UNREALINTEGER : Integer = HIGH(INTEGER);
   	UNREALDATE	: TDateTime = 0;

   	MAXROWOPEN = 15;
   	MAXROWCLOSE = 15;

type
	TOnWorkRcpt	= procedure (Sender : TObject ; AWorkCount : Cardinal) of object;
type
	TrecCassetteInfo = record
  	Picker 			: Integer;
    Nominal 		: Double;
    Currency		: String;
    Count 			: Integer;
    Ostatok 		: Integer;
    Vydano 			: Integer;
    Sbrosheno 	: Integer;
  end;

type TrecMTKARTInfo = record
  RestType								: Integer; // 0 - open ; 1 - private
  Address									: String;
  DateCheck								: TDateTime;
  Time										: TDateTime;
  ATMName									: String;
  Check	 							: String;
  Operation								: String;
  OpCode									: Integer;
	PAN 										: String;
  BankCode 								: String;
  Account 								: String;
  ValidThru 			  			: TDateTime;
  Currency 								: String;
  AmountBefore						: Double;
  AmountNeed							: Double;
  AmountOut								: Double;
  AmountAfter							: Double;
  Fee											: Double;
  ClientInfo							: String;
  ClientTrnNumber					: Integer;
  MerchantInfo						: String;
  MerchantTrnNumber				: Integer;
  MerchantTrnPacket				: Integer;
  ClientSertificate				: String;
  MerchantSertificate			: String;
  EndServiceDay 					: Integer;
  EndServiceOperation 		: Integer;

end;

type
	TrecListStl = record
    Date 				: TDateTime;
    CountTrn 		: Integer;
    Amount 			: Double;
    NumberPack 	: Integer;

  end;  

type
  TrecOpen = record
      Address							: String;
      DateCheck						: TDateTime;
      ATMName							: String;
      Check								: String;
      Operation						: String;
			CassetteInfo 				: array [1..4] of TrecCassetteInfo;
   		Zagruzheno 					: Double;
      Vydano 							: Double;
      CntSbros 						: Integer;
      Sdacha 							: Double;
      AmountSbroc 				: Double;
      CntCardZaderzhano 	: Integer;
      MTKARTSpisano 			: Double;
      PercentSpysano 			: Double;
      Storno 							: Double;
      KVyplate 						: Double;
      SpornajaSumma 			: Double;
      PANTerminala 				: String;
      PAcket 							: Integer;
      DatePacket 					: TDateTime;
      BalansPacket 				: Double;
      CntIPS 							: Integer;
      CntRetractIPS 			: Integer;
      VydanoIPS 					: Double;
      SoprnajaSummaIPS 		: Double;

  end;


type
	TrecClose = record
      Address							: String;
      DateCheck						: TDateTime;
      ATMName							: String;
      Check								: String;
      Operation						: String;
			CassetteInfo 				: array [1..4] of TrecCassetteInfo;
   		Zagruzheno 					: Double;
      Vydano 							: Double;
      CntSbros 						: Integer;
      Sdacha 							: Double;
      AmountSbroc 				: Double;
      CntCardZaderzhano 	: Integer;
      MTKARTSpisano 			: Double;
      PercentSpysano 			: Double;
      Storno 							: Double;
      KVyplate 						: Double;
      SpornajaSumma 			: Double;
      PANTerminala 				: String;
      PAcket 							: Integer;
      DatePacket 					: TDateTime;
      BalansPacket 				: Double;
      CntIPS 							: Integer;
      CntRetractIPS 			: Integer;
      VydanoIPS 					: Double;
      SoprnajaSummaIPS 		: Double;
      ListStl							: array of TrecListStl;
  end;

type
	TrecPresentCash = record
  	CardInfo : TrecMTKARTInfo;
    TypeAccount : boolean; // true - close; false - Open
    InAmount		: Double;
    Amount			: Double;
    OffAmount		: Double;
    Fee : Double;
    RestAmount : Double;
  end;
type
	TParseReceipt = class
    private
    	fLog : TLogAcceptor;
      fATMName 					: String;
  		fNamFil						: String;
      fTag 							: Integer;
      fSuccessParse			: boolean;
      fConn 						: TADOConnection;
      fProc1						: TADOStoredProc;
      fProc2						: TADOStoredProc;
      fProc3						: TADOStoredProc;
      fF 								: TextFile;
      fTmpStr 					: String;
      fPrevStr					: TStringList;

      farrOpenATM 			: array of TrecOpen;
      farrCloseATM 			: array of TrecClose;
      farrDispPriv			: array of TrecMTKARTInfo;
      farrDispOpen			: array of TrecMTKARTInfo;

      fStateOpenATM			: Integer;
      fStateCloseATM		: Integer;
      fCntRowOpenATM		: Integer;
      fCntRowCloseATM		: Integer;
      fStateDispPriv		: Integer;
      fStateDispOpen		: Integer;
      fCntRowDispPriv		: Integer;
      fCntRowDispOpen		: Integer;
      fRowCassette			: Integer;

      fCheckOpenATM			: boolean;
      fCheckCloseATM 		: boolean;
      fCheckPresentCash	: boolean;

      fOnWorkRcpt : TOnWorkRcpt;

      procedure fStateOpen;
      procedure fStateClose;
      procedure fStatePresentCash;
      procedure fCheckPriv;
      procedure fCheckOpen;
      function fDefNumCheck(str : String) : String;
      function fIsAbortOpen : boolean;
      function fIsAbortClose : boolean;
			function fDelDelimiter(Delimiter: Char ; Str : String): String;
     	function fGetDateCloseStl(str : String) : String;
     	function fGetTrnCloseStl(str : String) : String;
      function fGetAmountCloseStl(str : String) : String;
     	function fGetPacketCloseStl(str : String) : String;

      procedure fConnectSQL;
      procedure fDisconnectSQL;
      procedure fInsertSQL;
	   	procedure fInsertOpenATM;
	   	procedure fInsertCloseATM;

    public
    	constructor Create(isLog : boolean ; ATMName : String);
      Destructor Destroy;

      procedure Start;

      property Tag 	: Integer read fTag write fTag;
      property NamFil				: String  read	fNamFil 			 write fNamFil;
	   	property SuccessParse		: boolean read fSuccessParse write fSuccessParse;
      property CheckOpenATM			: boolean read  fCheckOpenATM		write fCheckOpenATM;
      property CheckCloseATM 		: boolean read  fCheckCloseATM 	write fCheckCloseATM;
      property CheckPresentCash : boolean read  fCheckPresentCash 	write fCheckPresentCash;

    	property OnWorkRcpt	: TOnWorkRcpt read fOnWorkRcpt write fOnWorkRcpt;
    end;


implementation

uses
	frmParsing1;
{ TParseJournal }

{ TParseReceipt }

constructor TParseReceipt.Create(isLog: boolean; ATMName: String);
begin
   if isLog then fLog := TLogAcceptor.Create('ParseReceipt_' + ATMName, frmParsing.fGlobalParams.Values['LocalDir']) ;
   fTag := StrToInt(ATMName);
   fATMName := ATMName;
   if Assigned(fLog) then fLog.Write('PArseJournal class create') ;
	 fConn := TADOConnection.Create(nil);
   fProc1 := TADOStoredProc.Create(nil);
   fProc2 := TADOStoredProc.Create(nil);
   fProc3 := TADOStoredProc.Create(nil);
//   fConn.ConnectionString := 'data source=S-EUROPAY;user id=sa;password=MasterCard;initial catalog=Translog';
   fConn.ConnectionString := 'Provider=SQLOLEDB.1;data source=S-EUROPAY;Integrated Security=SSPI;initial catalog=Translog';
   fConn.CommandTimeout := 10000;
   fConn.LoginPrompt := false;
   fConn.KeepConnection := true;
   fConn.ConnectionTimeout := 5000;
   fProc1.Connection := fConn;
   fProc1.CommandTimeout := 10000;
   fProc1.Parameters.Clear;
   fProc2.Connection := fConn;
   fProc2.CommandTimeout := 10000;
   fProc2.Parameters.Clear;
   fProc2.Connection := fConn;
   fProc2.CommandTimeout := 10000;
   fProc3.Connection := fConn;
   fProc3.CommandTimeout := 10000;
   fProc3.Parameters.Clear;
   fProc3.Connection := fConn;
   fProc3.CommandTimeout := 10000;


   SetLength(farrOpenATM , 0);
   SetLength(farrCloseATM , 0);
   fPrevStr := TstringList.Create;


end;

destructor TParseReceipt.Destroy;
begin
if Assigned (fLog)  then flog.Free;
if Assigned (fConn) then fConn.Free ;
if Assigned (fProc1) then fProc1.Free ;
if Assigned (fProc2) then fProc1.Free ;
if Assigned (fProc3) then fProc1.Free ;
if Assigned (fPrevStr) then fPrevStr.Free ;

end;

procedure TParseReceipt.fCheckOpen;
begin

end;

procedure TParseReceipt.fCheckPriv;
var
i , ind : Integer;
sAddress , sDate , sTime , sATM , sCheck : String;
begin
  SetLength(farrDispPriv , Length(farrDispPriv) + 1);
  ind := Length(fArrDispPriv) - 1;
  fArrDispPriv[ind].RestType := 1;
  if fPrevStr.Count > 1 then
  	fArrDispPriv[ind].Address := fPrevStr[1]
  else
  	fArrDispPriv[ind].Address := '';
  if fPrevStr.Count > 2 then
  	begin
    	sDate := Copy(fPrevStr[2] , 12 , 10);
      sDate[3] :='.';
      sDate[6] := '.';
      sTime := Copy(fPrevStr[2] , 35 , 8);
    end
  else
  	begin
    	sDate := '';
      sTime := '';
    end;
  if fPrevStr.Count > 3 then
  	begin
    	if Pos('#NCT#' , fPrevStr[3]) <> 0 then
      	fArrDispPriv[ind].ATMName := fDefNumCheck(fPrevStr[3])
      else
      	fArrDispPriv[ind].ATMName := Trim(Copy(fPrevStr[3] , 17));
      end
    else
    	begin
      	fArrDispPriv[ind].ATMName := '';
      end;
    if fPrevStr.Count > 4 then
    	fArrDispPriv[ind].Check := fDefNumCheck(fPrevStr[4])
    else
    	fArrDispPriv[ind].Check :=  '';

	if Assigned (fLog) then fLog.Write('DispPriv. adr - ' + fPrevStr[1] + '. date - ' + sDate + '. time - ' + sTime + '. atm - ' + Trim(Copy(fPrevStr[3] , 17)) + '. check - ' + fDefNumCheck(fPrevStr[4])) ;
  try
  	fArrDispPriv[ind].DateCheck := StrToDateTime (sDate + ' ' + sTime);
  except
  	on e : Exception do
    	begin
      	if Assigned(fLog) then fLog.Write('Error convert to Date Check DispPriv. ' + E.Message + E.ClassName ) ;
        fArrDispPriv[ind].DateCheck  := UNREALDATE;
      end;
  end;
  fPrevStr.Clear;
  fStateOpenATM := 1;
  fCntRowOpenATM := 0;
	if fStateOpenATM = 0 then
		exit;
	Inc(fCntRowOpenATM);
  if Pos('NL:' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].PAN := Trim(Copy(fTmpStr , 4));
    end;
  if Pos('LPE BAOLA   :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].BankCode := Trim(Copy(fTmpStr , 14));
    end;
  if Pos('OPNFR SYFTA :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].Account := Trim(Copy(fTmpStr , 14));
    end;
  if Pos('SRPL EFKSTC.:' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].ValidThru := StrToDateTime(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('CAM. LART]' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].Currency := Trim(Copy(fTmpStr , 14));
    end;
  if Pos('ISL         :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].AmountBefore := StrToFloat(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('SUNNA       :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].AmountNeed := StrToFloat(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('SQJSAOP     :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].AmountOut := StrToFloat(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('LPNNJSJa    :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].Fee := StrToFloat(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('SQJSAOP     :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].AmountOut := StrToFloat(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('PSTATPL ISL :' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].AmountAfter := StrToFloat(Trim(Copy(fTmpStr , 14)));
    end;
  if Pos('L:' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].ClientInfo := Trim(Copy(fTmpStr , 3 , 10));
    	fArrDispPriv[ind].ClientTrnNumber := StrToInt(Trim(Copy(fTmpStr , 19)));
    end;
  if Pos('N:' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].MerchantInfo := Trim(Copy(fTmpStr , 3 , 14));
    	fArrDispPriv[ind].MerchantTrnNumber := StrToInt(Trim(Copy(fTmpStr , 18 , 3)));
    	fArrDispPriv[ind].MerchantTrnPacket := StrToInt(Trim(Copy(fTmpStr , 22)));
    end;
  if Pos('SL:' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].ClientInfo := Trim(Copy(fTmpStr , 10 , 16));
    end;
  if Pos('SN:' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].ClientInfo := Trim(Copy(fTmpStr , 10 , 16));
    end;
  if Pos('EP LPOXA QFR. PBSM.' , fTmpStr) = 1 then
  	begin
    	fArrDispPriv[ind].EndServiceDay := StrToInt(Trim(Copy(fTmpStr , 20 , 4)));
    	fArrDispPriv[ind].EndServiceOperation := StrToInt(Trim(Copy(fTmpStr , 27 , 4)));
    end;
  if Pos('SQASJBP' , fTmpStr) = 1 then
  	begin
		  fStateOpenATM := 0;
		  fCntRowOpenATM := 0;
    end;


end;

procedure TParseReceipt.fConnectSQL;
begin
if Assigned(fLog) then fLog.Write('In Connect SQL') ;
	try
		fConn.Connected := true;
   except
   	on E : Exception do
if Assigned(fLog) then fLog.Write('Error Connect to SQL server. ' + E.Message + '. ' + E.ClassName ) ;
   end;
end;

function TParseReceipt.fDefNumCheck(str: String): String;
var
posBeg , PosEnd : Integer;
begin
	posBeg := Pos('#NCT#' , str) + Length('#NCT#') + 1;
  posEnd := Pos('#CCT#' , str);
	Result := Copy(str , PosBeg , PosEnd - PosBeg);
end;

function TParseReceipt.fDelDelimiter(Delimiter: Char; Str: String): String;
var
i : Integer;
tmpStr : String;
begin
tmpStr := '';
if Length(Str) > 0  then
begin
	for i := 0 to Length(Str) do
 		begin
	    if Str[i] <> Delimiter then
   	 	tmpStr := tmpStr + Str[i];
	   end;
   fDelDelimiter := tmpStr;
end;
end;

procedure TParseReceipt.fDisconnectSQL;
begin
if fConn.Connected  then
	fConn.Connected := false;
if Assigned(fLog) then fLog.Write('After DisConnect SQL') ;   
end;

function TParseReceipt.fGetAmountCloseStl(str: String): String;
var
promStr : String;
iBeg , iEnd : Integer;
i  , j , c : Integer;
begin
  c := 0;
  iBeg := 0;
  iEnd := 0;
	for i := 1 to Length(str) do
   	begin
    	if str[i] = ',' then
      	Inc(c);
      if ((iBeg = 0) and (c = 2)) then
        iBeg := i;
      if ((iEnd = 0) and (c = 3)) then
      	iEnd := i;
    end;
  promStr := Copy(str , iBeg + 1 , iEnd - (iBeg + 1));
// if Assigned(fLog) then flog.Write('GetAmountClose - ' + promStr);
  Result := promStr;
end;

function TParseReceipt.fGetDateCloseStl(str: String): String;
var
promStr : String;
begin
  promStr := Copy(Trim(str) , 1 , 19);
  promStr[3] := '.';
  promStr[6] := '.';
// if Assigned(fLog) then flog.Write('GetDateClose - ' + promStr);
 
  Result := promStr;
end;

function TParseReceipt.fGetPacketCloseStl(str: String): String;
var
promStr : String;
iBeg , iEnd : Integer;
i  , j , c : Integer;
begin
  c := 0;
  iBeg := 0;
  iEnd := 0;
	for i := 1 to Length(str) do
   	begin
    	if str[i] = ',' then
      	Inc(c);
      if ((iBeg = 0) and (c = 3)) then
        iBeg := i;
    end;
  promStr := Trim(Copy(str , iBeg + 1 ));
// if Assigned(fLog) then flog.Write('GetPacketClose - ' + promStr);
  Result := promStr;

end;

function TParseReceipt.fGetTrnCloseStl(str: String): String;
var
promStr : String;
iBeg , iEnd : Integer;
i  , j , c : Integer;
begin
  c := 0;
  iBeg := 0;
  iEnd := 0;
	for i := 1 to Length(str) do
   	begin
    	if str[i] = CHR(44) then
      	Inc(c);
      if ((iBeg = 0) and (c = 1)) then
        iBeg := i;
      if ((iEnd = 0) and (c = 2)) then
      	iEnd := i;
    end;

  promStr := Copy(str , iBeg + 1 , iEnd - (iBeg + 1));
// if Assigned(fLog) then flog.Write('GetTrnClose - ' + promStr);
  Result := promStr;
end;

procedure TParseReceipt.fInsertCloseATM;
var
i , j : Integer;
iTmpValue : Integer;
iRetErr , iRetId : Integer;
begin
if Assigned(fLog) then fLog.Write('In Close ATM');

	fProc1.ProcedureName := 'insert_CheckOPenCloseCycle';
  fProc2.ProcedureName := 'insert_CasseteInfo';
  fProc3.ProcedureName := 'insert_IncassList';
	if Assigned(fLog) then fLog.Write('Insert Balancing. ' + fProc1.ProcedureName );
	if Length(fArrCloseATM) > 0 then
		for i := 0 to Length(fArrCloseATM) - 1 do
    	begin
//	if Assigned(fLog) then fLog.Write('1 In Close ATM');
       fProc1.Parameters.Clear;
       fProc1.Parameters.CreateParameter('@atmName'	 					, ftString		, pdInput  , 50 , fArrCloseATM[i].ATMName           );
//	if Assigned(fLog) then fLog.Write('2 In Close ATM');
       fProc1.Parameters.CreateParameter('@Address'		 				, ftString		, pdInput  ,100 , fArrCloseATM[i].Address           );
       fProc1.Parameters.CreateParameter('@CheckNumber'				, ftString		, pdInput  , 10	, fArrCloseATM[i].Check 		         );
//	if Assigned(fLog) then fLog.Write('2.5 In Close ATM');
       fProc1.Parameters.CreateParameter('@atmNumber' 				, ftString		, pdInput  , 10 , fATMName           							 );
//	if Assigned(fLog) then fLog.Write('3 In Close ATM. date chrck - ' + DateTimeToStr(fArrCloseATM[i].DateCheck));
       if fArrCloseATM[i].DateCheck = UNREALDATE then
	       fProc1.Parameters.CreateParameter('@datetime' 					, ftDateTime  , pdInput  ,  8 , NULL)
       else
				fProc1.Parameters.CreateParameter('@datetime' 					, ftDateTime  , pdInput  ,  8 , fArrCloseATM[i].DateCheck );

       fProc1.Parameters.CreateParameter('@type' 							, ftInteger   , pdInput  ,  1 , 1); // 0 Close 1 - close          );

       if FloatToStrF(fArrCloseATM[i].Zagruzheno , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
       	fProc1.Parameters.CreateParameter('@AmountIn' 					, ftCurrency  , pdInput  , 10 , NULL)
       else
       	fProc1.Parameters.CreateParameter('@AmountIn' 					, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].Zagruzheno        );
//	if Assigned(fLog) then fLog.Write('4 In Close ATM');
       if FloatToStrF(fArrCloseATM[i].Vydano , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
              fProc1.Parameters.CreateParameter('@AmountDispensed' 	, ftCurrency  , pdInput  , 10 , NULL)
       else
	       fProc1.Parameters.CreateParameter('@AmountDispensed' 	, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].Vydano  );

       if FloatToStrF(fArrCloseATM[i].AmountSbroc  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
  	     fProc1.Parameters.CreateParameter('@AmountDivert' 			, ftCurrency  , pdInput  , 10 , NULL)
       else
	  	   fProc1.Parameters.CreateParameter('@AmountDivert' 			, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].AmountSbroc       );

       if FloatToStrF(fArrCloseATM[i].Sdacha  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@AmountOut' 				, ftCurrency  , pdInput  , 10 , NULL)
       else
  	     fProc1.Parameters.CreateParameter('@AmountOut' 				, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].Sdacha            );
//	if Assigned(fLog) then fLog.Write('5 In Close ATM');
       if fArrCloseATM[i].CntSbros = UNREALINTEGER then
    	   fProc1.Parameters.CreateParameter('@CntDivert' 				, ftInteger   , pdInput  ,  4 , NULL)
       else
      	 fProc1.Parameters.CreateParameter('@CntDivert' 				, ftInteger   , pdInput  ,  4 , fArrCloseATM[i].CntSbros          );

       if fArrCloseATM[i].CntCardZaderzhano = UNREALINTEGER then
       	fProc1.Parameters.CreateParameter('@CardsRetain' 			, ftInteger   , pdInput  ,  4 , NULL)
       else
				fProc1.Parameters.CreateParameter('@CardsRetain' 			, ftInteger   , pdInput  ,  4 , fArrCloseATM[i].CntCardZaderzhano );

       if FloatToStrF(fArrCloseATM[i].MTKARTSpisano  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
    	   fProc1.Parameters.CreateParameter('@MTAmount' 					, ftCurrency  , pdInput  , 10 , NULL)
       else
      	 fProc1.Parameters.CreateParameter('@MTAmount' 					, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].MTKARTSpisano     );

       if FloatToStrF(fArrCloseATM[i].PercentSpysano  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
       	fProc1.Parameters.CreateParameter('@MTFeeAmount' 			, ftCurrency  , pdInput  , 10 , NULL)
       else
       	fProc1.Parameters.CreateParameter('@MTFeeAmount' 			, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].PercentSpysano    );

       if FloatToStrF(fArrCloseATM[i].Storno  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@StornoAmount' 			, ftCurrency  , pdInput  , 10 , NULL )
       else
  	     fProc1.Parameters.CreateParameter('@StornoAmount' 			, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].Storno );
//	if Assigned(fLog) then fLog.Write('6 In Close ATM');
       if FloatToStrF(fArrCloseATM[i].KVyplate  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@ToPayAmount' 			, ftCurrency  , pdInput  , 10 , NULL)
      	else
  	     fProc1.Parameters.CreateParameter('@ToPayAmount' 			, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].KVyplate        );

       if FloatToStrF(fArrCloseATM[i].SpornajaSumma  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
  	     fProc1.Parameters.CreateParameter('@DispAmount' 				, ftCurrency  , pdInput  , 10 , NULL     )
       else
    	   fProc1.Parameters.CreateParameter('@DispAmount' 				, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].SpornajaSumma );

       fProc1.Parameters.CreateParameter('@PANTerminal' 			, ftString    , pdInput  , 25 , fArrCloseATM[i].PANTerminala      );

       if fArrCloseATM[i].PAcket = UNREALINTEGER then
       	fProc1.Parameters.CreateParameter('@MTPacketNumber' 		, ftInteger   , pdInput  ,  4 , NULL)
       else
       	fProc1.Parameters.CreateParameter('@MTPacketNumber' 		, ftInteger   , pdInput  ,  4 , fArrCloseATM[i].PAcket            );

       if fArrCloseATM[i].DatePacket = UNREALDATE then
  	     fProc1.Parameters.CreateParameter('@MTPacketDate'			, ftDateTime  , pdInput  ,  8 , NULL)
       else
	       fProc1.Parameters.CreateParameter('@MTPacketDate'			, ftDateTime  , pdInput  ,  8 , fArrCloseATM[i].DatePacket        );

       if FloatToStrF(fArrCloseATM[i].BalansPacket  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@MTPacketBalance' 	, ftCurrency  , pdInput  , 10 , NULL)
       else
  	     fProc1.Parameters.CreateParameter('@MTPacketBalance' 	, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].BalansPacket      );

       if fArrCloseATM[i].CntIPS = UNREALINTEGER then
    	   fProc1.Parameters.CreateParameter('@IPSCnt' 						, ftInteger   , pdInput  ,  4 , NULL)
       else
      	 fProc1.Parameters.CreateParameter('@IPSCnt' 						, ftInteger   , pdInput  ,  4 , fArrCloseATM[i].CntIPS            );
//	if Assigned(fLog) then fLog.Write('7 In Close ATM');
       if fArrCloseATM[i].CntRetractIPS = UNREALINTEGER then
		       fProc1.Parameters.CreateParameter('@IPSretractCnt' 		, ftInteger   , pdInput  ,  4 , NULL     )
      	else
    		   fProc1.Parameters.CreateParameter('@IPSretractCnt' 		, ftInteger   , pdInput  ,  4 , fArrCloseATM[i].CntRetractIPS     );

       if FloatToStrF(fArrCloseATM[i].VydanoIPS  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@IPSAmountOut' 			, ftCurrency  , pdInput  , 10 , NULL        )
       else
  	     fProc1.Parameters.CreateParameter('@IPSAmountOut' 			, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].VydanoIPS         );

       if FloatToStrF(fArrCloseATM[i].SoprnajaSummaIPS , ffFixed , 15 , 2)  = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
		       fProc1.Parameters.CreateParameter('@IPSDispAmount' 		, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].SoprnajaSummaIPS  )
      	else
    		   fProc1.Parameters.CreateParameter('@IPSDispAmount' 		, ftCurrency  , pdInput  , 10 , fArrCloseATM[i].SoprnajaSummaIPS  );

       fProc1.Parameters.CreateParameter('@filename'    , ftString  , pdInput 	, 250 , fNamFil);
//	if Assigned(fLog) then fLog.Write('8 In Close ATM');
       fProc1.Parameters.CreateParameter('@id' 								, ftInteger   , pdOutput  ,  4 , 0 );
       fProc1.Parameters.CreateParameter('@err' 							, ftInteger   , pdOutput  ,  4 , 0 );
       fProc1.Parameters.CreateParameter('@Mess' 							, ftString    , pdOutput ,  100 , 0  );
//	if Assigned(fLog) then fLog.Write('9 In Close ATM');
      	iRetErr := 0;
       try
       		fProc1.ExecProc ;
       except
       	on E : EOleException do
          	begin
if Assigned(fLog) then fLog.Write('EOleException exec proc.  ' + fProc1.ProcedureName + '. Code - ' + IntToStr(E.ErrorCode) + '. MSG - '  + E.Message + '. ' + E.ClassName ) ;
            	iRetErr := E.ErrorCode;
//            	exit;
            end;

       	on E : Exception do
          	begin
if Assigned(fLog) then fLog.Write('Exception exec proc Close ATM. ' + fProc1.ProcedureName + '. ' + E.Message + '. ' + E.ClassName ) ;
//            	exit;
            	iRetErr := -1;
            end;
			 end;
if Assigned(fLog) then fLog.Write('After proc1 close atm');
        if iRetErr = 0 then
        	begin
		       iRetErr := fProc1.Parameters.ParamByName('@err').Value ;
    		   if iRetErr = 0 then
		       	begin
				       iRetId := fProc1.Parameters.ParamByName('@id').Value ;
        			for j := 1 to 4 do
           			begin
		            	fProc2.Parameters.Clear;
									fProc2.Parameters.CreateParameter('@checkId' 	 , ftInteger , pdInput	, 4 , iRetId	 );

        		      if fArrCloseATM[i].CassetteInfo[j].Picker 		= UNREALINTEGER  	then
										fProc2.Parameters.CreateParameter('@Picker'    , ftInteger , pdInput	, 4 , NULL   )
		              else
    		            fProc2.Parameters.CreateParameter('@Picker'    , ftInteger , pdInput	, 4 , fArrCloseATM[i].CassetteInfo[j].Picker    );
        		      if FloatToStrF(fArrCloseATM[i].CassetteInfo[j].Nominal  , ffFixed , 15 , 2) 	= FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2)  	then
            		  	fProc2.Parameters.CreateParameter('@Nominal'   , ftCurrency, pdInput	,10 , NULL  )
		              else
    		            fProc2.Parameters.CreateParameter('@Nominal'   , ftCurrency, pdInput	,10 , fArrCloseATM[i].CassetteInfo[j].Nominal   );
//              if fArrCloseATM[i].CassetteInfo[j].Currency 	= ''							then fArrCloseATM[i].CassetteInfo[j].Currency 	:= ftNULL;
        		      if fArrCloseATM[i].CassetteInfo[j].Count 		= UNREALINTEGER  	then
            		  	fProc2.Parameters.CreateParameter('@Count'     , ftInteger , pdInput	, 4 , NULL     )
		              else
    		            fProc2.Parameters.CreateParameter('@Count'     , ftInteger , pdInput	, 4 , fArrCloseATM[i].CassetteInfo[j].Count     );
        		      if fArrCloseATM[i].CassetteInfo[j].Ostatok 	= UNREALINTEGER  	then
            		  	fProc2.Parameters.CreateParameter('@rest'   , ftInteger , pdInput	, 4 , NULL   )
		              else
    		          	fProc2.Parameters.CreateParameter('@rest'   , ftInteger , pdInput	, 4 , fArrCloseATM[i].CassetteInfo[j].Ostatok   );
        		      if fArrCloseATM[i].CassetteInfo[j].Vydano		= UNREALINTEGER  	then
  	        		    fProc2.Parameters.CreateParameter('@dispensed'    , ftInteger , pdInput	, 4 , NULL)
		              else
	  		            fProc2.Parameters.CreateParameter('@dispensed'    , ftInteger , pdInput	, 4 , fArrCloseATM[i].CassetteInfo[j].Vydano    );

        		      if fArrCloseATM[i].CassetteInfo[j].Sbrosheno = UNREALINTEGER  	then
            		  	fProc2.Parameters.CreateParameter('@divert' , ftInteger , pdInput	, 4 , NULL)
		              else
    		            fProc2.Parameters.CreateParameter('@divert' , ftInteger , pdInput	, 4 , fArrCloseATM[i].CassetteInfo[j].Sbrosheno );

          		    fProc2.Parameters.CreateParameter('@Ccy'  , ftString  , pdInput	, 5 , fArrCloseATM[i].CassetteInfo[j].Currency  );

      			 			fProc2.Parameters.CreateParameter('@err' 							, ftInteger   , pdOutput  ,  4 , 0                                );
					       	fProc2.Parameters.CreateParameter('@Mess' 							, ftString    , pdOutput  ,  100 , 0                                );
    		          try
        		      	fProc2.ExecProc ;
            		  except
		              	on E : Exception do
    		            	if Assigned(fLog) then fLog.Write('Exception exec proc2.  ' + fProc2.ProcedureName + '. '  + E.Message + '. ' + E.ClassName ) ;
        		      end; // try
            		end;
// if Assigned(fLog) then fLog.Write('After proc2 close atm. Len List Inkass - ' + IntToStr(Length(fArrCloseATM[i].ListStl)) + '. Len arrcloseATM - ' + IntToStr(Length(fArrCloseATM)));

		          if Length(fArrCloseATM[i].ListStl) > 0  then
    		      	begin
        		     	for j := 0 to Length(fArrCloseATM[i].ListStl) - 1 do
            		  	begin
                			fProc3.Parameters.Clear;

		                  fProc3.Parameters.CreateParameter('@checkId' 	 , ftInteger , pdInput		, 4 , iRetId												        );
    		              if fArrCloseATM[i].ListStl[j].Date 				= UNREALDATE 	 		then
	      		            fProc3.Parameters.CreateParameter('@date'      , ftDateTime, pdInput		, 8 , NULL)
            		      else
		    								fProc3.Parameters.CreateParameter('@date'      , ftDateTime, pdInput		, 8 , fArrCloseATM[i].ListStl[j].Date       );

      		            if fArrCloseATM[i].ListStl[j].CountTrn 		= UNREALINTEGER   then
	        		          fProc3.Parameters.CreateParameter('@countTrn'  , ftInteger , pdInput		, 4 , NULL)
		                  else
    		                fProc3.Parameters.CreateParameter('@countTrn'  , ftInteger , pdInput		, 4 , fArrCloseATM[i].ListStl[j].CountTrn   );

        		          if FloatToStrF(fArrCloseATM[i].ListStl[j].Amount  , ffFixed , 15 , 2) 			= FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2)    then
  	        		        fProc3.Parameters.CreateParameter('@Amount'    ,  ftCurrency, pdInput		,10 , NULL)
                		  else
			                  fProc3.Parameters.CreateParameter('@Amount'    ,  ftCurrency, pdInput		,10 , fArrCloseATM[i].ListStl[j].Amount );

      		            if fArrCloseATM[i].ListStl[j].NumberPack 	= UNREALINTEGER  	then
	        		          fProc3.Parameters.CreateParameter('@PackNumber',  ftInteger , pdInput		, 4 , NULL)
              		    else
		                    fProc3.Parameters.CreateParameter('@PackNumber',  ftInteger , pdInput		, 4 , fArrCloseATM[i].ListStl[j].NumberPack  );

	    			  			 	fProc3.Parameters.CreateParameter('@err' 								, ftInteger   , pdOutput  ,  4 , 0                             );
							       	fProc3.Parameters.CreateParameter('@Mess' 							, ftString    , pdOutput ,  100 , 0                           );
				              try
    				          	fProc3.ExecProc ;
        				      except
            				  	on E : Exception do
		                			if Assigned(fLog) then fLog.Write('Exception exec proc3.  ' + fProc1.ProcedureName + '. '  + E.Message + '. ' + E.ClassName ) ;
				              end; // try
// if Assigned(fLog) then fLog.Write('After proc3 close atm');
        		        end;
            		    SetLength(fArrCloseATM[i].ListStl , 0);
		            end;
            end;
        end;
      end;
	SetLength(farrCloseATM , 0);
end;

procedure TParseReceipt.fInsertOpenATM;
var
i , j : Integer;
iTmpValue : Integer;
iRetErr , iRetId : Integer;
begin
	fProc1.ProcedureName := 'insert_CheckOpenCloseCycle';
  fProc2.ProcedureName := 'insert_CasseteInfo';
	if Assigned(fLog) then fLog.Write('Insert OpenATM. ' + fProc1.ProcedureName );
	if Length(fArrOpenATM) > 0 then
		for i := 0 to Length(fArrOpenATM) - 1 do
    	begin
if Assigned(fLog) then fLog.Write('OPEN. i - ' + IntToStr(i) + '. check - ' + fArrOpenATM[i].Check);

       fProc1.Parameters.Clear;
       fProc1.Parameters.CreateParameter('@atmName'	 					, ftString		, pdInput  , 50 , fArrOpenATM[i].ATMName           );
       fProc1.Parameters.CreateParameter('@Address'		 				, ftString		, pdInput  ,100 , fArrOpenATM[i].Address           );
       fProc1.Parameters.CreateParameter('@CheckNumber'				, ftString		, pdInput  , 10	, fArrOpenATM[i].Check 		         );
       fProc1.Parameters.CreateParameter('@atmNumber' 				, ftString		, pdInput  , 10 , fATMName           							 );

      if fArrOpenATM[i].DateCheck = UNREALDATE then
	       fProc1.Parameters.CreateParameter('@datetime' 					, ftDateTime  , pdInput  ,  8 , NULL)
       else
				fProc1.Parameters.CreateParameter('@datetime' 					, ftDateTime  , pdInput  ,  8 , fArrOpenATM[i].DateCheck );

       fProc1.Parameters.CreateParameter('@type' 							, ftInteger   , pdInput  ,  1 , 0); // 0 Open 1 - close          );

       if FloatToStrF(fArrOpenATM[i].Zagruzheno , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
       	fProc1.Parameters.CreateParameter('@AmountIn' 					, ftCurrency  , pdInput  , 10 , NULL)
       else
       	fProc1.Parameters.CreateParameter('@AmountIn' 					, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].Zagruzheno        );
//	if Assigned(fLog) then fLog.Write('4 In Open ATM');
       if FloatToStrF(fArrOpenATM[i].Vydano , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
              fProc1.Parameters.CreateParameter('@AmountDispensed' 	, ftCurrency  , pdInput  , 10 , NULL)
       else
	       fProc1.Parameters.CreateParameter('@AmountDispensed' 	, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].Vydano  );

       if FloatToStrF(fArrOpenATM[i].AmountSbroc  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
  	     fProc1.Parameters.CreateParameter('@AmountDivert' 			, ftCurrency  , pdInput  , 10 , NULL)
       else
	  	   fProc1.Parameters.CreateParameter('@AmountDivert' 			, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].AmountSbroc       );

       if FloatToStrF(fArrOpenATM[i].Sdacha  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@AmountOut' 				, ftCurrency  , pdInput  , 10 , NULL)
       else
  	     fProc1.Parameters.CreateParameter('@AmountOut' 				, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].Sdacha            );
//	if Assigned(fLog) then fLog.Write('5 In Open ATM');
       if fArrOpenATM[i].CntSbros = UNREALINTEGER then
    	   fProc1.Parameters.CreateParameter('@CntDivert' 				, ftInteger   , pdInput  ,  4 , NULL)
       else
      	 fProc1.Parameters.CreateParameter('@CntDivert' 				, ftInteger   , pdInput  ,  4 , fArrOpenATM[i].CntSbros          );

       if fArrOpenATM[i].CntCardZaderzhano = UNREALINTEGER then
       	fProc1.Parameters.CreateParameter('@CardsRetain' 			, ftInteger   , pdInput  ,  4 , NULL)
       else
				fProc1.Parameters.CreateParameter('@CardsRetain' 			, ftInteger   , pdInput  ,  4 , fArrOpenATM[i].CntCardZaderzhano );

       if FloatToStrF(fArrOpenATM[i].MTKARTSpisano  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
    	   fProc1.Parameters.CreateParameter('@MTAmount' 					, ftCurrency  , pdInput  , 10 , NULL)
       else
      	 fProc1.Parameters.CreateParameter('@MTAmount' 					, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].MTKARTSpisano     );

       if FloatToStrF(fArrOpenATM[i].PercentSpysano  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
       	fProc1.Parameters.CreateParameter('@MTFeeAmount' 			, ftCurrency  , pdInput  , 10 , NULL)
       else
       	fProc1.Parameters.CreateParameter('@MTFeeAmount' 			, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].PercentSpysano    );

       if FloatToStrF(fArrOpenATM[i].Storno  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@StornoAmount' 			, ftCurrency  , pdInput  , 10 , NULL )
       else
  	     fProc1.Parameters.CreateParameter('@StornoAmount' 			, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].Storno );
//	if Assigned(fLog) then fLog.Write('6 In Open ATM');
       if FloatToStrF(fArrOpenATM[i].KVyplate  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@ToPayAmount' 			, ftCurrency  , pdInput  , 10 , NULL)
      	else
  	     fProc1.Parameters.CreateParameter('@ToPayAmount' 			, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].KVyplate        );

       if FloatToStrF(fArrOpenATM[i].SpornajaSumma  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
  	     fProc1.Parameters.CreateParameter('@DispAmount' 				, ftCurrency  , pdInput  , 10 , NULL     )
       else
    	   fProc1.Parameters.CreateParameter('@DispAmount' 				, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].SpornajaSumma );

       fProc1.Parameters.CreateParameter('@PANTerminal' 			, ftString    , pdInput  , 25 , fArrOpenATM[i].PANTerminala      );

       if fArrOpenATM[i].PAcket = UNREALINTEGER then
       	fProc1.Parameters.CreateParameter('@MTPacketNumber' 		, ftInteger   , pdInput  ,  4 , NULL)
       else
       	fProc1.Parameters.CreateParameter('@MTPacketNumber' 		, ftInteger   , pdInput  ,  4 , fArrOpenATM[i].PAcket            );

       if fArrOpenATM[i].DatePacket = UNREALDATE then
  	     fProc1.Parameters.CreateParameter('@MTPacketDate'			, ftDateTime  , pdInput  ,  8 , NULL)
       else
	       fProc1.Parameters.CreateParameter('@MTPacketDate'			, ftDateTime  , pdInput  ,  8 , fArrOpenATM[i].DatePacket        );

       if FloatToStrF(fArrOpenATM[i].BalansPacket  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@MTPacketBalance' 	, ftCurrency  , pdInput  , 10 , NULL)
       else
  	     fProc1.Parameters.CreateParameter('@MTPacketBalance' 	, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].BalansPacket      );

       if fArrOpenATM[i].CntIPS = UNREALINTEGER then
    	   fProc1.Parameters.CreateParameter('@IPSCnt' 						, ftInteger   , pdInput  ,  4 , NULL)
       else
      	 fProc1.Parameters.CreateParameter('@IPSCnt' 						, ftInteger   , pdInput  ,  4 , fArrOpenATM[i].CntIPS            );
//	if Assigned(fLog) then fLog.Write('7 In Open ATM');
       if fArrOpenATM[i].CntRetractIPS = UNREALINTEGER then
		       fProc1.Parameters.CreateParameter('@IPSretractCnt' 		, ftInteger   , pdInput  ,  4 , NULL     )
      	else
    		   fProc1.Parameters.CreateParameter('@IPSretractCnt' 		, ftInteger   , pdInput  ,  4 , fArrOpenATM[i].CntRetractIPS     );

       if FloatToStrF(fArrOpenATM[i].VydanoIPS  , ffFixed , 15 , 2) = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
	       fProc1.Parameters.CreateParameter('@IPSAmountOut' 			, ftCurrency  , pdInput  , 10 , NULL        )
       else
  	     fProc1.Parameters.CreateParameter('@IPSAmountOut' 			, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].VydanoIPS         );

       if FloatToStrF(fArrOpenATM[i].SoprnajaSummaIPS , ffFixed , 15 , 2)  = FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2) then
		       fProc1.Parameters.CreateParameter('@IPSDispAmount' 		, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].SoprnajaSummaIPS  )
      	else
    		   fProc1.Parameters.CreateParameter('@IPSDispAmount' 		, ftCurrency  , pdInput  , 10 , fArrOpenATM[i].SoprnajaSummaIPS  );


       fProc1.Parameters.CreateParameter('@filename'    , ftString  , pdInput 	, 250 , fNamFil);
       fProc1.Parameters.CreateParameter('@id' 								, ftInteger   , pdOutput  ,  4 , 0                                );
       fProc1.Parameters.CreateParameter('@err' 							, ftInteger   , pdOutput  ,  4 , 0                                );
       fProc1.Parameters.CreateParameter('@Mess' 							, ftString    , pdOutput  ,  100 , 0                                );
       iRetErr := 0;
       try
       		fProc1.ExecProc ;
       except
       	on E : EOleException do
          	begin
if Assigned(fLog) then fLog.Write('EOleException exec proc.  ' + fProc1.ProcedureName + '. Code - ' + IntToStr(E.ErrorCode) + '. MSG - '  + E.Message + '. ' + E.ClassName ) ;
            	iRetErr := E.ErrorCode;
            end;
       	on E : Exception do
          	begin
if Assigned(fLog) then fLog.Write('Exception exec proc.  ' + fProc1.ProcedureName + '. '  + E.Message + '. ' + E.ClassName ) ;
            	iRetErr := -1;
            end;
			 end;

if Assigned(fLog) then fLog.Write('After proc1 OPEN atm');
        if iRetErr = 0 then
        	begin
		       iRetErr := fProc1.Parameters.ParamByName('@err').Value ;
    		   if iRetErr = 0 then
       			begin
			       iRetId := fProc1.Parameters.ParamByName('@id').Value ;
    		    	for j := 1 to 4 do
        		   	begin
            			fProc2.Parameters.Clear;
									fProc2.Parameters.CreateParameter('@checkId'    , ftInteger , pdInput	, 4 , iRetId ) ;
    		          if fArrOpenATM[i].CassetteInfo[j].Picker 		= UNREALINTEGER  	then
										fProc2.Parameters.CreateParameter('@Picker'    , ftInteger , pdInput	, 4 , NULL   )
            		  else
                		fProc2.Parameters.CreateParameter('@Picker'    , ftInteger , pdInput	, 4 , fArrOpenATM[i].CassetteInfo[j].Picker    );
		              if FloatToStrF(fArrOpenATM[i].CassetteInfo[j].Nominal  , ffFixed , 15 , 2) 	= FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2)  	then
    		          	fProc2.Parameters.CreateParameter('@Nominal'   , ftCurrency, pdInput	,10 , NULL  )
        		      else
            		    fProc2.Parameters.CreateParameter('@Nominal'   , ftCurrency, pdInput	,10 , fArrOpenATM[i].CassetteInfo[j].Nominal   );
//              if fArrOpenATM[i].CassetteInfo[j].Currency 	= ''							then fArrOpenATM[i].CassetteInfo[j].Currency 	:= ftNULL;
		              if fArrOpenATM[i].CassetteInfo[j].Count 		= UNREALINTEGER  	then
    		          	fProc2.Parameters.CreateParameter('@Count'     , ftInteger , pdInput	, 4 , NULL     )
        		      else
            		    fProc2.Parameters.CreateParameter('@Count'     , ftInteger , pdInput	, 4 , fArrOpenATM[i].CassetteInfo[j].Count     );
		              if fArrOpenATM[i].CassetteInfo[j].Ostatok 	= UNREALINTEGER  	then
    		          	fProc2.Parameters.CreateParameter('@rest'   , ftInteger , pdInput	, 4 , NULL   )
        		      else
            		  	fProc2.Parameters.CreateParameter('@rest'   , ftInteger , pdInput	, 4 , fArrOpenATM[i].CassetteInfo[j].Ostatok   );
		              if fArrOpenATM[i].CassetteInfo[j].Vydano		= UNREALINTEGER  	then
  			            fProc2.Parameters.CreateParameter('@dispensed'    , ftInteger , pdInput	, 4 , NULL)
        		      else
	          		    fProc2.Parameters.CreateParameter('@dispensed'    , ftInteger , pdInput	, 4 , fArrOpenATM[i].CassetteInfo[j].Vydano    );

  		            if fArrOpenATM[i].CassetteInfo[j].Sbrosheno = UNREALINTEGER  	then
      		        	fProc2.Parameters.CreateParameter('@divert' , ftInteger , pdInput	, 4 , NULL)
          		    else
              		  fProc2.Parameters.CreateParameter('@divert' , ftInteger , pdInput	, 4 , fArrOpenATM[i].CassetteInfo[j].Sbrosheno );

		              fProc2.Parameters.CreateParameter('@Ccy'  , ftString  , pdInput	, 5 , fArrOpenATM[i].CassetteInfo[j].Currency  );

    		  			 	fProc2.Parameters.CreateParameter('@err' 							, ftInteger   , pdOutput  ,  4 , 0                                );
			  		     	fProc2.Parameters.CreateParameter('@Mess' 							, ftString    , pdOutput  ,  100 , 0                                );
            		  try
		              	fProc2.ExecProc ;
    		          except
        		      	on E : Exception do
            		    	if Assigned(fLog) then fLog.Write('Exception exec proc2.  ' + fProc2.ProcedureName + '. '  + E.Message + '. ' + E.ClassName ) ;
		              end; // try
if Assigned(fLog) then fLog.Write('After proc2 OPEN atm');
		            end;
            end;
        end;
      end;
		SetLength(farrOpenATM , 0);      
end;

procedure TParseReceipt.fInsertSQL;
begin
if Assigned(fLog) then fLog.Write('In INSERT SQL. fAtmName - ' + fATMName) ;
	fConnectSQL;
	   if fConn.Connected  then
   		begin
	   		if fCheckOpenATM then
   	   		fInsertOpenATM;
	   		if fCheckCloseATM then
   	   		fInsertCloseATM;
   			fDisconnectSQL;
      end;

end;

function TParseReceipt.fIsAbortClose: boolean;
var
retVAl : boolean;
begin
retVal := false;
	if EOF(fF) then
  	begin
    	retVAl := true;
    end;
  if fCntRowOpenATM > MAXROWCLOSE then
  	begin
     retVAl := true;
    end;
Result := retval
end;

function TParseReceipt.fIsAbortOpen: boolean;
var
retVAl : boolean;
begin
retVal := false;
	if EOF(fF) then
  	begin
    	retVAl := true;
    end;
  if fCntRowOpenATM > MAXROWOPEN then
  	begin
     retVAl := true;
    end;
Result := retval
end;

procedure TParseReceipt.fStateClose;
var
ind : Integer;
sAddress , sDate , sTime , sATM , sCheck : String;
begin
	if Pos('IALR]TJF BAOLPNATA' , ftmpStr) <> 0  then
  	begin
    	SetLength(farrCloseAtm , Length(fArrCloseATM) + 1);
			ind := Length(fArrCloseATM) - 1;
      fStateCloseATM := 1;
      fCntRowCloseATM := 0;
      fRowCassette := 0;
      if fPrevStr.Count > 1 then
	      fArrCloseATM[ind].Address := fPrevStr[1]
      else
      	fArrCloseATM[ind].Address := '';
      if fPrevStr.Count > 2 then
      	begin
		      sDate := Copy(fPrevStr[2] , 12 , 10);
    		  sDate[3] :='.';
		      sDate[6] := '.';
    		  sTime := Copy(fPrevStr[2] , 35 , 8);
        end
      else
      	begin
	      	sDate := '';
          sTime := '';
        end;
      if fPrevStr.Count > 3 then
      	begin
		      if Pos('#NCT#' , fPrevStr[3]) <> 0 then
			      fArrCloseATM[ind].ATMName := fDefNumCheck(fPrevStr[3])
    		  else
	    		  fArrCloseATM[ind].ATMName := Trim(Copy(fPrevStr[3] , 17));
        end
      else
      	begin
        	fArrCloseATM[ind].ATMName := '';
        end;
      if fPrevStr.Count > 4 then
      	fArrCloseATM[ind].Check := fDefNumCheck(fPrevStr[4])
      else
      	fArrCloseATM[ind].Check :=  '';

if Assigned (fLog) then fLog.Write('CLOSE. adr - ' + fPrevStr[1] + '. date - ' + sDate + '. time - ' + sTime + '. atm - ' + Trim(Copy(fPrevStr[3] , 17)) + '. check - ' + fDefNumCheck(fPrevStr[4])) ;
    	try
      	fArrCloseATM[ind].DateCheck := StrToDateTime (sDate + ' ' + sTime);
      except
        on e : Exception do
        	begin
							if Assigned(fLog) then fLog.Write('Error convert to Date Check CloseATM. ' + E.Message + E.ClassName ) ;
  	          fArrCloseATM[ind].DateCheck  := UNREALDATE;
          end;
      end;
      fPrevStr.Clear;
    end;
	if fStateCloseATM = 0 then
		exit;
	Inc(fCntRowCloseATM);
	ind := Length(fArrCloseATM) - 1;
	if fStateCloseATM = 1 then
		begin
	  	if fIsAbortClose then
  	  begin
    		fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
	    end;
// if Assigned(fLog) then fLog.Write('State 1 ' + fTmpStr + '. Index of cassette - ' + IntToStr(fRowCassette));

  	  if ((Ord(fTmpStr[1]) > $2F) and (Ord(fTmpStr[1]) < $3A)) then
    	begin
    		Inc(fRowCassette);
	      try
  	    	fArrCloseATM[ind].CassetteInfo[fRowCassette ].Picker 		:= StrToInt(fTmpStr[1]);
    	  except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Picker CloseATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
  	          fArrCloseATM[ind].CassetteInfo[fRowCassette].Picker := UNREALINTEGER;
    	      end;
      	end;
	      try
  	    	fArrCloseATM[ind].CassetteInfo[fRowCassette].Nominal 	:= StrToInt(Trim(Copy(fTmpStr , 2 , 5)));
    	  except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to nominal CloseATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
            	fArrCloseATM[ind].CassetteInfo[fRowCassette].Nominal := UNREALINTEGER;
	          end;
  	      end;
        if Length(fTmpStr) > 0  then
	    	  fArrCloseATM[ind].CassetteInfo[fRowCassette].Currency 	:= Trim(Copy(fTmpStr , 13 , 3))
        else
					fArrCloseATM[ind].CassetteInfo[fRowCassette].Currency 	:= '';
      	try
      		fArrCloseATM[ind].CassetteInfo[fRowCassette].Count 		:= StrToInt(Trim(Copy(fTmpStr , 21 , 5)));
	      except
  	    	on E : Exception do
    	    	begin
							if Assigned(fLog) then fLog.Write('Error convert to count CloseATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
        	    fArrCloseATM[ind].CassetteInfo[fRowCassette].Count := UNREALINTEGER;
          	end;
	      end;
  	    try
    	  	fArrCloseATM[ind].CassetteInfo[fRowCassette].Ostatok  	:= StrToInt(Trim(Copy(fTmpStr , 26 , 5)));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to OSTATOK CloseATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].CassetteInfo[fRowCassette].Ostatok := UNREALINTEGER;
  	        end;
    	  end;
      	try
      		fArrCloseATM[ind].CassetteInfo[fRowCassette].Vydano 		:= StrToInt(Trim(Copy(fTmpStr , 31 , 5)));
	      except
  	    	on E : Exception do
    	    	begin
							if Assigned(fLog) then fLog.Write('Error convert to Vydano CloseATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
							fArrCloseATM[ind].CassetteInfo[fRowCassette].Vydano := UNREALINTEGER;
          	end;
	      end;
  	    try
    	  	fArrCloseATM[ind].CassetteInfo[fRowCassette ].Sbrosheno	:= StrToInt(Trim(Copy(fTmpStr , 36 , 5)));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Sbrosheno CloseATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].CassetteInfo[fRowCassette ].Sbrosheno := UNREALINTEGER;
  	        end;
    	  end;
	    end;

  	  if ((fRowCassette > 0) and (Pos('-------------------------' , fTmpStr) <> 0)) then
    	  begin
      	 fStateCloseATM := 2;
	       fCntRowCloseATM := 0;
  	    end;
	  end;
	if fStateCloseATM = 2 then
  	begin
  		if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 2 ' + fTmpStr);
  	  if Pos('IADRUHFOP' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].Zagruzheno := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Zagruzheno CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].Zagruzheno := UNREALDOUBLE;
if Assigned(fLog) then fLog.Write('Zagruzheno - ' + FloatToStrF(fArrCloseATM[ind].Zagruzheno , ffFixed , 15 , 2));
  	        end;
        end;
      	fStateCloseATM := 3;
      	fCntRowCloseATM := 0;
      end;
    end;
	if fStateCloseATM = 3 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 3 ' + fTmpStr);
    if Pos('C]EAOP' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].Vydano := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Vydano CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].Vydano := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 4;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 4 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 4 ' + fTmpStr);
    if Pos('YJSMP SBR' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].CntSbros := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntSbros CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].CntSbros := UNREALINTEGER;
  	        end;
        end;
       	fStateCloseATM := 5;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 5 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 5 ' + fTmpStr);
    if Pos('L SEAYF' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].Sdacha := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Sdacha CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].Sdacha := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 6;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 6 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 6 ' + fTmpStr);
    if Pos('CBRPZFOP' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].AmountSbroc  := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to AmountSbroc CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].AmountSbroc := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 7;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 7 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 7 ' + fTmpStr);
    if Pos('IAEFRHAOP LART' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].CntCardZaderzhano := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 20))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntCardZaderzhano CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].CntCardZaderzhano := UNREALINTEGER;
  	        end;
        end;
       	fStateCloseATM := 8;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 8 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 8 ' + fTmpStr);
    if Pos('SQJSAOP S LMJFOTPC' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].MTKARTSpisano := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to MTKARTSpisano  CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].MTKARTSpisano := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 9;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 9 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 9 ' + fTmpStr);
    if Pos('JI OJW QRPXFOT]' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].PercentSpysano := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to PercentSpysano   CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].PercentSpysano  := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 10;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 10 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 10 ' + fTmpStr);
    if Pos('EMa STPROJRPCAOJa' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].Storno  := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Storno    CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].Storno   := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 11;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 11 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 11 ' + fTmpStr);
    if Pos('L C]QMATF LMJFOTAN' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].KVyplate   := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 20))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to KVyplate CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].KVyplate   := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 12;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 12 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 12 ' + fTmpStr);
    if Pos('SQPROAa SUNNA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].SpornajaSumma   := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to SpornajaSumma CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].SpornajaSumma   := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 13;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 13 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 13 ' + fTmpStr);
    if Pos('OPNFR #NCT#MK#CCT#' , fTmpStr) <> 0 then
    	begin
      	fArrCloseATM[ind].PANTerminala    := Copy(fTmpStr , 20);
       	fStateCloseATM := 14;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 14 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 14 ' + fTmpStr);
    if Pos('QALFT' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].PAcket := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 7 , 5))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to PAcket CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].Packet := UNREALINTEGER;
  	        end;
        end;
      	try
	        fArrCloseATM[ind].DatePacket := StrToDateTime(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 17 , 10))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to DatePacket CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].DatePacket := UNREALDATE;
  	        end;
        end;

       	fStateCloseATM := 15;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 15 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 15 ' + fTmpStr);
    if Pos('BAMAOS QALFTA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].BalansPacket   := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 15))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to BalansPacket CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].BalansPacket   := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 16;
      	fCntRowCloseATM := 0;
      end;
	end;
  if fStateCloseATM = 16 then
  	begin
	  	if fIsAbortClose then
  	  	begin
    	   	fStateCloseATM := 0;
      		fCntRowCloseATM := 0;
	      end;
      if Pos('QMATFHOAa SJSTFNA' , fTmpStr) <> 0 then
        begin
         fStateCloseATM := 18;
         fCntRowCloseATM := 0;
        end;

	    if Pos('SQJSPL JOLASSAXJK:' , fTmpStr) <> 0 then
        begin
         fStateCloseATM := 17;
         fCntRowCloseATM := 0;
        end;
		end;
  if fStateCloseATM = 17 then
  	begin
	  	if fIsAbortClose then
  	  	begin
    	   	fStateCloseATM := 0;
      		fCntRowCloseATM := 0;
	      end;
      if Length(fTmpStr) > 0  then
      	begin
		      if Pos('QMATFHOAa SJSTFNA' , fTmpStr) <> 0 then
    		    begin
        		 fStateCloseATM := 18;
		         fCntRowCloseATM := 0;
    		    end;
		      	if (((Ord(fTmpStr[1]) > $2F) and (Ord(fTmpStr[1]) < $3A))) and
    		    	 (((Ord(fTmpStr[2]) > $2F) and (Ord(fTmpStr[2]) < $3A))) then
            	begin
			         	SetLength(farrCloseATM[ind].ListStl , Length(farrCloseATM[ind].ListStl) + 1);
    			      try
      	  		    farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].Date := StrToDateTime(fgetDateCloseSTL(fTmpStr));
		    	      except
    		  	    	on E : Exception do
        			    	begin
											if Assigned(fLog) then fLog.Write('Error convert to Date STL CloseATM. ' + E.Message + E.ClassName ) ;
	            					farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].Date  := UNREALDATE;
		              	end;
	    	    	  end;
  	    		    try
    	        		farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].CountTrn := StrToInt(fgetTrnCloseSTL(fTmpStr));
      	        except
		    	      	on E : Exception do
    		  	      	begin
											if Assigned(fLog) then fLog.Write('Error convert to Count TRN STL CloseATM. ' + E.Message + E.ClassName ) ;
	          			  		farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].CountTrn  := UNREALINTEGER;
		            	  end;
	    		      end;
  	      		  try
    	        		farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].Amount := StrToFloat(fgetAmountCloseSTL(fTmpStr));
		  	        except
    			      	on E : Exception do
        			    	begin
											if Assigned(fLog) then fLog.Write('Error convert to Amount STL CloseATM. ' + E.Message + E.ClassName ) ;
	            					farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].Amount  := UNREALDOUBLE;
		            	  end;
	    		      end;
  	      		  try
    	        		farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].NumberPack := StrToInt(fgetPacketCloseSTL(fTmpStr));
		  	        except
    			      	on E : Exception do
        			    	begin
											if Assigned(fLog) then fLog.Write('Error convert to NumberPack STL CloseATM. ' + E.Message + E.ClassName ) ;
	            					farrCloseATM[ind].ListStl[Length(farrCloseATM[ind].ListStl) - 1].NumberPack  := UNREALINTEGER;
		            	  end;
	    		      end;
            	end;
        end;
		end;
	if fStateCloseATM = 18 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 18 ' + fTmpStr);
    if Pos('YJSMP TR-XJK' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].CntIPS := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 17))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntIPS CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].CntIPS := UNREALINTEGER;
  	        end;
        end;
       	fStateCloseATM := 19;
      	fCntRowCloseATM := 0;
      end;
	end;
	if fStateCloseATM = 19 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 19 ' + fTmpStr);
    if ((Pos('YJSMP' , fTmpStr) <> 0) and (Pos('RETRACT' , fTmpStr) <> 0)) then
    	begin
      	try
	        fArrCloseATM[ind].CntRetractIPS := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 27))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntRetractIPS CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].CntRetractIPS := UNREALINTEGER;
  	        end;
        end;
       	fStateCloseATM := 20;
      	fCntRowCloseATM := 0;
      end;
	end;
 	if fStateCloseATM = 20 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 20 ' + fTmpStr);
    if Pos('C]EAOOAa SUNNA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].VydanoIPS := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 23 , 10))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to VydanoIPS CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].VydanoIPS   := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 21;
      	fCntRowCloseATM := 0;
      end;
	end;
 	if fStateCloseATM = 21 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 21 ' + fTmpStr);
    if Pos('SQPROAa SUNNA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrCloseATM[ind].SoprnajaSummaIPS := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 23 , 10))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to SoprnajaSummaIPS  CloseATM. ' + E.Message + E.ClassName ) ;
	            fArrCloseATM[ind].SoprnajaSummaIPS := UNREALDOUBLE;
  	        end;
        end;
       	fStateCloseATM := 22;
      	fCntRowCloseATM := 0;
      end;
	end;
 	if fStateCloseATM = 22 then
	begin
  	if fIsAbortClose then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 22 ' + fTmpStr);
    if Pos('=======================================' , fTmpStr) <> 0 then
    	begin
       	fStateCloseATM := 0;
      	fCntRowCloseATM := 0;
      end;
	end;
end;

procedure TParseReceipt.fStateOpen;
var
i , ind : Integer;
sAddress , sDate , sTime , sATM , sCheck : String;
begin
	if Pos('PTLR]TJF BAOLPNATA' , ftmpStr) <> 0  then
  	begin
    	SetLength(farrOpenAtm , Length(fArrOpenATM) + 1);
			ind := Length(fArrOpenATM) - 1;
      for i := 1 to 4 do
       	begin
        	farrOpenAtm[ind].CassetteInfo[i].Picker   	:= UNREALINTEGER;
          farrOpenAtm[ind].CassetteInfo[i].Nominal    := UNREALDOUBLE;
          farrOpenAtm[ind].CassetteInfo[i].Currency   := '';
          farrOpenAtm[ind].CassetteInfo[i].Count      := UNREALINTEGER;
          farrOpenAtm[ind].CassetteInfo[i].Ostatok    := UNREALINTEGER;
          farrOpenAtm[ind].CassetteInfo[i].Vydano     := UNREALINTEGER;
          farrOpenAtm[ind].CassetteInfo[i].Sbrosheno  := UNREALINTEGER;
        end;
      fStateOpenATM := 1;
      fCntRowOpenATM := 0;
      fRowCassette := 0;
      if fPrevStr.Count > 1 then
	      fArrOpenATM[ind].Address := fPrevStr[1]
      else
      	fArrOpenATM[ind].Address := '';
      if fPrevStr.Count > 2 then
      	begin
		      sDate := Copy(fPrevStr[2] , 12 , 10);
    		  sDate[3] :='.';
		      sDate[6] := '.';
    		  sTime := Copy(fPrevStr[2] , 35 , 8);
        end
      else
      	begin
	      	sDate := '';
          sTime := '';
        end;
      if fPrevStr.Count > 3 then
      	begin
		      if Pos('#NCT#' , fPrevStr[3]) <> 0 then
			      fArrOpenATM[ind].ATMName := fDefNumCheck(fPrevStr[3])
    		  else
	    		  fArrOpenATM[ind].ATMName := Trim(Copy(fPrevStr[3] , 17));
        end
      else
      	begin
        	fArrOpenATM[ind].ATMName := '';
        end;
      if fPrevStr.Count > 4 then
      	fArrOpenATM[ind].Check := fDefNumCheck(fPrevStr[4])
      else
      	fArrOpenATM[ind].Check :=  '';

if Assigned (fLog) then fLog.Write('OPEN. adr - ' + fPrevStr[1] + '. date - ' + sDate + '. time - ' + sTime + '. atm - ' + Trim(Copy(fPrevStr[3] , 17)) + '. check - ' + fDefNumCheck(fPrevStr[4])) ;
    	try
      	fArrOpenATM[ind].DateCheck := StrToDateTime (sDate + ' ' + sTime);
      except
        on e : Exception do
        	begin
							if Assigned(fLog) then fLog.Write('Error convert to Date Check OPENATM. ' + E.Message + E.ClassName ) ;
  	          fArrOpenATM[ind].DateCheck  := UNREALDATE;
          end;
      end;
      fPrevStr.Clear;
    end;
	if fStateOpenATM = 0 then
		exit;
	Inc(fCntRowOpenATM);
	ind := Length(fArrOpenATM) - 1;
	if fStateOpenATM = 1 then
		begin
	  	if fIsAbortOpen then
  	  begin
    		fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
	    end;
// if Assigned(fLog) then fLog.Write('State 1. + '. str - ' + fTmpStr );

  	  if ((Ord(fTmpStr[1]) > $2F) and (Ord(fTmpStr[1]) < $3A)) then
    	begin
    		Inc(fRowCassette);
	      try
  	    	fArrOpenATM[ind].CassetteInfo[fRowCassette ].Picker 		:= StrToInt(fTmpStr[1]);
    	  except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Picker OPENATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
  	          fArrOpenATM[ind].CassetteInfo[fRowCassette].Picker := UNREALINTEGER;
    	      end;
      	end;
	      try
  	    	fArrOpenATM[ind].CassetteInfo[fRowCassette].Nominal 	:= StrToInt(Trim(Copy(fTmpStr , 2 , 5)));
    	  except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to nominal OPENATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
            	fArrOpenATM[ind].CassetteInfo[fRowCassette].Nominal := UNREALINTEGER;
	          end;
  	      end;
    	  fArrOpenATM[ind].CassetteInfo[fRowCassette].Currency 	:= Trim(Copy(fTmpStr , 13 , 3));
      	try
      		fArrOpenATM[ind].CassetteInfo[fRowCassette].Count 		:= StrToInt(Trim(Copy(fTmpStr , 21 , 5)));;
	      except
  	    	on E : Exception do
    	    	begin
							if Assigned(fLog) then fLog.Write('Error convert to count OPENATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
        	    fArrOpenATM[ind].CassetteInfo[fRowCassette].Count := UNREALINTEGER;
          	end;
	      end;
  	    try
    	  	fArrOpenATM[ind].CassetteInfo[fRowCassette].Ostatok  	:= StrToInt(Trim(Copy(fTmpStr , 26 , 5)));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to OSTATOK OPENATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].CassetteInfo[fRowCassette].Ostatok := UNREALINTEGER;
  	        end;
    	  end;
      	try
      		fArrOpenATM[ind].CassetteInfo[fRowCassette].Vydano 		:= StrToInt(Trim(Copy(fTmpStr , 31 , 5)));
	      except
  	    	on E : Exception do
    	    	begin
							if Assigned(fLog) then fLog.Write('Error convert to Vydano OPENATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
							fArrOpenATM[ind].CassetteInfo[fRowCassette].Vydano := UNREALINTEGER;
          	end;
	      end;
  	    try
    	  	fArrOpenATM[ind].CassetteInfo[fRowCassette ].Sbrosheno	:= StrToInt(Trim(Copy(fTmpStr , 36 , 5)));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Sbrosheno OPENATM. N - ' + IntToStr(fRowCassette)+ '. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].CassetteInfo[fRowCassette ].Sbrosheno := UNREALINTEGER;
  	        end;
    	  end;
	    end;
  	  if ((fRowCassette > 0) and (Pos('-------------------------' , fTmpStr) <> 0)) then
    	  begin
      	 fStateOpenATM := 2;
	       fCntRowOpenATM := 0;
  	    end;
	  end;
	if fStateOpenATM = 2 then
  	begin
  		if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 2 ' + fTmpStr);
  	  if Pos('IADRUHFOP' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].Zagruzheno := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Zagruzheno OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].Zagruzheno := UNREALDOUBLE;
  	        end;
        end;
      	fStateOpenATM := 3;
      	fCntRowOpenATM := 0;
      end;
    end;
	if fStateOpenATM = 3 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 3 ' + fTmpStr);
    if Pos('C]EAOP' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].Vydano := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Vydano OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].Vydano := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 4;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 4 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 4 ' + fTmpStr);
    if Pos('YJSMP SBR' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].CntSbros := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntSbros OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].CntSbros := UNREALINTEGER;
  	        end;
        end;
       	fStateOpenATM := 5;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 5 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 5 ' + fTmpStr);
    if Pos('L SEAYF' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].Sdacha := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Sdacha OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].Sdacha := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 6;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 6 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 6 ' + fTmpStr);
    if Pos('CBRPZFOP' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].AmountSbroc  := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 12))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to AmountSbroc OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].AmountSbroc := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 7;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 7 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 7 ' + fTmpStr);
    if Pos('IAEFRHAOP LART' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].CntCardZaderzhano := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 20))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntCardZaderzhano OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].CntCardZaderzhano := UNREALINTEGER;
  	        end;
        end;
       	fStateOpenATM := 8;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 8 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 8 ' + fTmpStr);
    if Pos('SQJSAOP S LMJFOTPC' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].MTKARTSpisano := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to MTKARTSpisano  OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].MTKARTSpisano := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 9;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 9 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 9 ' + fTmpStr);
    if Pos('JI OJW QRPXFOT]' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].PercentSpysano := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to PercentSpysano   OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].PercentSpysano  := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 10;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 10 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 10 ' + fTmpStr);
    if Pos('EMa STPROJRPCAOJa' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].Storno  := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to Storno    OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].Storno   := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 11;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 11 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 11 ' + fTmpStr);
    if Pos('L C]QMATF LMJFOTAN' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].KVyplate   := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 20))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to KVyplate OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].KVyplate   := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 12;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 12 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 12 ' + fTmpStr);
    if Pos('SQPROAa SUNNA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].SpornajaSumma   := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 21))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to SpornajaSumma OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].SpornajaSumma   := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 13;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 13 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 13 ' + fTmpStr);
    if Pos('OPNFR #NCT#MK#CCT#' , fTmpStr) <> 0 then
    	begin
      	fArrOPenATM[ind].PANTerminala    := Copy(fTmpStr , 20);
       	fStateOpenATM := 14;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 14 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 14 ' + fTmpStr);
    if Pos('QALFT' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].PAcket := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 7 , 5))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to PAcket OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].PAcket := UNREALINTEGER;
  	        end;
        end;
      	try
	        fArrOPenATM[ind].DatePacket := StrToDateTime(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 17 , 10))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to DatePacket OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].DatePacket := UNREALDATE;
  	        end;
        end;

       	fStateOpenATM := 15;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 15 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 15 ' + fTmpStr);
    if Pos('BAMAOS QALFTA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].BalansPacket   := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 15))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to BalansPacket OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].BalansPacket   := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 16;
      	fCntRowOpenATM := 0;
      end;
	end;
// 	if fStateOpenATM = 16 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 16 ' + fTmpStr);
    if Pos('YJSMP TR-XJK' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].CntIPS := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 17))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntIPS OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].CntIPS := UNREALINTEGER;
  	        end;
        end;
       	fStateOpenATM := 17;
      	fCntRowOpenATM := 0;
      end;
	end;
	if fStateOpenATM = 17 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 17 ' + fTmpStr);
    if ((Pos('YJSMP' , fTmpStr) <> 0) and (Pos('RETRACT' , fTmpStr) <> 0)) then
    	begin
      	try
	        fArrOPenATM[ind].CntRetractIPS := StrToInt(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 27))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to CntRetractIPS OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].CntRetractIPS := UNREALINTEGER;
  	        end;
        end;
       	fStateOpenATM := 18;
      	fCntRowOpenATM := 0;
      end;
	end;
 	if fStateOpenATM = 18 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 18 ' + fTmpStr);
    if Pos('C]EAOOAa SUNNA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].VydanoIPS := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 23 , 10))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to VydanoIPS OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].VydanoIPS   := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 19;
      	fCntRowOpenATM := 0;
      end;
	end;
 	if fStateOpenATM = 19 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 19 ' + fTmpStr);
    if Pos('SQPROAa SUNNA' , fTmpStr) <> 0 then
    	begin
      	try
	        fArrOPenATM[ind].SoprnajaSummaIPS := StrToFloat(fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , fDelDelimiter( CHR(36) , Trim(Copy(fTmpStr , 23 , 10))))));
      	except
      		on E : Exception do
        		begin
							if Assigned(fLog) then fLog.Write('Error convert to SoprnajaSummaIPS  OPENATM. ' + E.Message + E.ClassName ) ;
	            fArrOpenATM[ind].SoprnajaSummaIPS := UNREALDOUBLE;
  	        end;
        end;
       	fStateOpenATM := 20;
      	fCntRowOpenATM := 0;
      end;
	end;
 	if fStateOpenATM = 20 then
	begin
  	if fIsAbortOpen then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
// if Assigned(fLog) then fLog.Write('State 20 ' + fTmpStr);      
    if Pos('=======================================' , fTmpStr) <> 0 then
    	begin
       	fStateOpenATM := 0;
      	fCntRowOpenATM := 0;
      end;
	end;
end;

procedure TParseReceipt.fStatePresentCash;
begin

end;

procedure TParseReceipt.Start;
var
	IsReadyFile : boolean;
  NumRow : Integer;
  i : Integer;
begin
if Assigned(fLog) then fLog.Write('Start parsing. ' + fNamFil);
fSuccessParse := false;
IsReadyFile := true;
fPrevStr.Clear;
try
	AssignFile(fF , fNamFil);
except
	on E : Exception do
   	begin
if Assigned(fLog) then fLog.Write('Exception assigned file. ' + fNamFil + '. Msg - ' + E.Message + '. ' + E.ClassName );
      	IsReadyFile := false;
      end;
end;
try
	Reset(fF);
except
	on E : Exception do
   	begin
if Assigned(fLog) then fLog.Write('Exception Reset file. ' + fNamFil + '. Msg - ' + E.Message + '. ' + E.ClassName );
      	IsReadyFile := false;
      end;
end;
if IsReadyFile then
begin
   NumRow := 0;
   fStateOpenATM 	:= 0;
   fStateCloseATM := 0;
   fCntRowOpenATM 	:= 0;
   fCntRowCloseATM := 0;

	while not Eof(fF) do
	begin
  	Readln(fF , fTmpStr);
    fOnWorkRcpt(self , Length(fTmpStr));
    if (
    			(fPrevStr.Count > 0)
    		and
    			(
          	(fPrevStr.Strings[0] = 'JOEUSTRJAMBAOL' )
          or
          	(fPrevStr.Strings[0] = 'JOEASTRJAMBAOL' )
          )
        )  then
    	begin
      	if Length(Trim(fTmpStr)) > 0 then
        	begin
						fPrevStr.Add(Trim(fTmpStr));
          end;
      end;
    if ((Trim(fTmpStr) = 'JOEUSTRJAMBAOL') or (Trim(fTmpStr) = 'JOEASTRJAMBAOL')) then
    	begin
      	fPrevStr.Clear;
				fPrevStr.Add(Trim(fTmpStr));

      end;
try
    if fCheckOpenATM then
    	begin
      	fStateOpen;
      end;
    if fCheckCloseATM then
    	begin
      	fStateClose;
      end;
    if fCheckPresentCash then
      begin
      	if Pos('C]EAYA OAMJYO]W S ISL' , ftmpStr) <> 0  then
			  	begin
      			fCheckPriv;
			    end;
				if Pos('S PTLR]TPDP SYFTA' , ftmpStr) <> 0  then
			  	begin
    				fCheckOpen;
			    end;
      end;
    if  EOF(fF) then
    	break;
    if fPrevStr.Count > 5 then
    	fPrevStr.Clear;
except
	on E : EStringListError do
  	begin
      SendMessage(frmParsing.AppHndl , WM_PHARSERCPTERROR	, 300 , fTag);
    end;
  on E : Exception do
  	begin
      SendMessage(frmParsing.AppHndl , WM_PHARSERCPTERROR	, 212 , fTag);
    end;
end;
	end;
  fPrevStr.Clear;
	CloseFile(fF);
	fSuccessParse := true;
end;
if Assigned(fLog) then fLog.Write('End of Parsing file. ' + fNamFil);

if fSuccessParse then
	begin
  	fInsertSQL;
  end;
end;

end.
