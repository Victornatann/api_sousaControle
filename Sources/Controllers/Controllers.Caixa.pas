unit Controllers.Caixa;

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
  ICaixaController = interface
    ['{87654321-4321-4321-4321-CBA987654321}']
    function GetCaixaGeral(var aStatusCode: Integer): TJSONObject;
    function GetCaixaGeralDia(const aData: string; var aStatusCode: Integer): TJSONObject;
  end;

  TCaixaController = class(TInterfacedObject, ICaixaController)
  private
    FQuery: TFDQuery;
    AccessLiberado: Boolean;
    FDM: TDM;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: ICaixaController;
    function GetCaixaGeral(var aStatusCode: Integer): TJSONObject;
    function GetCaixaGeralDia(const aData: string; var aStatusCode: Integer): TJSONObject;

  end;

implementation

uses
  uconsts;

class function TCaixaController.New: ICaixaController;
begin
  Result := Self.Create;
end;

constructor TCaixaController.Create;
begin
  AccessLiberado := True;
  FDM := TDM.Create(nil);
  FQuery := FDM.GetQuery;
end;

destructor TCaixaController.Destroy;
begin
  FDM.Free;
  FQuery.Free;
  inherited;
end;

function TCaixaController.GetCaixaGeral(var aStatusCode: Integer): TJSONObject;
var
  Json: TJSONObject;
  AberturasArray: TJSONArray;
  Obj: TJSONObject;
  iQtdeCaixa, iQtdeVd: Integer;
  rTotal, rDispo, rSangria: Double;
begin

  if not AccessLiberado then
  begin
     Exit(TJSONObject.ParseJSONValue(pdFormatoJsonTokenInvalido) as TJSONObject);
  end;

  Json := TJSONObject.Create;
  AberturasArray := TJSONArray.Create;

  iQtdeCaixa := 0;
  iQtdeVd := 0;
  rTotal := 0;
  rDispo := 0;
  rSangria := 0;

  try
    FQuery.SQL.Text :=
      'SELECT ' +
      ' codabertura, ' +
      ' codcaixa, ' +
      ' sum(t.qtde_venda) qtdevenda, ' +
      ' sum(t.total_venda) total, ' +
      ' sum(t.qtde_cancelada) qtde_cancelada, ' +
      ' sum(t.total_cancelada) total_cancelada, ' +
      ' sum(t.qtde_interrompida) qtde_interrompida, ' +
      ' sum(t.total_interrompida) total_interrompida, ' +
      ' sum(t.disponivel) disponivel, ' +
      ' sum(t.sangria) sangria ' +
      'FROM view_cx_app_total t ' +
      'WHERE status = ''ABERTO'' ' +
      'GROUP BY 2,1';

    FQuery.Open;
    while not FQuery.Eof do
    begin
      Inc(iQtdeCaixa);
      iQtdeVd := iQtdeVd + FQuery.FieldByName('qtdevenda').AsInteger;
      rTotal := rTotal + FQuery.FieldByName('total').AsFloat;
      rDispo := rDispo + FQuery.FieldByName('disponivel').AsFloat;
      rSangria := rSangria + FQuery.FieldByName('sangria').AsFloat;

      Obj := TJSONObject.Create;
      Obj.AddPair('codabertura', TJSONNumber.Create(FQuery.FieldByName('codabertura').AsInteger));
      Obj.AddPair('codcaixa', TJSONNumber.Create(FQuery.FieldByName('codcaixa').AsInteger));
      Obj.AddPair('qtdevenda', TJSONNumber.Create(FQuery.FieldByName('qtdevenda').AsInteger));
      Obj.AddPair('total', TJSONNumber.Create(FQuery.FieldByName('total').AsFloat));
      Obj.AddPair('disponivel', TJSONNumber.Create(FQuery.FieldByName('disponivel').AsFloat));
      Obj.AddPair('sangria', TJSONNumber.Create(FQuery.FieldByName('sangria').AsFloat));
      Obj.AddPair('qtde_interrompida', TJSONNumber.Create(FQuery.FieldByName('qtde_interrompida').AsInteger));
      Obj.AddPair('total_interrompida', TJSONNumber.Create(FQuery.FieldByName('total_interrompida').AsFloat));
      Obj.AddPair('qtde_cancelada', TJSONNumber.Create(FQuery.FieldByName('qtde_cancelada').AsInteger));
      Obj.AddPair('total_cancelada', TJSONNumber.Create(FQuery.FieldByName('total_cancelada').AsFloat));
      AberturasArray.AddElement(Obj);

      FQuery.Next;
    end;

    Json.AddPair('aberturas', AberturasArray);
    Json.AddPair('qtdecaixa', TJSONNumber.Create(iQtdeCaixa));
    Json.AddPair('qtdevenda', TJSONNumber.Create(iQtdeVd));
    Json.AddPair('total', TJSONNumber.Create(rTotal));
    Json.AddPair('disponivel', TJSONNumber.Create(rDispo));
    Json.AddPair('sangria', TJSONNumber.Create(rSangria));

    Result := Json;
    aStatusCode := 200;
  except
    Json.Free;
    raise;
  end;
