unit clATMSheet1;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids,
  Gauges, ComCtrls; // , clLogAcceptor1 ;
type
	TATMSheet = class(TTabsheet)
    private
      BBreakAll				: TButton;
      BBreakFTPJrn		: TButton;
      BBreakFTPRcpt		: TButton;
      BBreakFTPOther	: TButton;
      BBreakBilbo			: TButton;
      BBreakWorkJrn		: TButton;
      BBreakWorkRcpt	: TButton;

      BBreakOne	: TButton;

      procedure fDefPropMemo;
      procedure fDefPropSG;
      procedure fDefPropBBreakAll;
      procedure fDefPropBtns;

      procedure fG1Align;
      procedure fG2Align;
      procedure fG3Align;

      procedure BBreakAllClick			(Sender : TObject);
      procedure BBreakFTPJrnClick		(Sender : TObject);
      procedure BBreakFTPRcptClick	(Sender : TObject);
      procedure BBreakFTPOtherClick	(Sender : TObject);
      procedure BBreakBilboClick		(Sender : TObject);
      procedure BBreakWorkJrnClick	(Sender : TObject);
      procedure BBreakWorkRcptClick	(Sender : TObject);

      procedure SG2DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    public
      M1 		: TMemo;
    	SG2 	: TStringGrid;
      G1		: array[0..5] of TGauge;
      G2		: array[0..5] of TGauge;
      G3		: array[0..5] of TGauge;
//      G1		: TGauge;
//      G2		: TGauge;
//      G3		: TGauge;

    	Constructor Create(AOwner : TComponent ); override;
      Destructor Destroy; override;
  end;

implementation

{ TATMSheet }

procedure TATMSheet.BBreakAllClick(Sender: TObject);
begin
  M1.Lines.Add('BBreak Click');
end;


procedure TATMSheet.BBreakBilboClick(Sender: TObject);
begin
M1.Lines.Add('BBreak Bilbo Click');
end;

procedure TATMSheet.BBreakFTPJrnClick(Sender: TObject);
begin
M1.Lines.Add('BBreak FTP journal Click');
end;

procedure TATMSheet.BBreakFTPOtherClick(Sender: TObject);
begin
M1.Lines.Add('BBreak FTP Other Click');
end;

procedure TATMSheet.BBreakFTPRcptClick(Sender: TObject);
begin
M1.Lines.Add('BBreak FTP receipt Click');
end;

procedure TATMSheet.BBreakWorkJrnClick(Sender: TObject);
begin
M1.Lines.Add('BBreak Journal Click');
end;

procedure TATMSheet.BBreakWorkRcptClick(Sender: TObject);
begin
M1.Lines.Add('BBreak Receipt Click');
end;

constructor TATMSheet.Create(AOwner: TComponent);
begin
  inherited;
    Parent := TWinControl(AOwner);
	  M1 := TMemo.Create(self);
    M1.Parent := self;
	  SG2 := TStringGrid.Create(self);
    SG2.Parent := self;
    SG2.OnDrawCell := SG2DrawCell;
    BBreakAll := TButton.Create(self);
    BBreakAll.Parent := self;
    BBreakFTPJrn := TButton.Create(self);
    BBreakFTPJrn.Parent := self;
    BBreakFTPRcpt := TButton.Create(self);
    BBreakFTPRcpt.Parent := self;
    BBreakFTPOther := TButton.Create(self);
    BBreakFTPOther.Parent := self;
    BBreakBilbo := TButton.Create(self);
    BBreakBilbo.Parent := self;
    BBreakWorkJrn := TButton.Create(self);
    BBreakWorkJrn.Parent := self;
    BBreakWorkRcpt := TButton.Create(self);
    BBreakWorkRcpt.Parent := self;

  	fDefPropMemo;
	  fDefPropSG;
    fDefPropBBreakAll;
    fDefPropBtns;

end;

destructor TATMSheet.Destroy;
begin
	M1.Parent := nil;
  M1.Free;
  SG2.Parent := nil;
  SG2.Free;
	inherited;
end;

procedure TATMSheet.fDefPropBBreakAll;
begin
  BBreakAll.Left   := 610;
  BBreakAll.Top    := 425;
  BBreakAll.Width  := 75;
  BBreakAll.Height := 25;
  BBreakAll.Visible := true;
  BBreakAll.Caption := 'Прервать все';
  BBreakAll.OnClick := BBreakAllClick;

