unit frmParsing1;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, clThreadParseJournal1 , clThreadParseReceipt1, Grids,
  Gauges, clThFTP, clLogAcceptor1 , ADODB, DB , activeX , comobj , clThCopyBilbo1,
  ComCtrls, clATMSheet1;
const
  MASKFTPJRN = $00000001;
  MASKFTPRCPT = $00000002;
  MASKFTPOTHER = $00000004;
  MASKBILBO		= $00000008;
  MASKPARSEJRN = $00000010;
  MASKPARSERCPT = $00000020;

	WM_COPYJRN = WM_USER + 1;
  WM_COPYRCPT	= WM_USER + 2;
  WM_COPYBILBO	= WM_USER + 3;
  WM_COPYANOTHER	= WM_USER + 100;

  WM_SENDBILBO	= WM_USER + 4;
  WM_PHARSEJRN	= WM_USER + 5;
  WM_PHARSERCPT	= WM_USER + 6;

  WM_SOCKETERROR	= WM_USER + 7;
  WM_PHARSERCPTERROR = WM_USER + 8;
//	DIRLOG = 'K:\Управлiння роздрiбних операцiй\Вiддiл технiчного обслуговування\ATMLogs\';'
//		DIRLOG = 'D:\ATMLogs\';
//   	DIRSAVEARCHIVE = 'ARCHIVE\';
//   	MASKFILEJRN = '*.jrn.*';
//   	MASKDIRJRN = '_ATM08*';

//   	MASKFILERCT = 'r*.log.*';
//   	MASKDIRRCT = '_ATM08*';

type
  TfrmParsing = class(TForm)
    PC1: TPageControl;
    TabSheet1: TTabSheet;
    CBATM: TComboBox;
    SG1: TStringGrid;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure fOnButtonClick(Sender : TObject);
    procedure SG1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject );
    procedure FormHide(Sender: TObject);
  private
    { Private declarations }
    fLog						: TLogAcceptor;
    fThFTP					: array of TThFTP;
//    fThBILBO				: array of TThBILBO;
    fThParseJournal : array of TThParseJournal;
    fThParseReceipt : array of TThParseReceipt;
    fThCopyBilbo		: array of TThCopyBilbo;

    fATMSheet : array of TATMSheet;
    fB1 : TButton;

    fConn 		: TADOConnection;
    fQuery		: TADOQuery;

    fFTPParams				: TStringList;
    fBILBOParams			: TStringList;
    fParseParams			: TStringList;
    fReceiptParams 		: TStringList;

    fServer 			: String;
    fDataBase 		: String;
    fUser 				: String;
    fPassword 		: String;
    fProvider 		: String;

    procedure fDefSG;
    procedure fDefButton(iTag : Integer);
    procedure fDefATMSheet(iTag : Integer);
    function fReadGlobalParams : boolean;
    function fConnectSQL : boolean;
    function fReadFTPParam : boolean;
    procedure fB1Align;

    procedure fStartJrnTh(index : Integer);
    procedure fStartRcptTh(index : Integer);
    procedure fStartBilboTh(index : Integer);

    procedure f_COPYJRN (var MSG : TMessage); Message WM_COPYJRN;
    procedure f_COPYRCPT (var MSG : TMessage); Message WM_COPYRCPT;
    procedure f_COPYBILBO (var MSG : TMessage); Message WM_COPYBILBO;
    procedure f_COPYANOTHER (var MSG : TMessage); Message WM_COPYANOTHER;
    procedure f_SENDBILBO (var MSG : TMessage); Message WM_SENDBILBO;
    procedure f_PHARSEJRN (var MSG : TMessage); Message WM_PHARSEJRN;
    procedure f_PHARSERCPT (var MSG : TMessage); Message WM_PHARSERCPT;
    procedure f_SOCKETERROR (var MSG : TMessage); Message WM_SOCKETERROR;
    procedure f_PHARSERCPTERROR (var MSG : TMessage); Message WM_PHARSERCPTERROR;
  public
    { Public declarations }
    fGlobalParams			: TStringList;
    ATMListJournal : TStringList;
    MaskJrn 			: String;
    MaskRcpt 			: String;
    ArchExt 			: String;
    ArchPrg 			: String;
    ArchParam1 		: String;
    UnArchPrg 		: String;
    UnArchParam1 	: String;
    AppHndl				: LongInt;
    fMaskWork				: DWORD;

    procedure Parse(Mask : DWORD);

    property Server 			: String 	read fServer 		  write fServer			;
    property DataBase 		: String 	read fDataBase 	  write fDataBase   ;
    property User 				: String 	read fUser 			  write fUser       ;
    property Password 		: String 	read fPassword 	  write fPassword   ;
    property Provider 		: String 	read fProvider 	  write fProvider   ;
    property MaskWork			: DWORD		read fMaskWork		write fMaskWork		;
  end;
var
  frmParsing: TfrmParsing;

implementation

{$R *.dfm}


