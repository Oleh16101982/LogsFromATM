unit clParseJournal1;

interface
uses
	Windows, SysUtils, Variants, Classes, clLogAcceptor1 , ADODB, DB , activeX , comobj;
const
		UNREALDOUBLE : Double = -999999999.99;
   	UNREALINTEGER : Integer = HIGH(INTEGER);
   	UNREALDATE	: TDateTime = 0;

   	MAXROWTRNIPS 				= 30;
   	MAXROWBALANCING 		= 70;
   	MAXROWWAITDISPCOUNT = 10;
   	MAXROWSTL 					= 150;
type
	TOnWorkJrn	= procedure (Sender : TObject ; AWorkCount : Cardinal) of object;

type
	TrecTrnIPS = record
      ATM 			: String;
      Address		: String;
      DateTime	: TDateTime;
      Check 		: String;
      Currency 	: String;
      PAN 			: String;
      Vydano 		: Double;
      Fee 			: Double;
      Itogo 		: Double;
      Ostatok		: Double;
      Overdraft 	: Double;
   	PrintCheck 	: Boolean;
      FileName		: String ;
//      State 		: Integer;
//      CountRow		: Integer;
   end;

type
	TrecTranType = record
   	Number	: TStringlist;
      Count		: TStringList;
      Amount	: TStringList;
   end;

type
	TrecDispCount = record
   	Number			: TStringlist;
      TypeCassette 	: TStringList;
      Nominal			: TStringList;
      Count				: TStringList;
      Amount			: TStringList;
      Currency 		: TStringList;
   end;

type
	TrecBalancing = record
      BusinessDate 	: String;
      Date			  	: String;
      Time			  	: String;
      Number			: String;
      TranType			: TrecTranType;
      DispCount		: TrecDispCount;
      State				: Integer;
      CountRow			: Integer;
   end;

type
	TrecSTL = record
      BeforePacketNum 	: Integer;
      BeforeTrnCount 	: Integer;
      BeforeTrnAmount 	: Double;
      DateTime				: TDateTime;
      AfterPacketNum 	: Integer;
      AfterTrnCount 		: Integer;
      AfterTrnAmount 	: Double;
      Success				: boolean;
      State 				: Integer;
      CountRow				: Integer;
   end;

type
	TParseJournal = class
    private
    	fLog : TLogAcceptor;
      fATMName 			: String;
      fCheckBalansing 	: boolean;
      fCheckTransIPS 	: boolean;
      fCheckStl 			: boolean;
		fNamFil				: String;
      fF						: TextFile;
      fTmpStr 				: String;
      farrBalancing		: array of TrecBalancing;
      fArrTRNIPS			: array of TrecTrnIPS;
      fArrStl				: array of TrecStl;
      fTag 					: Integer;
			fSuccessParse	: boolean;

      fConn : TADOConnection;
      fProc1	: TADOStoredProc;
      fProc2	: TADOStoredProc;
      fProc3	: TADOStoredProc;

      fStateTrnIPS 			: Integer;
      fStateBalancing 		: Integer;
      fSubStateBalancing 	: Integer;
      fStateStl 				: Integer;
      fCountRowTrnIPS		: Integer;
      fCountRowBalancing 	: Integer;
      fCountRowStl 			: Integer;
      fiWaitDispCount 		: Integer;

      fOnWorkJrn : TOnWorkJrn;

      procedure fIsVydachaIPS;
      procedure fIsBalansirovka;
      procedure fIsSettlement;

      procedure fConnectSQL;
      procedure fDisconnectSQL;
      procedure fInsertSQL;
	   	procedure fInsertBalancing;
   		procedure fInsertVydacha;
    	procedure fInsertSettlement;
      function fDelDelimiter(Delimiter : Char ; Str : String) : String;

      function fGetBalancing(Index : Integer) : TrecBalancing;
      procedure fSetBalancing(Index : Integer ; Value : TrecBalancing);

      function fFindCurrency(tmpStr : String) : String;
      function fFindDispAmount(tmpStr : String) : String;

      procedure fStateTrnMPS;
      procedure fStateBalanc;
      procedure fStateSettl;
      function fCheckCorrectTranType(str : String) : boolean;


    public
    	constructor Create(isLog : boolean ; ATMName : String);
      Destructor Destroy;

      procedure Start;

      property Tag 	: Integer read fTag write fTag;
      property CheckBalansing 	: boolean read fCheckBalansing write fCheckBalansing;
      property CheckTransIPS 		: boolean read fCheckTransIPS  write fCheckTransIPS;
      property CheckStl 			: boolean read fCheckStl       write fCheckStl;
      property NamFil				: String  read	fNamFil 			 write fNamFil;
//      property Balancing			: TrecBalancing read fGetBalancing write fSetBalancing;
   	property SuccessParse		: boolean read fSuccessParse write fSuccessParse;
    	property OnWorkJrn	: TOnWorkJrn read fOnWorkJrn write fOnWorkJrn;

    end;



implementation
uses
	frmParsing1;
{ TParseJournal }

constructor TParseJournal.Create(isLog: boolean ; ATMName : String);
begin
	inherited Create;
   if isLog then fLog := TLogAcceptor.Create('ParseJournal_' + ATMName, frmParsing.fGlobalParams.Values['LocalDir']) ;
   SetLength(farrBalancing , 0);
   SetLength(farrTrnIPS , 0);
   SetLength(farrStl , 0);
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
   fProc2.Connection := fConn;
   fProc3.Connection := fConn;
   fProc1.CommandTimeout := 10000;
   fProc2.CommandTimeout := 10000;
   fProc3.CommandTimeout := 10000;
   fProc1.Parameters.Clear;
   fProc2.Parameters.Clear;
   fProc3.Parameters.Clear;
end;

destructor TParseJournal.Destroy;
begin
if Assigned (fLog)  then flog.Free;
if Assigned (fConn) then fConn.Free ;
if Assigned (fProc1) then fProc1.Free ;
if Assigned (fProc2) then fProc1.Free ;
if Assigned (fProc3) then fProc1.Free ;

end;

function TParseJournal.fFindDispAmount(tmpStr: String): String;
   var
   	i : Integer;
      promStr : String;
   begin
   	promStr := '';
      for i := 5 to Length(tmpStr) do
       	begin
         if ((Ord(tmpStr[i]) > $2F) and (Ord(tmpStr[i]) < $3A))  then
            begin
               promStr := Trim(Copy(tmpStr , i));
               break;
         	end
         end;
      fFindDispAmount := promStr;
end;

function TParseJournal.fCheckCorrectTranType(str: String): boolean;
var
retVal : boolean;
tmpI : Integer;
begin
retVal := true;
if Length(str) < 3 then
	retVal := false;
if Copy(Trim(str) , 1 , 4) <> 'N/A' then
	begin
      try
      	tmpI := StrToInt(Copy(Trim(str) , 6 ));
      except
      	on E : Exception do
            retVal := false;
      end;
   end;
Result := retVAl;
end;

procedure TParseJournal.fConnectSQL;
begin
// if Assigned(fLog) then fLog.Write('In Connect SQL') ;
	try
		fConn.Connected := true;
   except
   	on E : Exception do
if Assigned(fLog) then fLog.Write('Error Connect to SQL server. ' + E.Message + '. ' + E.ClassName ) ;
   end;
end;

function TParseJournal.fDelDelimiter(Delimiter: Char ; Str : String): String;
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

procedure TParseJournal.fDisconnectSQL;
begin
if fConn.Connected  then
	fConn.Connected := false;
// if Assigned(fLog) then fLog.Write('After DisConnect SQL') ;   
end;

function TParseJournal.fFindCurrency(tmpStr: String): String;
var
	i : Integer;
	promStr : String;
begin
	Result := Trim(Copy(tmpStr , 1 , 3));
end;

function TParseJournal.fGetBalancing(Index: Integer): TrecBalancing;
begin
	Result := farrBalancing[Index];
end;

procedure TParseJournal.fInsertSQL;
begin
	fConnectSQL;
	   if fConn.Connected  then
   		begin
	   		if fCheckTransIPS then
   	   		fInsertVydacha;
	   		if fCheckBalansing then
   	   		fInsertBalancing;
	   		if fCheckStl then
   	   		fInsertSettlement;
   			fDisconnectSQL;
      end;
end;

procedure TParseJournal.fIsBalansirovka;
var
dopStr : String;
begin
if Assigned(fLog) then fLog.Write(fTmpStr);
	SetLength(farrBalancing , Length(farrBalancing) + 1);
   farrBalancing[Length(farrBalancing) - 1].TranType.Number 			:= TStringList.Create;
   farrBalancing[Length(farrBalancing) - 1].TranType.Count  			:= TStringList.Create;
   farrBalancing[Length(farrBalancing) - 1].TranType.Amount 			:= TStringList.Create;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Number  			:= TStringList.Create;;
   farrBalancing[Length(farrBalancing) - 1].DispCount.TypeCassette  	:= TStringList.Create;;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Nominal 			:= TStringList.Create;;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Count 			:= TStringList.Create;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Amount 			:= TStringList.Create;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Currency 		:= TStringList.Create;

   farrBalancing[Length(farrBalancing) - 1].TranType.Number.Clear;
   farrBalancing[Length(farrBalancing) - 1].TranType.Count.Clear;
   farrBalancing[Length(farrBalancing) - 1].TranType.Amount.Clear;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Number.Clear;
   farrBalancing[Length(farrBalancing) - 1].DispCount.TypeCassette.Clear;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Nominal.Clear;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Count.Clear;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Amount.Clear;
   farrBalancing[Length(farrBalancing) - 1].DispCount.Currency.Clear;

   Readln(fF , dopStr);
   farrBalancing[Length(farrBalancing) - 1].BusinessDate := Trim(dopStr);
   Readln(fF , dopStr);
   farrBalancing[Length(farrBalancing) - 1].Date := Copy(Trim(dopStr) , 1 , 8);
   farrBalancing[Length(farrBalancing) - 1].Time := Copy(Trim(dopStr) , 14 , 8);
   Readln(fF , dopStr);
   farrBalancing[Length(farrBalancing) - 1].Number := Trim(dopStr);