end;

procedure TATMSheet.fDefPropBtns;
begin
  BBreakFTPJrn.Left   := SG2.Left + SG2.Width + 2;
  BBreakFTPJrn.Top    := SG2.Top + 19;
  BBreakFTPJrn.Width  := 75;
  BBreakFTPJrn.Height := 18;
  BBreakFTPJrn.Visible := true;
  BBreakFTPJrn.Caption := 'Прервать';
  BBreakFTPJrn.OnClick := BBreakFTPJrnClick;

  BBreakFTPRcpt.Left   := SG2.Left + SG2.Width + 2;
  BBreakFTPRcpt.Top    := BBreakFTPJrn.Top + 19 ;
  BBreakFTPRcpt.Width  := 75;
  BBreakFTPRcpt.Height := 18;
  BBreakFTPRcpt.Visible := true;
  BBreakFTPRcpt.Caption := 'Прервать';
  BBreakFTPRcpt.OnClick := BBreakFTPRcptClick;

  BBreakFTPOther.Left   := SG2.Left + SG2.Width + 2;
  BBreakFTPOther.Top    := BBreakFTPRcpt.Top + 19;
  BBreakFTPOther.Width  := 75;
  BBreakFTPOther.Height := 18;
  BBreakFTPOther.Visible := true;
  BBreakFTPOther.Caption := 'Прервать';
  BBreakFTPOther.OnClick := BBreakFTPOtherClick;

  BBreakBilbo.Left   := SG2.Left + SG2.Width + 2;
  BBreakBilbo.Top    := BBreakFTPOther.Top + 19;
  BBreakBilbo.Width  := 75;
  BBreakBilbo.Height := 18;
  BBreakBilbo.Visible := true;
  BBreakBilbo.Caption := 'Прервать';
  BBreakBilbo.OnClick := BBreakBilboClick;

  BBreakWorkJrn.Left   := SG2.Left + SG2.Width + 2;
  BBreakWorkJrn.Top    := BBreakBilbo.Top  + 19;
  BBreakWorkJrn.Width  := 75;
  BBreakWorkJrn.Height := 18;
  BBreakWorkJrn.Visible := true;
  BBreakWorkJrn.Caption := 'Прервать';
  BBreakWorkJrn.OnClick := BBreakWorkJrnClick;

  BBreakWorkRcpt.Left   := SG2.Left + SG2.Width + 2;
  BBreakWorkRcpt.Top    := BBreakWorkJrn.Top + 19;
  BBreakWorkRcpt.Width  := 75;
  BBreakWorkRcpt.Height := 18;
  BBreakWorkRcpt.Visible := true;
  BBreakWorkRcpt.Caption := 'Прервать';
  BBreakWorkRcpt.OnClick := BBreakWorkRcptClick;
end;

procedure TATMSheet.fDefPropMemo;
begin
   M1.Left   := 1;
   M1.Top    := 162;
   M1.Width  := 680;
   M1.Height := 260;
   M1.BorderStyle := bsSingle;
   M1.Enabled := true;
   M1.ScrollBars := ssBoth;
   M1.Lines.Add('fDefPropMemo Ended. ');
end;

