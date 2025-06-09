program ServerApiErp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.Jhonson,
  Data.DB,
  Vcl.Forms,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  System.JSON,
  System.Classes,
  System.IniFiles,
  udm in 'Sources\DmServer\udm.pas' {dm: TDataModule},
  Routes.Auth in 'Sources\Routes\Routes.Auth.pas',
  Routes.Produto in 'Sources\Routes\Routes.Produto.pas',
  Routes.Caixa in 'Sources\Routes\Routes.Caixa.pas',
  Routes.DFE in 'Sources\Routes\Routes.DFE.pas',
  Controllers.Auth in 'Sources\Controllers\Controllers.Auth.pas',
  Controllers.Caixa in 'Sources\Controllers\Controllers.Caixa.pas',
  Controllers.DFE in 'Sources\Controllers\Controllers.DFE.pas',
  Controllers.Produto in 'Sources\Controllers\Controllers.Produto.pas',
  util.ini in 'Sources\Utils\util.ini.pas',
  ServerUtils in 'Sources\Utils\ServerUtils.pas',
  uconsts in 'Sources\Consts\uconsts.pas',
  EstoqueDTO in 'Sources\DTO\EstoqueDTO.pas';

const Porta = 8087;

procedure OnListen();
begin
  WriteLn('Servidor rodando na porta ' + Porta.ToString());
end;

begin
  try
    try
      THorse.Use(Jhonson());
      Routes.Auth.Registry;
      Routes.Caixa.Registry;
      Routes.DFE.Registry;
      Routes.Produto.Registry;

      THorse.Listen(Porta, OnListen);
    finally
    end;
  except
    on E: Exception do
    begin
      WriteLn(E.Message);
      ReadLn;
    end;
  end;
end. 