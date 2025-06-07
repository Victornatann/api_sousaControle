unit util.ini;

interface

uses
  System.SysUtils, System.IniFiles, System.Classes;

function LerIni(const aSecao, aChave: string): string;

implementation

function LerIni(const aSecao, aChave: string): string;
var
  IniFile: TIniFile;
begin
  Result := '';
  IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini');
  try
    Result := IniFile.ReadString(aSecao, aChave, '');
  finally
    IniFile.Free;
  end;
end;

end. 