// if Assigned(fLog) then fLog.Write('1. ' + dopStr);
      while true do
	      begin
            Readln(fF , dopStr);
               if EOF(fF) then
               	break;
               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
               	break;
// if Assigned(fLog) then fLog.Write('2. ' + dopStr);
            if ((dopStr[1] = '*') and ((Ord(dopStr[2]) > $2F) and (Ord(dopStr[2]) < $3A))) then
               break;
            if POS('TRAN.     =   AMOUNT' , dopStr) <> 0 then
            	begin
               	while true do
                  	begin
		               	Readln(fF , dopStr);
			               if EOF(fF) then
         			      	break;
			               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
         			      	break;

// if Assigned(fLog) then fLog.Write('3. ' + dopStr);
			               if EOF(fF) then
         			      	break;
				               if (Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0) then
         			      	break;
                     	if not ((Length(Trim(dopStr)) = 0) or (dopStr[1] = '*'))  then
                        	begin
		                        if POS(' =  DEN.    =DISP' , dopStr) <> 0  then
      		                  	begin
            		               	Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('4. ' + dopStr);
	               	         		break;
		                           end;
      		                  if EOF(fF) then
            		            	break;
                  		      if Length(dopStr) <> 0 then
                        			begin
                           			if Length(Trim(Copy(dopStr , 1 , 2))) > 0 then
		                              	begin
      		                              farrBalancing[Length(farrBalancing) - 1].TranType.Number.Add(Trim(Copy(dopStr , 1 , 4)));
            		                        farrBalancing[Length(farrBalancing) - 1].TranType.Count.Add(Trim(Copy(dopStr , 6 )));
                  		                  Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('5. ' + dopStr);
                        		            farrBalancing[Length(farrBalancing) - 1].TranType.Amount.Add(fFindDispAmount(dopStr));
                              		   end;
		                           end;
									end;
      		         end;
					end;
            if POS('---  AMOUNT' , dopStr) <> 0 then
            	begin
               	while true do
                  	begin
		               	Readln(fF , dopStr);
				            if EOF(fF) then
            			   	break;
			               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
         			      	break;

// if Assigned(fLog) then fLog.Write('6. ' + dopStr);
                        if ((dopStr[1] = '*') and ((Ord(dopStr[2]) > $2F) and (Ord(dopStr[2]) < $3A))) then
                        	break;
                        if EOF(fF) then
                        	break;
                        if Length(dopStr) <> 0 then
                        	begin
                           	if (((Ord(dopStr[1]) > $2F) and (Ord(dopStr[1]) < $3A)) and (POS('/' , dopStr) = 0)) then
                              	begin
                                    farrBalancing[Length(farrBalancing) - 1].DispCount.Number.Add(Trim(Copy(dopStr , 1 , 2)));
                                    farrBalancing[Length(farrBalancing) - 1].DispCount.TypeCassette.Add(Trim(Copy(dopStr , 2 , 3 )));
                                    farrBalancing[Length(farrBalancing) - 1].DispCount.Nominal.Add(Trim(Copy(dopStr , 5 , 10 )));
                                    farrBalancing[Length(farrBalancing) - 1].DispCount.Count.Add(Trim(Copy(dopStr , 15 )));
                                    Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('7. ' + dopStr);                                    
                                    farrBalancing[Length(farrBalancing) - 1].DispCount.Currency.Add	(fFindCurrency		(dopStr));
                                    farrBalancing[Length(farrBalancing) - 1].DispCount.Amount.Add	(fFindDispAmount	(dopStr));
                                 end;
                           end;
                     end;
               end;
      	end;
end;

procedure TParseJournal.fIsSettlement;
   var
   	i : Integer;
      maxCountWait : Integer;
      curCountRow : Integer;
      dopStr : String;
      isSuccess : boolean;

      sBeforePacketNum 	: String;
      sBeforeTrnCount 	: String;
      sBeforeTrnAmount 	: String;
      sDate					: String;
      sTime 				: String;
      sAfterPacketNum 	: String;
      sAfterTrnCount 	: String;
      sAfterTrnAmount 	: String;

      sDateTime 			: String;
   	isCorrectConvert	: boolean;

   begin
   	SetLength(fArrStl , Length(fArrStl) + 1);
   	maxCountWait := 100;
      curCountRow := 1;
      isSuccess := false;
      while true do
      begin
         Readln(fF , dopStr);
               if EOF(fF) then
               	break;
               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
               	break;
// if Assigned(fLog) then fLog.Write('1. ' + dopStr);
         if EOF(fF) then
         	break;
         if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , dopStr) <> 0 then
         	begin
            	isSuccess := true;
               break;
            end;  // Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , dopStr) <> 0 then
         if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , dopStr) <> 0 then
         	begin
            	isSuccess := false;
               break;
            end;
         if Pos('Duet Non Service' , dopStr) <> 0 then
         	begin
            	isSuccess := false;
               break;
            end;
         while true do
         	begin
               if EOF(fF) then
               	break;
               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
               	break;
            	if Pos('ÕŒÃ≈– œ¿ ≈“¿ “–¿Õ«¿ ÷»…' , dopStr) <> 0 then
   	            begin
                     sBeforePacketNum := Trim(Copy(dopStr , 26 ));
                     Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('2. ' + dopStr);
                     sBeforeTrnCount := Trim(Copy(dopStr , 22 ));
                     Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('3. ' + dopStr);
                     sBeforeTrnAmount := Trim(Copy(dopStr , 11 ));
      	         	break;
	               end;
            	Readln(fF , dopStr);
// Assigned(fLog) then fLog.Write('4. ' + dopStr);
            end;
         while true do
         	begin
					Readln(fF , dopStr);
               if EOF(fF) then
               	break;
               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
               	break;
// Assigned(fLog) then fLog.Write('5. ' + dopStr);
            	if Pos('ƒ¿“¿ Õ¿ —≈–¬≈–≈' , dopStr) <> 0 then
   	            begin
							sDate := Trim(Copy(dopStr , 19 , 10 ));
                     sTime := Trim(Copy(dopStr , 30));
      	         	break;
	               end;
            end;

		         while true do
      		   	begin
            			Readln(fF , dopStr);
		               if EOF(fF) then
      		         	break;
            		   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
               			break;
// Assigned(fLog) then fLog.Write('6. ' + dopStr);
		            	if Pos('œŒ—À≈ »Õ ¿——¿÷»»' , dopStr) <> 0 then
   			            begin
									Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('7. ' + dopStr);
                  		   sAfterPacketNum := Trim(Copy(dopStr , 26 ));
		                     Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('8. ' + dopStr);
      		               sAfterTrnCount := Trim(Copy(dopStr , 22 ));
            		         Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('9. ' + dopStr);
                  		   sAfterTrnAmount := Trim(Copy(dopStr , 11 ));
		      	         	break;
	   		            end;
                  end;
         Inc(curCountRow);
         if curCountRow > maxCountWait then
         break;
      end;

