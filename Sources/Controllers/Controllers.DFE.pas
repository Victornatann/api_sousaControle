unit Controllers.DFE;

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
  IDFEController = interface
    ['{12345678-1234-1234-1234-123456789ABC}']
    function GetDFEResumo(const Modelo, Data, Periodo: string; var aStatusCode: Integer): TJSONObject;
  end;

  TDFEController = class(TInterfacedObject, IDFEController)
  private
    FQuery: TFDQuery;
    FDM: TDM;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IDFEController;
    function GetDFEResumo(const Modelo, Data, Periodo: string; var aStatusCode: Integer): TJSONObject;
  end;

implementation

uses ServerUtils;

class function TDFEController.New: IDFEController;
begin
  Result := Self.Create;
end;

constructor TDFEController.Create;
begin
  FDM := TDM.Create(nil);
  FQuery := FDM.GetQuery;
end;

destructor TDFEController.Destroy;
begin
  FDM.Free;
  FQuery.Free;
  inherited;
end;

function TDFEController.GetDFEResumo(const Modelo, Data, Periodo: string; var aStatusCode: Integer): TJSONObject;
var
  Json: TJSONObject;
  JsonArray: TJSONArray;
  sFiltro: string;
  pData: TDate;
  rTotal: Currency;
begin
  Json := TJSONObject.Create;
  rTotal := 0;

  try
    if Modelo.IsEmpty then
    begin
      Json.AddPair('total', TJSONNumber.Create(0));
      Json.AddPair('resumo', TJSONArray.Create);
      aStatusCode := 400;
      Result := Json;
      Exit;
    end;

    // Filtro
    if not Data.IsEmpty then
    begin
      if SameText(Modelo, 'PED') or SameText(Modelo, 'TU') or SameText(Modelo, 'TP10') then
        sFiltro := ' WHERE t.tv_datavenda = ' + QuotedStr(Data)
      else if Modelo = 'TT' then
        sFiltro := ' WHERE cast(n.dtemissao as date) = ' + QuotedStr(Data)
      else if Modelo = 'Cupom' then
        sFiltro := ' WHERE ((n.modelo = ''59'') OR (n.modelo = ''65'')) AND cast(n.dtemissao as date) = ' + QuotedStr(Data)
      else
        sFiltro := ' WHERE n.modelo = :modelo AND cast(n.dtemissao as date) = ' + QuotedStr(Data);
    end
    else
    begin
      if SameText(Modelo, 'PED') or SameText(Modelo, 'TU') or SameText(Modelo, 'TP10') then
        sFiltro := ' WHERE t.tv_datavenda BETWEEN :inicio AND :fim'
      else if Modelo = 'TT' then
        sFiltro := ' WHERE n.dtemissao BETWEEN :inicio AND :fim'
      else if Modelo = 'Cupom' then
        sFiltro := ' WHERE ((n.modelo = ''59'') OR (n.modelo = ''65'')) AND n.dtemissao BETWEEN :inicio AND :fim'
      else
        sFiltro := ' WHERE n.modelo = :modelo AND n.dtemissao BETWEEN :inicio AND :fim';
    end;

    // SQL
    if Modelo = 'PED' then
    begin
      if not sFiltro.IsEmpty then
        sFiltro := sFiltro + ' AND ((t.tv_cancelado IS NULL) OR (t.tv_cancelado <> ''S''))';

      FQuery.SQL.Text :=
        'SELECT f.forma AS status, ' +
        ' ''PED'' AS modelo, COUNT(*) AS qtde, SUM(f.valor) AS total ' +
        'FROM formapgto f ' +
        'INNER JOIN tvenda t ON t.codvenda = f.codvenda ' + sFiltro +
        ' GROUP BY 1, 2';
    end
    else if Modelo = 'TP10' then
    begin
      FQuery.SQL.Text :=
        'SELECT FIRST 10 d.pro_codigo, d.pro_descricao, COUNT(*) AS qtde_item, ' +
        ' CAST(SUM(d.dv_qtde) AS NUMERIC(15,3)) AS qtde, ' +
        ' CAST(SUM(d.TOTALPROD) AS NUMERIC(15,2)) AS total, ' +
        ' CAST(AVG(d.DV_PRECO) AS NUMERIC(15,2)) AS preco_medio ' +
        'FROM dvenda_si_view d ' +
        'INNER JOIN tvenda t ON t.codvenda = d.codvenda ' + sFiltro +
        ' GROUP BY 1,2 ORDER BY 4 DESC';
    end
    else
    begin
      FQuery.SQL.Text :=
        'SELECT CASE ' +
        ' WHEN e.status IN (''Aguardando'', ''NAO ENVIADA'', ''NAO ENNVIADA'') THEN ''Aguardando'' ' +
        ' ELSE e.status END AS status, ' +
        ' n.modelo, COUNT(n.no_codigo) AS qtde, SUM(n.vltotnota) AS total ' +
        'FROM nnfe n ' +
        'INNER JOIN nnfestatus e ON e.no_codigo = n.no_codigo ' + sFiltro +
        ' GROUP BY 1, 2';
    end;

    // Parâmetros
    if FQuery.Params.FindParam('modelo') <> nil then
      FQuery.ParamByName('modelo').AsString := Modelo;
    if FQuery.Params.FindParam('inicio') <> nil then
    begin
      pData := StrToDate('01/' + Periodo);
      FQuery.ParamByName('inicio').AsDate := pData;
    end;
    if FQuery.Params.FindParam('fim') <> nil then
      FQuery.ParamByName('fim').AsDateTime := UltimoDiaDoMes(Periodo);

    FQuery.Open;

    // Monta JSON
    JsonArray := TJSONArray.Create;

    if Modelo = 'TP10' then
    begin
      while not FQuery.Eof do
      begin
        JsonArray.AddElement(
          TJSONObject.Create
            .AddPair('codigo', FQuery.FieldByName('pro_codigo').AsString)
            .AddPair('descricao', FQuery.FieldByName('pro_descricao').AsString)
            .AddPair('qtde_item', TJSONNumber.Create(FQuery.FieldByName('qtde_item').AsInteger))
            .AddPair('qtde', TJSONNumber.Create(FQuery.FieldByName('qtde').AsFloat))
            .AddPair('total', TJSONNumber.Create(FQuery.FieldByName('total').AsFloat))
            .AddPair('preco_medio', TJSONNumber.Create(FQuery.FieldByName('preco_medio').AsFloat))
        );
        FQuery.Next;
      end;
      Json.AddPair('resumo', JsonArray);
    end
    else
    begin
      while not FQuery.Eof do
      begin
        JsonArray.AddElement(
          TJSONObject.Create
            .AddPair('status', FQuery.FieldByName('status').AsString)
            .AddPair('modelo', FQuery.FieldByName('modelo').AsString)
            .AddPair('qtde', TJSONNumber.Create(FQuery.FieldByName('qtde').AsInteger))
            .AddPair('total', TJSONNumber.Create(FQuery.FieldByName('total').AsFloat))
        );
        rTotal := rTotal + FQuery.FieldByName('total').AsFloat;
        FQuery.Next;
      end;
      Json.AddPair('resumo', JsonArray);
      Json.AddPair('total', TJSONNumber.Create(rTotal));
    end;

    aStatusCode := 200;
    Result := Json;
  except
    on E: Exception do
    begin
      Json.Free;
      Result := TJSONObject.Create;
      Result.AddPair('error', 'Erro ao processar requisição: ' + E.Message);
      aStatusCode := 500;
    end;
  end;
end;

end. 