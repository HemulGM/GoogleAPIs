unit GoogleAPIs;

interface

uses
  System.SysUtils, HGM.FastClientAPI, GoogleAPIs.UserInfo, GoogleAPIs.Drive,
  GoogleAPIs.Token;

type
  TGoogleAPI = class(TCustomAPI)
  public
    const
      BASE_API_URL = 'https://www.googleapis.com';
      AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
  private
    FDrive: TGoogleDriveRoute;
    FUserInfo: TUserInfoRoute;
    FTokens: TTokenRoute;
    FScope: string;
    FClientId: string;
    FClientSecret: string;
    FRedirectUri: string;
    FRefreshToken: string;
    function GetDrive: TGoogleDriveRoute;
    function GetUserInfo: TUserInfoRoute;
    procedure SetClientId(const Value: string);
    procedure SetClientSecret(const Value: string);
    procedure SetRedirectUri(const Value: string);
    procedure SetScope(const Value: string);
    function GetTokens: TTokenRoute;
    procedure SetRefreshToken(const Value: string);
  public
    property Drive: TGoogleDriveRoute read GetDrive;
    property UserInfo: TUserInfoRoute read GetUserInfo;
    property Tokens: TTokenRoute read GetTokens;
  public
    procedure Auth(Callback: TProc<Boolean, string>);
    function GetOAuth2Uri(const Offline: Boolean = True; const Force: Boolean = True): string;
    property ClientId: string read FClientId write SetClientId;
    property ClientSecret: string read FClientSecret write SetClientSecret;
    property RedirectUri: string read FRedirectUri write SetRedirectUri;
    property Scope: string read FScope write SetScope;
    property RefreshToken: string read FRefreshToken write SetRefreshToken;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  GoogleAPIs.OAuth2Server, System.Net.URLClient;

{ TGoogleAPI }

procedure TGoogleAPI.Auth(Callback: TProc<Boolean, string>);
begin
  try
    FRedirectUri := TGoogleOAuth2Server.Run(
      procedure(ACode, AError: string)
      begin
        var Error: string := AError;
        if not ACode.IsEmpty then
        try
          var Response := Tokens.GetByCode(ACode, ClientId, ClientSecret, FRedirectUri);
          if Assigned(Response) then
          try
            Token := Response.AccessToken;
            RefreshToken := Response.RefreshToken;
          finally
            Response.Free;
          end;
        except
          on E: Exception do
          begin
            Token := '';
            Error := E.Message;
          end;
        end;
        Callback(not Token.IsEmpty, Error);
      end);
    TGoogleOAuth2Server.StartOAuth2(GetOAuth2Uri);
  except
    on E: Exception do
      Callback(False, E.Message);
  end;
end;

constructor TGoogleAPI.Create;
begin
  inherited;
  BaseUrl := BASE_API_URL;
end;

destructor TGoogleAPI.Destroy;
begin
  TGoogleOAuth2Server.ProcCodeCallback := nil;
  TGoogleOAuth2Server.Stop;
  FDrive.Free;
  FUserInfo.Free;
  FTokens.Free;
  inherited;
end;

function TGoogleAPI.GetDrive: TGoogleDriveRoute;
begin
  if not Assigned(FDrive) then
    FDrive := TGoogleDriveRoute.CreateRoute(Self);
  Result := FDrive;
end;

function TGoogleAPI.GetOAuth2Uri(const Offline, Force: Boolean): string;
begin
  var URI := TURI.Create(AUTH_URL);
  URI.AddParameter('client_id', FClientId);
  URI.AddParameter('redirect_uri', FRedirectUri);
  URI.AddParameter('scope', FScope);
  URI.AddParameter('response_type', 'code');
  if Offline then
    URI.AddParameter('access_type', 'offline');
  if Force then
    URI.AddParameter('approval_prompt', 'force');
  URI.AddParameter('include_granted_scopes', 'true');
  Result := URI.Encode;
end;

function TGoogleAPI.GetTokens: TTokenRoute;
begin
  if not Assigned(FTokens) then
    FTokens := TTokenRoute.CreateRoute(Self);
  Result := FTokens;
end;

function TGoogleAPI.GetUserInfo: TUserInfoRoute;
begin
  if not Assigned(FUserInfo) then
    FUserInfo := TUserInfoRoute.CreateRoute(Self);
  Result := FUserInfo;
end;

procedure TGoogleAPI.SetClientId(const Value: string);
begin
  FClientId := Value;
end;

procedure TGoogleAPI.SetClientSecret(const Value: string);
begin
  FClientSecret := Value;
end;

procedure TGoogleAPI.SetRedirectUri(const Value: string);
begin
  FRedirectUri := Value;
end;

procedure TGoogleAPI.SetRefreshToken(const Value: string);
begin
  FRefreshToken := Value;
end;

procedure TGoogleAPI.SetScope(const Value: string);
begin
  FScope := Value;
end;

end.