// if Assigned(fLog) then fLog.Write('Start converting STL');
	sBeforePacketNum := Trim(sBeforePacketNum);
   sBeforePacketNum := fDelDelimiter(CHR(39) , sBeforePacketNum);
   sBeforePacketNum := fDelDelimiter(CHR(32) , sBeforePacketNum);
   sBeforePacketNum := fDelDelimiter(CHR(0)  , sBeforePacketNum);

	sBeforeTrnCount := Trim(sBeforeTrnCount);
   sBeforeTrnCount := fDelDelimiter(CHR(39) , sBeforeTrnCount);
   sBeforeTrnCount := fDelDelimiter(CHR(32) , sBeforeTrnCount);
   sBeforeTrnCount := fDelDelimiter(CHR(0)  , sBeforeTrnCount);

	sBeforeTrnAmount := Trim(sBeforeTrnAmount);
   sBeforeTrnAmount := fDelDelimiter(CHR(39) , sBeforeTrnAmount);
   sBeforeTrnAmount := fDelDelimiter(CHR(32) , sBeforeTrnAmount);
   sBeforeTrnAmount := fDelDelimiter(CHR(0)  , sBeforeTrnAmount);

	sAfterPacketNum := Trim(sAfterPacketNum);
   sAfterPacketNum := fDelDelimiter(CHR(39) , sAfterPacketNum);
   sAfterPacketNum := fDelDelimiter(CHR(32) , sAfterPacketNum);
   sAfterPacketNum := fDelDelimiter(CHR(0)  , sAfterPacketNum);

	sAfterTrnCount := Trim(sAfterTrnCount);
   sAfterTrnCount := fDelDelimiter(CHR(39) , sAfterTrnCount);
   sAfterTrnCount := fDelDelimiter(CHR(32) , sAfterTrnCount);
   sAfterTrnCount := fDelDelimiter(CHR(0)  , sAfterTrnCount);

	sAfterTrnAmount := Trim(sAfterTrnAmount);
   sAfterTrnAmount := fDelDelimiter(CHR(39) , sAfterTrnAmount);
   sAfterTrnAmount := fDelDelimiter(CHR(32) , sAfterTrnAmount);
   sAfterTrnAmount := fDelDelimiter(CHR(0)  , sAfterTrnAmount);


   sDateTime := Trim(sDate) + ' ' + Trim(sTime);
   if Length(sDateTime) > 6 then
      begin
       sDateTime[3] := '.';
       sDateTime[6] := '.';
      end;
   isCorrectConvert := true;
   if Length(sBeforePacketNum) > 0 then
      try
      	fArrStl[Length(fArrStl) - 1].BeforePacketNum := StrToInt(sBeforePacketNum);
      except
      	on E : Exception do
         		begin
	if Assigned(fLog) then fLog.Write('Error convert sBeforePacketNum in STL. ' + E.Message + E.ClassName ) ;
   					isCorrectConvert := false;
   				end;
      end
   else
   	isCorrectConvert := false;

   if Length(sBeforeTrnCount) > 0 then
      try
      	fArrStl[Length(fArrStl) - 1].BeforeTrnCount := StrToInt(sBeforeTrnCount);
      except
      	on E : Exception do
         		begin
	if Assigned(fLog) then fLog.Write('Error convert sBeforeTrnCount in STL. ' + E.Message + E.ClassName ) ;
   					isCorrectConvert := false;
   				end;
      end
   else
   	isCorrectConvert := false;

   if Length(sAfterPacketNum) > 0 then
      try
      	fArrStl[Length(fArrStl) - 1].AfterPacketNum := StrToInt(sAfterPacketNum);
      except
      	on E : Exception do
         		begin
	if Assigned(fLog) then fLog.Write('Error convert sAfterPacketNum in STL. ' + E.Message + E.ClassName ) ;
   					isCorrectConvert := false;
   				end;
      end
   else
   	isCorrectConvert := false;

   if Length(sAfterTrnCount) > 0 then
      try
      	fArrStl[Length(fArrStl) - 1].AfterTrnCount := StrToInt(sAfterTrnCount);
      except
      	on E : Exception do
         		begin
	if Assigned(fLog) then fLog.Write('Error convert sAfterTrnCount in STL. ' + E.Message + E.ClassName ) ;
   					isCorrectConvert := false;
   				end;
      end
   else
   	isCorrectConvert := false;

   if Length(sBeforeTrnAmount) > 0 then
      try
      	fArrStl[Length(fArrStl) - 1].BeforeTrnAmount := StrToFloat(sBeforeTrnAmount);
      except
      	on E : Exception do
         		begin
	if Assigned(fLog) then fLog.Write('Error convert sBeforeTrnAmount in STL. ' + E.Message + E.ClassName ) ;
   					isCorrectConvert := false;
   				end;
      end
   else
   	isCorrectConvert := false;

   if Length(sAfterTrnAmount) > 0 then
      try
      	fArrStl[Length(fArrStl) - 1].AfterTrnAmount := StrToFloat(sAfterTrnAmount);
      except
      	on E : Exception do
         		begin
	if Assigned(fLog) then fLog.Write('Error convert sAfterTrnAmount in STL. ' + E.Message + E.ClassName ) ;
   					isCorrectConvert := false;
   				end;
      end
   else
   	isCorrectConvert := false;



{
      sBeforePacketNum 	: String;
      sBeforeTrnCount 	: String;
      sBeforeTrnAmount 	: String;
      sDate					: String;
      sTime 				: String;
      sAfterPacketNum 	: String;
      sAfterTrnCount 	: String;
      sAfterTrnAmount 	: String;
}
end;

procedure TParseJournal.fIsVydachaIPS;
var
dopStr : String;
StateCheck : Integer;
sATM 			: String;
sAddress 	: String;
sDate 		: String;
sTime 		: String;
sCheck 		: String;
sCurrency 	: String;
sPAN 			: String;
sVydano 		: String;
sFee 			: String;
sItogo 		: String;
sOstatok 	: String;
sOverdraft 	: String;
ind : Integer;
begin
// if Assigned(fLog) then fLog.Write('In fIsVydachaIPS');

	SetLength(fArrTrnIPS , Length(fArrTrnIPS) + 1);
   ind := Length(fArrTrnIPS) - 1;
      Readln(fF ,  dopStr);
      if POS('******************' , dopStr) <> 0 then
	      Readln(fF , dopStr);
      sAddress := Trim(dopStr);
// if Assigned(fLog) then fLog.Write('1 - ' + sAddress);
      Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('2 - ' + dopStr);
      sDate := Copy(dopStr , 1 , 8);
      sDate[3] := '.';
      sDate[6] := '.';
      sTime	:= Copy(dopStr , 14 , 8);
      Readln(fF , dopStr);
      Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('3 - ' + dopStr);
      sATM := Trim(Copy(dopStr , 5 , 4));
      sCheck := Trim(Copy(dopStr , 11 , 6));
      sCurrency := Trim(Copy(dopStr , 17 , 7));
      Readln(fF , dopStr);
// if Assigned(fLog) then fLog.Write('4 - ' + dopStr);
      sPAN := Trim(Copy(dopStr , 4 , 16));
      fArrTrnIPS[ind].PrintCheck := true;
      while true do
      begin
      	Readln(fF,dopStr);
               if EOF(fF) then
               	break;
               if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , dopStr) <> 0 then
               	break;
         if ((Pos('VYDANO' , dopStr) <> 0) or (Pos('VIDANO' , dopStr) <> 0)) then
         	begin
// if Assigned(fLog) then fLog.Write('5 - ' + dopStr);
            	StateCheck := 1;
               sVydano := Trim(Copy(dopStr , 11));
               sVydano := fDelDelimiter(CHR(39) , sVydano);
               sVydano := fDelDelimiter(CHR(0) , sVydano);
            end;
         if ((Pos('KOMISSIQ' , dopStr) <> 0) or (Pos('KOMgSgQ' , dopStr) <> 0)) then
         	begin
// if Assigned(fLog) then fLog.Write('6 - ' + dopStr);
            	if StateCheck = 1 then
               	begin
                     sFee := Trim(Copy(dopStr , 11));
							sFee := fDelDelimiter(CHR(39) , sFee);
                     sFee := fDelDelimiter(CHR(0) , sFee);
                     StateCheck := 2;
                  end;
            end;
         if ((Pos('ITOGO' , dopStr) <> 0) or (Pos('RAZOM' , dopStr) <> 0)) then
         	begin
// if Assigned(fLog) then fLog.Write('7- ' + dopStr);
            	if StateCheck < 3 then
               	begin
                     sItogo := Trim(Copy(dopStr , 11));
							sItogo := fDelDelimiter(CHR(39) , sItogo);
                     sItogo := fDelDelimiter(CHR(0) , sItogo);
                     StateCheck := 3;
                  end;
            end;
         if ((Pos('OSTATOK' , dopStr) <> 0) or (Pos('ZALIWOK' , dopStr) <> 0)) then
         	begin
            	if ((StateCheck = 3) or (StateCheck = 1)) then
               	begin
// if Assigned(fLog) then fLog.Write('8 - ' + dopStr);
                     sOstatok := Trim(Copy(dopStr , 11));
							sOstatok := fDelDelimiter(CHR(39) , sOstatok);
                     sOstatok := fDelDelimiter(CHR(0) , sOstatok);
                     if sOstatok[Length(sOstatok)] = '-' then
                     	sOstatok := '-' + Copy(sOstatok , 1 , Length(sOstatok) - 1);
                     StateCheck := 4;
                  end;
            end;
         if Pos('OVERDRAFT' , dopStr) <> 0 then
         	begin
            	if StateCheck = 4 then
               	begin
// if Assigned(fLog) then fLog.Write('8 - ' + dopStr);
                     sOverdraft := Trim(Copy(dopStr , 11));
							sOverdraft := fDelDelimiter(CHR(39) , sOverdraft);
                     sOverdraft := fDelDelimiter(CHR(0) , sOverdraft);
                     StateCheck := 5;
                  end;
            end;
         if Pos('BEZ PEXATI XEKA' , dopStr) <> 0 then
         	begin
	         	if ((StateCheck = 4) or (StateCheck = 5)) then
		         	begin
      	         	fArrTrnIPS[ind].PrintCheck := false;
      		      end;
               StateCheck := 6;
            end;
         if Pos('*********************' , dopStr) <> 0 then
         	begin
            	if StateCheck > 2 then
                  begin
                  	StateCheck := 6;
                  end;
            end;
         if StateCheck = 6 then
         	begin
            	StateCheck := 0;
               break;
            end;
      end;
// if Assigned(fLog) then fLog.Write('Start Convert data');
	fArrTrnIPS[ind].ATM := sATM;
	fArrTrnIPS[ind].Address := sAddress;
	try
		fArrTrnIPS[ind].DateTime := StrToDateTime(sDate + ' ' + sTime);
	except
		on E : Exception do
      	      	begin
	if Assigned(fLog) then fLog.Write('Error convert to datetime check IPS. ' + E.Message + E.ClassName ) ;
	               end;
	end;
	fArrTrnIPS[ind].Check 		:= sCheck;
   fArrTrnIPS[ind].Currency 	:= sCurrency;
   fArrTrnIPS[ind].PAN 			:= sPAN;
   if Length(sVydano) > 0  then
   	begin
		   try
			   fArrTrnIPS[ind].Vydano 		:= StrToFloat(sVydano);
	   	except
				on E : Exception do
      			      	begin
