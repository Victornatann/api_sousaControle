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
end;

end. 