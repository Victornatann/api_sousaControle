unit Routes.Caixa;

interface

uses
  Horse,
  System.JSON,
  Controllers.Caixa;

procedure Registry;

implementation

procedure rtfGetCaixaGeral(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  JsonObj: TJSONObject;
  StatusCode: Integer;
begin
  JsonObj :=
    TCaixaController
      .New
      .GetCaixaGeral(StatusCode);
  Res.Send(JsonObj).Status(StatusCode);
end;

procedure rtfGetCaixaGeralDia(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  JsonObj: TJSONObject;
  StatusCode: Integer;
  Data: string;
begin
  Data := Req.Query['data'];
  JsonObj := TCaixaController.New.GetCaixaGeralDia(Data, StatusCode);
  Res.Send(JsonObj).Status(StatusCode);
end;

procedure Registry;
begin
  THorse.Post('/v1/caixageraldia', rtfGetCaixaGeralDia);
  THorse.Post('/v1/caixageral', rtfGetCaixaGeral);
end;

end. 