if Assigned(fLog) then fLog.Write('Error convert to Float Vydano  IPS. ' + E.Message + E.ClassName ) ;
		         	      end;
		   end;
      end
	else
   	fArrTrnIPS[ind].Vydano := UNREALDOUBLE;
   if Length(sFee) > 0  then
   	begin
		   try
	   		fArrTrnIPS[ind].Fee 			:= StrToFloat(sFee);
		   except
				on E : Exception do
      	   		   	begin
	if Assigned(fLog) then fLog.Write('Error convert to Float Fee IPS. ' + E.Message + E.ClassName ) ;
	               		end;
		   end;
      end
   else
   	fArrTrnIPS[ind].Fee := UNREALDOUBLE;
   if Length(sItogo) > 0  then
   	begin
		   try
   			fArrTrnIPS[ind].Itogo 		:= StrToFloat(sItogo);
		   except
				on E : Exception do
      	   		   	begin
	if Assigned(fLog) then fLog.Write('Error convert to Float Itogo IPS. ' + E.Message + E.ClassName ) ;
	               		end;
		   end;
      end
   else
   	fArrTrnIPS[ind].Itogo := UNREALDOUBLE;
   if Length(sOstatok) > 0  then
   	begin
		   try
	   		fArrTrnIPS[ind].Ostatok 	:= StrToFloat(sOstatok);
		   except
				on E : Exception do
		      	      	begin
	if Assigned(fLog) then fLog.Write('Error convert to Float Ostatok IPS. ' + E.Message + E.ClassName ) ;
	   		            end;
		   end;
      end
   else
   	fArrTrnIPS[ind].Ostatok := UNREALDOUBLE;
   if Length(sOverdraft) > 0  then
   	begin
		   try
   			fArrTrnIPS[ind].Overdraft 	:= StrToFloat(sOverdraft);
		   except
				on E : Exception do
      	   		   	begin
	if Assigned(fLog) then fLog.Write('Error convert to Float Overdraft IPS. ' + E.Message + E.ClassName ) ;
	               		end;
		   end;
      end
   else
   	fArrTrnIPS[ind].Overdraft := UNREALDOUBLE;
// if Assigned(fLog) then fLog.Write('END convert data') ;

end;

procedure TParseJournal.fSetBalancing(Index: Integer; Value: TrecBalancing);
begin
	farrBalancing[Index] := Value;
end;

procedure TParseJournal.fStateBalanc;
var
ind : Integer;
begin
	if Pos('BUSINESS DATE' , fTmpStr) <> 0 then
   	begin
			SetLength(fArrBalancing , Length(fArrBalancing) + 1);
         farrBalancing[Length(farrBalancing) - 1].TranType.Number 			:= TStringList.Create;
         farrBalancing[Length(farrBalancing) - 1].TranType.Count  			:= TStringList.Create;
         farrBalancing[Length(farrBalancing) - 1].TranType.Amount 			:= TStringList.Create;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Number  		:= TStringList.Create;;
         farrBalancing[Length(farrBalancing) - 1].DispCount.TypeCassette:= TStringList.Create;;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Nominal 		:= TStringList.Create;;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Count 			:= TStringList.Create;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Amount 			:= TStringList.Create;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Currency 		:= TStringList.Create;

         farrBalancing[Length(farrBalancing) - 1].TranType.Number.Clear;
         farrBalancing[Length(farrBalancing) - 1].TranType.Count.Clear;
         farrBalancing[Length(farrBalancing) - 1].TranType.Amount.Clear;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Number.Clear;
         farrBalancing[Length(farrBalancing) - 1].DispCount.TypeCassette.Clear;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Nominal.Clear;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Count.Clear;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Amount.Clear;
         farrBalancing[Length(farrBalancing) - 1].DispCount.Currency.Clear;

      	fStateBalancing := 1;
         fSubStateBalancing := 0;
	      fCountRowBalancing := 0;

      end;
if fStateBalancing = 0 then
	exit;
Inc(fCOuntRowBalancing);
ind := Length(fArrBalancing) - 1;
if fStateBalancing = 1 then
	begin
      if fCountRowBalancing = 2 then
      	begin
			   farrBalancing[Length(farrBalancing) - 1].BusinessDate := Trim(fTmpStr);
         end;
      if fCountRowBalancing = 3 then
      	begin
			   farrBalancing[Length(farrBalancing) - 1].Date := Copy(Trim(fTmpStr) , 1 , 8);
			   farrBalancing[Length(farrBalancing) - 1].Time := Copy(Trim(fTmpStr) , 14 , 8);
         end;
      if fCountRowBalancing = 4 then
      	begin
			   farrBalancing[Length(farrBalancing) - 1].Number := Trim(fTmpStr);
         end;
      if POS('TRAN.     =   AMOUNT' , fTmpStr) <> 0 then
      	begin
          fStateBalancing := 2;
          fiWaitDispCount := 0;
          fSubStateBalancing := 1;
          fCountRowBalancing := 0;
         end;
   if EOF(fF) then
   	begin
      	fStateBalancing := 0;
        fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('Õ¿◊¿ÀŒ Œœ≈–¿÷»» —  ¿–“Œ…' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
        fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if fCOuntRowBalancing > MAXROWBALANCING then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;

   end;
if fStateBalancing = 2 then
	begin
   	if POS(' =  DEN.    =DISP' , fTmpStr) <> 0  then
      	begin
          fStateBalancing := 3;
          fSubStateBalancing := 2;
          fCountRowBalancing := 0;
         end;
   	if Length(Trim(fTmpStr)) <> 0 then
    	begin
if Assigned(fLog) then fLog.Write('Tran Type. State = 2. ' + fTmpStr + '. CountRow - ' + IntToStr(fiWaitDispCount));
     
      	if not ((fTmpStr[1] = '*') and ((Ord(fTmpStr[2]) > $2F) and (Ord(fTmpStr[2]) < $3A))) then
        	begin
          	fiWaitDispCount := 0;
            if fCountRowBalancing = 1 then
            	begin
              	if fCheckCorrectTranType(fTmpStr) then
                	begin
                  	farrBalancing[Length(farrBalancing) - 1].TranType.Number.Add(Trim(Copy(fTmpStr , 1 , 4)));
                    farrBalancing[Length(farrBalancing) - 1].TranType.Count.Add(Trim(Copy(fTmpStr , 6 )));
                  end
                else
                	begin
                  	fCountRowBalancing := 0;
                  end;
              end;
            if fCountRowBalancing = 2 then
            	begin
              	farrBalancing[Length(farrBalancing) - 1].TranType.Amount.Add(fFindDispAmount(fTmpStr));
                fCountRowBalancing := 0;
              end;
          end
        else
        	begin
          	Inc(fiWaitDispCount);
            fCountRowBalancing := 0;
            if fiWaitDispCount > MAXROWWAITDISPCOUNT then
            	begin
              	fStateBalancing := 0;
                fCountRowBalancing := 0;
              end;
          end;
      end
    else
    	begin
      	fCountRowBalancing := 0;
        Inc(fiWaitDispCount);
        if fiWaitDispCount > MAXROWWAITDISPCOUNT then
        	begin
          	fStateBalancing := 0;
          end;
      end;
   if EOF(fF) then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('Õ¿◊¿ÀŒ Œœ≈–¿÷»» —  ¿–“Œ…' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
        fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if fCOuntRowBalancing > MAXROWBALANCING then
   	begin
      	fStateBalancing := 0;
        fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;

   end;
if fStateBalancing = 3 then
	begin
   	if POS('---  AMOUNT' , fTmpStr) <> 0 then
      	begin
         	fStateBalancing := 4;
            fCountRowBalancing := 0;
         end;
   if EOF(fF) then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('Õ¿◊¿ÀŒ Œœ≈–¿÷»» —  ¿–“Œ…' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
        fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if fCOuntRowBalancing > MAXROWBALANCING then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;

   end;
if fStateBalancing = 4 then
	begin
   	if fSubStateBalancing = 2 then
      	begin
         	if (((Ord(fTmpStr[1]) > $2F) and (Ord(fTmpStr[1]) < $3A)) and (POS('/' , fTmpStr) = 0)) then
            	begin
               	fStateBalancing := 5;
                fCountRowBalancing := 1;
               end;
         end;
   if EOF(fF) then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if fCOuntRowBalancing > MAXROWBALANCING then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;

   end;
if fStateBalancing = 5 then
   begin
   	if ((fTmpStr[1] = '*') and ((Ord(fTmpStr[2]) > $2F) and (Ord(fTmpStr[2]) < $3A))) then
      	begin
         	fStateBalancing := 0;
            fSubStateBalancing := 0;
            fCountRowBalancing := 0;
         end
	else
   	begin
         if Length(Trim(fTmpStr)) > 0 then
         begin
		    if fCountRowBalancing = 1 then
      		begin
			      farrBalancing[Length(farrBalancing) - 1].DispCount.Number.Add(Trim(Copy(fTmpStr , 1 , 2)));
      		   farrBalancing[Length(farrBalancing) - 1].DispCount.TypeCassette.Add(Trim(Copy(fTmpStr , 2 , 3 )));
		         farrBalancing[Length(farrBalancing) - 1].DispCount.Nominal.Add(Trim(Copy(fTmpStr , 5 , 10 )));
      		   farrBalancing[Length(farrBalancing) - 1].DispCount.Count.Add(Trim(Copy(fTmpStr , 15 )));

		      end;
		    if fCountRowBalancing = 2 then
      		begin
// if Assigned(fLog) then fLog.Write('3. Count row - ' + IntToStr(fCountRowBalancing) + '. Str - ' + fTmpStr);
            	farrBalancing[Length(farrBalancing) - 1].DispCount.Currency.Add	(fFindCurrency(fTmpStr));
               farrBalancing[Length(farrBalancing) - 1].DispCount.Amount.Add	(fFindDispAmount(fTmpStr));
               fCountRowBalancing := 0;
		      end;
         end;
      end;
	end;
   if EOF(fF) then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
   if fCOuntRowBalancing > MAXROWBALANCING then
   	begin
      	fStateBalancing := 0;
         fSubStateBalancing := 0;
	      fCOuntRowBalancing := 0;
      end;
// if Assigned(fLog) then fLog.Write('state - ' + IntToStr(fStateBalancing) + '. SubState - ' + IntToStr(fSubStateBalancing) + '. CountRow - ' + IntToStr(fCountRowBalancing));
// if Assigned(fLog) then fLog.Write('Length Balance - ' + IntToStr(Length(fArrBalancing)));

end;

procedure TParseJournal.fStateSettl;
var
	ind : Integer;
	PromStr : String;
  sDAteTime : String;
begin
if Pos('ƒŒ »Õ ¿——¿÷»»' , fTmpStr) <> 0 then
	begin
   	SetLength(fArrStl , Length(fArrStl) + 1);
      fStateStl := 1;
      fCountRowStl := 0;
      fArrStl[Length(fArrStl) - 1].Success := false;
   end;
ind := Length(fArrStl) - 1;
Inc(fCountRowStl);
if fStateStl = 0 then
	exit;
if fStateStl = 1 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;


   	if Pos('ÕŒÃ≈– œ¿ ≈“¿ “–¿Õ«¿ ÷»…' , fTmpStr) <> 0 then
      	begin
            fStateStl := 2;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 26)))))));
		      try
					fArrStl[ind].BeforePacketNum	:= StrToInt(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to BeforePacketNumin STL ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].BeforePacketNum := UNREALINTEGER;
		            end;
		      end;
         end;
   end;
