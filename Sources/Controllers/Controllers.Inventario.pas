unit Controllers.Inventario;

interface

uses
  Horse,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  System.JSON,
  System.SysUtils,
  udm;

type
  IInventarioController = interface
    ['{8958C5CC-7B9C-483F-85E4-0328B88121F3}']
    function GetInventarios(const CodEmp: Integer; var aStatusCode: Integer): TJSONObject;
    function PostInventarioItem(const ABody: TJSONObject;var aStatusCode: Integer): TJSONObject;
    function GetItensInventario(const ABalancoID: Integer; const ACodEmp: Integer; var aStatusCode: Integer): TJSONObject;
    function DeleteItemInventario(const AItemID: Integer;var aStatusCode: Integer): TJSONObject;
    function PostInventario(const ABody: TJSONObject;var aStatusCode: Integer): TJSONObject;
    function PutInventarioItem(const ABody: TJSONObject;var aStatusCode: Integer): TJSONObject;
  end;

  TInventarioController = class(TInterfacedObject, IInventarioController)
  private
    FQuery: TFDQuery;
    FDM: TDM;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IInventarioController;
    function GetInventarios(const CodEmp: Integer; var aStatusCode: Integer): TJSONObject;
    function PostInventarioItem(const ABody: TJSONObject; var aStatusCode: Integer): TJSONObject;
    function GetItensInventario(const ABalancoID: Integer; const ACodEmp: Integer;var aStatusCode: Integer): TJSONObject;
    function DeleteItemInventario(const AItemID: Integer;var aStatusCode: Integer): TJSONObject;
    function PostInventario(const ABody: TJSONObject;var aStatusCode: Integer): TJSONObject;
    function PutInventarioItem(const ABody: TJSONObject;var aStatusCode: Integer): TJSONObject;

  end;

implementation

{ TInventarioController }

constructor TInventarioController.Create;
begin
  FDM := TDM.Create(nil);
  FQuery := FDM.GetQuery;
end;

function TInventarioController.DeleteItemInventario(const AItemID: Integer;
  var aStatusCode: Integer): TJSONObject;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  try
    if not FQuery.Connection.Connected then
      FQuery.Connection.Connected := True;
    FQuery.Connection.StartTransaction;

    // Verifica se existe
    FQuery.SQL.Text := 'SELECT COUNT(*) AS total FROM ESTOQUE_BALANCO_I WHERE id = :id';
    FQuery.ParamByName('id').AsInteger := AItemID;
    FQuery.Open;

    if FQuery.FieldByName('total').AsInteger = 0 then
    begin
      FQuery.Connection.Rollback;
      aStatusCode := 404;
      Result.AddPair('error', 'Item não encontrado.');
      Exit;
    end;

    // Deleta
    FQuery.SQL.Text := 'DELETE FROM ESTOQUE_BALANCO_I WHERE ID = :ID';
    FQuery.ParamByName('id').AsInteger := AItemID;
    FQuery.ExecSQL;

    FQuery.Connection.Commit;
    Result.AddPair('message', 'Item removido com sucesso.');
  except
    on E: Exception do
    begin
      FQuery.Connection.Rollback;
      aStatusCode := 500;
      Result.AddPair('error', 'Erro ao remover item: ' + E.Message);
    end;
  end;
end;

destructor TInventarioController.Destroy;
begin
  FDM.Free;
  FQuery.Free;
  inherited;
end;

function TInventarioController.GetInventarios(
  const CodEmp: Integer;
  var aStatusCode: Integer
): TJSONObject;

var
  JsonArray: TJSONArray;
  JsonObj: TJSONObject;

