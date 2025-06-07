unit ServerUtils;

interface

uses
  System.SysUtils,
  System.Classes,
  IdHashMessageDigest,
  System.NetEncoding,
  DateUtils;

function TiraZero(const aCodigo: string): string;
function MD5Sum(strValor: String): String;
function ExtractFormValue(const Body, Key: string): string;
function UltimoDiaDoMes(const APeriodo: string): TDateTime;

implementation

function TiraZero(const aCodigo: string): string;
var
  i: Integer;
begin
  Result := aCodigo;
  for i := 1 to Length(aCodigo) do
  begin
    if aCodigo[i] = '0' then
      Result[i] := ' '
    else
      Break;
  end;
  Result := Trim(Result);
end;

function ExtractFormValue(const Body, Key: string): string;
var
  Pairs: TArray<string>;
  Pair: string;
  V: string;
  i: Integer;
begin
  Result := '';
  Pairs := Body.Split(['&']);
  for i := 0 to Length(Pairs) - 1 do
  begin
    Pair := Pairs[i];
    if Pair.StartsWith(Key + '=') then
    begin
      V := Pair.Substring(Length(Key) + 1);
      Result := TNetEncoding.URL.Decode(V);
      Exit;
    end;
  end;
end;

function MD5Sum(strValor: String): String;
var
  idmd5 : TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    result := idmd5.HashStringAsHex(strValor);
  finally
    idmd5.Free;
  end;
end;

function UltimoDiaDoMes(const APeriodo: string): TDateTime;
var
  Data: TDateTime;
  Ano, Mes, Dia: Word;
begin
  Data := StrToDate('01/' + APeriodo);
  DecodeDate(Data, Ano, Mes, Dia);
  Result := EndOfAMonth(Ano, Mes);
end;

end. 