//////// STATE 2
if fStateStl = 2 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;

   	if Pos('“–¿Õ«¿ ÷»… Õ¿  ¿–“≈' , fTmpStr) <> 0 then
      	begin
            fStateStl := 3;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 22)))))));
		      try
					fArrStl[ind].BeforeTrnCount := StrToInt(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to BeforeTrnCount in STL. ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].BeforeTrnCount := UNREALINTEGER;
		            end;
		      end;
         end;
   end;
//////// STATE 3
if fStateStl = 3 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;

   	if Pos('Õ¿ —”ÃÃ” =' , fTmpStr) <> 0 then
      	begin
            fStateStl := 4;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(32) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 11)))))));
		      try
					fArrStl[ind].BeforeTrnAmount := StrToFloat(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to BeforeTrnAmount in STL. ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].BeforeTrnAmount := UNREALDOUBLE;
		            end;
		      end;
         end;
   end;
//////// STATE 4
if fStateStl = 4 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;

   	if Pos('ƒ¿“¿ Õ¿ —≈–¬≈–≈ =' , fTmpStr) <> 0 then
      	begin
            fStateStl := 5;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 18)))))));
          promStr[3] := '.';
          promStr[6] := '.';
          promStr := promStr + ':00';
		      try
					fArrStl[ind].DateTime := StrToDateTime(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to DAteTime  in STL. ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].DateTime := UNREALDATE;
		            end;
		      end;
         end;
   end;
//////// STATE 5
if fStateStl = 5 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;

   	if Pos('œŒ—À≈ »Õ ¿——¿÷»»' , fTmpStr) <> 0 then
      	begin
            fStateStl := 6;
            fCOuntRowStl := 0;
		   end;
  end;

if fStateStl = 6 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;


   	if Pos('ÕŒÃ≈– œ¿ ≈“¿ “–¿Õ«¿ ÷»…' , fTmpStr) <> 0 then
      	begin
            fStateStl := 7;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 26)))))));
		      try
					fArrStl[ind].AfterPacketNum	:= StrToInt(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to AfterPacketNumin STL ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].BeforePacketNum := UNREALINTEGER;
		            end;
		      end;
         end;
   end;
//////// STATE 7
if fStateStl = 7 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;

   	if Pos('“–¿Õ«¿ ÷»… Õ¿  ¿–“≈' , fTmpStr) <> 0 then
      	begin
            fStateStl := 8;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 22)))))));
		      try
					fArrStl[ind].AfterTrnCount := StrToInt(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to AfterTrnCount in STL. ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].AfterTrnCount := UNREALINTEGER;
		            end;
		      end;
         end;
   end;
//////// STATE 8
if fStateStl = 8 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;

   	if Pos('Õ¿ —”ÃÃ” =' , fTmpStr) <> 0 then
      	begin
            fStateStl := 9;
            fCOuntRowStl := 0;
         	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(32) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 11)))))));
		      try
					fArrStl[ind].AfterTrnAmount := StrToFloat(PromStr);
		      except
      			on E : Exception do
         			begin
if Assigned(fLog) then fLog.Write('Error convert to AfterTrnAmount in STL. ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            			fArrStl[ind].AfterTrnAmount := UNREALDOUBLE;
		            end;
		      end;
         end;
   end;
//////// STATE 9
if fStateStl = 9 then
	begin
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('“≈–Ã»Õ¿À Õ≈ »Õ»÷»¿À»«»–Œ¬¿Õ' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('Duet Non Service' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := false;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
      if Pos('”—œ≈ÿÕ¿ﬂ »Õ ¿——¿÷»ﬂ — ’Œ—“¿' , PromStr) <> 0 then
      	begin
          fArrStl[ind].Success := true;
          fStateStl := 0;
          fCountRowStl := 0;
         end;
	   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   		begin
      		fStateStl := 0;
	      	fCOuntRowStl := 0;
	      end;
   	if fCOuntRowStl > MAXROWSTL then
   		begin
      		fStateStl := 0;
		      fCOuntRowStl := 0;
   	   end;
  end;
end;

procedure TParseJournal.fStateTrnMPS;
var
promStr : String;
ind : Integer;
begin
{
 State
 1 - begin
 2 - define address
 3 = define Date and time
 4 - define ATM check valuta
 5 - PAN card
}
if ((Pos('INDUSTRIALBANK' , fTmpStr) <> 0) or (Pos('ALBANK' , fTmpStr) <> 0)) then
	begin
		SetLength(fArrTrnIPS , Length(fArrTrnIPS) + 1);
      fArrTrnIPS[ind].PrintCheck := true;
      fStateTrnIPS := 1;
      fCountRowTrnIPS := 0;
   end;
if fStateTrnIPS = 0 then
	exit;
Inc(fCOuntRowTrnIPS);
ind := Length(fArrTrnIPS) - 1;
// if Assigned(fLog) then fLog.Write('In check state trn IPS. State - ' + IntToStr(fStateTrnIPS) + '. row - ' + IntToStr(fCountRowTrnIPS)) ;
if fStateTrnIPS = 1 then
begin
	if ((POS('******************' , fTmpStr) = 0) and (fCountRowTrnIPS = 2)) then
   	begin
      	fArrTrnIPS[ind].Address := Trim(fTmpStr);
         fStateTrnIPS := 2;
         fCountRowTrnIPS := 0;
      end
   else
      if fCOuntRowTrnIPS = 3 then
	      begin
	      	fArrTrnIPS[ind].Address := Trim(fTmpStr);
   	      fStateTrnIPS := 2;
      	   fCOuntRowTrnIPS := 0;
	      end;
   if EOF(fF) then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if fCOuntRowTrnIPS > MAXROWTRNIPS then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
end;
if fStateTrnIPS = 2 then
begin
   if fCOuntRowTrnIPS = 1 then
   begin
   	promStr := Copy(fTmpStr , 1 , 8);
      promStr[3] := '.';
      promStr[6] := '.';
		promStr := promStr + ' ' + Copy(fTmpStr , 14 , 8);
      try
			fArrTrnIPS[ind].DateTime	:= StrToDateTime(promStr);
      except
      	on E : Exception do
         	begin
if Assigned(fLog) then fLog.Write('Error convert to datetime in trnIPS. ' + promStr + '. ' + E.Message + ' ' + E.ClassName ) ;
            	fArrTrnIPS[ind].DateTime := UNREALDATE;
            end;
      end;
      fStateTrnIPS := 3;
      fCOuntRowTrnIPS := 0;
   end;
   if EOF(fF) then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if fCOuntRowTrnIPS > MAXROWTRNIPS then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;

end;
if fStateTrnIPS = 3 then
begin
   if fCOuntRowTrnIPS = 2 then
   begin
   	fArrTrnIPS[ind].ATM := Trim(Copy(fTmpStr , 5 , 4));
      fArrTrnIPS[ind].Check := Trim(Copy(fTmpStr , 11 , 6));
      fArrTrnIPS[ind].Currency := Trim(Copy(fTmpStr , 17 , 7));
      fStateTrnIPS := 4;
      fCOuntRowTrnIPS := 0;
   end;
   if EOF(fF) then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if fCOuntRowTrnIPS > MAXROWTRNIPS then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;

end;
if fStateTrnIPS = 4 then
begin
   if fCOuntRowTrnIPS = 1 then
   begin
   	fArrTrnIPS[ind].PAN := Trim(Copy(fTmpStr , 4 , 16));
      fStateTrnIPS := 5;
      fCOuntRowTrnIPS := 0;
   end;
   if EOF(fF) then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if fCOuntRowTrnIPS > MAXROWTRNIPS then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;

end;
if fStateTrnIPS = 5 then
begin
	if ((Pos('VYDANO' , fTmpStr) <> 0) or (Pos('VIDANO' , fTmpStr) <> 0) or (Pos('WITHDRAWAL' , fTmpStr) <> 0)) then
		begin
   		promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) ,Trim(Copy(fTmpStr , 11)))))));
		   	try
			   	fArrTrnIPS[ind].Vydano 		:= StrToFloat(promStr);
		   	except
					on E : Exception do
      			      	begin