procedure TfrmParsing.fDefATMSheet(iTag: Integer);
begin
// ShowMessage(IntToStr(Length(fATMSheet)));
// ShowMessage(IntToStr(iTag));
  fATMSheet[iTag] := TATMSheet.Create(self);
  fATMSheet[iTag].Parent := frmParsing;
  fATMSheet[iTag].Caption := 'ATM ' + ATMListJournal.Strings[iTag];
  fATMSheet[iTag].Tag := iTag + 1;
  fATMSheet[iTag].PageControl := PC1;
end;

procedure TfrmParsing.fDefButton(iTag : Integer);
begin
  fB1 := TButton.Create(frmParsing);
  fB1.Width := 0;
  fB1.Height := 0;
  fB1.Visible := false;
  fB1.Caption := 'Прервать';
  fB1.Tag := iTag;
//  fB1.Parent := SG1;
  fb1.Parent := TabSheet1;
//  fB1.OnClick := Button1.OnClick;
  fB1.OnClick := fOnButtonClick;
  SG1.Objects[7 , iTag + 1] := fB1;
end;

procedure TfrmParsing.fDefSG;
begin
  SG1.ColCount := 8;
  SG1.RowCount := ATMListJournal.Count + 2;
  SG1.FixedCols := 1;
  SG1.FixedRows := 2;
	SG1.RowHeights[0] := 16;
  SG1.RowHeights[1] := 16;
  SG1.Cells[0 , 0] := 'ATM';
  SG1.ColWidths[0] := 30;
  SG1.ColWidths[1] := 60;
  SG1.ColWidths[2] := 60;
  SG1.ColWidths[3] := 60;
  SG1.ColWidths[4] := 60;
  SG1.ColWidths[5] := 60;
  SG1.ColWidths[6] := 60;
  SG1.ColWidths[7] := 60;
  SG1.Cells[1 , 0] := 'FTP';
  SG1.Cells[1 , 1] := 'журналы';
  SG1.Cells[2 , 0] := 'FTP';
  SG1.Cells[2 , 1] := 'чеки';
  SG1.Cells[3 , 0] := 'FTP';
  SG1.Cells[3 , 1] := 'пр.логи';
  SG1.Cells[4 , 0] := 'BILBO';
  SG1.Cells[5 , 0] := 'Обработка';
  SG1.Cells[5 , 1] := 'журналов';
  SG1.Cells[6 , 0] := 'Обработка';
  SG1.Cells[6 , 1] := 'чеков'; 
end;

procedure TfrmParsing.fOnButtonClick(Sender: TObject);
begin
//   ShowMessage('Click Button. Tag - ' + IntToStr((Sender as TButton).Tag));
end;

procedure TfrmParsing.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   ATMListJournal.Free ;
   fGlobalParams.Free;
   fFTPParams.Free;
   fBILBOParams.Free;
   fParseParams.Free;
   fReceiptParams.Free;
   if Assigned(fQuery) then fQuery.Free;
   if Assigned(fConn) then fConn.Free;
   if Assigned(fLog) then fLog.Free;
   
end;

procedure TfrmParsing.FormCreate(Sender: TObject);
begin
   ATMListJournal := TStringList.Create ;
   fConn := TADOConnection.Create(nil);
   fQuery	:= TADOQuery.Create(nil);

   fGlobalParams			:= TStringList.Create;
   fFTPParams					:= TStringList.Create;
   fBILBOParams				:= TStringList.Create;
   fParseParams				:= TStringList.Create;
   fReceiptParams 		:= TStringList.Create;

   fServer 			:= '';
   fDataBase 		:= '';
   fUser 				:= '';
   fPassword 		:= '';
   fProvider 		:= '';
   AppHndl := frmParsing.Handle;
end;

procedure TfrmParsing.Parse(Mask : DWORD) ;
var
i : Integer;
begin
  fMaskWork := Mask;
  if ATMListJournal.Count = 0 then
    begin
    	if Assigned(fLog) then fLog.Write('Не выбран ни один банкомат. Работа невозможна');
      exit;
    end;

  if fReadGlobalParams then
  	begin
			fLog := TLogAcceptor.Create('parsing', frmParsing.fGlobalParams.Values['LocalDir']);    
    	MaskJrn 			:= fGlobalParams.Values['MaskJournal'];
      MaskRcpt 			:= fGlobalParams.Values['MaskReceipt'];
      ArchExt 			:= fGlobalParams.Values['ArchExt'];
      ArchPrg 			:= fGlobalParams.Values['ArchPrg'];
      ArchParam1 		:= fGlobalParams.Values['ArchParam1'];
      UnArchPrg 		:= fGlobalParams.Values['UnArchPrg'];
      UnArchParam1 	:= fGlobalParams.Values['UnArchParam1'];
    end
  else
  	begin
    	exit;
    end;

   for i := 0 to ATMListJournal.Count - 1 do
