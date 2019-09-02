unit clLogAcceptor1;

interface
uses SysUtils, Dialogs ;
type
	ELogAcceptorException = class(Exception)
  	eErrCode : Integer;
    eErrMsg : String;
  private
  	constructor Create(ErrCode : Integer ; ErrMsg : String );
	public

end;
type
	TLogAcceptor = class
  	private
    	fStr : String;
      fLogDir  : String;
			fLogFile : String;
      fLogLines : Cardinal;
      fLogDays	: Word;
      fLogFullFileName : String;
    public
			constructor Create(MaskName : String ; LogDir : String);

      procedure fCheckDir(Directory : String);
      procedure fCreateFullName;
      procedure fCheckFile;
    	procedure Write(Str : String);

      property LogDir : String read fLogDir write fLogDir;
      property LogFile : String read fLogFile write fLogFile ;
      property LogLines : Cardinal read fLogLines write fLogLines  default 10000;
      property LogDays	: Word read fLogDays write fLogDays  default 30;
      property LogFullFileName	: String read fLogFullFileName write fLogFullFileName;
end;

implementation

{ LogAcceptor }

constructor TLogAcceptor.Create(MaskName : String ; LogDir : String);
begin
	inherited Create;
  if Length(LogDir) = 0 then
	  fLogDir := 'LOGS\'
  else
  	fLogDir := LogDir + '\LOGS\';
  fLogFile := '_' + MaskName + '.log';
  fCheckDir(fLogDir);
  fCreateFullName;
  fCheckFile;
end;

procedure TLogAcceptor.fCheckDir(Directory: String);
begin
  if not DirectoryExists(fLogDir) then
    if not CreateDir(fLogDir) then
    	raise ElogAcceptorException.Create(100 , 'Cannot create c:\temp');
end;

procedure TLogAcceptor.fCheckFile;
var
	F : TextFile;
begin
	AssignFile(F , fLogFullFileName);
  if not FileExists(fLogFullFileName) then
  	Rewrite(F)
  else
  	Append(F);
  CloseFile(F);
end;

procedure TLogAcceptor.fCreateFullName;
var
	yy , mm , dd : Word;
	syy , smm , sdd : String;
begin
	DecodeDate(NOW , yy , mm , dd);
  syy := IntToStr(yy);
  if mm < 10 then
  	smm := '0' + IntToStr(mm)
  else
  	smm := IntToStr(mm);

  if dd < 10 then
  	sdd := '0' + IntToStr(dd)
  else
  	sdd := IntToStr(dd);
  fLogFullFileName := fLogDir + syy + smm + sdd + fLogFile;
end;

procedure TLogAcceptor.Write(Str: String);
var
f : TextFile;
begin
	fCreateFullName;
	AssignFile(F , fLogFullFileName);
  if not FileExists(fLogFullFileName) then
  	Rewrite(F)
  else
  	Append(F);
  Writeln(F , FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz' , Now) + '. ' + Str);
  Flush(F);
  CloseFile(F);

end;

{ ELogAcceptorException }

constructor ELogAcceptorException.Create(ErrCode: Integer; ErrMsg: String);
begin
 inherited Create('WriteLog Exception');
 eErrCode	:= ErrCode;
 eErrMsg 	:= ErrMsg ;
end;

end.
 