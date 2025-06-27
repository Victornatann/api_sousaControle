unit Controllers.Financeiro;

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
  IFinanceiroController = interface
    ['{9C4C6510-A680-4359-867E-9AD910857944}']
    function DadosDash(const ACodEmp: Integer; var aStatusCode: Integer): TJSONObject;

  end;

  TFinanceiroController = class(TInterfacedObject, IFinanceiroController)
  private
    FQuery: TFDQuery;
    FDM: TDM;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IFinanceiroController;
    function DadosDash(const ACodEmp: Integer; var aStatusCode: Integer): TJSONObject;

  end;

implementation

{ TInventarioController }

constructor TFinanceiroController.Create;
begin
  FDM := TDM.Create(nil);
  FQuery := FDM.GetQuery;
end;

function TFinanceiroController.DadosDash(const ACodEmp: Integer;
  var aStatusCode: Integer): TJSONObject;
var
  JsonArray: TJSONArray;
  JsonObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  try
    JsonArray := TJSONArray.Create;

    FQuery.SQL.Text :=
      'SELECT ' +
      '  1 tipo, ' +
      '  COUNT(*) qtde_venda, ' +
      '  AVG(t.tv_vtotal) ticket_medio, ' +
      '  SUM(t.tv_vtotal) total ' +
      'FROM tvenda t ' +
      'WHERE t.tv_datavenda = current_date ' +
      '  AND t.tv_cancelado = ''N'' ' +

      'UNION ALL ' +

      'SELECT ' +
      '  2 tipo, ' +
      '  COUNT(*) qtde_venda, ' +
      '  AVG(t.tv_vtotal) ticket_medio, ' +
      '  SUM(t.tv_vtotal) total ' +
      'FROM tvenda t ' +
      'WHERE t.tv_datavenda >= (current_date - 7) ' +
      '  AND t.tv_cancelado = ''N''';

    FQuery.Open;

    while not FQuery.Eof do
    begin
      JsonObj := TJSONObject.Create;
      JsonObj.AddPair('tipo', TJSONNumber.Create(FQuery.FieldByName('tipo').AsInteger));
      JsonObj.AddPair('qtde_venda', TJSONNumber.Create(FQuery.FieldByName('qtde_venda').AsInteger));
      JsonObj.AddPair('ticket_medio', TJSONNumber.Create(FQuery.FieldByName('ticket_medio').AsFloat));
      JsonObj.AddPair('total', TJSONNumber.Create(FQuery.FieldByName('total').AsFloat));
      JsonArray.AddElement(JsonObj);
      FQuery.Next;
    end;

    Result.AddPair('dash', JsonArray);

  except
    on E: Exception do
    begin
      aStatusCode := 500;
      Result.AddPair('error', 'Erro ao buscar dados do dashboard: ' + E.Message);
    end;
  end;
end;

destructor TFinanceiroController.Destroy;
begin
  FDM.Free;
  FQuery.Free;
  inherited;
end;

class function TFinanceiroController.New: IFinanceiroController;
begin
  Result := Self.Create;
end;

end.