//    	M2.Lines.Add(ATMListJournal.Strings[i]);
  if not fReadFTPParam then
  	begin
    	if Assigned(fLog) then fLog.Write('Ошибка чтения параметров банкоматов');
    	exit
    end;
  SetLength(fThFTP					, ATMListJournal.Count );
	SetLength(fThParseJournal , ATMListJournal.Count );
	SetLength(fThParseReceipt , ATMListJournal.Count );
  SetLength(fThCopyBilbo 		, ATMListJournal.Count );
	for i := 0 to Length(fThParseJournal) - 1 do
   	begin
      fQuery.First;
      while not fQuery.Eof do
      	begin
          if ATMListJournal.Strings[0] <> '0' then
          	begin
	          if Trim(fQuery.FieldByName('atm_number1').AsString) = Trim(ATMListJournal.Strings[i]) then
  	        	begin
					      fThFTP[i] 							:= TThFTP.Create(true , 'ftp_' + ATMListJournal.Strings[i]);
    					  fThFTP[i].Tag := i + 1;
        	      fThFTP[i].Number            := fQuery.FieldByName('atm_number1').AsString;
          	    fThFTP[i].FUIB              := fQuery.FieldByName('atm_number2').AsString;
            	  fThFTP[i].Address           := fQuery.FieldByName('atm_netaddress1').AsString;
              	fThFTP[i].Port              := fQuery.FieldByName('ftpPort').AsInteger;
	              fThFTP[i].User              := fQuery.FieldByName('ftpUser').AsString;
  	            fThFTP[i].Password          := fQuery.FieldByName('ftpPassword').AsString;
    	          fThFTP[i].ReadTimeout       := StrToInt(fGlobalParams.Values['FTPReadTimeOut']);
      	        fThFTP[i].TransferTimeout   := StrToInt(fGlobalParams.Values['FTPTransferTimeOut']);
        	      fThFTP[i].RemoteDir         := fGlobalParams.Values['FTPRemoteDir'];
          	    fThFTP[i].LocalDir          := fGlobalParams.Values['FTPLocalDir'];
            	  fThFTP[i].MaxCountFile      := StrToInt(fGlobalParams.Values['MaxCountFiles']);
              	fThFTP[i].isDelRemote       := true;
                fThFTP[i].MaskWork 					:= fMaskWork;
	            end;
            end
          else
          	begin
					      fThFTP[i] 							:= TThFTP.Create(true , 'ftp_' + ATMListJournal.Strings[i]);
    					  fThFTP[i].Tag := i + 1;
        	      fThFTP[i].Number            := fQuery.FieldByName('atm_number1').AsString;
          	    fThFTP[i].FUIB              := fQuery.FieldByName('atm_number2').AsString;
            	  fThFTP[i].Address           := fQuery.FieldByName('atm_netaddress1').AsString;
              	fThFTP[i].Port              := fQuery.FieldByName('ftpPort').AsInteger;
	              fThFTP[i].User              := fQuery.FieldByName('ftpUser').AsString;
  	            fThFTP[i].Password          := fQuery.FieldByName('ftpPassword').AsString;
    	          fThFTP[i].ReadTimeout       := StrToInt(fGlobalParams.Values['FTPReadTimeOut']);
      	        fThFTP[i].TransferTimeout   := StrToInt(fGlobalParams.Values['FTPTransferTimeOut']);
        	      fThFTP[i].RemoteDir         := fGlobalParams.Values['FTPRemoteDir'];
          	    fThFTP[i].LocalDir          := fGlobalParams.Values['FTPLocalDir'];
            	  fThFTP[i].MaxCountFile      := StrToInt(fGlobalParams.Values['MaxCountFiles']);
              	fThFTP[i].isDelRemote       := true;
                fThFTP[i].MaskWork 					:= fMaskWork;
            end;
            fQuery.Next;
        end;
