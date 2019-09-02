unit clThreadParseReceipt1;

interface
uses
Windows, SysUtils, Variants, Classes, ShellAPI , clLogAcceptor1, clParseReceipt1,
// ztvregister, ztvBase, ztvUnRar, ztvGbls,
ActiveX , comObj;

type
	TThParseReceipt = class(TThread)
   private
   	fLog : TLogAcceptor;
      fRootDir		: String;
      fWorkDir 		: String;
      fMaskName 	: String;
      fMaskDir		: String;
      fATMName		: String;
      fTag 				: Integer;
      fParse 			: TParseReceipt;
      fArrLists		: TStringlist;
      fUnPackDir 	: String;
      fTextToMemo	: String;
      fDestFile		: String;

      fMaskWork		: DWORD;

      fArrFileSize 						: array of WORD;
      fCurrFileNameRcpt				: String	;
      fCurrCountRcpt			 		: Integer	;
      fAllCountRcpt					: Integer	;
      fCurrFileSizeRcpt				: Word		;
      fAllFileSizeRcpt		 	 	: WORD		;
      fCurrSizeReceivedRcpt		: WORD		;
      fAllSizeReceivedRcpt 		: WORD		;


      procedure fUnArcFile(NameFile : String);
      procedure fCreateLists;
      function  fDefATMDir : String;
      procedure fWorkFile(NameFile : String);
      procedure fAddToMemo;
      procedure fParseReceipt;
      function  fRenMov(FilName : String) : boolean;
      procedure fOnPharseWorkRcpt(Sender : TObject ; AWorkCount : Cardinal);
   public
      Constructor Create(CreateSuspended : boolean ; isLog : boolean ; Atm : String);
      Destructor Destroy; override;

      procedure Execute; override;
      procedure Terminate;

      property Tag : Integer read fTag  write fTag;
      property RootDir : String read fRootDir write fRootDir;
      property MaskName : String read fMaskName write fMaskName;
      property MaskDir : String read fMaskDir write fMaskDir;
      property ATMName	: String read fATMName write fATMName;
      property MaskWork					: DWORD			read 		fMaskWork				write fMaskWork;

      property CurrFileNameRcpt		 	: String	 read fCurrFileNameRcpt		 	write fCurrFileNameRcpt			;
      property CurrCountRcpt				: Integer	 read fCurrCountRcpt				write fCurrCountRcpt				;
      property AllCountRcpt				 	: Integer	 read fAllCountRcpt				 	write fAllCountRcpt					;
      property CurrFileSizeRcpt		 	: Word		 read fCurrFileSizeRcpt		 	write fCurrFileSizeRcpt			;
      property AllFileSizeRcpt			: WORD		 read fAllFileSizeRcpt			write fAllFileSizeRcpt			;
      property CurrSizeReceivedRcpt : WORD		 read fCurrSizeReceivedRcpt write fCurrSizeReceivedRcpt ;
      property AllSizeReceivedRcpt  : WORD		 read fAllSizeReceivedRcpt  write fAllSizeReceivedRcpt 	;


   end;


implementation
uses
	frmParsing1;

constructor TThParseReceipt.Create(CreateSuspended, isLog: boolean ; Atm : String);
begin
  inherited Create(CreateSuspended);
  if isLog then fLog := TLogAcceptor.Create('ThParseReceipt_' + Atm, frmParsing.fGlobalParams.Values['LocalDir']);
  if Assigned(fLog) then fLog.Write('Class Thread ParseReceipt Create');
  fArrLists := TStringList.Create;
  fAtmName := Atm;
  fParse := TParseReceipt.Create(true , fATMName);
  fParse.OnWorkRcpt := fOnPharseWorkRcpt;
end;

destructor TThParseReceipt.Destroy;
begin
   if Assigned(fArrLists) then fArrLists.Free ;
	if Assigned(fParse) then fParse.Free;

	if Assigned(fLog) then fLog.Free;
  inherited;
end;

procedure TThParseReceipt.Execute;
var
i : Integer;
begin
  inherited;
  if ((fMaskWork and frmParsing1.MASKPARSERCPT) <> 0 ) then
  	begin
			CoInitialize(nil);
			if Assigned(fLog) then fLog.Write('In Execute');
			SetLength(fArrFileSize,0);
			fCurrFileNameRcpt			:= '';
			fCurrCountRcpt				:= 0	;
			fAllCountRcpt					:= 0	;
			fCurrFileSizeRcpt			:= 0	;
			fAllFileSizeRcpt			:= 0	;
			fCurrSizeReceivedRcpt	:= 0	;
			fAllSizeReceivedRcpt 	:= 0	;

		  fCreateLists;
		  if fArrLists.Count > 0 then
  			begin
