# ServerApiErp

API REST desenvolvida em Delphi usando o framework Horse.

## Requisitos

- Delphi 10.4 ou superior
- FireDAC (incluído no Delphi)
- Boss (Boss Installer for Delphi)

## Instalação

1. Instale o Boss através do comando:
   ```
   iwr https://raw.githubusercontent.com/HashLoad/boss/master/install.ps1 -useb | iex
   ```

2. Instale as dependências do projeto:
   ```
   boss install
   ```

3. Configure o arquivo `config.ini` com as credenciais do seu banco de dados Firebird
4. Compile o projeto

## Configuração

Edite o arquivo `config.ini` com as configurações do seu banco de dados:

```ini
[DATABASE]
Database=C:\caminho\para\seu\banco.fdb
User_Name=SYSDBA
Password=sua_senha
```

## Endpoints

### GET /produtos
Retorna uma lista dos primeiros 100 produtos cadastrados.

Resposta:
```json
[
  {
    "pro_codigo": "string",
    "gru_codigo": "string",
    "pro_descricao": "string",
    "pro_pvenda": number,
    "pro_embalagem": "string",
    "pro_estoque": number
  }
]
```

## Executando

1. Compile o projeto
2. Execute o arquivo gerado
3. O servidor iniciará na porta 8082
4. Acesse http://localhost:8082/produtos para testar "# api_sousaControle" 
