unit GoogleAPIs.Token;

interface

uses
  System.Classes, Rest.Json, Rest.Json.Types, HGM.FastClientAPI, System.Net.Mime;

type
  TTokenParams = class(TFastMultipartFormData);

  TTokenResponse = class
  private
    [JsonNameAttribute('access_token')]
    FAccessToken: string;
    [JsonNameAttribute('expires_in')]
    FExpiresIn: UInt64;
    [JsonNameAttribute('refresh_token_expires_in')]
    FRefreshTokenExpiresIn: UInt64;
    [JsonNameAttribute('scope')]
    FScope: string;
    [JsonNameAttribute('token_type')]
    FTokenType: string;
    [JsonNameAttribute('id_token')]
    FIdToken: string;
    [JsonNameAttribute('refresh_token')]
    FRefreshToken: string;
  public
    property AccessToken: string read FAccessToken write FAccessToken;
    property ExpiresIn: UInt64 read FExpiresIn write FExpiresIn;
    property Scope: string read FScope write FScope;
    property TokenType: string read FTokenType write FTokenType;
    property IdToken: string read FIdToken write FIdToken;
    property RefreshToken: string read FRefreshToken write FRefreshToken;
    property RefreshTokenExpiresIn: UInt64 read FRefreshTokenExpiresIn write FRefreshTokenExpiresIn;
  end;

  TTokenRoute = class(TAPIRoute)
    function GetByCode(const Code, ClientId, ClientSecret, RedirectUri: string): TTokenResponse;
    function Refresh(const RefreshToken, ClientId, ClientSecret: string): TTokenResponse; overload;
    procedure Refresh; overload;
    procedure Revoke(const Token: string); overload;
    procedure Revoke; overload;
  end;

implementation

uses
  GoogleAPIs;

{ TTokenRoute }

function TTokenRoute.GetByCode(const Code, ClientId, ClientSecret, RedirectUri: string): TTokenResponse;
begin
  Result := API.PostForm<TTokenResponse, TTokenParams>('https://oauth2.googleapis.com/token',
    procedure(Params: TTokenParams)
    begin
      Params.AddField('code', Code);
      Params.AddField('client_id', ClientId);
      Params.AddField('client_secret', ClientSecret);
      Params.AddField('redirect_uri', RedirectUri);
      Params.AddField('grant_type', 'authorization_code');
    end);
end;

function TTokenRoute.Refresh(const RefreshToken, ClientId, ClientSecret: string): TTokenResponse;
begin
  Result := API.PostForm<TTokenResponse, TTokenParams>('https://oauth2.googleapis.com/token',
    procedure(Params: TTokenParams)
    begin
      Params.AddField('client_id', ClientId);
      Params.AddField('client_secret', ClientSecret);
      Params.AddField('refresh_token', RefreshToken);
      Params.AddField('grant_type', 'refresh_token');
    end);
end;

procedure TTokenRoute.Refresh;
begin
  var Response := Refresh(TGoogleAPI(API).RefreshToken, TGoogleAPI(API).ClientId, TGoogleAPI(API).ClientSecret);
  if Assigned(Response) then
  try
    TGoogleAPI(API).AccessToken := Response.AccessToken;
  finally
    Response.Free;
  end;
end;

procedure TTokenRoute.Revoke;
begin
  Revoke(TGoogleAPI(API).AccessToken);
end;

procedure TTokenRoute.Revoke(const Token: string);
begin
  API.PostForm<TObject, TTokenParams>('https://oauth2.googleapis.com/revoke',
    procedure(Params: TTokenParams)
    begin
      Params.AddField('token', Token);
    end).Free;
end;

end.

