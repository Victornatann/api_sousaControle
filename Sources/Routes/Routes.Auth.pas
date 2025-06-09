unit Routes.Auth;

interface

uses
  Horse,
  System.JSON,
  System.SysUtils,
  Controllers.Auth;

procedure Registry;

implementation

procedure rtfPostLogin(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  lStatusCode: Integer;
begin

  Res.Send<TJSONObject>(
     TAuthController
     .New
     .PostLogin(Req, lStatusCode)
  ).Status(LStatusCode);

end;

procedure AtualizarAutorizacao(Req: THorseRequest; Res: THorseResponse; next: TProc);
var
  LStatusCode: Integer;
  idAutorizacao, idUsuario: Integer;
  acao, obs: string;
begin
  idAutorizacao := StrToIntDef(req.Query.Items['idautorizacao'], 0);
  idUsuario := StrToIntDef(req.Query.Items['idusuario'], 0);
  acao := req.Query.Items['acao'];
  obs := req.Query.Items['obs'];

  Res.Send<TJSONObject>(
     TAuthController
     .New
     .AtualizarAutorizacao(idAutorizacao, idUsuario, acao, obs, LStatusCode)
  ).Status(LStatusCode);
end;

procedure rtfPostPermissaoSuperv(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
   LStatusCode: Integer;
   LStatus: string;
   LIdUsuario: Integer;
begin

  LStatus := req.Query['status'];
  LIdUsuario := StrToIntDef(req.Query['idusuario'], 0);

  Res.Send<TJSONObject>(
     TAuthController
     .New
     .GetPermissao(LStatusCode, LStatus, LIdUsuario)
  ).Status(LStatusCode);

end;


procedure Registry;
begin
  THorse.Post('/v1/login', rtfPostLogin);
  THorse.Post('/v1/permissaosuperv', rtfPostPermissaoSuperv);
  THorse.Post('/v1/permissaoret', AtualizarAutorizacao);
end;

end. 