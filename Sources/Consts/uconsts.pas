unit uConsts;

interface

uses
    SysUtils,
    util.ini;

Const
 vUsername   = 'sousaautomacao';
 vPassword   = '##siscom26##';
 sepBarra    = '/';
 iVersaoDBAtual = 2;
 pdFormatodata = 'dd/mm/yyyy hh:mm:ss';
 pdFormatoDecimal = '.';
 pdFormatoJsonVazio = '{}';
 pdFormatoJsonTokenInvalido = '{"error":"Credencias de acesso invalida"}';

Var
  iQtdedeRequisicao:Integer;
  RetirarZerosCodigo:Boolean;


implementation

Initialization
   FormatSettings.ShortDateFormat:='dd/mm/yyyy';
   FormatSettings.DateSeparator := '/';
   FormatSettings.ThousandSeparator := '.';
   FormatSettings.DecimalSeparator := ',';
   RetirarZerosCodigo:= LerIni('CONFIG','retirazeros')='S';
Finalization


end.