if Assigned(fLog) then fLog.Write('Error convert to Float Vydano  IPS. ' + E.Message + E.ClassName ) ;
							   	fArrTrnIPS[ind].Vydano := UNREALDOUBLE;
		         	      end;
	      	end;
   	end;
   if ((Pos('KOMISSIQ' , fTmpStr) <> 0) or (Pos('KOMgSgQ' , fTmpStr) <> 0) or (Pos('FEE' , fTmpStr) <> 0)) then
   	begin
      	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , Trim(Copy(fTmpStr , 11)))))));
		   try
			   fArrTrnIPS[ind].Fee	:= StrToFloat(promStr);
	   	except
				on E : Exception do
      			      	begin
if Assigned(fLog) then fLog.Write('Error convert to Float FEE  IPS. ' + E.Message + E.ClassName ) ;
							   	fArrTrnIPS[ind].Fee := UNREALDOUBLE;
		         	      end;
	      end;
		end;
	if ((Pos('ITOGO' , fTmpStr) <> 0) or (Pos('RAZOM' , fTmpStr) <> 0) or (Pos('TOTAL' , fTmpStr) <> 0)) then
   	begin
      	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , Trim(Copy(fTmpStr , 11)))))));
      	try
         	fArrTrnIPS[ind].Itogo	:= StrToFloat(promStr);
	   	except
				on E : Exception do
      			      	begin
if Assigned(fLog) then fLog.Write('Error convert to Float ITOGO  IPS. ' + E.Message + E.ClassName ) ;
							   	fArrTrnIPS[ind].Itogo  := UNREALDOUBLE;
		         	      end;
			end;
		end;

	if ((Pos('OSTATOK' , fTmpStr) <> 0) or (Pos('ZALIWOK' , fTmpStr) <> 0)) then
     	begin
      	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , Trim(Copy(fTmpStr , 11)))))));
         if promStr[Length(promStr)] = '-' then
         	promStr := '-' + Copy(promStr , 1 , Length(promStr) - 1);
	      	try
   	      	fArrTrnIPS[ind].Ostatok	:= StrToFloat(promStr);
	   		except
					on E : Exception do
      			      	begin
if Assigned(fLog) then fLog.Write('Error convert to Float Ostatok  IPS. ' + E.Message + E.ClassName ) ;
							   	fArrTrnIPS[ind].Ostatok  := UNREALDOUBLE;
		         	      end;
				end;
      end;
	if Pos('OVERDRAFT' , fTmpStr) <> 0 then
   	begin
      	promStr := Trim(fDelDelimiter(CHR(36) , (fDelDelimiter(CHR(0) , fDelDelimiter(CHR(39) , Trim(Copy(fTmpStr , 11)))))));
         try
         	fArrTrnIPS[ind].Overdraft	:= StrToFloat(promStr);
         except
         	on E : Exception do
      			      	begin
if Assigned(fLog) then fLog.Write('Error convert to Float Overdraft  IPS. ' + E.Message + E.ClassName ) ;
							   	fArrTrnIPS[ind].Overdraft  := UNREALDOUBLE;
		         	      end;
			end;
	end;
   if Pos('BEZ PEXATI XEKA' , fTmpStr) <> 0 then
   	begin
      	fArrTrnIPS[ind].PrintCheck := false;
	      fStateTrnIPS := 0;
   	   fCOuntRowTrnIPS := 0;
      end;
   if Pos('*********************' , fTmpStr) <> 0 then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if EOF(fF) then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if Pos('œ–»ÀŒ∆≈Õ»≈ «¿œ”Ÿ≈ÕŒ' , fTmpStr) <> 0 then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;
   if fCOuntRowTrnIPS > MAXROWTRNIPS then
   	begin
      	fStateTrnIPS := 0;
	      fCOuntRowTrnIPS := 0;
      end;

end;
// if Assigned(fLog) then fLog.Write('State - ' + IntToStr(fStateTrnIPS) + '. Count TRN - ' + IntToStr(Length(fArrTrnIPS)));

end;

procedure TParseJournal.fInsertBalancing;
var
i , j : Integer;
tmpPrintCheck : Integer;
sDateTime : String;
iRetId : Integer;
iRetErr : Integer;
// var for insert with correct type
sBusinessDate : String;
dBusinessDate : TDateTime;
dDateTime	: TDateTime;
// for nominal
iNominalNumber : Integer;
iNominalNominal : Double;
iNominalCount : Integer;
iNominalAmount : Double;
// for Tran type
iTranTypeCount : Integer;
iTranTypeAmount : Double;
isCorrectConvert : boolean;
begin
fProc1.ProcedureName := 'insert_CheckBalance';
fProc2.ProcedureName := 'insert_TransTypesBalance';
fProc3.ProcedureName := 'insert_NominalBalance';
// if Assigned(fLog) then fLog.Write('Insert Balancing. ' + fProc1.ProcedureName );
if Length(fArrBalancing) > 0 then
	for i := 0 to Length(fArrBalancing) - 1 do
 		begin
         isCorrectConvert := true;
		   if Length(Trim(fArrBalancing[i].BusinessDate)) > 0  then
		   	begin
            	fArrBalancing[i].BusinessDate := fDelDelimiter(CHR(0) , fArrBalancing[i].BusinessDate);
      			fArrBalancing[i].BusinessDate[3] := '.';
		         fArrBalancing[i].BusinessDate[6] := '.';
               sBusinessDate := '';
               sBusinessDate := Copy(fArrBalancing[i].BusinessDate , 4 , 2) + '.' + Copy(fArrBalancing[i].BusinessDate , 1 , 2) + '.20' + Copy(fArrBalancing[i].BusinessDate , 7 , 2);
				   try
	   				dBusinessDate := StrToDateTime(sBusinessDate); // + ' ' + '00:00:00');
				   except
						on E : Exception do
		      			      	begin
// 	if Assigned(fLog) then fLog.Write('Error convert to DateTime Business date. ' + E.Message + E.ClassName ) ;
                              	isCorrectConvert := false;
	   		      		      end;
				   end;
      		end
		   else
   			isCorrectConvert := false;

      	sDateTime := Trim(fArrBalancing[i].Date + ' ' + fArrBalancing[i].Time );
         sDateTime := fDelDelimiter(CHR(0) , sDateTime);
		   if Length(Trim(sDateTime)) > 0  then
		   	begin
		         sDateTime[3] := '.';
      		   sDateTime[6] := '.';
				   try
	   				dDateTime := StrToDateTime(sDateTime);
				   except
						on E : Exception do
		      			      	begin
// 	if Assigned(fLog) then fLog.Write('Error convert to DateTime DateTime. ' + E.Message + E.ClassName ) ;
                              	isCorrectConvert := false;
	   		      		      end;
				   end;
      		end
		   else
   			isCorrectConvert := false;

         if isCorrectConvert then
         	begin
          	fProc1.Parameters.Clear ;
						fProc1.Parameters.CreateParameter('@atmNumber' 		, ftString 	, pdInput 	, 10 	, fATMName);
            fProc1.Parameters.CreateParameter('@BusinessDate'	, ftDateTime, pdInput 	, 8 	, dBusinessDate);
            fProc1.Parameters.CreateParameter('@datetime'		, ftDateTime, pdInput 	, 8 	, sDateTime);
						fProc1.Parameters.CreateParameter('@Number' 			, ftString 	, pdInput 	, 10 	, fArrBalancing[i].Number);
            fProc1.Parameters.CreateParameter('@filename'    	, ftString  , pdInput 	, 250 , fNamFil);
            fProc1.Parameters.CreateParameter('@id'         	, ftInteger , pdOutput 	, 4 , 0);
	   		   	fProc1.Parameters.CreateParameter('@err'         	, ftInteger , pdOutput 	, 4 , 0);
   		   		fProc1.Parameters.CreateParameter('@Mess'        	, ftString  , pdOutput 	, 100 , 0 );
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
									if Assigned(fLog) then fLog.Write('Exception exec proc1 in insert Balancing. ' + E.Message + '. ' + E.ClassName ) ;
                  iRetErr := -1;
                end;
						end;
		        if iRetErr = 0 then
    		    	begin
		            iRetErr := fProc1.Parameters.ParamByName('@err').Value ;
								if iRetErr = 0  then
        		    	begin
		        		    iRetId := fProc1.Parameters.ParamByName('@id').Value ;
              			isCorrectConvert := true;
		                if fArrBalancing[i].TranType.Number.Count  > 0 then
    		            	begin
        		          	for j := 0 to fArrBalancing[i].TranType.Number.Count - 1 do
            		        	begin
														if Length(fArrBalancing[i].TranType.Count.Strings[j]) = 0 then
															fArrBalancing[i].TranType.Count.Strings[j] := '0';
  													if Length(fArrBalancing[i].TranType.Count.Strings[j]) > 0 then
		                        	begin
    		                      	fArrBalancing[i].TranType.Count.Strings[j] := fDelDelimiter(CHR(39) , fArrBalancing[i].TranType.Count.Strings[j]);
        		                    fArrBalancing[i].TranType.Count.Strings[j] := fDelDelimiter(CHR(0) , fArrBalancing[i].TranType.Count.Strings[j]);
            		                try
                		            	iTranTypeCount := StrToInt(fArrBalancing[i].TranType.Count.Strings[j]);
                    		        except
																	on E : Exception do
		      						      					begin
																				if Assigned(fLog) then fLog.Write('Error convert to Count of TranType. ' + E.Message + E.ClassName ) ;
		                                  	isCorrectConvert := false;
				   		      		   				   	end;
  															end;
  														end
  													else
                    		    	isCorrectConvert := false;
                        	  if Length(fArrBalancing[i].TranType.Amount.Strings[j]) > 0 then
                          		begin
                            		fArrBalancing[i].TranType.Amount.Strings[j] := fDelDelimiter(CHR(39) , fArrBalancing[i].TranType.Amount.Strings[j]);
	                              fArrBalancing[i].TranType.Amount.Strings[j] := fDelDelimiter(CHR(0) , fArrBalancing[i].TranType.Amount.Strings[j]);
  	                            try
    	                          	iTranTypeAmount := StrToFloat(fArrBalancing[i].TranType.Amount.Strings[j]);
      	                        except
																	on E : Exception do
		      							      			begin
																			if Assigned(fLog) then fLog.Write('Error convert TranType Amount. ' + E.Message + E.ClassName ) ;
	  																	isCorrectConvert := false;
                                    end;
	  														end;
  														end
  													else
      	                    	isCorrectConvert := false;
                            if isCorrectConvert then
                            	begin
                              	fProc2.Parameters.Clear;
                                fProc2.Parameters.CreateParameter('@CheckId'	, ftInteger , pdInput , 4 , iRetId);
                                fProc2.Parameters.CreateParameter('@Number'  , ftString	, pdInput , 10 , fArrBalancing[i].TranType.Number.Strings[j] );
                                fProc2.Parameters.CreateParameter('@count'   , ftInteger , pdInput , 4 , iTranTypeCount);
                                fProc2.Parameters.CreateParameter('@amount'  , ftCurrency, pdInput , 10 , iTranTypeAmount);
									   		   			fProc2.Parameters.CreateParameter('@err'     , ftInteger , pdOutput 	, 4 , 0);
											   		   	fProc2.Parameters.CreateParameter('@Mess'    , ftString  , pdOutput 	, 100 , 0 );
										   		      try
												  		    fProc2.ExecProc ;
												         except
										      		   	on E : Exception do
																		if Assigned(fLog) then fLog.Write('Exception exec proc2. ' + E.Message + '. ' + E.ClassName ) ;
												        end; // try
                              end; // isCorrectConvert
                            end; // for j for trantype
                      end;