end;

function TCaixaController.GetCaixaGeralDia(const aData: string; var aStatusCode: Integer): TJSONObject;
var
  AberturasArray: TJSONArray;
  AberturaObj: TJSONObject;
  ResultObj: TJSONObject;
  iQtdeCaixa, iQtdeVd: Integer;
  rTotal, rDispo, rSangria: Currency;
begin
  ResultObj := TJSONObject.Create;
  AberturasArray := TJSONArray.Create;

  if not AccessLiberado then
  begin
    ResultObj.AddPair('error', 'Token inválido');
    aStatusCode := 401;
    Exit(ResultObj);
  end;

  try
    iQtdeCaixa := 0;
    iQtdeVd := 0;
    rTotal := 0;
    rDispo := 0;
    rSangria := 0;

    FQuery.SQL.Text :=
      'select ' +
      '  t.codabertura, ' +
      '  t.codcaixa, ' +
      '  t.data_abertura, ' +
      '  t.data_fechamento, ' +
      '  sum(t.qtde_venda) as qtdevenda, ' +
      '  sum(t.total_venda) as total, ' +
      '  sum(t.qtde_cancelada) as qtde_cancelada, ' +
      '  sum(t.total_cancelada) as total_cancelada, ' +
      '  sum(t.qtde_interrompida) as qtde_interrompida, ' +
      '  sum(t.total_interrompida) as total_interrompida, ' +
      '  sum(t.disponivel) as disponivel, ' +
      '  sum(t.sangria) as sangria ' +
      'from view_cx_app2_total t ' +
      'where t.status = ''FECHADO'' and t.data_abertura = :DATA ' +
      'group by t.codabertura, t.codcaixa, t.data_abertura, t.data_fechamento';
    FQuery.ParamByName('DATA').AsString := aData;
    FQuery.Open;

    while not FQuery.Eof do
    begin
      Inc(iQtdeCaixa);
      Inc(iQtdeVd, FQuery.FieldByName('qtdevenda').AsInteger);
      rTotal := rTotal + FQuery.FieldByName('total').AsFloat;
      rDispo := rDispo + FQuery.FieldByName('disponivel').AsFloat;
      rSangria := rSangria + FQuery.FieldByName('sangria').AsFloat;

      AberturaObj := TJSONObject.Create;
      AberturaObj.AddPair('data_abertura', FQuery.FieldByName('data_abertura').AsString);
      AberturaObj.AddPair('data_fechamento', FQuery.FieldByName('data_fechamento').AsString);
      AberturaObj.AddPair('codabertura', TJSONNumber.Create(FQuery.FieldByName('codabertura').AsInteger));
      AberturaObj.AddPair('codcaixa', TJSONNumber.Create(FQuery.FieldByName('codcaixa').AsInteger));
      AberturaObj.AddPair('qtdevenda', TJSONNumber.Create(FQuery.FieldByName('qtdevenda').AsInteger));
      AberturaObj.AddPair('total', TJSONNumber.Create(FQuery.FieldByName('total').AsFloat));
      AberturaObj.AddPair('disponivel', TJSONNumber.Create(FQuery.FieldByName('disponivel').AsFloat));
      AberturaObj.AddPair('sangria', TJSONNumber.Create(FQuery.FieldByName('sangria').AsFloat));
      AberturaObj.AddPair('qtde_interrompida', TJSONNumber.Create(FQuery.FieldByName('qtde_interrompida').AsInteger));
      AberturaObj.AddPair('total_interrompida', TJSONNumber.Create(FQuery.FieldByName('total_interrompida').AsFloat));
      AberturaObj.AddPair('qtde_cancelada', TJSONNumber.Create(FQuery.FieldByName('qtde_cancelada').AsInteger));
      AberturaObj.AddPair('total_cancelada', TJSONNumber.Create(FQuery.FieldByName('total_cancelada').AsFloat));

      AberturasArray.AddElement(AberturaObj);
      FQuery.Next;
    end;

    ResultObj.AddPair('aberturas', AberturasArray);
    ResultObj.AddPair('qtdecaixa', TJSONNumber.Create(iQtdeCaixa));
    ResultObj.AddPair('qtdevenda', TJSONNumber.Create(iQtdeVd));
    ResultObj.AddPair('total', TJSONNumber.Create(rTotal));
    ResultObj.AddPair('disponivel', TJSONNumber.Create(rDispo));
    ResultObj.AddPair('sangria', TJSONNumber.Create(rSangria));

    aStatusCode := 200;
  finally
  end;

  Result := ResultObj;
end;

end. 