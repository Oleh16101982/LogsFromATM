unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, clLogAcceptor1, frmPArsing1;

type
  TForm3 = class(TForm)
    Button1: TButton;
    M1: TMemo;
    Label1: TLabel;
    E1: TEdit;
    Label2: TLabel;
    E2: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    fLog : TLogAcceptor;

    procedure fWork;
    procedure fWorkStart;
    
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.Button1Click(Sender: TObject);
begin
 fWork;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
fLog := TLogAcceptor.Create('main' , '');
if Assigned(fLog) then fLog.Write('Program Started');

end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
if Assigned(fLog) then fLog.Free;

end;

procedure TForm3.fWork;
begin
  if true then
  	fWorkStart;

end;

procedure TForm3.fWorkStart;
begin
   frmParsing.ATMListJournal.Clear ;
//		frmParsing.ATMListJournal.Add('0'); // All ATMs in Work

			frmParsing.ATMListJournal.Add('1');
	  	frmParsing.ATMListJournal.Add('2');
	    frmParsing.ATMListJournal.Add('3');
  	  frmParsing.ATMListJournal.Add('4');
  	  frmParsing.ATMListJournal.Add('5');
      frmParsing.ATMListJournal.Add('7');
      frmParsing.ATMListJournal.Add('8');
      frmParsing.ATMListJournal.Add('9');
      frmParsing.ATMListJournal.Add('10');
      frmParsing.ATMListJournal.Add('11');
      frmParsing.ATMListJournal.Add('12');
			frmParsing.ATMListJournal.Add('15');
	    frmParsing.ATMListJournal.Add('16');
			frmParsing.ATMListJournal.Add('17');
  	  frmParsing.ATMListJournal.Add('18');
      frmParsing.ATMListJournal.Add('19');
  		frmParsing.ATMListJournal.Add('20');
	    frmParsing.ATMListJournal.Add('25');
  	  frmParsing.ATMListJournal.Add('26');
    	frmParsing.ATMListJournal.Add('27');
	    frmParsing.ATMListJournal.Add('35');
	  	frmParsing.ATMListJournal.Add('36');
	    frmParsing.ATMListJournal.Add('37');
  	  frmParsing.ATMListJournal.Add('38');
    	frmParsing.ATMListJournal.Add('39');
	    frmParsing.ATMListJournal.Add('44');
  	  frmParsing.ATMListJournal.Add('45');
    	frmParsing.ATMListJournal.Add('47');
  	  frmParsing.ATMListJournal.Add('51');
	    frmParsing.ATMListJournal.Add('53');
	    frmParsing.ATMListJournal.Add('68');
	  	frmParsing.ATMListJournal.Add('72');
    	frmParsing.ATMListJournal.Add('73');
	    frmParsing.ATMListJournal.Add('74');
	  	frmParsing.ATMListJournal.Add('75');

	frmParsing.Show;
  frmParsing.Server := E1.Text ;
  frmParsing.DataBase := E2.Text ;
  frmParsing.Provider := 'SQLOLEDB.1';
//	frmParsing.Parse($3B)
	frmParsing.Parse($3F);

end;

end.

