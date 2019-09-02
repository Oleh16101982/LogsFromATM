unit clThreadParseJournal1;

interface
uses
Windows, SysUtils, Variants, Classes, ShellAPI , clLogAcceptor1, clParseJournal1,
// ztvregister, ztvBase, ztvUnRar, ztvGbls,
ActiveX , comObj, Messages;


type
	TThParseJournal = class(TThread)
   private
   	fLog : TLogAcceptor;
      fRootDir		: String;
      fWorkDir 	: String;
      fMaskName 	: String;
      fMaskDir		: String;
      fATMName		: String;
      fTag 			: Integer;
      fParse 		: TParseJournal;
      fArrLists	: TStringlist;
      fUnPackDir 	: String;
      fTextToMemo	: String;
      fDestFile	: String;

      fMaskWork	: DWORD;
      fArrFileSize 						: array of WORD;
      fCurrFileNameJrn				: String	;
      fCurrCountJrn						: Integer	;
      fAllCountJrn						: Integer	;
      fCurrFileSizeJrn				: Word		;
      fAllFileSizeJrn				 	: WORD		;
      fCurrSizeReceivedJrn 		: WORD		;
      fAllSizeReceivedJrn 		: WORD		;



      procedure fUnArcFile(NameFile : String);
      procedure fCreateLists;
      function fDefATMDir : String;
      procedure fWorkFile(NameFile : String);
      procedure syncfAddToMemo;
      procedure syncfAddCountJrn;
      procedure syncfAddNameJrn;
      procedure syncfGaugeCntJrn;
      procedure syncfIncProgressCntJrn;
//      procedure syncfGaugeParse;
      procedure fParseJournal;
      function fRenMov(FilName : String) : boolean;

      procedure fOnPharseWorkJrn(Sender : TObject ; AWorkCount : Cardinal);

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

      property CurrFileNameJrn		 	: String	 read fCurrFileNameJrn		 write fCurrFileNameJrn			;
      property CurrCountJrn					: Integer	 read fCurrCountJrn				 write fCurrCountJrn				;
      property AllCountJrn				 	: Integer	 read fAllCountJrn				 write fAllCountJrn					;
      property CurrFileSizeJrn		 	: Word		 read fCurrFileSizeJrn		 write fCurrFileSizeJrn			;
      property AllFileSizeJrn				: WORD		 read fAllFileSizeJrn			 write fAllFileSizeJrn			;
      property CurrSizeReceivedJrn 	: WORD		 read fCurrSizeReceivedJrn write fCurrSizeReceivedJrn ;
      property AllSizeReceivedJrn  	: WORD		 read fAllSizeReceivedJrn  write fAllSizeReceivedJrn 	;


   end;


implementation
uses
	frmParsing1;
{ TThParseJournal }

constructor TThParseJournal.Create(CreateSuspended, isLog: boolean ; Atm : String);
begin
  inherited Create(CreateSuspended);
  if isLog then fLog := TLogAcceptor.Create('ThParseJournal_' + Atm, frmParsing.fGlobalParams.Values['LocalDir']);
  if Assigned(fLog) then fLog.Write('Class Thread ParseJournal Create');
  fArrLists := TStringList.Create;
  fAtmName := Atm;
  fParse := TParseJournal.Create(true , fATMName);
  fParse.OnWorkJrn := fOnPharseWorkJrn;  
end;

destructor TThParseJournal.Destroy;
begin
   if Assigned(fArrLists) then fArrLists.Free ;
	if Assigned(fParse) then fParse.Free;

	if Assigned(fLog) then fLog.Free;
  inherited;
end;

procedure TThParseJournal.Execute;
var
i : Integer;
begin
  inherited;
  if ((fMaskWork and frmParsing1.MASKPARSEJRN) <> 0 ) then
  	begin
			CoInitialize(nil);
			if Assigned(fLog) then fLog.Write('In Execute');

			SetLength(fArrFileSize,0);
			fCurrFileNameJrn				:= '';
			fCurrCountJrn						:= 0	;
			fAllCountJrn						:= 0	;
			fCurrFileSizeJrn				:= 0	;
			fAllFileSizeJrn				 	:= 0	;
			fCurrSizeReceivedJrn 		:= 0	;
			fAllSizeReceivedJrn 		:= 0	;
		  fCreateLists;
// Synchronize(syncfAddCountJrn);
  		if fArrLists.Count > 0 then
  			begin
//					PostMessage(frmParsing.AppHndl , WM_PHARSEJRN , 2 , fTag);
					for i := 0 to fArrLists.Count - 1 do
      			begin
            	fCurrSizeReceivedJrn := 0;
              fCurrFileNameJrn := fArrLists.Strings[i];
              fCurrFileSizeJrn := fArrFileSize[i];
//							PostMessage(frmParsing.AppHndl , WM_PHARSEJRN , 4 , fTag);
							if Assigned(fLog) then fLog.Write('i - ' + IntToStr(i) + '. ' + fArrLists.Strings [i]) ;
//              PostMessage(frmParsing.AppHndl , WM_PHARSEJRN , 0 , fTag);
            	fWorkFile(fArrLists.Strings[i]);
              Inc(fCurrCountJrn);