//					PostMessage(frmParsing.AppHndl , WM_PHARSERCPT , 2 , fTag);
					for i := 0 to fArrLists.Count - 1 do
      			begin
              fCurrFileNameRcpt := fArrLists.Strings[i];
              fCurrFileSizeRcpt := fArrFileSize[i];
//							PostMessage(frmParsing.AppHndl , WM_PHARSERCPT , 4 , fTag);
							if Assigned(fLog) then fLog.Write('i - ' + IntToStr(i) + '. ' + fArrLists.Strings [i]) ;
//              PostMessage(frmParsing.AppHndl , WM_PHARSERCPT , 0 , fTag);
	            fWorkFile(fArrLists.Strings[i]);
              Inc(fCurrCountRcpt);
//							PostMessage(frmParsing.AppHndl , WM_PHARSERCPT , 4 , fTag);
  	       end;
   			end
   		else
   			begin
					if Assigned(fLog) then fLog.Write('No files in Directory');
      	end;
			CoUninitialize();
//      PostMessage(frmParsing.AppHndl , WM_PHARSERCPT , 0 , fTag);
    end
	else
  	begin
//			PostMessage(frmParsing.AppHndl , WM_PHARSERCPT , 1 , fTag);
    end;

end;

procedure TThParseReceipt.fAddToMemo;
begin
//   frmParsing1.frmParsing.M2.Lines.Add(fTextToMemo);
end;

procedure TThParseReceipt.fCreateLists;
var
sr : TsearchRec;
tmpMask : String;
begin
	fArrLists.Clear;
   fWorkDir := fDefATMDir;
   if Length(fWorkDir) <> 0 then
   begin
   	tmpMask := fWorkDir + fMaskName;
if Assigned(fLog) then fLog.Write(tmpMask);
		if FindFirst(tmpMask , faHidden + faSysFile + faArchive , sr) = 0 then
			begin
		  		repeat
if Assigned(fLog) then fLog.Write(sr.Name ) ;
						if ((Ord(sr.Name[2]) > $2F) and (Ord(sr.Name[2]) < $3A) and
            			(Ord(sr.Name[2]) > $2F) and (Ord(sr.Name[2]) < $3A)) then
               fArrLists.Add(fWorkDir + sr.Name );
               SetLength(fArrFileSize , Length(fArrFileSize) + 1);
               fArrFileSize[Length(fArrFileSize) -1] := sr.Size;
               fAllFileSizeRcpt := fAllFileSizeRcpt + sr.Size;
               Inc(fAllCountRcpt);
				until FindNext(sr) <> 0;
				FindClose(sr);
			end;
   end;
end;

function TThParseReceipt.fDefATMDir : String;
var
sr : TSearchRec;
tmpName : String;
tmpMask : String;
retVal : String;
begin
retVAl := '';
if Assigned(fLog) then fLog.Write('In DefATM Dir');
   if StrToInt(fATMName) < 10 then
      begin
      	tmpName := '00' + fATMName;
      end
   else
   	begin
      	if StrToInt(fATMName) < 100 then
         	begin
	         	tmpName := '0' + fATMName;
            end
         else
            begin
             tmpName := fATMName;
            end;
      end;
	tmpMask := fRootDir + '\' + tmpName + fMaskDir;
if Assigned(fLog) then fLog.Write(tmpMask);
	if FindFirst(tmpMask , faDirectory , sr) = 0 then
   	begin
			if Assigned(fLog) then fLog.Write(sr.Name) ;
         retVal := fRootDir + '\' + sr.Name + '\';
         FindClose(sr);
      end
   else
      FindClose(sr);
Result := retVal;
end;

procedure TThParseReceipt.fOnPharseWorkRcpt(Sender: TObject; AWorkCount: Cardinal);
begin
	fCurrSizeReceivedRcpt := fCurrSizeReceivedRcpt + AWorkCount;
  fAllSizeReceivedRcpt		:= fAllSizeReceivedRcpt + AWorkCount;
	SendMessage(frmParsing.AppHndl , WM_PHARSERCPT , 4 , fTag);
end;

procedure TThParseReceipt.fParseReceipt;
begin
 fParse.NamFil := fDestFile;
 fParse.CheckOpenATM := true;
 fParse.CheckCloseATM := true;
 fParse.CheckPresentCash := true;
 fParse.Start;

end;

function TThParseReceipt.fRenMov(FilName: String): boolean;
var
 Fo : TSHFileOpStruct; 
 pbuffer : array [0..4096] of char;
 dbuffer : array [0..4096] of char;
 p : pchar;
 d : pchar;
