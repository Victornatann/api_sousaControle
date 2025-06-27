unit Routes.Inventario;

interface

uses
  Horse,
  System.JSON,
  Controllers.Inventario;

procedure Registry;

implementation

uses
  System.SysUtils,
  ServerUtils;

procedure GetInventarios(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  LIdEmpresa: Integer;
begin
  LIdEmpresa := ExtractFormValue(Req.Body, 'idempresa').ToInteger();
  Res.Send(
    TInventarioController.New.GetInventarios(
      LIdEmpresa,
      StatusCode
    )
  ).Status(StatusCode);
end;

procedure PostInventarioItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  BodyJSON: TJSONObject;
begin
  BodyJSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  Res.Send(
    TInventarioController.New.PostInventarioItem(
      BodyJSON,
      StatusCode
    )
  ).Status(StatusCode);
end;

procedure GetInventarioItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  LIdEmpresa: Integer;
  LIdBalanco: Integer;
  BodyJSON: TJSONObject;
begin
  try
    BodyJSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    LIdEmpresa := BodyJSON.GetValue<Integer>('idempresa');
    LIdBalanco := Req.Params['id'].ToInteger();
    Res.Send(
      TInventarioController.New.GetItensInventario(
        LIdBalanco,
        LIdEmpresa,
        StatusCode
      )
    ).Status(StatusCode);
  except
  end;
end;

procedure DeleteItemInventario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  LItemID: Integer;
begin
  try
    LItemID := Req.Params['id'].ToInteger();

    Res.Send(
      TInventarioController.New.DeleteItemInventario(LItemID, StatusCode)
    ).Status(StatusCode);
  except
    on E: Exception do
      Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
  end;
end;

procedure PostInventario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  BodyJSON: TJSONObject;
begin
  try
    BodyJSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    if not Assigned(BodyJSON) then
    begin
      Res.Send('JSON inválido').Status(400);
      Exit;
    end;

    Res.Send(
      TInventarioController.New.PostInventario(
        BodyJSON,
        StatusCode
      )
    ).Status(StatusCode);
  except
    on E: Exception do
      Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
  end;
end;

procedure PutInventarioItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  BodyJSON: TJSONObject;
begin
  BodyJSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  try
    Res.Send(
      TInventarioController.New.PutInventarioItem(BodyJSON, StatusCode)
    ).Status(StatusCode);
  finally
    BodyJSON.Free;
  end;
end;

procedure Registry;
begin
  THorse.Post('/v1/inventarios', GetInventarios);
  THorse.Post('/v1/postInventario', PostInventario);
  THorse.Get('/v1/inventario-itens/:id', GetInventarioItem);
  THorse.Post('/v1/inventario-itens', PostInventarioItem);
  THorse.Delete('/v1/inventario-itens/:id', DeleteItemInventario);
  THorse.Put('/v1/inventario-itens', PutInventarioItem);
end;


end.
