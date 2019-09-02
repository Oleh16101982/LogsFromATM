unit clThFTP;

interface
uses
	Windows, SysUtils, Classes, DateUtils, Variants, ShellAPI,
	IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdAllFTPListParsers,
  IdExplicitTLSClientServerBase, IdFTP, IdThread, IdFTPCommon, IdFTPList, IdReplyRFC, IdStack,
  clLogAcceptor1;
const
	JRNFILES = 1;
  RCPTFILES = 2;
  ALLFILES = 0;
type
	TrecFTPFileInfo = record
   Name : String;
   Date : TDateTime;
   Size : DWORD;

  end;

type
TThFTP = class(TThread)
private
	fLog							: TLogAcceptor;
	fFTP							: TIdFTP;
  fNumber						: String;
  fFUIB							: String;
  fTag							: Integer;
  fAddress 					: String;
  fPort							: Integer;
  fUser							: String;
  fPassword					: String;
	fTransferTimeout	: Integer;
  fReadTimeout			: Integer;
  fRemoteDir				: String;
  fRemoteDirArch		: String;
  fLocalDir					: String;
  fLastDate					: TDateTime;
	fFileList 				: TIdFTPListItems;
  fMaxCountFile			: Integer;
  fIsDelRemote			: boolean;
  fIsArc						: boolean;
  fIsNotArc 				: boolean;
  fEnabled 					: boolean;

  fCurrFileFTP						: String	;

  fAllCountFileFTP		: Integer	;
  fCurrCountFileFTP		: Integer	;
  fCurrSizeFileFTP		: DWORD		;
  fCurrReceiveFileFTP	: DWORD		;
  fAllSizeFileFTP			: DWORD		;
  fAllReceiveFileFTP	: DWORD		;



  fCountRcv	: Integer;
  fMsg : String;

  fMaskWork			: DWORD;

  fArrFTPFileInfo		: array of TrecFTPFileInfo;
  fArrFile					: TStringList;
  fFNameOrg					: String;
  fFNameArc					: String;
  fFNameDest				: String;
  fFNameDestArc			: String;
  fLocalTarget			: String;
  fDirArcBilbo			: String;
  fDirSendBilbo			: String;
  fDirBackBilbo			: String;

  fMode							: Integer; // 1 - journal 2 - receipt 10 - other

  procedure fSyncMsg			;
  procedure fSyncMsgStatus;
  procedure fSyncMsgWork	;
  procedure fSyncMsgCount	;
  procedure fSyncMsgFiles	;
  procedure fSyncMsgLastCopy;

  procedure fDefLocalDir;
  procedure fDefFileName(fDate : TDateTime);
//	function 	fIsFileExists : boolean;
	procedure fCopyFile(Name: String; dat: TDateTime; Size: Int64);
//  procedure fListFile;
  function fChangeDir(WorkDir : String) : boolean;
  function fDeleteFile(Name : String ; dat : TDateTime) : boolean;
  function fIsNeedCopy(Name : String ; dat : TDateTime ; Size : Int64): boolean;
  procedure fDefFTPFileInfo(mode : Integer);
  procedure fArcFile(Name : String);
  function fCopyBilbo(Name : String ; dat : TDateTime ; Size : Int64): boolean;
  function fCopyMov(mode : Integer ; FilName : String ; DestDir : STring) : boolean;
	procedure fUnArcFileBilbo(NameFile: String ; Sourse : String ; DestDir : String);

  procedure fOnAfterClientLogin(Sender : TObject);
  procedure fOnAfterGet(ASender: TObject; VStream: TStream);
  procedure fOnDisconnected(Sender: TObject);
//  procedure fOnWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Integer);
  procedure fOnWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
//  procedure fOnWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Integer);
  procedure fOnWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
  procedure fOnWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
  procedure fOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
public
	constructor Create(ACreateSuspended: Boolean ; Name : String);
  destructor Destroy; override;
  procedure Execute; override;
  procedure Terminate;
  procedure InitFTP;

  property Tag : Integer read fTag write fTag;
  property Number						: String	read fNumber		write fNumber;
  property FUIB							: String	read fFUIB			write fFUIB;
  property Address 					: String 	read fAddress 	write fAddress;
  property Port							: Integer read fPort	 		write fPort;
  property User							: String 	read fUser			write fUser;
  property Password					: String 	read fPassword	write fPassword;
  property ReadTimeout			: Integer read fReadTimeout		write fReadTimeout;
  property TransferTimeout	: Integer read fTransferTimeout		write fTransferTimeout;
  property RemoteDir			 	: String 		read		fRemoteDir			write  fRemoteDir;
  property RemoteDirArch   	: String 		read    fRemoteDirArch 	write  fRemoteDirArch;
  property LocalDir        	: String 		read    fLocalDir      	write  fLocalDir;
  property MaxCountFile			: Integer		read 		fMaxCountFile		write fMaxCountFile;
  property IsDelRemote			: boolean		read 		fIsDelRemote		write fIsDelRemote;
  property LastDate					: TDateTime	read 		fLastDate 			write fLastDate;
  property Enabled					: boolean 	read 		fEnabled				write fEnabled;
  property MaskWork					: DWORD			read 		fMaskWork				write fMaskWork;
  property CurrFileFTP			: String		read 		fCurrFileFTP		write fCurrFileFTP;

  property AllCountFileFTP		: Integer	 	read fAllCountFileFTP				write fAllCountFileFTP				;
  property CurrCountFileFTP		: Integer		read fCurrCountFileFTP			write fCurrCountFileFTP			;
  property CurrSizeFileFTP		: DWORD		 	read fCurrSizeFileFTP				write fCurrSizeFileFTP				;
  property CurrReceiveFileFTP	: DWORD			read fCurrReceiveFileFTP		write fCurrReceiveFileFTP		;
  property AllSizeFileFTP			: DWORD			read fAllSizeFileFTP				write fAllSizeFileFTP				;
  property AllReceiveFileFTP	: DWORD		 	read fAllReceiveFileFTP			write fAllReceiveFileFTP			;