tmpDir : String;
destFil : String;
begin
	tmpDir := fWorkDir + frmParsing.fGlobalParams.Values['DirSaveArchive'];
  	if not DirectoryExists(tmpDir) then
  		if not ForceDirectories(tmpDir) then
    		begin
if Assigned(fLog) then fLog.Write('Not Create Directory ' + tmpDir);
        		exit;
      	end;
	destFil := tmpDir + '\' +  ExtractFileName(FilName);

///////////////////////////////////////////////////////

 FillChar(pBuffer, sizeof(pBuffer), #0);
 FillChar(dBuffer, sizeof(dBuffer), #0);
 p := @pbuffer;
 d := @dbuffer;

 //Начали подключение файлов, предназначенных для копирования
 p := StrPCopy(p, FilName) + 1;
 d := StrPCopy(d, tmpDir) + 1;
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




/// ///////////////////////////////////////////////////


end;

procedure TThParseReceipt.fUnArcFile(NameFile: String);
var
Param1 , Param2, Param3, Param4 : String;
fPath , fName , fExt : String;
sr : TSearchrec;
currTick : DWord;
MaxTick : DWord;
retVal : Integer;
begin
MaxTick := 10000;
if Assigned(fLog) then fLog.Write('In Arch File. Name - ' + NameFile);
   fUnPackDir := fWorkDir + 'UnPack';

  if not DirectoryExists(fUnPackDir) then
  	if not ForceDirectories(fUnPackDir) then
    	begin
if Assigned(fLog) then fLog.Write('Not Create Directory ' + fUnPackDir);
        exit;
      end;

	fName := ExtractFileName(NameFile);
	fExt := ExtractFileExt(NameFile);
  	fName := Copy(fName , 1 , Pos(fExt , fName) - 1);
	fPath := fUnPackDir + '\';
	fDestFile := fPath + fName;
   if FileExists(fDestFile) then
   	begin
       if not DeleteFile(fDestFile) then
       	begin
if Assigned(fLog) then fLog.Write('Error delete previos FIle. ' + fDestFile);
         	exit;
         end
      	else
            begin
if Assigned(fLog) then fLog.Write('Successfuly delete file. ' + fDestFile);
            end;
      end;
	Param1 := 'open';
  Param2 := 'rar.exe';
//  Param3 := 'm -y -inul -ep' + ' "' + fPath + fName + '.rar' + '" ' + NameFile ;
  Param3 := 'x -y -inul -ep' + ' "' + NameFile + '" ' + '"' + fPath + '"';
if Assigned(fLog) then fLog.Write(Param3);

  Param4 := '';
	retVal := ShellExecute(0 , PChar(Param1) , PChar(Param2) , PChar(Param3) , PChar(Param4) , SW_HIDE);
fTextToMemo := 'Unpack retVal - ' + IntToStr(retVAl) + '. File - ' + fDestFile;
// Synchronize(fAddToMemo);
fTextToMemo := '';
   if retVal < 32 then
   	begin
if Assigned (fLog) then fLog.Write('Error Execute Shell - ' + NameFile);
         exit;
      end;
   currTick := GetTickCount;
   while true do
   	begin
      	if FileExists(fDestFile) then
         	begin
if Assigned (fLog) then fLog.Write('File exists - ' + fDestFile);
            	exit;
            end;
         if GetTickCount > currtick + MaxTick then
         	begin
					if Assigned (fLog) then fLog.Write('Error. No Such file - ' + fPath + fName);
               fDestFile := '';
               exit
            end;
         sleep(150);
      end;
end;


procedure TThParseReceipt.fWorkFile(NameFile: String);
var
tmpName , tmpExt : String;
begin
if Assigned(fLog) then fLog.Write('fWorkFile. ' + ExtractFileName(NameFile)) ;
tmpName := ExtractFileName(NameFile);
tmpExt := ExtractFileExt(NameFile);
fDestFile := ''; // Copy(tmpName , 1 , Pos(tmpExt , tmpName) - 1);
if UPPERCASE(ExtractFileExt(NameFile)) = UPPERCASE('.rar') then
   begin
//      fUnRarFile(NameFile);
      fUnArcFile(NameFile);
      if Length(fDestFile) > 0 then
      	begin
if Assigned(fLog) then fLog.Write('fWorkFile. ' + fDestFile);
      	sleep(250);
          fParseReceipt;
          if fParse.SuccessParse  then
            if not DeleteFile(fDestFile) then
            	begin
if Assigned(fLog) then fLog.Write('Cannot delete file - ' + fDestFile + ' after parsing');
               	exit;
               end
         	else
            	begin
                  fRenMov(NameFile);
               end;
          
         end;
   end;

end;


procedure TThParseReceipt.Terminate;
begin
inherited;
end;


end.