begin
  Result := TJSONObject.Create;
  aStatusCode := 200;
  try
    FQuery.SQL.Text := 
      'SELECT '+
      '  ID, '+
      '  ID_EMPRESA, '+
      '  DATA, '+
      '  STATUS, '+
      '  OBS '+
      'FROM ESTOQUE_BALANCO '+
      'WHERE Status = 0 '+
      '  AND ID_EMPRESA = :IDEMPRESA '+
      'ORDER BY ID';
    FQuery.ParamByName('idempresa').AsInteger := CodEmp;
    FQuery.Open;

    JsonArray := TJSONArray.Create;
    while not FQuery.Eof do
    begin
      JsonObj := TJSONObject.Create;
      JsonObj.AddPair('id', TJSONNumber.Create(FQuery.FieldByName('ID').AsFloat));
      JsonObj.AddPair('idEmpresa', TJSONNumber.Create(FQuery.FieldByName('ID_EMPRESA').AsFloat));
      JsonObj.AddPair('data', FormatDateTime('DD/MM/YYYY', FQuery.FieldByName('DATA').AsDateTime));
      JsonObj.AddPair('status', TJSONNumber.Create(FQuery.FieldByName('STATUS').AsFloat));
      JsonObj.AddPair('obs', FQuery.FieldByName('OBS').AsString);
      JsonArray.AddElement(JsonObj);
      FQuery.Next;
    end;
    Result.AddPair('inventarios', JsonArray);
  finally
  end;
end;

function TInventarioController.GetItensInventario(
  const ABalancoID,
  ACodEmp: Integer;
  var aStatusCode: Integer
): TJSONObject;
var
  JsonArray: TJSONArray;
  JsonObj, ProdutoObj, ItemObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  FQuery.SQL.Text :=
    'SELECT '+
    '   i.id, '+
    '   i.id_balanco, '+
    '   i.id_deposito, '+
    '   i.pro_codigo, '+
    '   i.qtde, '+
    '   i.estoque, '+
    '   i.perca_ganho, '+
    '   i.obs, '+
    '   gl.descricao grade_linha, '+
    '   gc.descricao grade_coluna, '+
    '   i.inc_data, '+
    '   i.inc_user, '+
    '   i.alt_data, '+
    '   i.alt_user, '+
    '   p.pro_descricao, '+
    '   p.pro_codbarra, '+
    '   e.pvenda, '+
    '   e.pcusto, '+
    '   e.estoque AS estoque_atual, '+
    '   g.gru_nome, '+
    '   m.ma_nome, '+
    '   e.ultima_saida, '+
    '   e.ultima_entrada, '+
    '   f.nome AS fornecedor, '+
    '   p.pro_embalagem '+
    'FROM ESTOQUE_BALANCO_I i '+
    'JOIN produto p ON p.pro_codigo = i.pro_codigo '+
    'inner join prod_estoque e on (e.pro_codigo = p.pro_codigo and e.id_empresa=:idempresa) '+
    'left outer join grupo g on (g.gru_codigo = p.gru_codigo) '+
    'left outer join marca m on (m.ma_codigo = p.ma_codigo) '+
    'left outer join pessoas f on (f.id_pessoa = p.for_codigo) '+
    'left outer join prod_grade_linha gl on (gl.id_linha = i.grade_linha and gl.pro_codigo = i.pro_codigo ) '+
    'left outer join prod_grade_coluna gc on (gc.id_coluna = i.grade_coluna and gc.pro_codigo = i.pro_codigo) '+
    'WHERE i.id_balanco = :id_balanco';

  FQuery.ParamByName('id_balanco').AsInteger := ABalancoID;
  FQuery.ParamByName('idempresa').AsInteger := ACodEmp;
  FQuery.Open;

  JsonArray := TJSONArray.Create;
  while not FQuery.Eof do
  begin
    ProdutoObj := TJSONObject.Create;
    ProdutoObj.AddPair('pro_codigo', TJSONNumber.Create(FQuery.FieldByName('pro_codigo').AsInteger));
    ProdutoObj.AddPair('pro_descricao', FQuery.FieldByName('pro_descricao').AsString);
    ProdutoObj.AddPair('pro_codbarra', FQuery.FieldByName('pro_codbarra').AsString);
    ProdutoObj.AddPair('pvenda', TJSONNumber.Create(FQuery.FieldByName('pvenda').AsFloat));
    ProdutoObj.AddPair('pcusto', TJSONNumber.Create(FQuery.FieldByName('pcusto').AsFloat));
    ProdutoObj.AddPair('estoque', TJSONNumber.Create(FQuery.FieldByName('estoque_atual').AsFloat));
    ProdutoObj.AddPair('gru_nome', FQuery.FieldByName('gru_nome').AsString);
    ProdutoObj.AddPair('ma_nome', FQuery.FieldByName('ma_nome').AsString);
    ProdutoObj.AddPair('ultima_saida', FormatDateTime('DD/MM/YYYY', FQuery.FieldByName('ultima_saida').AsDateTime));
    ProdutoObj.AddPair('ultima_entrada', FormatDateTime('DD/MM/YYYY', FQuery.FieldByName('ultima_entrada').AsDateTime));
    ProdutoObj.AddPair('fornecedor', FQuery.FieldByName('fornecedor').AsString);
    ProdutoObj.AddPair('pro_embalagem', FQuery.FieldByName('pro_embalagem').AsString);

    ItemObj := TJSONObject.Create;
    ItemObj.AddPair('id', TJSONNumber.Create(FQuery.FieldByName('id').AsInteger));
    ItemObj.AddPair('idBalanco', TJSONNumber.Create(FQuery.FieldByName('id_balanco').AsInteger));
    ItemObj.AddPair('idDeposito', TJSONNumber.Create(FQuery.FieldByName('id_deposito').AsInteger));
    ItemObj.AddPair('qtde', TJSONNumber.Create(FQuery.FieldByName('qtde').AsFloat));
    ItemObj.AddPair('estoque', TJSONNumber.Create(FQuery.FieldByName('estoque').AsFloat));
    ItemObj.AddPair('percaGanho', TJSONNumber.Create(FQuery.FieldByName('perca_ganho').AsFloat));
    ItemObj.AddPair('obs', FQuery.FieldByName('obs').AsString);
    ItemObj.AddPair('gradeLinha', FQuery.FieldByName('grade_linha').AsString);
    ItemObj.AddPair('gradeColuna', FQuery.FieldByName('grade_coluna').AsString);
    ItemObj.AddPair('incData', FormatDateTime('DD/MM/YYYY HH:NN', FQuery.FieldByName('inc_data').AsDateTime));
    ItemObj.AddPair('incUser', FQuery.FieldByName('inc_user').AsString);
    ItemObj.AddPair('altData', FormatDateTime('DD/MM/YYYY HH:NN', FQuery.FieldByName('alt_data').AsDateTime));
    ItemObj.AddPair('altUser', FQuery.FieldByName('alt_user').AsString);

    JsonObj := TJSONObject.Create;
    JsonObj.AddPair('produto', ProdutoObj);
    JsonObj.AddPair('item', ItemObj);
    JsonArray.AddElement(JsonObj);

    FQuery.Next;
  end;

  Result.AddPair('itens', JsonArray);