//  M2.Lines.Add(fThFTP[i].FUIB + '. ' + fThFTP[i].LocalDir);

			fThParseJournal[i] 	:= TThParseJournal.Create(true , true , ATMListJournal.Strings[i] );
      fThParseJournal[i].RootDir := fGlobalParams.Values['LocalDir'];
      fThParseJournal[i].ATMName := ATMListJournal.Strings[i];
      fThParseJournal[i].MaskName := fGlobalParams.Values['MaskJournal'] + '.' + fGlobalParams.Values['ArchExt'];
      fThParseJournal[i].MaskDir 	:= fGlobalParams.Values['MaskDirJrn'];
      fThParseJournal[i].Tag := i + 1;
      fThParseJournal[i].MaskWork 					:= fMaskWork;

			fThParseReceipt[i] := TThParseReceipt.Create(true , true , ATMListJournal.Strings[i] );
      fThParseReceipt[i].RootDir := fGlobalParams.Values['LocalDir'];
      fThParseReceipt[i].ATMName := ATMListJournal.Strings[i];
      fThParseReceipt[i].MaskName := fGlobalParams.Values['MaskReceipt'] + '.' + fGlobalParams.Values['ArchExt'];
      fThParseReceipt[i].MaskDir  := fGlobalParams.Values['MaskDirRcpt'];
      fThParseReceipt[i].Tag := i + 1;
      fThParseReceipt[i].MaskWork 					:= fMaskWork;

      fThCopyBilbo[i] := TThCopyBilbo.Create(true , true , StrToInt(ATMListJournal.Strings[i]));
      fThCopyBilbo[i].Tag := i + 1;
      fThCopyBilbo[i].ProgName 			:= fGlobalParams.Values['BilboProgName'];
      fThCopyBilbo[i].Address				:= fGlobalParams.Values['BilboAddress'];
      fThCopyBilbo[i].RootDir   		:= fGlobalParams.Values['BilboRootDir'];
      fThCopyBilbo[i].SubDir    		:= fGlobalParams.Values['BilboSubDir'];
      fThCopyBilbo[i].User      		:= fGlobalParams.Values['BilboUser'];
      fThCopyBilbo[i].Password  		:= fGlobalParams.Values['BilboPassword'];
      fThCopyBilbo[i].Params				:= fGlobalParams.Values['BilboParams'];
      fThCopyBilbo[i].FUIBDir   		:= Copy(fThFTP[i].FUIB , 5 , 4) ;
      fThCopyBilbo[i].RootDirBilbo	:= fGlobalParams.Values['LocalDir'];
      fThCopyBilbo[i].DirArchBilbo	:= fGlobalParams.Values['DirArchForBilbo'];
      fThCopyBilbo[i].DirSendBilbo	:= fGlobalParams.Values['DirSendForBilbo'];
      fThCopyBilbo[i].DirBackBilbo	:= fGlobalParams.Values['DirBackForBilbo'];
      fThCopyBilbo[i].DirLogBilbo	 	:= fGlobalParams.Values['DirLogForBilbo'];
      fThCopyBilbo[i].MaskLog 			:= fGlobalParams.Values['MaskJournal'];
      fThCopyBilbo[i].MaskWork 					:= fMaskWork;
		end;


	for i := 0 to Length(fThFTP) - 1 do
   	if fThFTP[i].Suspended  then
      	begin
         	fThFTP[i].Resume;
         end;
         
end;

procedure TfrmParsing.SG1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
	if not (gdFixed in State) then fB1Align;
end;

procedure TfrmParsing.FormHide(Sender: TObject);
var
i : Integer;
begin
//	M2.Lines.Add('On Hide');
  fB1.Free;
  for i := 0 to Length(fATMSheet) - 1 do
   	begin
      fATMSheet[i].Free;
    end;
	for i := 0 to Length(fThParseJournal) - 1 do
   	begin
         if fThParseJournal[i].Suspended  then
         	fThParseJournal[i].Resume ;
         fThParseJournal[i].Terminate;
      	fThParseJournal[i].Destroy;
      end;
	for i := 0 to Length(fThParseReceipt) - 1 do
   	begin
         if fThParseReceipt[i].Suspended  then
         	fThParseReceipt[i].Resume ;
         fThParseReceipt[i].Terminate;
      	fThParseReceipt[i].Destroy;
      end;
	for i := 0 to Length(fThCopyBilbo) - 1 do
   	begin
         if fThCopyBilbo[i].Suspended  then
         	fThCopyBilbo[i].Resume ;
         fThCopyBilbo[i].Terminate;
      	fThCopyBilbo[i].Destroy;
      end;
	for i := 0 to Length(fThFTP) - 1 do
   	begin
         if fThFTP[i].Suspended  then
         	fThFTP[i].Resume ;
         fThFTP[i].Terminate;
      	fThFTP[i].Destroy;
      end;


end;

procedure TfrmParsing.FormShow(Sender: TObject);
var
i : Integer;
begin
	CBATM.Clear;
  fDefSG;
  SetLength(fATMSheet , ATMListJournal.Count);
  for i := 0 to ATMListJournal.Count - 1 do
  	begin
    	CBATM.Items.Add(ATMListJournal.Strings[i]);
      SG1.RowHeights[i + 2] := 16;
    	SG1.Cells[0 , i + 2] := ATMListJournal.Strings[i];
		  fDefButton(i + 1);
      SG1.Cells[1 , i + 2] := 'Ожидание';
      SG1.Cells[2 , i + 2] := 'Ожидание';
      SG1.Cells[3 , i + 2] := 'Ожидание';
      SG1.Cells[4 , i + 2] := 'Ожидание';
      SG1.Cells[5 , i + 2] := 'Ожидание';
      SG1.Cells[6 , i + 2] := 'Ожидание';
      fDefATMSheet(i);
    end;

end;

procedure TfrmParsing.Button1Click(Sender: TObject);
begin
//   ShowMessage('Click Button. Tag - ' + IntToStr((Sender as TButton).Tag));
end;

procedure TfrmParsing.fB1Align;
var
	i : Integer;
	Rect: TRect;
  NewBtn : TButton;
begin
 for i := 1 to SG1.RowCount do
 	begin
 		NewBtn := (SG1.Objects[7,i ] as TButton);
 		if NewBtn <> nil then
			begin
 				Rect := SG1.CellRect(7,i);
				NewBtn.Left := SG1.Left + Rect.Left + 2;
				NewBtn.Top := SG1.Top + Rect.Top + 2;
				NewBtn.Width := Rect.Right - Rect.Left;
 				NewBtn.Height := Rect.Bottom - Rect.Top;
 				NewBtn.Visible := True;
      end;
 end;

