unit Controllers.Produto;

interface

uses
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  System.JSON,
  System.SysUtils,
  EstoqueDTO,
  udm;

type
  IProdutoController = interface
    function GetGrupos(var aStatusCode: Integer): TJSONObject;
    function GetProdutos(var aStatusCode: Integer;const pGrupo, pCodigo, pDescricao: String; const pIdEmpresa: Integer): TJSONObject;
    function GetProduto(var aStatusCode: Integer; const pId: String; pIdEmpresa: Integer): TJSONObject;
    function ZeraEstoque(var aStatusCode: Integer;const pCodProduto, pUsuario, pDispositivo: String): TJSONObject;
    function ContarEstoque(const DTO: TEstoqueDTO; out StatusCode: Integer): TJSONObject;
  end;

  TProdutoController = class(TInterfacedObject, IProdutoController)
  private
    FDM: TDM;
    FQuery: TFDQuery;
    AccessLiberado: Boolean;
    constructor Create;
  public
    class function New: IProdutoController;
    destructor Destroy; override;

    function GetProdutos(var aStatusCode: Integer;const pGrupo, pCodigo, pDescricao: String; const pIdEmpresa: Integer): TJSONObject;
    function GetProduto(var aStatusCode: Integer; const pId: String; pIdEmpresa: Integer): TJSONObject;
    function GetGrupos(var aStatusCode: Integer): TJSONObject;
    function ZeraEstoque(var aStatusCode: Integer;const pCodProduto, pUsuario, pDispositivo: String): TJSONObject;
    function ContarEstoque(const DTO: TEstoqueDTO; out StatusCode: Integer): TJSONObject;
  end;

implementation

uses
  ServerUtils,
  uconsts;

function TProdutoController.ContarEstoque(const DTO: TEstoqueDTO;
  out StatusCode: Integer): TJSONObject;
var
  sQtde:String;
  rQtde: Real;
begin
  try
    Result := TJSONObject.Create;
    try

      sQtde := StringReplace(DTO.estoque,'.','',[rfReplaceAll]);
      sQtde := StringReplace(sQtde,',','.',[rfReplaceAll]) ;
      rQtde := StrToFloat(sQtde);


      FQuery.SQL.Text := 'select pro_codigo from prod_grade where pro_codigo = ' + DTO.codproduto.ToString;
      FQuery.Open;

      if (FQuery.IsEmpty) or
         ((not FQuery.IsEmpty) and (DTO.id_linha > 0) and (DTO.id_coluna > 0)) then
      begin
        FQuery.Close;
        FQuery.SQL.Text := 'execute procedure PROC_CONTA_ESTOQUE(:idempresa,:procodigo,:usuario,' +
                          ':dispositivo, :qtde, :iddeposito, :idlinha, :idcoluna)';

        FQuery.ParamByName('idempresa').AsInteger  := DTO.idemp;
        FQuery.ParamByName('procodigo').AsInteger  := DTO.codproduto;
        FQuery.ParamByName('usuario').AsString     := DTO.usuario;
        FQuery.ParamByName('dispositivo').AsString := DTO.dispositivo;
        FQuery.ParamByName('qtde').AsFloat         := rQtde;
        FQuery.ParamByName('iddeposito').AsInteger := DTO.iddep;
        FQuery.ParamByName('idlinha').AsInteger    := DTO.id_linha;
        FQuery.ParamByName('idcoluna').AsInteger   := DTO.id_coluna;

        FQuery.ExecSQL;

        Result.AddPair('retorno', 'OK');
        StatusCode := 200;
      end
      else
      begin
        Result.AddPair('retorno', 'Produto possui Grade, não pode ser processado');
        StatusCode := 200;
      end;

    except
      on E: Exception do
      begin
        Result.AddPair('retorno', 'Erro ao contar estoque');
        Result.AddPair('erro', E.Message);
        StatusCode := 200;
      end;
    end;

  finally
  end;
end;

constructor TProdutoController.Create;
begin
  FDM := TDM.Create(nil);
  FQuery := FDM.GetQuery;
  AccessLiberado := True;
end;

destructor TProdutoController.Destroy;
begin
  FDM.Free;
  FQuery.Free;
  inherited;
end;

function TProdutoController.GetProdutos(var aStatusCode: Integer;const pGrupo, pCodigo, pDescricao: String; const pIdEmpresa: Integer): TJSONObject;
var
  Query: TFDQuery;
  sPesq: String;
  JsonArray: TJSONArray;
  JsonObj: TJSONObject;