end;

class function TInventarioController.New: IInventarioController;
begin
  Result := Self.Create;
end;

function TInventarioController.PostInventario(
  const ABody: TJSONObject;
  var aStatusCode: Integer
): TJSONObject;
var
  LObs: string;
  LIdEmpresa, LNewID: Integer;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  try
    // Lê dados obrigatórios
    LIdEmpresa := ABody.GetValue<Integer>('idempresa');
    LObs := ABody.GetValue<string>('obs', '');

    if not FQuery.Connection.Connected then
      FQuery.Connection.Connected := True;
    FQuery.Connection.StartTransaction;

    // Gera ID novo (supondo Firebird com generator ou uso de SELECT MAX)
    FQuery.SQL.Text := 'SELECT GEN_ID(GEN_ESTOQUE_BALANCO_ID, 1) AS NEW_ID FROM RDB$DATABASE';
    FQuery.Open;
    LNewID := FQuery.FieldByName('NEW_ID').AsInteger;

    // Insere o inventário
    FQuery.SQL.Text :=
      'INSERT INTO ESTOQUE_BALANCO (' +
      '  ID, ID_EMPRESA, DATA, STATUS, OBS' +
      ') VALUES (' +
      '  :ID, :ID_EMPRESA, :DATA, :STATUS, :OBS' +
      ')';
    FQuery.ParamByName('ID').AsInteger := LNewID;
    FQuery.ParamByName('ID_EMPRESA').AsInteger := LIdEmpresa;
    FQuery.ParamByName('DATA').AsDateTime := Now;
    FQuery.ParamByName('STATUS').AsInteger := 0;
    FQuery.ParamByName('OBS').AsString := LObs;
    FQuery.ExecSQL;

    FQuery.Connection.Commit;

    Result.AddPair('message', 'Inventário criado com sucesso');
    Result.AddPair('id', TJSONNumber.Create(LNewID));
  except
    on E: Exception do
    begin
      FQuery.Connection.Rollback;
      aStatusCode := 500;
      Result.AddPair('error', 'Erro ao criar inventário: ' + E.Message);
    end;
  end;