end;

function TfrmParsing.fConnectSQL : boolean;
begin
// if Assigned(fLog) then fLog.Write('In Connect SQL') ;
	try
		fConn.Connected := true;
   except
   	on E : Exception do
 if Assigned(fLog) then fLog.Write('Error Connect to SQL server. ' + E.Message + '. ' + E.ClassName ) ;
   end;
if fConn.Connected  then
	fConnectSQL := true
else
	fConnectSQL := false;
end;

function TfrmParsing.fReadFTPParam: boolean;
var
ind : Integer;
begin
	fQuery.Close;
   fQuery.SQL.Clear;
   fQuery.SQL.Add('select atm_number1 , atm_number2 , atm_netaddress1 , atm_name , ftpPort , ftpUser , ftpPassword from V_ATMsFTP');

   if fConn.Connected  then
   	begin
	    if not fConnectSQL then
      	begin
        	if Assigned(fLog) then fLog.Write('ReadFTPParam. Error connect to SQL server. ' + fServer);
        	fQuery.Close;
					fReadFTPParam := false;
          exit;
        end;
	  	    try
// if Assigned(fLog) then fLog.Write(fQuery.SQL[0]);
         
		  	  	fQuery.Open;
			  	except
   					on E : Exception do
							if Assigned(fLog) then fLog.Write('ReadFTPParam. Error Connect to SQL server. ' + E.Message + '. ' + E.ClassName ) ;
					end;
  		    if fQuery.RecordCount < 1 then
    		  	begin
      	  		fReadFTPParam := false;
        		end
	        else
  	      	begin
    	    		fReadFTPParam := true;
      	    end
  	  end;
end;

function TfrmParsing.fReadGlobalParams : boolean;
var
  ind : Integer;
begin
  if Length(fUser) = 0 then
    begin
	   fConn.ConnectionString := 'Provider=' + fProvider + ';data source=' + fServer + ';Integrated Security=SSPI;initial catalog=' + fDataBase
    end
  else
  	begin
	  	fConn.ConnectionString := 'Provider=' + fProvider + ';password=' + fPassword + ';data source=' + fServer + ';user=' + fUser + ';Integrated Security=SSPI;initial catalog=' + fDataBase;
    end;

   fConn.CommandTimeout := 10000;
   fConn.LoginPrompt := false;
   fConn.KeepConnection := true;
   fConn.ConnectionTimeout := 5000;

   fQuery.Connection := fConn;
   fQuery.SQL.Clear;
   fQuery.SQL.Add('select name , flag , value from Params');

   if fConnectSQL then
   	begin
      try
	    	fQuery.Open;
		  except
   			on E : Exception do
					if Assigned(fLog) then fLog.Write('ReadGlobalParamsError Connect to SQL server. ' + E.Message + '. ' + E.ClassName ) ;
			end;
      if fQuery.RecordCount > 0 then
      	begin
          fQuery.First;
          fGlobalParams.Clear;
          while not fQuery.Eof  do
          	begin
              ind := fGlobalParams.Add(fQuery.FieldbyName('name').AsString + '=' + fQuery.FieldByName('value').AsString);
//              M2.Lines.Add(fGlobalParams.Strings[ind]);
              fQuery.Next;
            end;
        	fReadGlobalParams := true;
        end
      else
        begin
          fConn.Connected := false;
          fQuery.Close;
          fQuery.SQL.Clear;
        	fReadGlobalParams := false;
        end;
    end
   else
   	begin
	    fReadGlobalParams := false;
    end;
end;

procedure TfrmParsing.fStartBilboTh(index: Integer);
begin
if fThCopyBilbo[index].Suspended then
	begin
// if Assigned(fLog) then fLog.Write('Before execute BILBO');
  	fThCopyBilbo[index].Resume;
  end
else
	begin
if Assigned(fLog) then fLog.Write('Thread COPYBILBO allready started. Index - ' + IntToStr(index) + '. ATM - ' + fThCopyBilbo[index].FUIBDir) ;
  end;
end;

procedure TfrmParsing.fStartJrnTh(index: Integer);
begin
if fThParseJournal[index].Suspended  then
	begin
  	fThParseJournal[index].Resume;
  end
else
	begin
if Assigned(fLog) then fLog.Write('Thread COPYJOURNAL allready started. Index - ' + IntToStr(Index) + '. ATM - ' + fThCopyBilbo[index].FUIBDir) ;
  end;

end;

procedure TfrmParsing.fStartRcptTh(index: Integer);
begin
if fThParseReceipt[index].Suspended  then
	begin
  	fThParseReceipt[index].Resume;
  end
else
	begin
if Assigned(fLog) then fLog.Write('Thread COPYRCPT allready started. Index - ' + IntToStr(Index) + '. ATM - ' + fThCopyBilbo[index].FUIBDir) ;
  end;
end;

