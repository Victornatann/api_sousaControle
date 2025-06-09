unit Routes.Produto;

interface

uses
  Horse,
  Controllers.Produto,
  System.JSON,
  System.SysUtils;

procedure Registry;

implementation

uses ServerUtils,
     EstoqueDTO;


function ParseEstoqueDTOFromQuery(const Req: THorseRequest): TEstoqueDTO;
begin
  Result := TEstoqueDTO.Create;
  Result.idemp       := StrToIntDef(Req.Query['idemp'], 0);
  Result.codproduto  := StrToIntDef(Req.Query['codproduto'], 0);
  Result.usuario     := Req.Query['usuario'];
  Result.dispositivo := Req.Query['dispositivo'];
  Result.estoque     := Req.Query['estoque'];
  Result.iddep       := StrToIntDef(Req.Query['iddep'], 0);
  Result.id_linha    := StrToIntDef(Req.Query['id_linha'], 0);
  Result.id_coluna   := StrToIntDef(Req.Query['id_coluna'], 0);
end;

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
    Res.Send<TJSONObject>(RespJSON).Status(StatusCode)

  finally
  end;
end;

procedure ContaEstoque(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
   DTO: TEstoqueDTO;
   StatusCode: Integer;
   RespJSON: TJSONObject;
begin
  DTO := ParseEstoqueDTOFromQuery(Req);
  try
    RespJSON := TProdutoController
                    .New
                    .ContarEstoque(DTO, StatusCode);
    Res.Send<TJSONObject>(RespJSON).Status(StatusCode);
  finally
  end;
end;

procedure GetGrupos(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  StatusCode: Integer;
  RespJSON: TJSONObject;
begin
  RespJSON := TProdutoController
                .New
                .GetGrupos(StatusCode);
  Res.Send<TJSONObject>(RespJSON).Status(StatusCode)
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
  Res.Send<TJSONObject>(RespJSON).Status(StatusCode)
end;

procedure Registry;
begin
  THorse.Post('/v1/produto', GetProduto);
  THorse.Post('/v1/produtos', GetProdutos);
  THorse.Post('/v1/grupos', GetGrupos);
  THorse.Post('/v1/zeraestoque', ZeraEstoque);
  THorse.Post('/v1/contaestoque', ContaEstoque);
end;

end.