const
  header = 'select first 100 p.pro_codigo, p.pro_descricao, p.pro_codbarra, e.pvenda, e.pcusto, e.estoque,'+
           ' g.gru_nome, m.ma_nome, e.ultima_saida, e.ultima_entrada, '+
           ' f.nome fornecedor, p.pro_embalagem '+
           ' from produto p '+
           ' inner join prod_estoque e on (e.pro_codigo = p.pro_codigo and e.id_empresa=:idempresa) '+
           ' left outer join grupo g on (g.gru_codigo = p.gru_codigo) '+
           ' left outer join marca m on (m.ma_codigo = p.ma_codigo) '+
           ' left outer join pessoas f on (f.id_pessoa = p.for_codigo)';
begin

  aStatusCode := 200;

  if not AccessLiberado then
    Exit(TJSONObject.ParseJSONValue(pdFormatoJsonTokenInvalido) as TJSONObject);

  if (pCodigo = '') and (pGrupo = '') and (pDescricao = '') then
    Exit(TJSONObject.ParseJSONValue(pdFormatoJsonVazio) as TJSONObject);

  Result := TJSONObject.Create;
  Query := FDM.GetQuery();
  try
    sPesq := ' where p.pro_excluido = ''N''';
    if pGrupo <> '' then
      sPesq := sPesq + ' and g.gru_codigo = :grupo';
    if pCodigo <> '' then
      sPesq := sPesq + ' and (p.pro_codigo = :codigo or p.pro_codbarra = :codigo)';
    if pDescricao <> '' then
      sPesq := sPesq + ' and p.pro_descricao like ''%''||:descricao||''%'' ';


    Query.SQL.Text := header + sPesq;
    
    if pGrupo <> '' then
      Query.ParamByName('grupo').AsString := pGrupo;
    if pCodigo <> '' then
      Query.ParamByName('codigo').AsString := pCodigo;
    if pDescricao <> '' then
      Query.ParamByName('descricao').AsString := pDescricao;
    Query.ParamByName('idempresa').AsInteger := pIdEmpresa;
    
    Query.Open;
    
    JsonArray := TJSONArray.Create;
    while not Query.Eof do
    begin
      JsonObj := TJSONObject.Create;
      JsonObj.AddPair('pro_codigo', TJSONNumber.Create(Query.FieldByName('pro_codigo').AsInteger));
      JsonObj.AddPair('pro_descricao', Query.FieldByName('pro_descricao').AsString);
      JsonObj.AddPair('pro_codbarra', Query.FieldByName('pro_codbarra').AsString);
      JsonObj.AddPair('pvenda', TJSONNumber.Create(Query.FieldByName('pvenda').AsFloat));
      JsonObj.AddPair('pcusto', TJSONNumber.Create(Query.FieldByName('pcusto').AsFloat));
      JsonObj.AddPair('estoque', TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));
      JsonObj.AddPair('gru_nome', Query.FieldByName('gru_nome').AsString);
      JsonObj.AddPair('ma_nome', Query.FieldByName('ma_nome').AsString);
      JsonObj.AddPair('ultima_saida', FormatDateTime('DD/MM/YYYY', Query.FieldByName('ultima_saida').AsDateTime));
      JsonObj.AddPair('ultima_entrada', FormatDateTime('DD/MM/YYYY', Query.FieldByName('ultima_entrada').AsDateTime));
      JsonObj.AddPair('fornecedor', Query.FieldByName('fornecedor').AsString);
      JsonObj.AddPair('pro_embalagem', Query.FieldByName('pro_embalagem').AsString);
      JsonArray.AddElement(JsonObj);
      Query.Next;
    end;

    Result.AddPair('produtos', JsonArray);
    aStatusCode := 200;
  finally
    Query.Free;
  end;
end;

class function TProdutoController.New: IProdutoController;
begin
  Result := Self.create;
end;

function TProdutoController.GetProduto(var aStatusCode: Integer; const pId: String; pIdEmpresa: Integer): TJSONObject;
var
  Json: TJSONObject;
  Query: TFDQuery;
  sCodigoPesquisa, sWhere, sHeader: String;
  idProduto, idEmpresa: Integer;
  ArrGrade: TJSONArray;
  ArrDeposito: TJSONArray;
  Item: TJSONObject;