end;

function TInventarioController.PostInventarioItem
(
  const ABody: TJSONObject;
  var aStatusCode: Integer
): TJSONObject;
var
  LIDBalanco, LIDDeposito: Integer;
  LProCodigo, LObs: string;
  LEstoque, LQtde, LQtdeTotal: Double;
  LGradeLinha, LGradeColuna: Integer;
  LPercaGanho: Double;
  LCodUser: Integer;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  try
    // Lê valores
    LIDBalanco := ABody.GetValue<Integer>('idBalanco');
    LIDDeposito := ABody.GetValue<Integer>('idDeposito');
    LProCodigo := ABody.GetValue<string>('proCodigo');
    LEstoque := ABody.GetValue<Double>('estoque');
    LQtde := ABody.GetValue<Double>('qtde');
    LGradeLinha := ABody.GetValue<Integer>('gradeLinha', 0);
    LGradeColuna := ABody.GetValue<Integer>('gradeColuna', 0);
    LObs := ABody.GetValue<string>('obs', '');
    LCodUser := ABody.GetValue<Integer>('codUser');

    if not FQuery.Connection.Connected then
      FQuery.Connection.Connected := True;
    FQuery.Connection.StartTransaction;

    FQuery.SQL.Text :=
      'SELECT QTDE FROM ESTOQUE_BALANCO_I ' +
      'WHERE ID_BALANCO = :ID_BALANCO ' +
      '  AND PRO_CODIGO = :PRO_CODIGO ' +
      '  AND GRADE_LINHA = :GRADE_LINHA ' +
      '  AND GRADE_COLUNA = :GRADE_COLUNA';
    FQuery.ParamByName('ID_BALANCO').AsInteger := LIDBalanco;
    FQuery.ParamByName('PRO_CODIGO').AsString := LProCodigo;
    FQuery.ParamByName('GRADE_LINHA').AsInteger := LGradeLinha;
    FQuery.ParamByName('GRADE_COLUNA').AsInteger := LGradeColuna;
    FQuery.Open;

    if not FQuery.IsEmpty then
    begin
      LQtdeTotal := FQuery.FieldByName('QTDE').AsFloat + LQtde;
      LPercaGanho := LQtdeTotal - LEstoque;

      FQuery.SQL.Text :=
        'UPDATE ESTOQUE_BALANCO_I SET ' +
        '  QTDE = :QTDE, ' +
        '  ALT_DATA = :ALT_DATA, ' +
        '  ALT_USER = :ALT_USER, ' +
        '  OBS = :OBS, ' +
        '  PERCA_GANHO = :PERCA_GANHO ' +
        'WHERE ID_BALANCO = :ID_BALANCO ' +
        '  AND PRO_CODIGO = :PRO_CODIGO ' +
        '  AND GRADE_LINHA = :GRADE_LINHA ' +
        '  AND GRADE_COLUNA = :GRADE_COLUNA';

      FQuery.ParamByName('QTDE').AsFloat := LQtdeTotal;
      FQuery.ParamByName('ALT_DATA').AsDateTime := Now;
      FQuery.ParamByName('ALT_USER').AsInteger := LCodUser;
      FQuery.ParamByName('OBS').AsString := LObs;
      FQuery.ParamByName('PERCA_GANHO').AsFloat := LPercaGanho;
      FQuery.ParamByName('ID_BALANCO').AsInteger := LIDBalanco;
      FQuery.ParamByName('PRO_CODIGO').AsString := LProCodigo;
      FQuery.ParamByName('GRADE_LINHA').AsInteger := LGradeLinha;
      FQuery.ParamByName('GRADE_COLUNA').AsInteger := LGradeColuna;
    end
    else
    begin
      LPercaGanho := LQtde - LEstoque;

      FQuery.SQL.Text :=
        'INSERT INTO ESTOQUE_BALANCO_I (' +
        '  ID_BALANCO, ID_DEPOSITO, PRO_CODIGO, ESTOQUE, QTDE, ' +
        '  GRADE_LINHA, GRADE_COLUNA, OBS, INC_DATA, INC_USER, PERCA_GANHO' +
        ') VALUES (' +
        '  :ID_BALANCO, :ID_DEPOSITO, :PRO_CODIGO, :ESTOQUE, :QTDE, ' +
        '  :GRADE_LINHA, :GRADE_COLUNA, :OBS, :INC_DATA, :INC_USER, :PERCA_GANHO' +
        ')';

      FQuery.ParamByName('ID_BALANCO').AsInteger := LIDBalanco;
      FQuery.ParamByName('ID_DEPOSITO').AsInteger := LIDDeposito;
      FQuery.ParamByName('PRO_CODIGO').AsString := LProCodigo;
      FQuery.ParamByName('ESTOQUE').AsFloat := LEstoque;
      FQuery.ParamByName('QTDE').AsFloat := LQtde;
      FQuery.ParamByName('GRADE_LINHA').AsInteger := LGradeLinha;
      FQuery.ParamByName('GRADE_COLUNA').AsInteger := LGradeColuna;
      FQuery.ParamByName('OBS').AsString := LObs;
      FQuery.ParamByName('INC_DATA').AsDateTime := Now;
      FQuery.ParamByName('INC_USER').AsInteger := LCodUser;
      FQuery.ParamByName('PERCA_GANHO').AsFloat := LPercaGanho;
    end;

    FQuery.ExecSQL;
    FQuery.Connection.Commit;

    Result.AddPair('message', 'Item salvo com sucesso.');
  except
    on E: Exception do
    begin
      FQuery.Connection.Rollback;
      aStatusCode := 500;
      Result.AddPair('error', 'Erro ao salvar item: ' + E.Message);
    end;
  end;