end;

implementation
 uses
 	frmParsing1;
{ TThFTP }



constructor TThFTP.Create(ACreateSuspended : boolean ; Name: string);
begin
  inherited Create(ACreateSuspended);
  fLog := TLogAcceptor.Create(Name , frmParsing.fGlobalParams.Values['LocalDir']);
  fFTP := TIdFTP.Create(nil);
  fFTP.OnAfterClientLogin := fOnAfterClientLogin;
  fFTP.OnAfterGet         := fOnAfterGet;
  fFTP.OnDisconnected     := fOnDisconnected;
  fFTP.OnWork             := fOnWork;
  fFTP.OnWorkBegin        := fOnWorkBegin;
  fFTP.OnWorkEnd          := fOnWorkEnd;
  fFTP.OnStatus           := fOnStatus;


  fNumber := Name;
  fArrFile := TStringList.Create;
end;

destructor TThFTP.Destroy;
begin
	if Assigned(fFTP) then fFTP.Free;
  if Assigned(fLog) then fLog.Free;
  if Assigned(fArrFile) then fArrFile.Free;  
  inherited;
end;

procedure TThFTP.fArcFile(Name: String);
var
Param1 , Param2, Param3, Param4 : String;
fPath , fName , fExt : String;
retVal : Integer;
begin
fLog.Write('In Arch File. Name - ' + Name);

	fName := ExtractFileName(Name);
  fExt := ExtractFileExt(Name);
  fName := Copy(fName , 1 , Pos(fExt , fName) - 1);
  fPath := ExtractFilePath(Name);
fLog.Write('In Arch File. fName - ' + fPath + fName + '.rar');
	Param1 := 'open';
  Param2 := 'rar.exe';
  Param3 := 'm -y -inul -ep' + ' "' + fPath + fName + '.rar' + '" ' + Name ;
  Param4 := '';
	retVal := ShellExecute(0 , PChar(Param1) , PChar(Param2) , PChar(Param3) , PChar(Param4) , SW_HIDE);

end;

function TThFTP.fChangeDir(WorkDir: String) : boolean;
var
	prevMode : Integer;
begin
// fLog.Write('Change Dir. ' + WorkDir);
	prevMode := fMode;
  fMode := 0;
	Result := true;
  try
		try
  	  fFTP.ChangeDir(WorkDir);
	  except
  		on E : EIdSocketError do
    									begin
                      	if Assigned(fLog) then fLog.Write('EIdSocketError. ' + E.Message + '. ' + IntToStr(E.LastError));
                        SendMessage(frmParsing.AppHndl , WM_SOCKETERROR 			, E.LastError , fTag);
//                        fMsg := E.Message;
//                        Synchronize(fSyncMsg);
//                        Synchronize(fSyncMsgStatus);
                        	Result := false;
                      end;

  		on e : Exception do
    									begin
                      	if Assigned(fLog) then fLog.Write(E.ClassName + '. ' + E.Message);
                        fMsg :=  'Change Dir. ' + E.Message;
//                        Synchronize(fSyncMsg);
                        fMsg := E.Message;
//                        Synchronize(fSyncMsgStatus);
                        Result := false;
                      end;
  	end;
  finally
    fMode := prevMode;
  end;
end;

function TThFTP.fCopyBilbo(Name : String ; dat : TDateTime ; Size : Int64): boolean;
var
srs , srd : TSearchRec;
retVal : boolean;
FullDirArc , FullDirSend , FullDirBack : String;
begin
if Assigned(fLog)  then fLog.Write('In Copy BILBO');

fDirArcBilbo			:= frmParsing.fGlobalParams.Values['DirArchForBilbo'];
fDirSendBilbo			:= frmParsing.fGlobalParams.Values['DirSendForBilbo'];
fDirBackBilbo			:= frmParsing.fGlobalParams.Values['DirBackForBilbo'];
FullDirArc 		:= frmParsing.fGlobalParams.Values['LocalDir'] + '\' + fDirArcBilbo + '\' + Copy(fFUIB , 5 , 4);
FullDirSend		:= frmParsing.fGlobalParams.Values['LocalDir'] + '\' + fDirArcBilbo + '\' + Copy(fFUIB , 5 , 4) + '\' + fDirSendBilbo;
FullDirBack		:= frmParsing.fGlobalParams.Values['LocalDir'] + '\' + fDirArcBilbo + '\' + Copy(fFUIB , 5 , 4) + '\' + fDirBackBilbo;

if Not DirectoryExists(FullDirSend) then
	if not ForceDirectories(FullDirSend)  then
  	begin
     exit;
    end;
if Not DirectoryExists(FullDirBack) then
	if not ForceDirectories(FullDirBack)  then
  	begin
     exit;
    end;
