unit clThCopyBilbo1;

interface
uses
	Windows, SysUtils , Classes, DateUtils, Variants, ShellAPI,
  clLogAcceptor1, ADODB, DB , activeX , comobj;
const
		UNREALDOUBLE : Double = -999999999.99;
   	UNREALINTEGER : Integer = HIGH(INTEGER);
   	UNREALDATE	: TDateTime = 0;

type
	TrecLogBilbo = record
  	FileNAme : String;
    sizeSended	: Integer;
    speed				: Double;
    eta					: TDateTime;
    progress		: Integer; 	
  end;

type
	TThCopyBilbo = class(TThread)
  private
		fLog							: TLogAcceptor;
    fAtm							: String;
    fTag							: Integer;

    fProgName					: String;
    fFUIBDir          : String;
    fAddress					: String;
    fRootDir          : String;
    fSubDir           : String;
    fUser             : String;
    fPassword         : String;
    fParams           : String;
    fRootDirBilbo			: String;
    fDirArchBilbo			: String;
    fDirSendBilbo			: String;
    fDirBackBilbo			: String;
    fDirLogBilbo			: String;
    fMaskLog					: String;

    fCurrFileName					: String;
    fCurrCountFileBilbo		: Integer;
    fAllCountFileBilbo		: Integer;
    fNameSource				: String;
    fNameDest					: String;
    fLogName					: String;
    fCmdParam1				: String;
    fCmdParam2				: String;
    fCmdParam3				: String;
    fCmdParam4				: String;

    fArrLogBilbo			: array of TrecLogBilbo;
    fConn : TADOConnection;
    fProc1	: TADOStoredProc;
    fMaskWork : DWORD;

    procedure fDefParam1;
    procedure fDefParam2;
    procedure fDefParam3;
    procedure fDefParam4;

    procedure fDefNameSource ;
    procedure fDefNameDest;
    procedure fDefLogName;
    procedure fCopyBilbo;
    function fSaveLog : boolean;
    function fAnalizLog : boolean;
    procedure fDefLogBilbo;
    procedure fConnectSQL;
    procedure fInsertSQL;
    function fRenMov(FilName: String): boolean;



  public
		constructor Create(ACreateSuspended, IsLog: boolean ; Num : Integer);
  	destructor Destroy; override;
	  procedure Execute; override;
  	procedure Terminate;

   property Tag : Integer read fTag write fTag ;

	  property ProgName : STring read fProgName write fProgName;
    property Address	: String read fAddress	write fAddress;
    property RootDir 	: String read fRootDir  write fRootDir;
    property SubDir  	: String read fSubDir   write fSubDir;
    property User    	: String read fUser     write fUser;
    property Password : String read fPassword write fPassword;
    property Params  	: String read fParams   write fParams;
    property FUIBDir 	: String read fFUIBDir  write fFUIBDir;
    property MaskLog	: String read fMaskLog	write fMaskLog;

    property RootDirBilbo		: String read fRootDirBilbo	 write fRootDirBilbo	;
    property DirArchBilbo		: String read fDirArchBilbo	 write fDirArchBilbo	;
    property DirSendBilbo		: String read fDirSendBilbo	 write fDirSendBilbo	;
    property DirBackBilbo		: String read fDirBackBilbo	 write fDirBackBilbo	;
    property DirLogBilbo	 	: String read fDirLogBilbo	 write fDirLogBilbo		;
    property MaskWork					: DWORD			read 		fMaskWork				write fMaskWork;
    property CurrFileName				: String	 read fCurrFileName					write fCurrFileName					;
    property CurrCountFileBilbo  : Integer  read fCurrCountFileBilbo   write fCurrCountFileBilbo   ;
    property AllCountFileBilbo   : Integer  read fAllCountFileBilbo    write fAllCountFileBilbo    ;

  end;
implementation
uses
  frmParsing1;
{ TThCopyBilbo }