end;

function TInventarioController.PutInventarioItem(const ABody: TJSONObject;
  var aStatusCode: Integer): TJSONObject;
var
  LID: Integer;
  LNovaQtde, LPercaGanho, LEstoque: Double;
  LCodUser: Integer;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  try

    LID := ABody.GetValue<Integer>('idItem');
    LNovaQtde := ABody.GetValue<Double>('qtde');
    LCodUser := ABody.GetValue<Integer>('codUser');

    if not FQuery.Connection.Connected then
      FQuery.Connection.Connected := True;
    FQuery.Connection.StartTransaction;

    FQuery.SQL.Text :=
      'SELECT ESTOQUE FROM ESTOQUE_BALANCO_I WHERE ID = :ID';

    FQuery.ParamByName('ID').AsInteger := LID;
    FQuery.Open;

    if FQuery.IsEmpty then
    begin
      aStatusCode := 404;
      Result.AddPair('error', 'Item do inventário não encontrado.');
      Exit;
    end;

    LEstoque := FQuery.FieldByName('ESTOQUE').AsFloat;
    LPercaGanho := LNovaQtde - LEstoque;

    // Atualiza
    FQuery.SQL.Text :=
      'UPDATE ESTOQUE_BALANCO_I SET ' +
      '  QTDE = :QTDE, ' +
      '  PERCA_GANHO = :PERCA_GANHO, ' +
      '  ALT_DATA = :ALT_DATA, ' +
      '  ALT_USER = :ALT_USER ' +
      'WHERE ID = :ID';

    FQuery.ParamByName('QTDE').AsFloat := LNovaQtde;
    FQuery.ParamByName('PERCA_GANHO').AsFloat := LPercaGanho;
    FQuery.ParamByName('ALT_DATA').AsDateTime := Now;
    FQuery.ParamByName('ALT_USER').AsInteger := LCodUser;
    FQuery.ParamByName('ID').AsInteger := LID;

    FQuery.ExecSQL;
    FQuery.Connection.Commit;

    Result.AddPair('message', 'Item atualizado com sucesso.');
  except
    on E: Exception do
    begin
      FQuery.Connection.Rollback;
      aStatusCode := 500;
      Result.AddPair('error', 'Erro ao atualizar item: ' + E.Message);
    end;
  end;
end;

end.