////////////////// disp amount
                     	if fArrBalancing[i].DispCount.Number.Count  > 0 then
                        begin
                           for j := 0 to fArrBalancing[i].DispCount.Number.Count - 1 do
                           	begin
															if Length(fArrBalancing[i].DispCount.Count.Strings[j]) = 0	then
																fArrBalancing[i].DispCount.Count.Strings[j] := '0';
															if Length(fArrBalancing[i].DispCount.Amount.Strings[j]) = 0 then
																fArrBalancing[i].DispCount.Amount.Strings[j] := '0.00';
                             	isCorrectConvert := true;
                              if Length(fArrBalancing[i].DispCount.Number.Strings[j]) > 0 then
                        	      begin
		                      	     	fArrBalancing[i].DispCount.Number.Strings[j] := fDelDelimiter(CHR(39) , fArrBalancing[i].DispCount.Number.Strings[j]);
      		                        fArrBalancing[i].DispCount.Number.Strings[j] := fDelDelimiter(CHR(0) , fArrBalancing[i].DispCount.Number.Strings[j]);
                                try
                                	iNominalNumber := StrToInt(fArrBalancing[i].DispCount.Number.Strings[j]);
                                except
																	on E : Exception do
		  		    						      			begin
																				if Assigned(fLog) then fLog.Write('Error convert to Number of Nominal Number. ' + E.Message + E.ClassName ) ;
                                      	isCorrectConvert := false;
                                      end;
                            end;
                           end
                     	else
                     		isCorrectConvert := false;
                      if Length(fArrBalancing[i].DispCount.Count.Strings[j]) > 0 then
                      	begin
                        	fArrBalancing[i].DispCount.Count.Strings[j] := fDelDelimiter(CHR(39) , fArrBalancing[i].DispCount.Count.Strings[j]);
                          fArrBalancing[i].DispCount.Count.Strings[j] := fDelDelimiter(CHR(0) , fArrBalancing[i].DispCount.Count.Strings[j]);
                          try
                          	iNominalCount := StrToInt(fArrBalancing[i].DispCount.Count.Strings[j]);
                          except
                          	on E : Exception do
                            		begin
																	if Assigned(fLog) then fLog.Write('Error convert to Count of Nominal Nominal. ' + E.Message + E.ClassName ) ;
                                  isCorrectConvert := false;
		   		      		   				   end;
                          end;
                        end
                      else
                      	isCorrectConvert := false;
                      if Length(fArrBalancing[i].DispCount.Nominal.Strings[j]) > 0 then
                      	begin
                        	fArrBalancing[i].DispCount.Nominal.Strings[j] := fDelDelimiter(CHR(39) , fArrBalancing[i].DispCount.Nominal.Strings[j]);
                          fArrBalancing[i].DispCount.Nominal.Strings[j] := fDelDelimiter(CHR(0) , fArrBalancing[i].DispCount.Nominal.Strings[j]);
                      		try
		                      	iNominalNominal := StrToFloat(fArrBalancing[i].DispCount.Nominal.Strings[j]);
    		                  except
        		              	on E : Exception do
            		            	begin
																if Assigned(fLog) then fLog.Write('Error convert to float of Nominal Nominal. ' + E.Message + E.ClassName ) ;
                    		        isCorrectConvert := false;
                        		  end;
	                        end;
  	                    end
											else
                      	isCorrectConvert := false;
                      if Length(fArrBalancing[i].DispCount.Amount.Strings[j]) > 0 then
                      	begin
                        	fArrBalancing[i].DispCount.Amount.Strings[j] := fDelDelimiter(CHR(39) , fArrBalancing[i].DispCount.Amount.Strings[j]);
                          fArrBalancing[i].DispCount.Amount.Strings[j] := fDelDelimiter(CHR(0) , fArrBalancing[i].DispCount.Amount.Strings[j]);
                        	try
                          	iNominalAmount := StrToFloat(fArrBalancing[i].DispCount.Amount.Strings[j]);
                          except
                          	on E : Exception do
		      						      	begin
																if Assigned(fLog) then fLog.Write('Error convert Nominal Amount. ' + E.Message + E.ClassName ) ;
                                isCorrectConvert := false;
                              end;
                          end;
                        end
                      else
                      	isCorrectConvert := false;
                      if isCorrectConvert then
                      	begin
                        	fProc3.Parameters.Clear;
                          fProc3.Parameters.CreateParameter('@CheckId'	, ftInteger , pdInput 	, 4 , iRetId);
                          fProc3.Parameters.CreateParameter('@Number'  , ftInteger	, pdInput 	, 4 , iNominalNumber);
													fProc3.Parameters.CreateParameter('@Cassette', ftString	, pdInput 	, 1 , fArrBalancing[i].DispCount.TypeCassette.Strings[j] );
                          fProc3.Parameters.CreateParameter('@Nominal' , ftCurrency	, pdInput 	, 10 , iNominalNominal);
                          fProc3.Parameters.CreateParameter('@count'   , ftInteger , pdInput 	, 4 , iNominalCount);
                          fProc3.Parameters.CreateParameter('@amount'  , ftCurrency, pdInput 	, 10 , iNominalAmount);
                          fProc3.Parameters.CreateParameter('@currency'  , ftString, pdInput 	, 5 , fArrBalancing[i].DispCount.Currency.Strings[j] );
									   		  fProc3.Parameters.CreateParameter('@err'     , ftInteger , pdOutput 	, 4 , 0);
								   		   	fProc3.Parameters.CreateParameter('@Mess'    , ftString  , pdOutput 	, 100 , 0 );
                          try
                          	fProc3.ExecProc ;
                          except
                          	on E : Exception do
															if Assigned(fLog) then fLog.Write('Exception exec proc3. ' + E.Message + '. ' + E.ClassName ) ;
                          end; // try
                        end; // isCorrectConvert
                      end; // for j for trantype
									end;
							end;
            end;
          end;
   end;
SetLength(fArrBalancing , 0);
end;

procedure TParseJournal.fInsertSettlement;
var
i : Integer;
begin
fProc1.ProcedureName := 'insert_CheckIncass';
// if Assigned(fLog) then fLog.Write('Insert STL ' + fProc1.ProcedureName );
if Length(fArrStl) > 0 then
	for i := 0 to Length(fArrStl) - 1 do
 		begin
			fProc1.Parameters.Clear ;
//if Assigned(fLog) then fLog.Write('1');
//			fProc1.Parameters.CreateParameter('@RETURN_VALUE', ftInteger	, pdOutput	, 4 	, 0);
// if Assigned(fLog) then fLog.Write('2');
			fProc1.Parameters.CreateParameter('@atmNumber' 	, ftString 	, pdInput 	, 10 	, fATMName);
// if Assigned(fLog) then fLog.Write('3  ' + IntToStr(fArrStl[i].BeforePacketNum));
			fProc1.Parameters.CreateParameter('@BeforePacketNum' 	, ftInteger 	, pdInput 	, 4 	, fArrStl[i].BeforePacketNum);
// if Assigned(fLog) then fLog.Write('4  ' + IntToStr(fArrStl[i].BeforeTrnCount));
			fProc1.Parameters.CreateParameter('@BeforeTrnCount' 	, ftInteger 	, pdInput 	, 4 	, fArrStl[i].BeforeTrnCount);
