unit GoogleAPIs.Auth;

interface

uses
  System.SysUtils, System.Classes, MARS.Core.Engine, MARS.http.Server.Indy,
  MARS.mORMotJWT.Token, MARS.Core.MessageBodyWriters, MARS.Core.Attributes,
  MARS.Core.MediaType, MARS.Core.Registry,
  MARS.Core.RequestAndResponse.Interfaces;

type
  [Path('auth')]
  TGoogleAuthRoute = class
    [Context]
    Request: IMARSRequest;
  public
    [GET]
    [Produces(TMediaType.TEXT_PLAIN)]
    function Auth: string;
  end;

var
  ProcTokenCallback: TProc<string> = nil;
  GOOGLE_CLIENT_ID: string;
  GOOGLE_SECRET: string;
  GOOGLE_AUTH_SCOPE: string;

const
  TOKEN_URL = 'https://oauth2.googleapis.com/token';
  AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
  LOCAL_SERVER_URL = 'http://localhost:8481/google/auth';

procedure RunServer;

procedure StopServer;

procedure StartGetTokenProcess;

implementation

uses
  System.Net.URLClient, Winapi.ShellAPI, System.JSON, System.Net.HttpClient;

var
  FEngine: MARS.Core.Engine.TMARSEngine;
  FServer: MARS.http.Server.Indy.TMARShttpServerIndy;

procedure StartGetTokenProcess;
begin
  RunServer;
  var URI := TURI.Create(AUTH_URL);
  URI.AddParameter('client_id', GOOGLE_CLIENT_ID);
  URI.AddParameter('redirect_uri', LOCAL_SERVER_URL);
  URI.AddParameter('scope', GOOGLE_AUTH_SCOPE);
  URI.AddParameter('response_type', 'code');
  URI.AddParameter('access_type', 'offline');
  URI.AddParameter('include_granted_scopes', 'true');

  ShellExecute(0, 'open', PChar(URI.Encode), nil, nil, 0);
end;

function GetAccessToken(const AAuthCode: string): string;
begin
  Result := AAuthCode;
  var HTTP := THTTPClient.Create;
  try
    var Params := TStringList.Create;
    try
      Params.AddPair('code', AAuthCode);
      Params.AddPair('client_id', GOOGLE_CLIENT_ID);
      Params.AddPair('client_secret', GOOGLE_SECRET);
      Params.AddPair('redirect_uri', LOCAL_SERVER_URL);
      Params.AddPair('grant_type', 'authorization_code');

      var Response := HTTP.Post(TOKEN_URL, Params);
      if Response.StatusCode <> 200 then
        raise Exception.Create(Response.StatusCode.ToString + ' - ' + Response.StatusText);

      var JSONObj := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      if Assigned(JSONObj) then
      try
        Result := JSONObj.GetValue('access_token').Value;
      finally
        JSONObj.Free;
      end;
    finally
      Params.Free;
    end;
  finally
    HTTP.Free;
  end;
end;

function TGoogleAuthRoute.Auth: string;
begin
  if Assigned(ProcTokenCallback) then
    ProcTokenCallback(GetAccessToken(Request.GetQueryParamValue('code')));
  Result := 'You can close this page.';
  StopServer;
end;

procedure RunServer;
begin
  StopServer;

  FEngine := MARS.Core.Engine.TMARSEngine.Create;
  FEngine.SetBasePath('/');
  FEngine.SetPort(8481);
  FEngine.AddApplication('DefaultAPI', '/google', ['*.TGoogleAuthRoute']);
  FServer := MARS.http.Server.Indy.TMARShttpServerIndy.Create(FEngine);

  FServer.Active := True;
end;

procedure StopServer;
begin
  if Assigned(FServer) then
  begin
    FServer.Active := False;
    FServer.Free;
    FServer := nil;
    FEngine := nil;
  end;
end;

initialization
  MARS.Core.Registry.TMARSResourceRegistry.Instance.RegisterResource<TGoogleAuthRoute>;

finalization
  StopServer;

end.

