unit Routes.Produto;

interface

uses
  Horse,
  Controllers.Produto,
  System.JSON,
  System.SysUtils;

procedure Registry;

implementation

uses ServerUtils;

procedure GetProdutos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Grupo, Codigo, Descricao: String;
  IdEmpresa: Integer;
  LStatusCode : Integer;
  BodyJSON: String;
begin
  Grupo := Req.Query['pGrupo'];
  Codigo := Req.Query['pCodigo'];
  Descricao := Req.Query['pDescricao'];

  BodyJSON := Req.Body;
  IdEmpresa := ExtractFormValue(BodyJSON, 'idempresa').ToInteger();

  Res.Send<TJSONObject>(
     TProdutoController
     .New
     .GetProdutos(LStatusCode, Grupo, Codigo, Descricao, IdEmpresa)
  ).Status(LStatusCode);
end;

procedure GetProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  RespJSON: TJSONObject;
  Id: String;
  IdEmpresa: Integer;
  StatusCode: Integer;
  BodyJSON: String;
begin
  try
    BodyJSON := Req.Body;
    IdEmpresa := ExtractFormValue(BodyJSON, 'idempresa').ToInteger();
    Id := Req.Query['id'];

    RespJSON := TProdutoController
                  .New
                  .GetProduto(StatusCode, Id, IdEmpresa);
    Res.Send(RespJSON).Status(StatusCode)

  finally
  end;
end;

procedure ContaEstoque(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Controller: IProdutoController;
  Estoque, CodProduto, Usuario, Dispositivo: String;
  IdEmp, IdDep, IdLinha, IdColuna: Integer;
begin
  Estoque := Req.Query['estoque'];
  CodProduto := Req.Query['codproduto'];
  Usuario := Req.Query['usuario'];
  Dispositivo := Req.Query['dispositivo'];
  IdEmp := Req.Query['idemp'].ToInteger;
  IdDep := Req.Query['iddep'].ToInteger;
  IdLinha := Req.Query['idlinha'].ToInteger;
  IdColuna := Req.Query['idcoluna'].ToInteger;

  Controller := TProdutoController.Create;
  Res.Send(Controller.ContaEstoque(Estoque, CodProduto, Usuario, Dispositivo,
                                 IdEmp, IdDep, IdLinha, IdColuna).ToString);
end;

procedure GetGrupos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  RespJSON: TJSONObject;
begin
  RespJSON := TProdutoController
                .New
                .GetGrupos(StatusCode);
  Res.Send(RespJSON).Status(StatusCode)
end;

procedure ZeraEstoque(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  CodProduto, Usuario, Dispositivo: String;
  StatusCode: Integer;
  RespJSON: TJSONObject;
begin
  CodProduto := Req.Query['codproduto'];
  Usuario := Req.Query['usuario'];
  Dispositivo := Req.Query['dispositivo'];

  RespJSON := TProdutoController
                .New
                .ZeraEstoque(
                  StatusCode,
                  CodProduto,
                  Usuario,
                  Dispositivo
                );
  Res.Send(RespJSON).Status(StatusCode)
end;

procedure Registry;
begin
  THorse.Post('/v1/produto', GetProduto);
  THorse.Post('/v1/produtos', GetProdutos);
  THorse.Post('/v1/grupos', GetGrupos);
  THorse.Post('/v1/zeraestoque', ZeraEstoque);
  THorse.Post('/v1/produto/contaestoque', ContaEstoque);
end;

end.