begin
  Json := TJSONObject.Create;
  Query := FDM.GetQuery();
  aStatusCode := 200;
  try
    idEmpresa := pIdEmpresa;
    sCodigoPesquisa := pId.Trim;

    if RetirarZerosCodigo then
      sCodigoPesquisa := TiraZero(sCodigoPesquisa);

    if Length(sCodigoPesquisa) > 10 then
      sWhere := ' where p.pro_codbarra =:codigo and p.pro_excluido=''N'' '
    else if StrToIntDef(sCodigoPesquisa, 0) > 0 then
      sWhere := ' where ((p.pro_codigo=:codigo) or (p.pro_codbarra =:codigo)) and p.pro_excluido=''N'' '
    else
      sWhere := ' where p.pro_codbarra =:codigo and p.pro_excluido=''N'' ';

    sHeader :=
      'select p.pro_codigo, p.pro_descricao, p.pro_codbarra, e.pvenda, e.pcusto, e.estoque,' +
      ' g.gru_nome, m.ma_nome, e.ultima_saida, e.ultima_entrada, ' +
      ' f.nome fornecedor, p.pro_embalagem, e.margem, p.pro_usa_grade, p.pro_usa_serial,' +
      ' v.v00 qtde0d, v.v01 qtde1d, v.v07 qtde7d, v.v15 qtde15d, v.v30 qtde30d, v.v60 qtde60d, v.v90 qtde90d ' +
      ' from produto p ' +
      ' inner join prod_estoque e on (e.pro_codigo = p.pro_codigo and e.id_empresa=:idempresa) ' +
      ' left outer join grupo g on (g.gru_codigo = p.gru_codigo) ' +
      ' left outer join marca m on (m.ma_codigo = p.ma_codigo) ' +
      ' left outer join pessoas f on (f.id_pessoa = p.for_codigo) ' +
      ' left outer join view_qtdevendida v on (v.pro_codigo = p.pro_codigo and v.id_empresa=:idempresa) ';

    // Primeira tentativa
    Query.SQL.Text := sHeader + sWhere;
    Query.ParamByName('codigo').AsString := sCodigoPesquisa;
    Query.ParamByName('idempresa').AsInteger := idEmpresa;
    Query.Open;

    // Segunda tentativa: procurar na tabela de código de barras
    if Query.IsEmpty then
    begin
      Query.Close;
      Query.SQL.Text := 'select pro_codigo from codigobarra where pro_codbarra = :codigo';
      Query.ParamByName('codigo').AsString := sCodigoPesquisa;
      Query.Open;

      if not Query.IsEmpty then
      begin
        sCodigoPesquisa := Query.FieldByName('pro_codigo').AsString;
        Query.Close;
        Query.SQL.Text := sHeader + ' where p.pro_codigo = :codigo and p.pro_excluido=''N'' ';
        Query.ParamByName('codigo').AsString := sCodigoPesquisa;
        Query.ParamByName('idempresa').AsInteger := idEmpresa;
        Query.Open;
      end;
    end;

    if Query.IsEmpty then
      Exit(Json); // retorna objeto vazio se não encontrar

    idProduto := Query.FieldByName('pro_codigo').AsInteger;

    with Json do
    begin
      AddPair('pro_codigo', TJSONNumber.Create(idProduto));
      AddPair('pro_descricao', Query.FieldByName('pro_descricao').AsString);
      AddPair('pro_codbarra', Query.FieldByName('pro_codbarra').AsString);
      AddPair('pvenda', TJSONNumber.Create(Query.FieldByName('pvenda').AsFloat));
      AddPair('pcusto', TJSONNumber.Create(Query.FieldByName('pcusto').AsFloat));
      AddPair('estoque', TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));
      AddPair('gru_nome', Query.FieldByName('gru_nome').AsString);
      AddPair('ma_nome', Query.FieldByName('ma_nome').AsString);
      AddPair('ultima_saida', FormatDateTime('DD/MM/YYYY', Query.FieldByName('ultima_saida').AsDateTime));
      AddPair('ultima_entrada', FormatDateTime('DD/MM/YYYY', Query.FieldByName('ultima_entrada').AsDateTime));
      AddPair('fornecedor', Query.FieldByName('fornecedor').AsString);
      AddPair('pro_embalagem', Query.FieldByName('pro_embalagem').AsString);
      AddPair('margem', TJSONNumber.Create(Query.FieldByName('margem').AsFloat));
      AddPair('qtde0d', TJSONNumber.Create(Query.FieldByName('qtde0d').AsFloat));
      AddPair('qtde1d', TJSONNumber.Create(Query.FieldByName('qtde1d').AsFloat));
      AddPair('qtde7d', TJSONNumber.Create(Query.FieldByName('qtde7d').AsFloat));
      AddPair('qtde15d', TJSONNumber.Create(Query.FieldByName('qtde15d').AsFloat));
      AddPair('qtde30d', TJSONNumber.Create(Query.FieldByName('qtde30d').AsFloat));
      AddPair('qtde60d', TJSONNumber.Create(Query.FieldByName('qtde60d').AsFloat));
      AddPair('qtde90d', TJSONNumber.Create(Query.FieldByName('qtde90d').AsFloat));
      AddPair('usa_grade', Query.FieldByName('pro_usa_grade').AsString);
      AddPair('usa_serial', Query.FieldByName('pro_usa_serial').AsString);
    end;

    // Dados por depósito
    Query.Close;
    Query.SQL.Text :=
      'select e.id_deposito, e.qtde, d.descricao from PROD_DEPOSITO_SALDO e ' +
      'inner join prod_deposito d on d.id_deposito = e.id_deposito ' +
      'where e.pro_codigo = :codigo and e.id_empresa = :idempresa';
    Query.ParamByName('codigo').AsInteger := idProduto;
    Query.ParamByName('idempresa').AsInteger := idEmpresa;
    Query.Open;

    ArrDeposito := TJSONArray.Create;
    while not Query.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('id_deposito', TJSONNumber.Create(Query.FieldByName('id_deposito').AsInteger));
      Item.AddPair('descricao', Query.FieldByName('descricao').AsString);
      Item.AddPair('qtde', TJSONNumber.Create(Query.FieldByName('qtde').AsFloat));
      ArrDeposito.AddElement(Item);
      Query.Next;
    end;
    Json.AddPair('deposito', ArrDeposito);

    // Dados da grade
    Query.Close;
    Query.SQL.Text :=
      'select id_deposito, estoque, descricao linha, valor coluna, id_coluna, id_linha, id_grade ' +
      'from SEL_GRADE_PROD_DEPL(:codigo, :idempresa)';
    Query.ParamByName('codigo').AsInteger := idProduto;
    Query.ParamByName('idempresa').AsInteger := idEmpresa;
    Query.Open;

    ArrGrade := TJSONArray.Create;
    while not Query.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('id_deposito', TJSONNumber.Create(Query.FieldByName('id_deposito').AsInteger));
      Item.AddPair('linha', Query.FieldByName('linha').AsString);
      Item.AddPair('coluna', Query.FieldByName('coluna').AsString);
      Item.AddPair('id_coluna', TJSONNumber.Create(Query.FieldByName('id_coluna').AsInteger));
      Item.AddPair('id_linha', TJSONNumber.Create(Query.FieldByName('id_linha').AsInteger));
      Item.AddPair('id_grade', TJSONNumber.Create(Query.FieldByName('id_grade').AsInteger));
      Item.AddPair('estoque', TJSONNumber.Create(Query.FieldByName('estoque').AsFloat));
      ArrGrade.AddElement(Item);
      Query.Next;
    end;
    Json.AddPair('grade', ArrGrade);
    Result := Json;
  finally
    Query.Close;
    Query.Free;
  end;