// if Assigned(fLog) then fLog.Write('5 	' + FloatToStrF(fArrStl[i].BeforeTrnAmount , ffFixed , 15 , 2));
			fProc1.Parameters.CreateParameter('@BeforeTrnAmount' 	, ftCurrency 	, pdInput 	, 10 	, fArrStl[i].BeforeTrnAmount);
// if Assigned(fLog) then fLog.Write('6 	' + DateTimeToStr(fArrStl[i].DateTime));
			fProc1.Parameters.CreateParameter('@datetime'		, ftDateTime, pdInput 	, 8 			, fArrStl[i].DateTime);
// if Assigned(fLog) then fLog.Write('7  ' + IntToStr(fArrStl[i].BeforePacketNum));
			fProc1.Parameters.CreateParameter('@AfterPacketNum' 	, ftInteger 	, pdInput 	, 4 	, fArrStl[i].AfterPacketNum);
// if Assigned(fLog) then fLog.Write('8  ' + IntToStr(fArrStl[i].BeforeTrnCount));
			fProc1.Parameters.CreateParameter('@AfterTrnCount' 	, ftInteger 	, pdInput 	, 4 	, fArrStl[i].AfterTrnCount);
// if Assigned(fLog) then fLog.Write('9  ' + FloatToStrF(fArrStl[i].BeforeTrnAmount , ffFixed , 15 , 2));
			fProc1.Parameters.CreateParameter('@AfterTrnAmount' 	, ftCurrency 	, pdInput 	, 10 	, fArrStl[i].AfterTrnAmount);
// if Assigned(fLog) then fLog.Write('10  ' + fNamFil);
	      fProc1.Parameters.CreateParameter('@filename'    , ftString  , pdInput 	, 250 , fNamFil);
// if Assigned(fLog) then fLog.Write('17');
   	   fProc1.Parameters.CreateParameter('@err'         , ftInteger , pdOutput 	, 4 , 0);
// if Assigned(fLog) then fLog.Write('18');
      	fProc1.Parameters.CreateParameter('@Mess'        , ftString  , pdOutput 	, 100 , 0 );
// if Assigned(fLog) then fLog.Write('19');
         try
		      fProc1.ExecProc ;
         except
         	on E : Exception do
if Assigned(fLog) then fLog.Write('Exception exec proc. ' + E.Message + '. ' + E.ClassName ) ;
         end;
if Assigned(fLog) then fLog.Write('After ExecProc. i = ' + IntToStr(i) + '. err - ' + IntToStr(fProc1.Parameters.ParamByName('@err').Value) + '. Mess - ' + fProc1.Parameters.ParamByName('@Mess').Value) ;
   end;
SetLength(fArrStl , 0);



end;

procedure TParseJournal.fInsertVydacha;
var
i : Integer;
tmpPrintCheck : Integer;

begin
fProc1.ProcedureName := 'insert_CheckMPS';
// if Assigned(fLog) then fLog.Write('Insert Vydacha. ' + fProc1.ProcedureName );
if Length(fArrTrnIPS) > 0 then
	for i := 0 to Length(fArrTrnIPS) - 1 do
 		begin
			fProc1.Parameters.Clear ;
//if Assigned(fLog) then fLog.Write('1');
//			fProc1.Parameters.CreateParameter('@RETURN_VALUE', ftInteger	, pdOutput	, 4 	, 0);
// if Assigned(fLog) then fLog.Write('2');
			fProc1.Parameters.CreateParameter('@atmNumber' 	, ftString 	, pdInput 	, 10 	, fATMName);
// if Assigned(fLog) then fLog.Write('3. atm - ' + fArrTrnIPS[i].ATM);
			fProc1.Parameters.CreateParameter('@atm' 			, ftString 	, pdInput 	, 10 	, fArrTrnIPS[i].ATM );
// if Assigned(fLog) then fLog.Write('4. address - ' + fArrTrnIPS[i].Address);
			fProc1.Parameters.CreateParameter('@address' 		, ftString 	, pdInput 	, 100	, fArrTrnIPS[i].Address );
// if Assigned(fLog) then fLog.Write('5. date - ' + DAteTimeToStr(fArrTrnIPS[i].DateTime));
			fProc1.Parameters.CreateParameter('@datetime'		, ftDateTime, pdInput 	, 8 	, fArrTrnIPS[i].DateTime);
// if Assigned(fLog) then fLog.Write('6. Check - ' + fArrTrnIPS[i].Check);
	      fProc1.Parameters.CreateParameter('@check'       , ftString  , pdInput 	, 10  , fArrTrnIPS[i].Check);
// if Assigned(fLog) then fLog.Write('7');
   	   fProc1.Parameters.CreateParameter('@currency'    , ftString  , pdInput 	, 5   , fArrTrnIPS[i].Currency);
// if Assigned(fLog) then fLog.Write('8');
      	fProc1.Parameters.CreateParameter('@pan'         , ftString  , pdInput 	, 20  , fArrTrnIPS[i].PAN);
// if Assigned(fLog) then fLog.Write('9');
      	if fArrTrnIPS[i].Vydano <> UNREALDOUBLE then
		      fProc1.Parameters.CreateParameter('@vydano'      , ftCurrency, pdInput 	, 10  , fArrTrnIPS[i].Vydano)
         else
		      fProc1.Parameters.CreateParameter('@vydano'      , ftCurrency, pdInput 	, 10  , NULL);
// if Assigned(fLog) then fLog.Write('10. ' + FloatToStrF(fArrTrnIPS[i].Fee , ffFixed , 15 , 2) + '. ' + FloatToStrF(UNREALDOUBLE , ffFixed , 15 , 2) );
      	if FloatToStrF(fArrTrnIPS[i].Fee , ffFixed , 15 , 2) <> FloatToStrF(UNREALDOUBLE  , ffFixed , 15 , 2)  then
	   	   fProc1.Parameters.CreateParameter('@fee'         , ftCurrency, pdInput 	, 10  , fArrTrnIPS[i].Fee)
         else
         	fProc1.Parameters.CreateParameter('@fee'         , ftCurrency, pdInput 	, 10  , NULL);
// if Assigned(fLog) then fLog.Write('11');
			if fArrTrnIPS[i].Itogo <> UNREALDOUBLE then
      		fProc1.Parameters.CreateParameter('@itogo'       , ftCurrency, pdInput 	, 10  , fArrTrnIPS[i].Itogo)
         else
	      	fProc1.Parameters.CreateParameter('@itogo'       , ftCurrency, pdInput 	, 10  , NULL);
// if Assigned(fLog) then fLog.Write('12');
      	if fArrTrnIPS[i].Ostatok <> UNREALDOUBLE then
	      	fProc1.Parameters.CreateParameter('@rest'        , ftCurrency, pdInput 	, 10  , fArrTrnIPS[i].Ostatok)
      	else
         	begin
					fProc1.Parameters.CreateParameter('@rest'        , ftCurrency, pdInput 	, 10  , NULL);
            end;
// if Assigned(fLog) then fLog.Write('13');
      	if fArrTrnIPS[i].Overdraft <> UNREALDOUBLE then
   	   	fProc1.Parameters.CreateParameter('@overdraft'   , ftCurrency, pdInput 	, 10  , fArrTrnIPS[i].Overdraft)
      	else
	         fProc1.Parameters.CreateParameter('@overdraft'   , ftCurrency, pdInput 	, 10  , NULL);
// if Assigned(fLog) then fLog.Write('14');
      	if fArrTrnIPS[i].PrintCheck then
         	tmpPrintCheck := 1
	      else
   	   	tmpPrintCheck := 0;
// if Assigned(fLog) then fLog.Write('15');
      	fProc1.Parameters.CreateParameter('@printCheck'  , ftInteger , pdInput 	, 4   , tmpPrintCheck);
// if Assigned(fLog) then fLog.Write('16');
	      fProc1.Parameters.CreateParameter('@filename'    , ftString  , pdInput 	, 250 , fNamFil);
// if Assigned(fLog) then fLog.Write('17');
   	   fProc1.Parameters.CreateParameter('@err'         , ftInteger , pdOutput 	, 4 , 0);
// if Assigned(fLog) then fLog.Write('18');
      	fProc1.Parameters.CreateParameter('@Mess'        , ftString  , pdOutput 	, 100 , 0 );
// if Assigned(fLog) then fLog.Write('19');
         try
		      fProc1.ExecProc ;
         except
         	on E : Exception do
if Assigned(fLog) then fLog.Write('Exception exec proc. ' + E.Message + '. ' + E.ClassName ) ;
         end;
// if Assigned(fLog) then fLog.Write('After ExecProc. i = ' + IntToStr(i) + '. err - ' + IntToStr(fProc1.Parameters.ParamByName('@err').Value) + '. Mess - ' + fProc1.Parameters.ParamByName('@Mess').Value) ;
   end;
SetLength(fArrTrnIPS , 0);


end;

procedure TParseJournal.Start;
var
	IsReadyFile : boolean;
   NumRow : Integer;
begin
if Assigned(fLog) then fLog.Write('Start parsing. ' + fNamFil);
fSuccessParse := false;
IsReadyFile := true;
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
   fStateTrnIPS := 0;
   fStateBalancing := 0;
   fStateStl := 0;
   fCountRowTrnIPS := 0;
   fCountRowBalancing := 0;
   fCountRowStl := 0;
	while not Eof(fF) do
	begin
		Readln(fF , fTmpStr);
    fOnWorkJrn(self , Length(fTmpStr));
	   if fCheckTransIPS then
         begin
		      fStateTrnMPS;
         end;
	   if fCheckBalansing then
      	begin
          fStateBalanc;
         end;
      if fCheckStl then
         begin
          fStateSettl;
         end;
	end;
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