procedure TATMSheet.fDefPropSG;
var
i : INteger;
begin
   SG2.Left   := 1;
   SG2.Top    := 1;
   SG2.Width  := 590;
   SG2.Height := 160;
   SG2.Visible := true;
   SG2.RowCount := 7;
   SG2.ColCount := 8;
   for i := 0 to SG2.RowCount - 1 do
   	begin
	    SG2.RowHeights[i] := 18;
      if i > 0 then
      	begin

			    G1[i - 1]  := TGauge.Create(self);
  			  G1[i - 1].Parent := SG2;
		    	G1[i - 1].Visible := true;
	  		  G1[i - 1].MinValue := 0;
		  	  G1[i - 1].MaxValue := 100;
    			G1[i - 1].Progress := 0;
			    G1[i - 1].Width := 0;
  			  G1[i - 1].Height := 0;
          G1[i - 1].Top := 0;
          G1[i - 1].Left := 0;
          G1[i - 1].Tag := i + 1;
		    	SG2.Objects[3 , i] := G1[i - 1];

			    G2[i - 1]  := TGauge.Create(self);
  			  G2[i - 1].Parent := SG2;
		    	G2[i - 1].Visible := true;
	  		  G2[i - 1].MinValue := 0;
		  	  G2[i - 1].MaxValue := 100;
    			G2[i - 1].Progress := 0;
			    G2[i - 1].Width := 0;
  			  G2[i - 1].Height := 0;
          G2[i - 1].Top := 0;
          G2[i - 1].Left := 0;
          G2[i - 1].Tag := i + 1;
		    	SG2.Objects[5 , i] := G2[i - 1];

          G3[i - 1]  := TGauge.Create(self);
          G3[i - 1].Parent := SG2;
          G3[i - 1].Visible := true;
          G3[i - 1].MinValue := 0;
          G3[i - 1].MaxValue := 100;
          G3[i - 1].Progress := 0;
          G3[i - 1].Width := 0;
          G3[i - 1].Height := 0;
          G3[i - 1].Top := 0;
          G3[i - 1].Left := 0;
          G3[i - 1].Tag := i + 1;
          SG2.Objects[7 , i] := G3[i - 1];

        end;

    end;

   SG2.Cells[0 , 0] := 'Процессы';
   SG2.Cells[0 , 1] := 'FTP журналы';
   SG2.Cells[0 , 2] := 'FTP чеки';
   SG2.Cells[0 , 3] := 'FTP прочие';
   SG2.Cells[0 , 4] := 'BILBO';
   SG2.Cells[0 , 5] := 'Обр.журналов';
   SG2.Cells[0 , 6] := 'Обр.чеков';

   SG2.ColWidths[0] := 70;
   SG2.ColWidths[1] := 40;
   SG2.ColWidths[2] := 40;
   SG2.ColWidths[3] := 80;
   SG2.ColWidths[4] := 80;
   SG2.ColWidths[5] := 90;
   SG2.ColWidths[6] := 50;
   SG2.ColWidths[6] := 90;
   SG2.Cells[0 , 0] := 'Действие';
   SG2.Cells[1 , 0] := 'Всего';
   SG2.Cells[2 , 0] := 'Обр.';
   SG2.Cells[3 , 0] := '';
   SG2.Cells[4 , 0] := 'Текущий файл';
   SG2.Cells[5 , 0] := 'Ход процесса';
   SG2.Cells[6 , 0] := 'Ошибки';
   SG2.Cells[7 , 0] := 'Общий ход';



   M1.Lines.Add('fDefStringGrid Ended');
end;

procedure TATMSheet.fG1Align;
var
  NewG: TGauge;
  Rect: TRect;
  i: Integer;
begin
  for i := 1 to SG2.RowCount do
  begin
    NewG := (SG2.Objects[3, i] as TGauge);
    if NewG <> nil then
    begin
      Rect := SG2.CellRect(3, i); // получаем размер ячейки
      NewG.Left := Rect.Left;
      NewG.Top := Rect.Top;
      NewG.Width := Rect.Right - Rect.Left;
      NewG.Height := Rect.Bottom - Rect.Top;
      NewG.Visible := True;
    end;
  end;
end;

procedure TATMSheet.fG2Align;
var
  NewG: TGauge;
  Rect: TRect;
  i: Integer;
begin
  for i := 1 to SG2.RowCount do
  begin
    NewG := (SG2.Objects[5, i] as TGAuge);
    if NewG <> nil then
    begin
      Rect := SG2.CellRect(5, i); // получаем размер ячейки
      NewG.Left := Rect.Left;
      NewG.Top := Rect.Top;
      NewG.Width := Rect.Right - Rect.Left;
      NewG.Height := Rect.Bottom - Rect.Top;
      NewG.Visible := True;
    end;
  end;
end;

procedure TATMSheet.fG3Align;
var
  NewG: TGauge;
  Rect: TRect;
  i: Integer;
begin
  for i := 1 to SG2.RowCount do
  begin
    NewG := (SG2.Objects[7, i] as TGAuge);
    if NewG <> nil then
    begin
      Rect := SG2.CellRect(7, i); // получаем размер ячейки
      NewG.Left := Rect.Left;
      NewG.Top := Rect.Top;
      NewG.Width := Rect.Right - Rect.Left;
      NewG.Height := Rect.Bottom - Rect.Top;
      NewG.Visible := True;
    end;
  end;
end;


procedure TATMSheet.SG2DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
	if not (gdFixed in State) then
  	begin
    	fG1Align;
      fG2Align;
      fG3Align;
    end;
end;

end.