// if Assigned(fLog) then fLog.Write('COPYMOV. ' + fLocalTarget + '\' + Name);
if FindFirst(fLocalTarget + '\' + Name , faAnyFile , srs) = 0 then
	begin
  	if FindFirst(FullDirArc , faAnyFile , srd) = 0 then
    	begin
        if not ((srs.Size = srd.Size) and (srs.Time = srd.Time)) then
        	begin
          	if fCopyMov(1 , fLocalTarget +'\' + Name , FullDirArc  + '\') then
            	begin
		            fUnArcFileBilbo(Name , FullDirArc , FullDirSend);
                DeleteFile(FullDirArc + '\' + Name);
              end;
          end;
      end
    else
    	begin
      	if fCopyMov(1 , fLocalTarget +'\' + Name , FullDirArc + '\') then
        	begin
            fUnArcFileBilbo(Name , FullDirArc , FullDirSend);
            DeleteFile(FullDirArc + '\' + Name);
          end;
      end;
  end;
FindClose(srs);
FindClose(srd);
end;

procedure TThFTP.fUnArcFileBilbo(NameFile: String ; Sourse : String ; DestDir : String);
var
Param1 , Param2, Param3, Param4 : String;
fPath , fName , fExt : String;
sr : TSearchrec;
currTick : INteger;
MaxTick : Integer;
DestFile : String;
DestName : String;
retVal : Integer;
begin
MaxTick := 90000;
// if Assigned(fLog) then fLog.Write('In UnArch File. Name - ' + NameFile);
	DestName := Copy(NameFile , 1 , Pos(frmParsing.fGlobalParams.Values['ArchExt']  , NameFile) - 1);
	DestFile := DestDir + '\' + DestName;
   if FileExists(DestFile) then
   	begin
       if not DeleteFile(DestFile) then
       	begin
if Assigned(fLog) then fLog.Write('Error delete previos FIle. ' + DestFile);
         	exit;
         end
      	else
            begin
if Assigned(fLog) then fLog.Write('Successfuly delete file. ' + DestFile);
            end;
      end;
	Param1 := 'open';
  Param2 := frmParsing.fGlobalParams.Values['UnArchPrg'];
//  Param3 := 'm -y -inul -ep' + ' "' + fPath + fName + '.rar' + '" ' + NameFile ;
  Param3 := frmParsing.fGlobalParams.Values['UnArchParam1'] + ' "' + Sourse + '\' + NameFile + '" ' + DestDir;

// if Assigned(fLog) then fLog.Write(Param3);

  Param4 := '';
	retVal := ShellExecute(0 , PChar(Param1) , PChar(Param2) , PChar(Param3) , PChar(Param4) , SW_HIDE);
// if Assigned(fLog) then fLog.Write('Unpack retVal - ' + IntToStr(retVAl) + '. File - ' + DestFile);
// Synchronize(fAddToMemo);
// fTextToMemo := '';
   if retVal < 32 then
   	begin
if Assigned (fLog) then fLog.Write('Error Execute Shell - ' + NameFile);
         exit;
      end;
   currTick := GetTickCount;
   while true do
   	begin
      	if FileExists(DestFile) then
         	begin
if Assigned (fLog) then fLog.Write('File exists - ' + DestFile);
            	exit;
            end;
         if GetTickCount > currtick + MaxTick then
         	begin
					if Assigned (fLog) then fLog.Write('Error. No Such file - ' + fPath + fName);
               DestFile := '';
               exit
            end;
         sleep(150);
      end;
end;


procedure TThFTP.fCopyFile(Name: String; dat: TDateTime; Size: Int64);
var
ErrCode : Integer;
sr : TSearchRec;
begin
fIsArc := false;
fLog.Write('Remote file - ' + Name + '. Local - ' + fLocalTarget +'\' + Name);
    	try
      	fMsg := fFNameArc;
//      	Synchronize(fSyncMsgFiles);
	     fFTP.Get(Name , fLocalTarget +'\' + Name, true , false);
      except
    		on E : EIdSocketError do
    									begin
                      	if Assigned(fLog) then fLog.Write('EIdSocketError. ' + E.Message + '. ' + IntToStr(E.LastError));
                        SendMessage(frmParsing.AppHndl , WM_SOCKETERROR 			, E.LastError , fTag);
//                        fMsg := E.Message;
//                        Synchronize(fSyncMsg);
//                        Synchronize(fSyncMsgStatus);
                      end;
      
      	on E : EIdReplyRFCError do
    									begin
if Assigned(fLog) then                       	fLog.Write(E.ClassName + '. ' + E.Message);
                        fMsg := 'Error get. ' + E.Message + '. code - ' + IntToStr(E.ErrorCode);
//                        Synchronize(fSyncMsg);
                        ErrCode := E.ErrorCode;
                      end;

      	on E : Exception do
    									begin
                      	if Assigned(fLog) then fLog.Write(E.ClassName + '. ' + E.Message);
                        fMsg := 'Error get. ' + E.Message;
//                        Synchronize(fSyncMsg);
                        fMsg := E.Message;
//                        Synchronize(fSyncMsgStatus);
                      end;
      end;
if ErrCode = 550 then
	fIsArc := false;

if not fIsArc then
	begin
  	fMsg := 'Journal File not exsist or can"t open';
//   	Synchronize(fSyncMsg);
  end;
if FindFirst(fLocalTarget + '\' + Name , faAnyFile , sr) = 0 then
	begin
    if sr.Size = Size then
    	begin
	      fIsArc := true;
      end;
  end;
FindClose(sr);
if fIsArc then
	begin
   if fDeleteFile(Name , dat) then
   	begin

    end;
  end;
end;

function TThFTP.fCopyMov(Mode : Integer ; FilName: String ; DestDir : String): boolean;
var
 Fo : TSHFileOpStruct; 
 pbuffer : array [0..4096] of char;
 dbuffer : array [0..4096] of char;
 p : pchar;
 d : pchar;
retVAl : boolean;
begin
retVal := false;


///////////////////////////////////////////////////////

 FillChar(pBuffer, sizeof(pBuffer), #0);
 FillChar(dBuffer, sizeof(dBuffer), #0);
 p := @pbuffer;
 d := @dbuffer;

 //Начали подключение файлов, предназначенных для копирования
// if Assigned(fLog) then fLog.Write(FilName + '. dest - ' + DestDir);

 p := StrPCopy(p, FilName) + 1;
 d := StrPCopy(d, DestDir) + 1;
 FillChar(Fo, sizeof(Fo), #0);
 Fo.Wnd := Handle;
// Fo.wFunc := FO_COPY; //Действие
case Mode of
	1 : Fo.wFunc := FO_COPY;
  2 : Fo.wFunc := FO_MOVE;
  else
  	Fo.wFunc := FO_COPY;
end;
  //Действие
 Fo.pFrom := @pBuffer; //Источник
 Fo.pTo := @dBuffer; //Назначение - показываем куда копируем
 Fo.fFlags := 0;
 Fo.fFlags := FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR or FOF_NOERRORUI  or FOF_SILENT;
 if ((SHFileOperation(Fo) <> 0) or (Fo.fAnyOperationsAborted <> false)) then
 	begin
// if Assigned(fLog) then fLog.Write('Error Copy or Move file');
   end
	else
   	begin
// if Assigned(fLog) then fLog.Write('SUCCESS Copy or Move file');
    	retVal := true;
		end;

Result := retVal;
end;

procedure TThFTP.fDefFileName(fDate : TDateTime);
var
	yy , mm , dd : Word;
	syy , smm , sdd : String;
begin
	DecodeDate(fDate , yy , mm , dd);
  syy := IntToStr(yy);
  if mm < 10 then
  	smm := '0' + IntToStr(mm)
  else
  	smm := IntToStr(mm);

  if dd < 10 then
  	sdd := '0' + IntToStr(dd)
  else
  	sdd := IntToStr(dd);

	fFNameOrg 		:= 	syy + smm + sdd + '.jrn';
	fFNameArc 		:=	syy + smm + sdd + '.jrn.rar';
	fFNameDest 		:= 'ATM' + fFUIB + '_' + Copy(syy , 3 , 2) + smm + sdd + '.jrn';
	fFNameDestArc := 'ATM' + fFUIB + '_' + Copy(syy , 3 , 2) + smm + sdd + '.rar';

end;

procedure TThFTP.fDefFTPFileInfo(mode : Integer);
var
i : Integer;
ListMask : String;
prevMode : Integer;
begin
  if fChangeDir(fRemoteDir) then
  	begin
		  case mode of
  			0 :
		    	begin
    		    ListMask := '*.*';
		      end;
    		1 :
		    	begin
    		  	ListMask := frmParsing.MaskJrn + '.' + frmParsing.ArchExt;
		      end;
    		2 :
		    	begin
    		  	ListMask := frmParsing.MaskRcpt+ '.' + frmParsing.ArchExt;
		      end;
	  	end;
      prevMode := fMode;
      fMode := 0;
      try
		  	try
  		  	fFTP.List(ListMask);
//				if Assigned(fLog) then fLog.Write('After Listing. count - ' + IntToStr(fFTP.DirectoryListing.Count));
//				if Assigned(fLog) then fLog.Write(fFTP.DirectoryListing.DirectoryName);
			    if fFTP.DirectoryListing.Count > 0 then
  			  	begin
    			  	SetLength(fArrFTPFileInfo , fFTP.DirectoryListing.Count);
	    				for i := 0 to fFTP.DirectoryListing.Count - 1 do
  	    				begin
          				fArrFTPFileInfo[i].Name := fFTP.DirectoryListing.Items[i].FileName;
            			fArrFTPFileInfo[i].Date := fFTP.DirectoryListing.Items[i].ModifiedDate;
		            	fArrFTPFileInfo[i].Size := fFTP.DirectoryListing.Items[i].Size;
		  	  	    end;
  		  	  end
	  		  else
  	  			begin
							if Assigned(fLog) then fLog.Write('After Listing. No files in directory');
			      end;
  			except
    			on E : EIdSocketError do
    									begin
                      	if Assigned(fLog) then fLog.Write('EIdSocketError. ' + E.Message + '. ' + IntToStr(E.LastError));
                        SendMessage(frmParsing.AppHndl , WM_SOCKETERROR 			, E.LastError , fTag);
//                        fMsg := E.Message;
//                        Synchronize(fSyncMsg);
//                        Synchronize(fSyncMsgStatus);
                      end;

  				on E : Exception do
		  	  	begin
							if Assigned(fLog) then fLog.Write('Error list command');
			      end;
	  		end;
      finally
      	fMode := prevMode;
      end;
    end
	else
  	begin
			SetLength(fArrFTPFileInfo , 0);    
    end;
end;

procedure TThFTP.fDefLocalDir;
var
sATM : String;
begin
  sATM := Trim(fNumber);
  if Length(sATM) = 1 then
    sATM := '00' + sATM;
  if Length(sATM) = 2 then
    sATM := '0' + sATM;
 if Length(sATM) = 3 then
    sATM := sATM;
 fLocalTarget := frmParsing.fGlobalParams.Values['FTPLocalDir'] + '\' + sATM + '_' + fFUIB;
// if Assigned(fLog) then fLog.Write('fLocalTarget := ' + fLocalTarget);
 if not DirectoryExists(fLocalTarget) then
  if not forceDirectories(fLocalTarget) then
  	begin
if Assigned(fLog) then fLog.Write('Ошибка создания каталога для файла');
   
    end;
 

  
end;

function TThFTP.fDeleteFile(Name: String ; dat : TDateTime): boolean;
var
retVal : boolean;
ErrCode : Integer;
sYY , sMM , sDD , dYY , dMM , dDD : WORD;
prevMode : Integer;
begin
// if Assigned(fLog) then fLog.Write('deleting file - ' + Name);
DecodeDate(dat , sYY , sMM , sDD);
DecodeDate(NOW , dYY , dMM , dDD);

	if ((sYY <> dYY) or (sMM <> dMM) or (sDD <> dDD)) then
    begin
      prevMode := fMode;
      fMode := 0;
    	try
        try
//      	Synchronize(fSyncMsgFiles);
					fFTP.Delete(Name);
		      except
    				on E : EIdSocketError do
    									begin
                      	if Assigned(fLog) then fLog.Write('EIdSocketError. ' + E.Message + '. ' + IntToStr(E.LastError));
                        SendMessage(frmParsing.AppHndl , WM_SOCKETERROR 			, E.LastError , fTag);
//                        fMsg := E.Message;
//                        Synchronize(fSyncMsg);
//                        Synchronize(fSyncMsgStatus);
                      end;

      			on E : EIdReplyRFCError do
    									begin
                      	if Assigned(fLog) then fLog.Write(E.ClassName + '. ' + E.Message);
                        fMsg := 'Error delete. ' + E.Message + '. code - ' + IntToStr(E.ErrorCode);
//                        Synchronize(fSyncMsg);
                        ErrCode := E.ErrorCode;
                      end;

      			on E : Exception do
    									begin
                      	if Assigned(fLog) then fLog.Write(E.ClassName + '. ' + E.Message);
                        fMsg := 'Error delete. ' + E.Message;
//                        Synchronize(fSyncMsg);
                        fMsg := E.Message;
//                        Synchronize(fSyncMsgStatus);
                      end;
      	end;
      finally
       	fMode := prevMode;
      end;
			if ErrCode = 550 then
      	begin
if Assigned(fLog) then fLog.Write('Error code 550 - ' + NAme);
        end;

// if Assigned(fLog) then fLog.Write('Successfully Deleted - ' + Name)
    end
	else
  	begin
if Assigned(fLog) then fLog.Write('Not Delete file (today modified) - ' + Name)
    end;
end;

function TThFTP.fIsNeedCopy(Name: String; dat: TDateTime; Size: Int64): boolean;
var
sr : TSearchRec;
retVAl : boolean;
begin
retVAl := true;
if FindFirst(fLocalTarget + '\' + Name , faAnyFile , sr) = 0 then
	begin
    if sr.Size = Size then
    	retVal := false;
  end;
FindClose(sr);
  Result := retVal;
end;

procedure TThFTP.fOnAfterClientLogin(Sender: TObject);
begin
if Assigned(fLog) then fLog.Write('On After Client Login');
end;

procedure TThFTP.fOnAfterGet(ASender: TObject; VStream: TStream);
begin

end;

procedure TThFTP.fOnDisconnected(Sender: TObject);
begin
	fMsg := '';
//	Synchronize(fSyncMsgFiles);
//  fSyncMsgLastCopy;
	if Assigned(fLog) then fLog.Write('Disconnected FTP link');
  
end;

procedure TThFTP.fOnStatus(ASender: TObject; const AStatus: TIdStatus;  const AStatusText: string);
begin
//	fMsg := AStatusText;
//	Synchronize(fSyncMsgStatus);
//  Synchronize(fSyncMsg);
  if Assigned(fLog) then fLog.Write('On Status - ' + AStatusText);
end;

//procedure TThFTP.fOnWork(ASender: TObject; AWorkMode: TWorkMode;  AWorkCount: Integer);
procedure TThFTP.fOnWork(ASender: TObject; AWorkMode: TWorkMode;  AWorkCount: Int64);
begin
//	fMsg := IntToStr(AWorkCount);
//	Synchronize(fSyncMsgWork);
  if Assigned(fLog) then fLog.Write('On Work. Mode  - ' + IntToStr(fMode) + '. Count - ' + IntToStr(AWorkCount));
  fCurrReceiveFileFTP := fCurrReceiveFileFTP + AWorkCount;
  fAllReceiveFileFTP	:= fAllReceiveFileFTP + AWorkCount;
  case fMode of
  	0 :
    	begin
				if Assigned(fLog) then fLog.Write('Mode 0');
      end;
    1 :
    	begin
				if Assigned(fLog) then fLog.Write('Mode 1');
      	SendMessage(frmParsing.AppHndl , WM_COPYJRN , 4 , fTag);
      end;
    2 :
    	begin
				if Assigned(fLog) then fLog.Write('Mode 2');
				SendMessage(frmParsing.AppHndl , WM_COPYRCPT , 4 , fTag);
      end;
    10 :
    	begin
				if Assigned(fLog) then fLog.Write('Mode 10');
				SendMessage(frmParsing.AppHndl , WM_COPYANOTHER , 4 , fTag);
      end;
    else
    	begin

      end;

  end;
end;

//procedure TThFTP.fOnWorkBegin(ASender: TObject; AWorkMode: TWorkMode;  AWorkCountMax: Integer);
procedure TThFTP.fOnWorkBegin(ASender: TObject; AWorkMode: TWorkMode;  AWorkCountMax: Int64);
begin
	fMsg := 'Begin';
//	Synchronize(fSyncMsgWork);
  if Assigned(fLog) then fLog.Write('On WorkBegin - ' + IntToStr(AWorkCountMax));
end;

procedure TThFTP.fOnWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  if Assigned(fLog) then fLog.Write('End');
//  fMsg := 'End';
//	Synchronize(fSyncMsgWork);
end;

procedure TThFTP.fSyncMsg;
begin
//	Form1.M1.Lines.Add(fMsg);
end;

procedure TThFTP.fSyncMsgCount;
begin
//	Form1.SG1.Cells[7 , fTag] := fMsg;
end;

procedure TThFTP.fSyncMsgFiles;
begin
//	Form1.SG1.Cells[8 , fTag] := fMsg;
end;

procedure TThFTP.fSyncMsgLastCopy;
var
	Sect : String;
begin
	Sect := 'ATM' + IntToStr(fTag);
//  Form1.IniFile.WriteDate(Sect , 'LastDate' , NOW);
end;

procedure TThFTP.fSyncMsgStatus;
begin
//	Form1.SG1.Cells[5 , fTag] := fMsg;
end;

procedure TThFTP.fSyncMsgWork;
begin
//	Form1.SG1.Cells[6 , fTag] := fMsg;
end;

procedure TThFTP.InitFTP;
begin
	fFTP.Port := fPort;
  fFTP.Host := fAddress;
  fFTP.Username := fUser;
  fFTP.Password := fPassword;
  fFTP.Passive := true;
  fFTP.ReadTimeout := fReadTimeout;
  fFTP.TransferTimeout := fTransferTimeout;
  fFTP.TransferType := ftBinary;
  fFTP.AutoLogin := true;
  fFTP.AUTHCmd 					:= tAuto;
	fFTP.OnAfterClientLogin := fOnAfterClientLogin;
  fIsArc := false;
  fIsNotArc := false;
  fCountRcv := 0;
end;

procedure TThFTP.Execute;
var
i : Integer;
MaxCount : Integer;
CurrYY , CurrMM , CurrDD , CurrHH , CurrNN , CurrSS  : WORD;
sCurrYY , sCurrMM , sCurrDD , sCurrHH , sCurrNN , sCurrSS  : String;

FileYY , FileMM , FileDD , FileHH , FileNN , FileSS  : WORD;
sFileYY , sFileMM , sFileDD , sFileHH , sFileNN , sFileSS  : String;  
tmpArrFTPFileInfo		: array of TrecFTPFileInfo;
begin
  inherited;
  fMode := 0;
// if Assigned(fLog) then fLog.Write('Start. ' + fAddress + ' tag - ' + IntToStr(fTag));
  InitFTP;
  fDefLocalDir;
  if (
        	((fMaskWork and frmParsing1.MASKFTPJRN) <> 0 )
        or
        	((fMaskWork and frmParsing1.MASKFTPRCPT) <> 0 )
        or
        	((fMaskWork and frmParsing1.MASKFTPOTHER) <> 0 )
  	) then
		begin
		  try
	  		fFTP.Connect;
		  except
    		on E : EIdSocketError do
    									begin
                      	if Assigned(fLog) then fLog.Write('EIdSocketError. ' + E.Message + '. ' + IntToStr(E.LastError));
                        SendMessage(frmParsing.AppHndl , WM_SOCKETERROR 			, E.LastError , fTag);
//                        fMsg := E.Message;
//                        Synchronize(fSyncMsg);
//                        Synchronize(fSyncMsgStatus);
                      end;

    		on E : Exception do
    									begin
                      	if Assigned(fLog) then fLog.Write(E.ClassName + '. ' + E.Message);
                        fMsg := E.Message;
//                        Synchronize(fSyncMsg);
//                        Synchronize(fSyncMsgStatus);
                      end;
			  end
    end
  else
  	begin
// if Assigned(fLog) then fLog.Write('Not for with FTP about MASKs Work');
      SendMessage(frmParsing.AppHndl , WM_COPYJRN 			, 1 , fTag);
      SendMessage(frmParsing.AppHndl , WM_COPYBILBO 		, 1 , fTag);
      SendMessage(frmParsing.AppHndl , WM_COPYRCPT 			, 1 , fTag);
			SendMessage(frmParsing.AppHndl , WM_COPYANOTHER 	, 1 , fTag);
    end;
  if fFTP.Connected  then
  	begin
if Assigned(fLog) then	    fLog.Write('Connected');
//      fMsg := 'Connect';
//      Synchronize(fSyncMsg);
    end;
  if fFTP.Connected then
  	begin
{
      promDate := fLastDate;
      while true do
      	begin
		    	fDefFileName(promDate);
    		  fCopyFile;
          if FileExists(fLocalDir +'\' + fFNameDest) then
          	begin
             fArcFile(fLocalDir +'\' + fFNameDest);
            end;
          promdate := promdate + 1;
          Inc(fCountRcv);
          fMsg := IntToStr(fCountRcv);
//          Synchronize(fSyncMsgCount);
if Assigned(fLog) then fLog.Write(DateTimeToStr(promDate));
          if promDate > NOW then
            break;
        end;
}
      DecodeDate(NOW , CurrYY , CurrMM , CurrDD);
      sCurrYY := IntToStr(CurrYY);

      if ((fMaskWork and frmParsing1.MASKFTPJRN) <> 0 ) then
      	begin

        	SendMessage(frmParsing.AppHndl , WM_COPYJRN , 2 , fTag);
//          SendMessage(frmParsing.AppHndl , WM_COPYBILBO , 2 , fTag);
					fDefFTPFileInfo(JRNFILES);
    		  if Length(fArrFTPFileInfo) > 0 then
      			begin
            	fMode := 1;
              fCurrFileFTP 				:= '';   // current file name
              fAllCountFileFTP		:= 0;		// +count file for work
              fCurrCountFileFTP		:= 0;		// +count received files
              fCurrSizeFileFTP		:= 0;		// +size current file
              fCurrReceiveFileFTP	:= 0;		// +received bytes of current file
              fAllSizeFileFTP			:= 0;		// +total size files for receive
              fAllReceiveFileFTP	:= 0;		// +total received size

              fAllCountFileFTP := Length(fArrFTPFileInfo);
              for i:= 0 to Length(fArrFTPFileInfo) - 1 do
                begin
                	fAllSizeFileFTP := fAllSizeFileFTP + fArrFTPFileInfo[i].Size;
                end;
		        	for i := 0 to Length(fArrFTPFileInfo) - 1 do
    		      	begin
                	fCurrSizeFileFTP := fArrFTPFileInfo[i].Size;
		            	fCurrFileFTP := fArrFTPFileInfo[i].Name;
    		          fCurrReceiveFileFTP := 0;
									SendMessage(frmParsing.AppHndl , WM_COPYJRN , 3 , fTag);
		    		    	if fIsNeedCopy(fArrFTPFileInfo[i].Name ,  fArrFTPFileInfo[i].Date , fArrFTPFileInfo[i].Size) then
                  	begin
//											if Assigned(fLog) then fLog.Write('Copying - ' + fArrFTPFileInfo[i].Name);
        		   				fCopyFile(fArrFTPFileInfo[i].Name ,  fArrFTPFileInfo[i].Date , fArrFTPFileInfo[i].Size);
					          end
  			        	else
    	  		      	begin
//                    	if Assigned(fLog) then fLog.Write('Copy file Not needed - ' + fArrFTPFileInfo[i].Name);
			              	fAllReceiveFileFTP := fAllReceiveFileFTP + fCurrSizeFileFTP;
      	    	    	  if fDeleteFile(fArrFTPFileInfo[i].Name , fArrFTPFileInfo[i].Date) then
                      	begin

                        end;
		            	  end;

// variant              fAllCurrReceiveFileFTP := fAllCurrReceiveFileFTP + fCurrReceiveFileFTPж
              	Inc(fCurrCountFileFTP);
            		SendMessage(frmParsing.AppHndl , WM_COPYJRN , 3 , fTag);
				      	fCopyBilbo(fArrFTPFileInfo[i].Name ,  fArrFTPFileInfo[i].Date , fArrFTPFileInfo[i].Size);
							end;
						end;
      			SendMessage(frmParsing.AppHndl , WM_COPYJRN , 0 , fTag);
			      SendMessage(frmParsing.AppHndl , WM_COPYBILBO , 0 , fTag);
        end
      else
      	begin
      			SendMessage(frmParsing.AppHndl , WM_COPYJRN , 1 , fTag);
			      SendMessage(frmParsing.AppHndl , WM_COPYBILBO , 1 , fTag);
        end;
    	fMode := 0;
      fCurrFileFTP 						:= '';
      fAllCountFileFTP 					:= 0;
      fCurrCountFileFTP				:= 0;	
      fCurrSizeFileFTP				:= 0;
      fCurrReceiveFileFTP			:= 0;
      fAllSizeFileFTP			:= 0;
      fAllReceiveFileFTP	:= 0;


      if ((fMaskWork and frmParsing1.MASKFTPRCPT) <> 0 ) then
      	begin
		      fFTP.ChangeDirUp;
          SendMessage(frmParsing.AppHndl , WM_COPYRCPT , 2 , fTag);
					fDefFTPFileInfo(RCPTFILES);
		      if Length(fArrFTPFileInfo) > 0 then
    		  	begin
              SetLength(tmpArrFTPFileInfo , 0);
              for i := 0 to Length(fArrFTPFileInfo) - 1 do
              	begin
		              if ((Ord(fArrFTPFileInfo[i].Name[2]) > $2F) and (Ord(fArrFTPFileInfo[i].Name[2]) < $3A) and
				              (Ord(fArrFTPFileInfo[i].Name[2]) > $2F) and (Ord(fArrFTPFileInfo[i].Name[2]) < $3A)) then
                  	begin
                    	SetLength(tmpArrFTPFileInfo , Length(tmpArrFTPFileInfo) + 1);
                      tmpArrFTPFileInfo[Length(tmpArrFTPFileInfo) - 1] := fArrFTPFileInfo[i];
                    end;
                end;
            end;
		      if Length(tmpArrFTPFileInfo) > 0 then
    		  	begin
            	fMode := 2;
            	fCurrFileFTP 						:= '';
              fAllCountFileFTP 				:= 0;
              fCurrCountFileFTP				:= 0;
              fCurrSizeFileFTP				:= 0;
              fCurrReceiveFileFTP			:= 0;
              fAllSizeFileFTP					:= 0;
              fAllReceiveFileFTP			:= 0;
              fAllCountFileFTP := Length(tmpArrFTPFileInfo);
              for i:= 0 to Length(tmpArrFTPFileInfo) - 1 do
                begin
                	fAllSizeFileFTP := fAllSizeFileFTP + fArrFTPFileInfo[i].Size;
                end;

              for i := 0 to Length(tmpArrFTPFileInfo) - 1 do
          			begin
									fCurrSizeFileFTP := tmpArrFTPFileInfo[i].Size;
	                fCurrFileFTP := tmpArrFTPFileInfo[i].Name;
                  fCurrReceiveFileFTP := 0;
                	SendMessage(frmParsing.AppHndl , WM_COPYRCPT , 3 , fTag);
                  if fIsNeedCopy(tmpArrFTPFileInfo[i].Name ,  tmpArrFTPFileInfo[i].Date , tmpArrFTPFileInfo[i].Size) then
                  	begin
//                        	if Assigned(fLog) then fLog.Write('Copying - ' + fArrFTPFileInfo[i].Name);
											fCopyFile(tmpArrFTPFileInfo[i].Name ,  tmpArrFTPFileInfo[i].Date , tmpArrFTPFileInfo[i].Size);
										end
									else
                  	begin
// if Assigned(fLog) then fLog.Write('Copy file Not needed - ' + fArrFTPFileInfo[i].Name);
											fAllReceiveFileFTP := fAllReceiveFileFTP + fCurrSizeFileFTP;
                      if fDeleteFile(tmpArrFTPFileInfo[i].Name , tmpArrFTPFileInfo[i].Date) then
                      	begin

                        end;
										end;
									Inc(fCurrCountFileFTP);
if Assigned(fLog) then fLog.Write('Rcpt currcount - ' + IntToStr(fCurrCountFileFTP));
                  SendMessage(frmParsing.AppHndl , WM_COPYRCPT , 3 , fTag);
            		end;
						end;
					SendMessage(frmParsing.AppHndl , WM_COPYRCPT , 0 , fTag);
        end
      else
      	begin
          SendMessage(frmParsing.AppHndl , WM_COPYRCPT , 1 , fTag);
        end;
        fMode := 0;
        fCurrFileFTP 						:= '';   // current file name
        fAllCountFileFTP 					:= 0;		// +count file for work
        fCurrCountFileFTP				:= 0;		// +count received files
        fCurrSizeFileFTP				:= 0;		// +size current file
        fCurrReceiveFileFTP			:= 0;		// +received bytes of current file
        fAllSizeFileFTP			:= 0;		// +total size files for receive
        fAllReceiveFileFTP	:= 0;		// +total received size

        if ((fMaskWork and frmParsing1.MASKFTPOTHER) <> 0 ) then
        	begin
			      fFTP.ChangeDirUp;
            SendMessage(frmParsing.AppHndl , WM_COPYANOTHER , 2 , fTag);
						fDefFTPFileInfo(ALLFILES);
    	  		MaxCount := StrToInt(Trim(frmParsing.fGlobalParams.Values['MaxCountFiles']));
		      	if Length(fArrFTPFileInfo) > 0 then
    		  		begin
				        fMode := 10;              
              	fCurrFileFTP 						:= '';   // current file name
                fAllCountFileFTP 					:= 0;		// +count file for work
                fCurrCountFileFTP				:= 0;		// +count received files
                fCurrSizeFileFTP				:= 0;		// +size current file
                fCurrReceiveFileFTP			:= 0;		// +received bytes of current file
                fAllSizeFileFTP			:= 0;		// +total size files for receive
                fAllReceiveFileFTP	:= 0;		// +total received size

                if Length(fArrFTPFileInfo) > MaxCount then
	                	fAllCountFileFTP := MaxCount
                else
	                fAllCountFileFTP := Length(fArrFTPFileInfo);

                SetLength(tmpArrFTPFileInfo , fAllCountFileFTP);
                for i  := 0 to Length(tmpArrFTPFileInfo) - 1 do
                	tmpArrFTPFileInfo[i] := fArrFTPFileInfo[i];
                SetLength(fArrFTPFileInfo , Length(tmpArrFTPFileInfo));
                for i := 0 to Length(tmpArrFTPFileInfo) - 1 do
                	fArrFTPFileInfo[i] := tmpArrFTPFileInfo[i];

                for i:= 0 to fAllCountFileFTP - 1 do
  	              begin
    	            	fAllSizeFileFTP := fAllSizeFileFTP + fArrFTPFileInfo[i].Size;
      	          end;

        				for i := 0 to Length(fArrFTPFileInfo) - 1 do
          				begin
                  	fCurrSizeFileFTP := fArrFTPFileInfo[i].Size;
	                  fCurrFileFTP := fArrFTPFileInfo[i].Name;
                    fCurrReceiveFileFTP := 0;
                  	SendMessage(frmParsing.AppHndl , WM_COPYANOTHER , 3 , fTag);
					         	if fIsNeedCopy(fArrFTPFileInfo[i].Name ,  fArrFTPFileInfo[i].Date , fArrFTPFileInfo[i].Size) then
  			  		     		begin
//												if Assigned(fLog) then fLog.Write('Copying - ' + fArrFTPFileInfo[i].Name);
    	  		  		   		fCopyFile(fArrFTPFileInfo[i].Name ,  fArrFTPFileInfo[i].Date , fArrFTPFileInfo[i].Size);
      	    		      	if i >= MaxCount then
        	      		  		begin
//														if Assigned(fLog) then fLog.Write('Exeeded Limit of max count. i - ' + IntToStr(i) + '. MaxCount - ' + IntToStr(MaxCount));
	                  				break;
		  	                	end;
											end
      		    			else
        		    			begin
		                    fAllReceiveFileFTP := fAllReceiveFileFTP + fCurrSizeFileFTP;
//												if Assigned(fLog) then fLog.Write('Copy file Not needed - ' + fArrFTPFileInfo[i].Name);
            	  	   		if fDeleteFile(fArrFTPFileInfo[i].Name , fArrFTPFileInfo[i].Date) then
										   		begin

										    	end;
          	    			end;
// variant              fAllCurrReceiveFileFTP := fAllCurrReceiveFileFTP + fCurrReceiveFileFTPж
										Inc(fCurrCountFileFTP);
                    SendMessage(frmParsing.AppHndl , WM_COPYANOTHER , 3 , fTag);
// if Assigned(fLog) then fLog.Write('fCurrFile - ' + fCurrFileFTP + '. Size - ' + IntToStr(fCurrSizeFileFTP));
// if Assigned(fLog) then fLog.Write('All files - ' + IntToStr(fAllCountFileFTP) + '. CurrCount - ' + IntToStr(fCurrCountFileFTP));
// if Assigned(fLog) then fLog.Write('All Size - ' + IntToStr(fAllSizeFileFTP) + '. Rcvd Size - ' + IntToStr(fAllReceiveFileFTP));
									end;
        			end;
						SendMessage(frmParsing.AppHndl , WM_COPYANOTHER , 1 , fTag);
          end;
    			SendMessage(frmParsing.AppHndl , WM_COPYANOTHER , 0 , fTag);
    end;
	if fFTP.Connected then
  	fFTP.Disconnect;
    fMsg := 'ATM' + fNumber + ' - End work';
//		Synchronize(fSyncMsg);
end;

procedure TThFTP.Terminate;
begin
	if fFTP.Connected  then
  	fFTP.Disconnect;
  if not fFTP.Connected  then
    if Assigned(fLog) then fLog.Write('Disconnect')
  else
  	if Assigned(fLog) then fLog.Write('Not DisConnect');

  inherited;
end;

end.