end;

function TProdutoController.GetGrupos(var aStatusCode: Integer): TJSONObject;
var
  Query: TFDQuery;
  JsonArray: TJSONArray;
  JsonObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  Query := FDM.GetQuery();
  try
    Query.SQL.Text := 'select gru_codigo codigo, gru_nome descricao from grupo where gru_excluido=''N'' order by gru_nome';
    Query.Open;
    
    JsonArray := TJSONArray.Create;
    Result.AddPair('grupos', JsonArray);
    
    while not Query.Eof do
    begin
      JsonObj := TJSONObject.Create;
      JsonObj.AddPair('GRU_CODIGO', TJSONNumber.Create(Query.FieldByName('codigo').AsInteger));
      JsonObj.AddPair('GRU_NOME', Query.FieldByName('descricao').AsString);
      JsonArray.AddElement(JsonObj);
      Query.Next;
    end;

    aStatusCode := 200;
  finally
    Query.Free;
  end;
end;

function TProdutoController.ZeraEstoque(var aStatusCode: Integer;const pCodProduto, pUsuario, pDispositivo: String): TJSONObject;
var
  Query: TFDQuery;
begin
  Result := TJSONObject.Create;
  Query := FDM.GetQuery();
  try
    Query.SQL.Text := 'update produto set pro_estoque = 0 where pro_codigo = :codigo';
    Query.ParamByName('codigo').AsString := pCodProduto;
    Query.ExecSQL;
    
    Query.SQL.Text := 'insert into estoque_zerado (cod_produto, usuario, dispositivo, data) ' +
                     'values (:cod_produto, :usuario, :dispositivo, CURRENT_TIMESTAMP)';
    Query.ParamByName('cod_produto').AsString := pCodProduto;
    Query.ParamByName('usuario').AsString := pUsuario;
    Query.ParamByName('dispositivo').AsString := pDispositivo;
    Query.ExecSQL;
    
    Result.AddPair('retorno', 'OK');
    aStatusCode := 200;
  except
    on E: Exception do
    begin
      Result.AddPair('retorno', 'Erro ao zerar estoque');
      aStatusCode := 200;
    end;
  end;
  Query.Free;
end;

end. 