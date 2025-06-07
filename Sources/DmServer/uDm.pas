unit uDm;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Phys.IBBase, FireDAC.Comp.UI, System.IniFiles;

type
  TDM = class(TDataModule)
    FDConnection: TFDConnection;
    FDGUIxWaitCursor: TFDGUIxWaitCursor;
    FDPhysFBDriverLink: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure ConfigurarConexao;
  public
    { Public declarations }
    function GetQuery: TFDQuery;
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDM.ConfigurarConexao;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'siscom.ini');
  try
    FDConnection.Params.Clear;
    FDConnection.Params.Add('DriverID=FB');
    FDConnection.Params.Add('CharacterSet=UTF8');
    FDConnection.Params.Add('Protocol=Local');
    FDConnection.Params.Database := IniFile.ReadString('BANCO_SERVIDOR', 'Diretorio', '');
    FDConnection.Params.UserName := 'SYSDBA';

    case IniFile.ReadInteger('BANCO_SERVIDOR', 'senhapadrao', 0) of
      0: FDConnection.Params.Password := 'masterkey';
      1: FDConnection.Params.Password := 'siscom26';
      2: FDConnection.Params.Password := '##siscom26';
    else
      FDConnection.Params.Password := 'masterkey';
    end;

    FDConnection.Params.Values['Server'] := IniFile.ReadString('BANCO_SERVIDOR', '127.0.0.1', '');
    FDConnection.Params.Values['Port'] := IniFile.ReadString('BANCO_SERVIDOR', 'Porta', '3050');
    //FDConnection.Params.Values['Protocol'] := IniFile.ReadString('BANCO_SERVIDOR', 'driver', 'firebird');
    //FDConnection.Params.Values['LibraryLocation'] := IniFile.ReadString('BANCO_SERVIDOR', 'DiretorioDLL', '');
  finally
    IniFile.Free;
  end;
end;

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  ConfigurarConexao;
end;

function TDM.GetQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FDConnection;
  Result.Close;
  Result.SQL.Clear;
end;

end.
