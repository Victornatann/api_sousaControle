unit Controllers.Auth;

interface

uses
  Horse,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  System.JSON,
  System.SysUtils,
  EncdDecd,
  System.NetEncoding,
  udm;

type
  TAuthController = class
  private
    FDM: TDM;
    AccessLiberado: Boolean;
    constructor Create;
  public
    class function New: TAuthController;
    destructor Destroy; override;
    function PostLogin(const Req: THorseRequest; var aStatusCode: Integer): TJSONObject;
    function GetPermissao(var aStatusCode: Integer; const status: String; idusuario: Integer): TJSONObject;
    function AtualizarAutorizacao(
      const idAutorizacao, idUsuario: Integer;
      const acao, obs: string;
      var aStatusCode: Integer
    ): TJSONObject;
  end;

implementation

uses ServerUtils, uconsts;


class function TAuthController.New: TAuthController;
begin
  Result := Self.create;
end;

function TAuthController.AtualizarAutorizacao(const idAutorizacao,
  idUsuario: Integer; const acao, obs: string;
  var aStatusCode: Integer): TJSONObject;
var
  Query: TFDQuery;
  acaoParam: string;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  if not AccessLiberado then
  begin
    Result.AddPair('retorno', 'Token inválido');
    Exit;
  end;

  try
    Query := FDM.GetQuery();
    try
      Query.SQL.Text :=
        'update autorizacao set OBS_SUPERVISOR=:obs, id_supervisor=:idusuario, ' +
        'aprovado=:acao, data_conclusao=current_date ' +
        'where id_autorizacao=:idautorizacao';

      Query.ParamByName('idautorizacao').AsInteger := idAutorizacao;
      Query.ParamByName('idusuario').AsInteger := idUsuario;

      if acao = 'C' then
        acaoParam := 'N'
      else
        acaoParam := acao;

      Query.ParamByName('acao').AsString := acaoParam;
      Query.ParamByName('obs').AsString := obs;

      Query.ExecSQL;
      Result.AddPair('retorno', 'OK');
    finally
      Query.Free;
    end;
  except
    on E: Exception do
    begin
      Result.AddPair('retorno', 'Erro ao mudar acao de permissao');
    end;
  end;
end;

constructor TAuthController.Create;
begin
  FDM := TDM.Create(nil);
  AccessLiberado := True;
end;

destructor TAuthController.Destroy;
begin
  FDM.Free;
  inherited;
end;

function TAuthController.GetPermissao(
  var aStatusCode: Integer;
  const status: String;
  idusuario: Integer
): TJSONObject;
const
  header01 = 'select a.ID_AUTORIZACAO, a.data_solicitacao data, a.titulo, a.obs_usuario obs, aprovado, OBS_SUPERVISOR obssuperv ' +
             'from AUTORIZACAO a ' +
             'where aprovado = :status ' +
             'order by id_autorizacao';

  header02 = 'select a.ID_AUTORIZACAO, a.data_solicitacao data, a.titulo, a.obs_usuario obs, aprovado, OBS_SUPERVISOR obssuperv ' +
             'from AUTORIZACAO a ' +
             'where aprovado = :status and ID_SUPERVISOR = :id_supervisor ' +
             'order by data_conclusao desc';
var
  Query: TFDQuery;
  liberacaoArray: TJSONArray;
  itemObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  aStatusCode := 200;

  if not AccessLiberado then
  begin
     Exit(TJSONObject.ParseJSONValue(pdFormatoJsonTokenInvalido) as TJSONObject);
  end;

  Query := FDM.GetQuery();
  try
    Query.Close;
    Query.SQL.Clear;

    if status <> 'P' then
    begin
      Query.SQL.Text := header02;
      Query.ParamByName('id_supervisor').AsInteger := idusuario;
    end
    else
      Query.SQL.Text := header01;

    Query.ParamByName('status').AsString := status;
    Query.Open;

    liberacaoArray := TJSONArray.Create;
    try
      while not Query.EOF do
      begin
        itemObj := TJSONObject.Create;
        itemObj.AddPair('ID_AUTORIZACAO', TJSONNumber.Create(Query.FieldByName('ID_AUTORIZACAO').AsInteger));
        itemObj.AddPair('data', TJSONString.Create(Query.FieldByName('data').AsString));
        itemObj.AddPair('titulo', TJSONString.Create(Query.FieldByName('titulo').AsString));
        itemObj.AddPair('obs', TJSONString.Create(Query.FieldByName('obs').AsString));
        itemObj.AddPair('aprovado', TJSONString.Create(Query.FieldByName('aprovado').AsString));
        itemObj.AddPair('obssuperv', TJSONString.Create(Query.FieldByName('obssuperv').AsString));
        liberacaoArray.Add(itemObj);
        Query.Next;
      end;

      Result.AddPair('liberacao', liberacaoArray);
    except
      liberacaoArray.Free;
      raise;
    end;

  finally
    Query.Close;
    FreeAndNil(Query);
  end;
end;

function TAuthController.PostLogin(const Req: THorseRequest; var aStatusCode: Integer): TJSONObject;
Var
  Query, Query02: TFDQuery;
  JsonObj: TJSONObject;
  JsonArray: TJSONArray;
  IdUsuario: string;
  sUser, sSenha, sSerial, sToken: String;