procedure TfrmParsing.f_COPYANOTHER(var MSG: TMessage);
var
ind : Integer;
begin
ind := Msg.LParam - 1;
// if Assigned(fLog) then fLog.Write('Post Message COPYANOTHER Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
case Msg.WParam of
	0 :
  		begin
				SG1.Cells[3 , ind + 2] := 'Закончил';
				fATMSheet[ind].SG2.Cells[4 , 3] := '';
      end;
	1 :
  		begin
        SG1.Cells[3 , ind + 2] := 'Отключен';
      end;
	2 :
  		begin
        SG1.Cells[3 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
        SG1.Cells[3 , ind + 2] := fThFTP[ind].CurrFileFTP;
        fATMSheet[ind].SG2.Cells[4 , 3] := fThFTP[ind].CurrFileFTP;
        fATMSheet[ind].SG2.Cells[1 , 3] := IntToStr(fThFTP[ind].AllCountFileFTP);
        fATMSheet[ind].SG2.Cells[2 , 3] := IntToStr(fThFTP[ind].CurrCountFileFTP);

        fATMSheet[ind].G1[2].MaxValue := fThFTP[ind].AllCountFileFTP;
        fATMSheet[ind].G2[2].MaxValue := fThFTP[ind].CurrSizeFileFTP;
        fATMSheet[ind].G3[2].MaxValue := fThFTP[ind].AllSizeFileFTP;
        fATMSheet[ind].G1[2].Progress := fThFTP[ind].CurrCountFileFTP;
        fATMSheet[ind].G2[2].Progress := fThFTP[ind].CurrReceiveFileFTP;
        fATMSheet[ind].G3[2].Progress := fThFTP[ind].AllReceiveFileFTP;
      end;
	4 :
  		begin
        fATMSheet[ind].G1[2].Progress := fThFTP[ind].CurrCountFileFTP;
        fATMSheet[ind].G2[2].Progress := fThFTP[ind].CurrReceiveFileFTP;
        fATMSheet[ind].G3[2].Progress := fThFTP[ind].AllReceiveFileFTP;
      end;
	else
  		begin

      end;
end;

end;

procedure TfrmParsing.f_COPYBILBO(var MSG: TMessage);
var
ind : Integer;
begin
// if Assigned(fLog) then fLog.Write('Post Message COPYBILBO Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
ind := Msg.LParam - 1;
case Msg.WParam of
	0 :
  		begin
//				SG1.Cells[1 , ind + 2] := 'Закончил';
				fStartBilboTh(Ind);
      end;
	1 :
  		begin
//        SG1.Cells[1 , ind + 2] := 'Отключен';
				fStartBilboTh(Ind);
      end;
	2 :
  		begin
//        SG1.Cells[1 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
//        SG1.Cells[1 , ind + 2] := fThFTP[ind].CurrFileFTP;
      end;
	else
  		begin

      end;
end;

end;

procedure TfrmParsing.f_COPYJRN(var MSG: TMessage);
var
ind : Integer;
i : Integer;
begin
// if Assigned(fLog) then fLog.Write('Post Message COPYJRN Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
ind := Msg.LParam - 1;
case Msg.WParam of
	0 :
  		begin
				SG1.Cells[1 , ind + 2] := 'Закончил';
        fStartJrnTh(ind);
				fATMSheet[ind].SG2.Cells[4 , 1] := '';
      end;
	1 :
  		begin
        SG1.Cells[1 , ind + 2] := 'Отключен';
        fStartJrnTh(ind);
      end;
	2 :
  		begin
        SG1.Cells[1 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
// if Assigned(fLog) then fLog.Write('WM_COPYJRN. LParam - ' + IntToStr(Msg.LParam) + '. file - ' + fThFTP[ind].CurrFileFTP + '. AllCount - ' + IntToStr(fThFTP[ind].AllCountFileFTP) + '. CurrCount - ' + IntToStr(fThFTP[ind].CurrCountFileFTP));

        SG1.Cells[1 , ind + 2] := fThFTP[ind].CurrFileFTP;
        fATMSheet[ind].SG2.Cells[4 , 1] := fThFTP[ind].CurrFileFTP;
        fATMSheet[ind].SG2.Cells[1 , 1] := IntToStr(fThFTP[ind].AllCountFileFTP);
        fATMSheet[ind].SG2.Cells[2 , 1] := IntToStr(fThFTP[ind].CurrCountFileFTP);
        fATMSheet[ind].G1[0].MaxValue := fThFTP[ind].AllCountFileFTP;
        fATMSheet[ind].G2[0].MaxValue := fThFTP[ind].CurrSizeFileFTP;
        fATMSheet[ind].G3[0].MaxValue := fThFTP[ind].AllSizeFileFTP;
        fATMSheet[ind].G1[0].Progress := fThFTP[ind].CurrCountFileFTP;
        fATMSheet[ind].G2[0].Progress := fThFTP[ind].CurrReceiveFileFTP;
        fATMSheet[ind].G3[0].Progress := fThFTP[ind].AllReceiveFileFTP;
      end;
	4 :
  		begin
        fATMSheet[ind].G1[0].Progress := fThFTP[ind].CurrCountFileFTP;
        fATMSheet[ind].G2[0].Progress := fThFTP[ind].CurrReceiveFileFTP;
        fATMSheet[ind].G3[0].Progress := fThFTP[ind].AllReceiveFileFTP;
      end;

	else
  		begin

      end;
end;

end;

procedure TfrmParsing.f_COPYRCPT(var MSG: TMessage);
var
ind : Integer;
begin
// if Assigned(fLog) then fLog.Write('Post Message COPYRCPT Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
ind := Msg.LParam - 1;
case Msg.WParam of
	0 :
  		begin
				SG1.Cells[2 , ind + 2] := 'Закончил';
				fATMSheet[ind].SG2.Cells[4 , 2] := '';
        fStartRcptTh(ind);
      end;
	1 :
  		begin
        SG1.Cells[2 , ind + 2] := 'Отключен';
        fStartRcptTh(ind);
      end;
	2 :
  		begin
        SG1.Cells[2 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
// if Assigned(fLog) then fLog.Write('3. WM_COPYRCPT. LParam - ' + IntToStr(Msg.LParam) + '. file - ' + fThFTP[ind].CurrFileFTP + '. AllCount - ' + IntToStr(fThFTP[ind].AllCountFileFTP) + '. CurrCount - ' + IntToStr(fThFTP[ind].CurrCountFileFTP));
        SG1.Cells[2 , ind + 2] := fThFTP[ind].CurrFileFTP;
        fATMSheet[ind].SG2.Cells[4 , 2] := fThFTP[ind].CurrFileFTP;
        fATMSheet[ind].SG2.Cells[1 , 2] := IntToStr(fThFTP[ind].AllCountFileFTP);
        fATMSheet[ind].SG2.Cells[2 , 2] := IntToStr(fThFTP[ind].CurrCountFileFTP);

        fATMSheet[ind].G1[1].MaxValue := fThFTP[ind].AllCountFileFTP;
        fATMSheet[ind].G2[1].MaxValue := fThFTP[ind].CurrSizeFileFTP;
        fATMSheet[ind].G3[1].MaxValue := fThFTP[ind].AllSizeFileFTP;
        fATMSheet[ind].G1[1].Progress := fThFTP[ind].CurrCountFileFTP;
        fATMSheet[ind].G2[1].Progress := fThFTP[ind].CurrReceiveFileFTP;
        fATMSheet[ind].G3[1].Progress := fThFTP[ind].AllReceiveFileFTP;
      end;
	4 :
  		begin
// if Assigned(fLog) then fLog.Write('4. WM_COPYRCPT. LParam - ' + IntToStr(Msg.LParam) + '. file - ' + fThFTP[ind].CurrFileFTP + '. AllCount - ' + IntToStr(fThFTP[ind].AllCountFileFTP) + '. CurrCount - ' + IntToStr(fThFTP[ind].CurrCountFileFTP));
        fATMSheet[ind].G1[1].Progress := fThFTP[ind].CurrCountFileFTP;
        fATMSheet[ind].G2[1].Progress := fThFTP[ind].CurrReceiveFileFTP;
        fATMSheet[ind].G3[1].Progress := fThFTP[ind].AllReceiveFileFTP;
      end;
	else
  		begin

      end;
end;
end;

procedure TfrmParsing.f_PHARSEJRN(var MSG: TMessage);
var
ind : Integer;
begin
// if Assigned(fLog) then fLog.Write('Post Message PHARESEJRN Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
ind := Msg.LParam - 1;
case Msg.WParam of
	0 :
  		begin
				SG1.Cells[5 , ind + 2] := 'Закончил';
      end;
	1 :
  		begin
        SG1.Cells[5 , ind + 2] := 'Отключен';
      end;
	2 :
  		begin
        SG1.Cells[5 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
        SG1.Cells[5 , ind + 2] 					:= fThParseJournal[ind].CurrFileNameJrn;
        fATMSheet[ind].SG2.Cells[4 , 5] := fThParseJournal[ind].CurrFileNameJrn;
        fATMSheet[ind].SG2.Cells[1 , 5] := IntToStr(fThParseJournal[ind].AllCountJrn);
        fATMSheet[ind].SG2.Cells[2 , 5] := IntToStr(fThParseJournal[ind].CurrCountJrn);

        fATMSheet[ind].G1[4].MaxValue 	:= fThParseJournal[ind].AllCountJrn					;
        fATMSheet[ind].G1[4].Progress	 	:= fThParseJournal[ind].CurrCountJrn				;
        fATMSheet[ind].G2[4].MaxValue 	:= fThParseJournal[ind].CurrFileSizeJrn			;
        fATMSheet[ind].G2[4].Progress 	:= fThParseJournal[ind].CurrSizeReceivedJrn	;
        fATMSheet[ind].G3[4].MaxValue 	:= fThParseJournal[ind].AllFileSizeJrn			;
        fATMSheet[ind].G3[4].Progress 	:= fThParseJournal[ind].AllSizeReceivedJrn	;

      end;
	4 :
  		begin
        fATMSheet[ind].G1[4].Progress 	:= fThParseJournal[ind].CurrCountJrn			  ;
        fATMSheet[ind].G2[4].Progress 	:= fThParseJournal[ind].CurrSizeReceivedJrn ;
        fATMSheet[ind].G3[4].Progress 	:= fThParseJournal[ind].AllSizeReceivedJrn	;
      end;
	else
  		begin

      end;
	end;
end;

procedure TfrmParsing.f_PHARSERCPT(var MSG: TMessage);
var
ind : Integer;
begin
// if Assigned(fLog) then fLog.Write('Post Message PHARESERCPT Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
ind := Msg.LParam - 1;
case Msg.WParam of
	0 :
  		begin
				SG1.Cells[6 , ind + 2] := 'Закончил';
      end;
	1 :
  		begin
        SG1.Cells[6 , ind + 2] := 'Отключен';
      end;
	2 :
  		begin
        SG1.Cells[6 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
        SG1.Cells[6 , ind + 2] 					:= fThParseReceipt[ind].CurrFileNameRcpt				;
        fATMSheet[ind].SG2.Cells[4 , 6] := fThParseReceipt[ind].CurrFileNameRcpt				;
        fATMSheet[ind].SG2.Cells[1 , 6] := IntToStr(fThParseReceipt[ind].AllCountRcpt)	;
        fATMSheet[ind].SG2.Cells[2 , 6] := IntToStr(fThParseReceipt[ind].CurrCountRcpt)	;

        fATMSheet[ind].G1[5].MaxValue 	:= fThParseReceipt[ind].AllCountRcpt						;
        fATMSheet[ind].G1[5].Progress	 	:= fThParseReceipt[ind].CurrCountRcpt						;
        fATMSheet[ind].G2[5].MaxValue 	:= fThParseReceipt[ind].CurrFileSizeRcpt				;
        fATMSheet[ind].G2[5].Progress 	:= fThParseReceipt[ind].CurrSizeReceivedRcpt		;
        fATMSheet[ind].G3[5].MaxValue 	:= fThParseReceipt[ind].AllFileSizeRcpt					;
        fATMSheet[ind].G3[5].Progress 	:= fThParseReceipt[ind].AllSizeReceivedRcpt			;

      end;
	4 :
  		begin
        fATMSheet[ind].G1[5].Progress 	:= fThParseReceipt[ind].CurrCountRcpt			  		;
        fATMSheet[ind].G2[5].Progress 	:= fThParseReceipt[ind].CurrSizeReceivedRcpt		;
        fATMSheet[ind].G3[5].Progress 	:= fThParseReceipt[ind].AllSizeReceivedRcpt			;
      end;
	else
  		begin

      end;
	end;
end;

procedure TfrmParsing.f_PHARSERCPTERROR(var MSG: TMessage);
begin
if Assigned(fLog) then fLog.Write('Parse receipt Error. ' + fThFTP[Msg.LParam - 1].Number + '. Error - ' + IntToStr(Msg.WParam));
end;

procedure TfrmParsing.f_SENDBILBO(var MSG: TMessage);
var
ind : Integer;
begin
// if Assigned(fLog) then fLog.Write('Post Message SENDBILBO Low - . ' + IntToStr(Msg.LParam) + '. High - ' + IntToStr(Msg.WParam)) ;
ind := Msg.LParam - 1;
case Msg.WParam of
	0 :
  		begin
				SG1.Cells[4 , ind + 2] := 'Закончил';
      end;
	1 :
  		begin
        SG1.Cells[4 , ind + 2] := 'Отключен';
      end;
	2 :
  		begin
        SG1.Cells[4 , ind + 2] := 'Работа';
      end;
	3 :
  		begin
        SG1.Cells[4 , ind + 2] := fThCopyBilbo[ind].CurrFileName;
        fATMSheet[ind].SG2.Cells[4 , 4] := fThCopyBilbo[ind].CurrFileName;
        fATMSheet[ind].SG2.Cells[1 , 4] := IntToStr(fThCopyBilbo[ind].AllCountFileBilbo);
        fATMSheet[ind].SG2.Cells[2 , 4] := IntToStr(fThCopyBilbo[ind].CurrCountFileBilbo);

        fATMSheet[ind].G1[3].MaxValue := fThCopyBilbo[ind].AllCountFileBilbo;
        fATMSheet[ind].G1[3].Progress := fThCopyBilbo[ind].CurrCountFileBilbo;
      end;
	4 :
  		begin
        fATMSheet[ind].G1[3].Progress := fThCopyBilbo[ind].CurrCountFileBilbo;
      end;
	else
  		begin

      end;
	end;
end;

procedure TfrmParsing.f_SOCKETERROR(var MSG: TMessage);
begin
if Assigned(fLog) then fLog.Write('SocketError. ' + fThFTP[Msg.LParam - 1].Number + '. Error - ' + IntToStr(Msg.WParam));

end;

end.