//							PostMessage(frmParsing.AppHndl , WM_PHARSEJRN , 4 , fTag);
//            Synchronize(syncfIncProgressCntJrn);
	         end;
				end
   		else
   			begin
					if Assigned(fLog) then fLog.Write('nO files in Directory');
				end;
			CoUninitialize();
//      PostMessage(frmParsing.AppHndl , WM_PHARSEJRN , 0 , fTag);
    end
	else
  	begin
//			PostMessage(frmParsing.AppHndl , WM_PHARSEJRN , 1 , fTag);
    end;
end;

procedure TThParseJournal.syncfAddCountJrn;
begin
//  frmParsing.SG1.Cells[1 , fTag] := IntToStr(fArrLists.Count);
//  frmParsing.fArrG1[fTag - 1].MinValue := 0;
//  frmParsing.fArrG1[fTag - 1].MaxValue := fArrLists.Count;
//  frmParsing.fArrG1[fTag - 1].Progress := 0;
end;

procedure TThParseJournal.syncfAddNameJrn;
begin
//  frmParsing.SG1.Cells[2 , fTag] := fParse.NamFil;
end;

procedure TThParseJournal.syncfAddToMemo;
begin
//   frmParsing1.frmParsing.M2.Lines.Add(fTextToMemo);
end;

procedure TThParseJournal.syncfGaugeCntJrn;
begin

end;

procedure TThParseJournal.syncfIncProgressCntJrn;
begin
//	if frmParsing.fArrG1[fTag - 1].Progress  < frmParsing.fArrG1[fTag - 1].MaxValue then
//		frmParsing.fArrG1[fTag - 1].Progress := frmParsing.fArrG1[fTag - 1].Progress + 1;
end;

procedure TThParseJournal.fCreateLists;
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
if Assigned(fLog) then fLog.Write('fCreateList file - ' + sr.Name ) ;
               fArrLists.Add(fWorkDir + sr.Name );
               SetLength(fArrFileSize , Length(fArrFileSize) + 1);
               fArrFileSize[Length(fArrFileSize) -1] := sr.Size;
               fAllFileSizeJrn := fAllFileSizeJrn + sr.Size;
               Inc(fAllCountJrn);
				until FindNext(sr) <> 0;
				FindClose(sr);
			end;
   end;
end;

function TThParseJournal.fDefATMDir : String;
var
sr : TSearchRec;
tmpName : String;
tmpMask : String;
retVal : String;
begin
retVAl := '';
if Assigned(fLog) then fLog.Write('In DefATM Dir. ATMNAme - ' + fATMName);
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

procedure TThParseJournal.fOnPharseWorkJrn(Sender: TObject; AWorkCount: Cardinal);
begin
	fCurrSizeReceivedJrn := fCurrSizeReceivedJrn + AWorkCount;
  fAllSizeReceivedJrn		:= fAllSizeReceivedJrn + AWorkCount;
	SendMessage(frmParsing.AppHndl , WM_PHARSEJRN , 4 , fTag);
end;

procedure TThParseJournal.fParseJournal;
begin
 fParse.CheckBalansing := true;
 fParse.CheckTransIPS := true;
 fParse.CheckStl := true;
 fParse.NamFil := fDestFile;
// Synchronize(syncfAddNameJrn);
if Assigned(fLog) then fLog.Write('1 Parse Journal');
 fParse.Start;
if Assigned(fLog) then fLog.Write('2 Parse Journal');
end;

function TThParseJournal.fRenMov(FilName: String): boolean;
var
 Fo : TSHFileOpStruct; 
 pbuffer : array [0..4096] of char;
 dbuffer : array [0..4096] of char;
 p : pchar;
 d : pchar;
tmpDir : String;
destFil : String;
begin
	tmpDir := fWorkDir + frmParsing.fGlobalParams.Values ['DirSaveArchive'];
  	if not DirectoryExists(tmpDir) then
  		if not ForceDirectories(tmpDir) then
    		begin
if Assigned(fLog) then fLog.Write('Not Create Directory ' + tmpDir);
        		exit;
      	end;
	destFil := tmpDir + ExtractFileName(FilName);

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

procedure TThParseJournal.fUnArcFile(NameFile: String);
var
Param1 , Param2, Param3, Param4 : String;
fPath , fName , fExt : String;
sr : TSearchrec;
currTick : INteger;
MaxTick : Integer;
retVal : Integer;
begin
MaxTick := 10000;
fLog.Write('In Arch File. Name - ' + NameFile);
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
// Synchronize(syncfAddToMemo);
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

procedure TThParseJournal.fWorkFile(NameFile: String);
var
tmpName , tmpExt : String;
begin
tmpName := ExtractFileName(NameFile);
tmpExt := ExtractFileExt(NameFile);
fDestFile := ''; // Copy(tmpName , 1 , Pos(tmpExt , tmpName) - 1);

if UPPERCASE(ExtractFileExt(NameFile)) = UPPERCASE('.rar') then
   begin
//      fUnRarFile(NameFile);
      fUnArcFile(NameFile);
      if Length(fDestFile) > 0 then
      	begin
      	sleep(250);
          fParseJournal;
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

procedure TThParseJournal.Terminate;
begin
inherited;
end;

end.