const
  SQLStmt =
    'SELECT u.codigo, u.nome, u.login, u.superv, '+
     ' case '+
     '   when (select first 1 id_dispositivo from acesso_dispositivo d where upper(d.serie)=upper(:serial) and ativo=''S'') is not null then ''S'' '+
     '   else ''N'' '+
     ' end validoacesso, '+
     ' current_date datalogin '+
     ' FROM usuario u '+
   ' WHERE upper(u.login) = upper(:user) AND upper(u.senhamd5)=upper(:senha)';
begin
  try
    sUser := Req.Query['user'];
    sSenha := Req.Query['password'];
    sSerial := Req.Query['serial'];
    sToken := Req.Query['token'];


    Query := FDM.GetQuery();
    Query02 := FDM.GetQuery();
    try
      // Registra o acesso do dispositivo
      Query.SQL.Text := 'insert into ACESSO_DISPOSITIVOLOG(serie, sistema) values (:serial, :sistema)';
      Query.ParamByName('serial').AsString := sSerial;
      Query.ParamByName('sistema').AsString := 'APP Sousa Gestão';
      Query.ExecSQL;

      // Prepara parâmetros para login
      sUser := UpperCase(sUser);
      sSenha := UpperCase(MD5Sum(DecodeString(sSenha)));
      sSerial := sSerial;

      // Verifica login
      Query.SQL.Text := SQLStmt;
      Query.ParamByName('user').AsString := sUser;
      Query.ParamByName('senha').AsString := sSenha;
      Query.ParamByName('serial').AsString := sSerial;
      Query.Open();

      if Query.IsEmpty then
      begin
        Result := TJSONObject.Create;
        Result.AddPair('error', 'Credenciais inválidas');
        aStatusCode := 403;
        Exit;
      end;

      // Gera ou recupera token
      IdUsuario := Query.FieldByName('codigo').AsString;
      Query02.Close;
      Query02.SQL.Text := 'select token from UCTABUSERS_TOKEN where UCIDUSER=:ID and DATA_EXPIRA >= current_timestamp';
      Query02.ParamByName('ID').AsString := IdUsuario;
      Query02.Open();

      if Query02.IsEmpty then
      begin
        Query02.Close;
        Query02.SQL.Text := 'update or insert into UCTABUSERS_TOKEN (UCIDUSER, DATA_CRIACAO, DATA_EXPIRA, TOKEN) '+
                           'values (:UCIDUSER, current_timestamp, cast(current_timestamp + 1 as timestamp), :TOKEN) '+
                           'matching (UCIDUSER)';
        Query02.ParamByName('UCIDUSER').AsString := IdUsuario;
        Query02.ParamByName('TOKEN').AsString := MD5Sum(IdUsuario + DateTimeToStr(now));
        Query02.ExecSQL();

        Query02.Close;
        Query02.SQL.Text := 'select token from UCTABUSERS_TOKEN where UCIDUSER=:ID and DATA_EXPIRA >= current_timestamp';
        Query02.ParamByName('ID').AsString := IdUsuario;
        Query02.Open();
      end;

      // Monta retorno do usuário
      Result := TJSONObject.Create;
      JsonObj := TJSONObject.Create;
      JsonArray := TJSONArray.Create;
      try
        JsonObj.AddPair('codigo', Query.FieldByName('codigo').AsString);
        JsonObj.AddPair('nome', Query.FieldByName('nome').AsString);
        JsonObj.AddPair('login', Query.FieldByName('login').AsString);
        JsonObj.AddPair('superv', Query.FieldByName('superv').AsString);
        JsonObj.AddPair('validoacesso', Query.FieldByName('validoacesso').AsString);
        JsonObj.AddPair('datalogin', FormatDateTime('DD/MM/YYYY', Query.FieldByName('datalogin').AsDateTime));
        JsonObj.AddPair('tokenacesso', Query02.FieldByName('token').AsString);
        
        Result.AddPair('usuario', JsonObj);

        // Busca menu do usuário
        Query.Close;
        Query.SQL.Text := 'select * from view_mob_menu where id_usuario = ' + IdUsuario;
        Query.Open();

        while not(Query.Eof) do
        begin
          JsonObj := TJSONObject.Create;
          JsonObj.AddPair('id_recurso', TJSONNumber.Create(Query.FieldByName('id_recurso').AsInteger));
          JsonObj.AddPair('id_imagem', TJSONNumber.Create(Query.FieldByName('id_imagem').AsInteger));
          JsonObj.AddPair('recurso', Query.FieldByName('recurso').AsString);
          JsonArray.AddElement(JsonObj);
          Query.Next;
        end;
        
        Result.AddPair('menu', JsonArray);
      except
        JsonObj.Free;
        JsonArray.Free;
        raise;
      end;

      // Atualiza token no dispositivo
      Query.Close;
      Query.SQL.Text := 'update ACESSO_DISPOSITIVO set token=:token, id_usuario=:id_usuario where serie = :serial';
      Query.ParamByName('serial').AsString := sSerial;
      Query.ParamByName('token').AsString := Query02.FieldByName('token').AsString;
      Query.ParamByName('id_usuario').AsString := IdUsuario;
      Query.ExecSQL();
      aStatusCode := 200;

    finally
      Query.Close;
      Query02.Close;
      FreeAndNil(Query);
      FreeAndNil(Query02);
    end;

  except
    on E: Exception do
    begin
      Result := TJSONObject.Create;
      Result.AddPair('error', 'Erro ao processar login: ' + E.Message);
    end;
  end;
end;

end. 