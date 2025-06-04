unit GoogleAPIs.OAuth2Server;

interface

uses
  System.SysUtils, System.Classes, MARS.Core.Engine, MARS.http.Server.Indy,
  MARS.Core.MessageBodyWriters, MARS.Core.Attributes, MARS.Core.MediaType,
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

  TGoogleOAuth2Server = class
    class var
      Engine: MARS.Core.Engine.TMARSEngine;
      Server: MARS.http.Server.Indy.TMARShttpServerIndy;
      ProcCodeCallback: TProc<string>;
  public
    class function Run(Callback: TProc<string>): string;
    class procedure Stop;
    class procedure StartOAuth2(const Uri: string);
  end;

var
  DefaultAuthPort: Word = 8481;

implementation

uses
  Winapi.ShellAPI, MARS.Core.Registry, MARS.mORMotJWT.Token;

{ TGoogleAuthRoute }

function TGoogleAuthRoute.Auth: string;
begin
  if Assigned(TGoogleOAuth2Server.ProcCodeCallback) then
    TGoogleOAuth2Server.ProcCodeCallback(Request.GetQueryParamValue('code'));
  Result := 'You can close this page.';
end;

{ TGoogleOAuth2Server }

class procedure TGoogleOAuth2Server.StartOAuth2(const Uri: string);
begin
  ShellExecute(0, 'open', PChar(Uri), nil, nil, 0);
end;

class function TGoogleOAuth2Server.Run(Callback: TProc<string>): string;
begin
  Stop;

  ProcCodeCallback := Callback;

  Engine := MARS.Core.Engine.TMARSEngine.Create;
  Engine.SetBasePath('/');
  Engine.SetPort(DefaultAuthPort);
  Engine.AddApplication('DefaultAPI', '/google', ['*.TGoogleAuthRoute']);
  Server := MARS.http.Server.Indy.TMARShttpServerIndy.Create(Engine);

  Server.Active := True;

  Result := Format('http://localhost:%d/google/auth', [DefaultAuthPort]);
end;

class procedure TGoogleOAuth2Server.Stop;
begin
  if Assigned(Server) then
  begin
    Server.Active := False;
    Server.Free;
    Server := nil;
    Engine := nil;
  end;
end;

initialization
  MARS.Core.Registry.TMARSResourceRegistry.Instance.RegisterResource<TGoogleAuthRoute>;

finalization
  TGoogleOAuth2Server.Stop;

end.