constructor TThCopyBilbo.Create(ACreateSuspended, IsLog: boolean ; Num : Integer);
begin
  inherited Create(ACreateSuspended);
  if isLog then
    fLog := TLogAcceptor.Create('CopyBilbo_' + IntToStr(Num), frmParsing.fGlobalParams.Values['LocalDir']);
    fAtm := IntToStr(Num);
	 fConn := TADOConnection.Create(nil);
   fProc1 := TADOStoredProc.Create(nil);
   fConn.ConnectionString := 'Provider=SQLOLEDB.1;data source=S-EUROPAY;Integrated Security=SSPI;initial catalog=Translog';
   fConn.CommandTimeout := 10000;
   fConn.LoginPrompt := false;
   fConn.KeepConnection := true;
   fConn.ConnectionTimeout := 5000;
   fProc1.Connection := fConn;
   fProc1.CommandTimeout := 10000;
   fProc1.Parameters.Clear;

end;

destructor TThCopyBilbo.Destroy;
begin
  if Assigned(fLog) then fLog.Free;
	if Assigned (fConn) then fConn.Free ;
	if Assigned (fProc1) then fProc1.Free ;

  inherited;
end;

procedure TThCopyBilbo.Execute;
var
sr : TSearchRec;
begin
  inherited;
  if ((fMaskWork and frmParsing1.MASKBILBO) <> 0 ) then
  	begin
			if Assigned(fLog) then fLog.Write('Execute Th Bilbo');
			if Assigned(fLog) then fLog.Write(fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirSendBilbo + '\' + fMaskLog);
    	fCurrCountFileBilbo	:= 0;
      fAllCountFileBilbo	:= 0;
			SendMessage(frmParsing.AppHndl , WM_SENDBILBO , 0 , fTag);
		  if FindFirst(fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirSendBilbo + '\' + fMaskLog , faAnyFile , sr) = 0 then
  			begin
		      repeat
          	Inc(fAllCountFileBilbo);
		      until (FindNext(sr) <> 0);
		      FindClose(sr);
        end;
			SendMessage(frmParsing.AppHndl , WM_SENDBILBO , 2 , fTag);
		  if FindFirst(fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirSendBilbo + '\' + fMaskLog , faAnyFile , sr) = 0 then
  			begin
		      repeat
		      	fCurrFileName := sr.Name;
			      SendMessage(frmParsing.AppHndl , WM_SENDBILBO , 3 , fTag);
						if Assigned(fLog) then fLOg.Write('Find File in ' + fRootDirBilbo  + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirSendBilbo + '\' + fMaskLog + '. name - ' + sr.Name);
					  fDefParam1;
					  fDefParam2;
					  fDefParam3;
					  fDefParam4;
    		    fCopyBilbo;
        		if fSaveLog then
		        	begin
								if Assigned(fLog) then fLOg.Write('fSaveLog - true');
		            if fRenMov(sr.Name) then
    		        	begin
										if Assigned(fLog) then fLOg.Write('Success Remove file');
		              end
    		        else
        		    	begin
										if Assigned(fLog) then fLOg.Write('Error Remove file');
		              end;
    		      end
		        else
    		      begin
								if Assigned(fLog) then fLOg.Write('fSaveLog - FALSE');
		          end;
            Inc(fCurrCountFileBilbo);
            SendMessage(frmParsing.AppHndl , WM_SENDBILBO , 3 , fTag);
		      until (FindNext(sr) <> 0);
	      	FindClose(sr);
	  	    fCurrFileName := '';
    		end;
      SendMessage(frmParsing.AppHndl , WM_SENDBILBO , 1 , fTag);
    end;
end;

function TThCopyBilbo.fAnalizLog: boolean;
var
i : Integer;
retVal : boolean;
begin
retVal := false;
  if Length(fArrLogBilbo) > 0 then
  	begin
    	for i := Length(fArrLogBilbo) - 1 downto 0 do
      	begin
          if fArrLogBilbo[i].progress = 100 then
            begin
            	retVal := true;
              exit;
            end;
        end;
    end;
	Result := retVal;
end;

procedure TThCopyBilbo.fCopyBilbo;
var
retVal : boolean;
currTick : DWord;
MaxTick : DWord;
SEInfo : TShellExecuteInfo;
begin
	MaxTick := 600000;
if Assigned(fLog)  then fLog.Write('param2 - ' + fCmdParam2);
if Assigned(fLog)  then fLog.Write('param3 - ' + fCmdParam3);

	FillChar(SEInfo, SizeOf(SEInfo), 0);
	SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  SEInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
//  SEInfo.Wnd := frmParsing.AppHndl;
  SEInfo.Wnd := 0;
  SEInfo.lpVerb:= 'open';
  SEInfo.nShow := SW_HIDE;
//  SEInfo.nShow := SW_SHOWNORMAL;
  SEInfo.lpFile := PChar(fCmdParam2);
  SEInfo.lpParameters := PChar(fCmdParam3);
if Assigned(fLog)  then fLog.Write('Before Start pscp - ' + fCmdParam2 + fCmdParam3);
	if ShellExecuteEx(@SEInfo) then
  	begin
     	WaitForSingleObject(SEInfo.hProcess , MaxTick);
if Assigned(fLog)  then fLog.Write('hndl process - ' + IntToStr(SEInfo.hProcess));
    end
  else
    begin
if Assigned (fLog) then fLog.Write('Error Execute Shell - ' + fCmdParam3);
	    exit;
    end;
// Synchronize(fAddToMemo);
if Assigned(fLog)  then fLog.Write('Cpy BILBO - After');
end;

procedure TThCopyBilbo.fDefLogBilbo;
var
	i : Integer;
  sr : TsearchRec;
  F : TextFile;
  tmpStr : String;
  analStr : String;
  ind : Integer;
  Fhndl : DWord;
  Buf	: PChar;
  PosBeg , PosEnd : Integer;
begin
  if FindFirst(fLogName , faAnyFile , sr) <> 0 then
  	begin
if Assigned(fLog) then fLog.Write('No such file of log bilbo work. ' + fLogName);
    	exit;
    end;
	if sr.Size = 0  then
  	begin
			if Assigned(fLog) then fLog.Write('No such file of log bilbo work. ' + fLogName);
      exit;
    end;
  SetLength(fArrLogBilbo , 0);
	AssignFile(F , fLogName);
  Reset(F);
  while not EOF(F) do
  	begin
    	readln(F , tmpStr);
     if Length(tmpStr) > 76 then
      	begin
		      PosBeg := 1;
    		  PosEnd := Pos('%' , tmpStr);
		      while true do
    		    begin
        			analStr := Copy(tmpStr , PosBeg , PosEnd);
				      if Length(analStr) > 76 then
      					begin
				         SetLength(fArrLogBilbo , Length(fArrLogBilbo) + 1);
                  ind := Length(fArrLogBilbo) - 1;
                  fArrLogBilbo[ind].FileNAme := Trim(Copy(analStr , 1 , 26));
                  try
                  	fArrLogBilbo[ind].sizeSended := StrToInt(Trim(Copy(analStr , 28 , 11)));
                  except
                  	on E : Exception do
                     	begin
                        if Assigned(fLog) then fLog.Write('Error Convert Size. file - ' + sr.Name + '. i - ' + IntToStr(i) + '. src Str - ' + Copy(analStr , 28 , 11));
                        fArrLogBilbo[ind].sizeSended := UNREALINTEGER;
                       end;
                  end;
                  try
                  	fArrLogBilbo[ind].speed := StrToFloat(Trim(Copy(analStr , 44 , 6)));
                  except
                  	on E : Exception do
                     	begin
                        if Assigned(fLog) then fLog.Write('Error Convert Speed. file - ' + sr.Name + '. i - ' + IntToStr(i) + '. src Str - ' + Copy(analStr , 44 , 6));
                       	fArrLogBilbo[ind].speed := UNREALDOUBLE;
                       end;
                  end;
                  try
                  	fArrLogBilbo[ind].eta := StrToDateTime(Trim(Copy(analStr , 63 , 8)));
                  except
                  	on E : Exception do
                     	begin
                        if Assigned(fLog) then fLog.Write('Error Convert ETA. file - ' + sr.Name + '. i - ' + IntToStr(i) + '. src Str - ' + Copy(analStr , 63 , 8));
                        fArrLogBilbo[ind].eta := UNREALDATE;
                       end;
                  end;
                  try
                  	fArrLogBilbo[ind].progress := StrToInt(Trim(Copy(analStr , 73 , 4)));
                  except
                  	on E : Exception do
                     	begin
                        if Assigned(fLog) then fLog.Write('Error Convert Size. file - ' + sr.Name + '. i - ' + IntToStr(i) + '. src Str - ' + Copy(analStr , 73 , 4));
                        fArrLogBilbo[ind].progress := UNREALINTEGER;
                       end;
                  end;
    		    		end  // if len analStr
              else
              	begin
                	exit;
                end;
              tmpStr := Copy(tmpStr , PosEnd + 1);
              if Length(tmpStr) < 77 then
              	begin
                 exit;
                end;
              PosEnd := Pos('%' , tmpStr);
        		end; // while true
        end;
    end;
  CloseFile(F);
end;

procedure TThCopyBilbo.fDefLogName;
var
	FilNam : String;
  cnt : Integer;
  sCnt : String;
begin
	FilNam := '';
  if not DirectoryExists(fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo) then
    begin
    	if not ForceDirectories(fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo) then
      	begin
if Assigned(fLog) then fLog.Write('Not create directiry - ' + fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo);

        end;
    end
  else
  	begin
if Assigned(fLog) then fLog.Write('directory EXISTS - ' + fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo);
    end;
if Assigned(fLog) then fLog.Write('Curr Fule NAme - ' + ExtractFileName(fCurrFileName));

	fLogName := fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo + '\' + Copy(fCurrFileName , 1 , Pos('.' , fCurrFileName) - 1) + '_000.txt';
  cnt := 0;
  while true do
  	begin
      if not FileExists(fLogName) then
      	begin
        	exit;
        end
      else
      	begin
          Inc(cnt);
          if cnt > 999 then
          	begin
							fLogName := fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo + '\' + Copy(fCurrFileName , 1 , Pos('.' , fCurrFileName) - 1) + '_000.txt';
              exit;
            end
	        else
          	begin
            	if cnt < 10  then
                	sCnt := '00' + IntToStr(cnt)
              else
                  if cnt < 99 then
                  	sCnt := '0' + IntToStr(cnt)
                  else
                  	sCnt := IntToStr(cnt);
            end;
        end;
      fLogName := fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirLogBilbo + '\' + Copy(fCurrFileName , 1 , Pos('.' , fCurrFileName) - 1) + '_' + sCnt + '.txt';
  	end;
end;

procedure TThCopyBilbo.fDefNameDest;
begin
if Assigned(fLog) then fLog.Write('Address - ' + fAddress + '. End');

	fNameDest := fUser + '@' + fAddress + ':' + fRootDir + '/' + fUser + fSubDir + '/' + fFUIBDir ;
end;

procedure TThCopyBilbo.fDefNameSource;
begin
	fNameSource := fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirSendBilbo + '\' + fCurrFileName;
end;

procedure TThCopyBilbo.fDefParam1;
begin
	fCmdParam1 := 'open';
end;

procedure TThCopyBilbo.fDefParam2;
begin
	fCmdParam2 := fProgName;
end;

procedure TThCopyBilbo.fDefParam3;
var
	tmpStr : String;
begin
	tmpStr := '';
  fDefNameSource;
  fDefNameDest;
  fDefLogName;
  fCmdParam3 := ' ' + fPassword + ' "' + fNameSource + '" ' + fUser + ' ' + fAddress + ' ' + fRootDir + ' ' + fSubDir + ' ' + fFUIBDir + ' ' + fLogName;
end;

procedure TThCopyBilbo.fDefParam4;
begin
	fCmdParam4 := '';
end;

procedure TThCopyBilbo.fInsertSQL;
var
i : Integer;
begin
	fProc1.ProcedureName := 'insert_LogBilbo';
  if Length(fArrLogBilbo) > 0 then
  	begin
    	for i := 0 to Length(fArrLogBilbo) - 1 do
      	begin
          fProc1.Parameters.Clear;
          fProc1.Parameters.CreateParameter('@atmNumber' 	, ftString 		, pdInput 	, 10 	, fATM												);
          fProc1.Parameters.CreateParameter('@filename'   , ftString    , pdInput 	,100  , fArrLogBilbo[i].FileNAme    );
          fProc1.Parameters.CreateParameter('@sizeSended' , ftInteger   , pdInput 	,  4  , fArrLogBilbo[i].sizeSended  );
          fProc1.Parameters.CreateParameter('@speed'      , ftFloat     , pdInput 	, 15 	, fArrLogBilbo[i].speed       );
          fProc1.Parameters.CreateParameter('@eta'        , ftDateTime  , pdInput 	,  8  , fArrLogBilbo[i].eta         );
          fProc1.Parameters.CreateParameter('@progress'   , ftInteger   , pdInput 	,  4  , fArrLogBilbo[i].progress    );
          fProc1.Parameters.CreateParameter('@logfilename', ftString		, pdInput 	,255	, fLogName						    );
	   	   	fProc1.Parameters.CreateParameter('@err'        , ftInteger 	, pdOutput 	, 4 	, 0);
	      	fProc1.Parameters.CreateParameter('@Mess'       , ftString  	, pdOutput 	, 100 , 0 );
					try
		      	fProc1.ExecProc ;
         except
         	on E : Exception do
if Assigned(fLog) then fLog.Write('Exception exec proc. ' + E.Message + '. ' + E.ClassName ) ;
         end;
if Assigned(fLog) then fLog.Write('After ExecProc. i = ' + IntToStr(i) + '. err - ' + IntToStr(fProc1.Parameters.ParamByName('@err').Value) + '. Mess - ' + fProc1.Parameters.ParamByName('@Mess').Value) ;
        end;
    end;
end;

function TThCopyBilbo.fSaveLog: boolean;
var
retVal : boolean;
begin
	retVal := false;
  fDefLogBilbo;
  if Length(fArrLogBilbo) > 0 then
  	begin
		  fConnectSQL;
		  if fConn.Connected  then
  			begin
		    	fInsertSQL;
    		end;
    	if not fAnalizLog then
      	begin
        end
    	else
      	begin
        	retVal := true;
        end;
    end
	else
  	begin
if Assigned(fLog) then fLog.Write('Length Log file BILBO = 0');
    end;
	Result := retVal;
end;

function TThCopyBilbo.fRenMov(FilName: String): boolean;
var
 Fo : TSHFileOpStruct;
 pbuffer : array [0..4096] of char;
 dbuffer : array [0..4096] of char;
 p : pchar;
 d : pchar;
 fromDir : String;
 fromFullName : String;
backDir : String;
destFil : String;
begin
	backDir := fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirBackBilbo;
	fromDir := fRootDirBilbo + '\' + fDirArchBilbo + '\' + fFUIBDir + '\' + fDirSendBilbo;
  	if not DirectoryExists(backDir) then
  		if not ForceDirectories(backDir) then
    		begin
if Assigned(fLog) then fLog.Write('Not Create Directory ' + backDir);
        		exit;
      	end;

	fromFullName	:= fromDir + '\' + FilName;
	destFil := backDir + '\' +  FilName;

///////////////////////////////////////////////////////

 FillChar(pBuffer, sizeof(pBuffer), #0);
 FillChar(dBuffer, sizeof(dBuffer), #0);
 p := @pbuffer;
 d := @dbuffer;

 //Начали подключение файлов, предназначенных для копирования
 p := StrPCopy(p, fromFullNAme) + 1;
 d := StrPCopy(d, backDir) + 1;
 FillChar(Fo, sizeof(Fo), #0);
 Fo.Wnd := Handle;
// Fo.wFunc := FO_COPY; //Действие
 Fo.wFunc := FO_MOVE; //Действие
 Fo.pFrom := @pBuffer; //Источник
 Fo.pTo := @dBuffer; //Назначение - показываем куда копируем
 Fo.fFlags := 0;
 Fo.fFlags := FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR or FOF_NOERRORUI  or FOF_SILENT;
 if ((SHFileOperation(Fo) <> 0) or (Fo.fAnyOperationsAborted <> false)) then
 	begin
if Assigned(fLog) then fLog.Write('Error Move file');
   end
	else
   	begin
if Assigned(fLog) then fLog.Write('SUCCESS Move file');
      end;
end;


procedure TThCopyBilbo.fConnectSQL;
begin
if Assigned(fLog) then fLog.Write('In Connect SQL') ;
	try
		fConn.Connected := true;
   except
   	on E : Exception do
if Assigned(fLog) then fLog.Write('Error Connect to SQL server. ' + E.Message + '. ' + E.ClassName ) ;
   end;
end;

procedure TThCopyBilbo.Terminate;
begin

inherited;
end;

end.
