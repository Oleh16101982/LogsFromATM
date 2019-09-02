program LogFromATM;

uses
  Forms,
  main in 'main.pas' {Form3},
  clLogAcceptor1 in 'clLogAcceptor1.pas',
  clParseJournal1 in 'clParseJournal1.pas',
  clParseReceipt1 in 'clParseReceipt1.pas',
  clThFTP in 'clThFTP.pas',
  clThreadParseJournal1 in 'clThreadParseJournal1.pas',
  clThreadParseReceipt1 in 'clThreadParseReceipt1.pas',
  frmParsing1 in 'frmParsing1.pas' {frmParsing},
  clThCopyBilbo1 in 'clThCopyBilbo1.pas',
  clATMSheet1 in 'clATMSheet1.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
//  Application.CreateForm(TfrmParsing, frmParsing);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TfrmParsing, frmParsing);
  Application.Run;
end.
