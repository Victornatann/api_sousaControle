unit Routes.Financeiro;

interface

uses
  Horse,
  System.JSON,
  Controllers.Inventario;

procedure Registry;

implementation

uses
  System.SysUtils, Controllers.Financeiro;

procedure GetDadosDash(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  CodEmp: Integer;
  BodyJSON: TJSONObject;
begin
  BodyJSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  CodEmp := BodyJSON.GetValue<Integer>('idempresa');
  Res.Send(
    TFinanceiroController.New.DadosDash(
      CodEmp,
      StatusCode
    )
  ).Status(StatusCode);
end;

procedure Registry;
begin
  THorse.Get('/v1/dash', GetDadosDash);
end;

end.
