unit Routes.DFE;

interface

uses
  Horse,
  System.JSON,
  Controllers.DFE;

procedure Registry;

implementation

procedure rtfGetDFEResumo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Modelo, Periodo, Data: string;
  StatusCode: Integer;
  RespJSON: TJSONObject;
begin
  try
    Modelo := Req.Query['modelo'];
    Periodo := Req.Query['periodo'];
    Data := Req.Query['data'];

    RespJSON := TDFEController
                  .New
                  .GetDFEResumo(Modelo, Data, Periodo, StatusCode);
    Res.Send(RespJSON).Status(StatusCode);
  finally
  end;
end;

procedure Registry;
begin
  THorse.Post('/v1/dferesumo', rtfGetDFEResumo);
end;

end. 