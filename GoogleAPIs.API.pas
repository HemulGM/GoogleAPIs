unit GoogleAPIs.API;

interface

uses
  System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Net.Mime,
  System.JSON, System.SysUtils, System.Types, System.RTTI, REST.JsonReflect,
  REST.Json.Interceptors, System.Generics.Collections;

type
  TJSONInterceptorStringToString = class(TJSONInterceptor)
    constructor Create; reintroduce;
  protected
    RTTI: TRttiContext;
  end;

type
  TJSONParam = class
  private
    FJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
    function GetCount: Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Add(const Key: string; const Value: string): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: Integer): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: Extended): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: Boolean): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: TDateTime; Format: string): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: TJSONValue): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: TJSONParam): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<string>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<Integer>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<Extended>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<TJSONValue>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<TJSONParam>): TJSONParam; overload; virtual;
    function GetOrCreateObject(const Name: string): TJSONObject;
    function GetOrCreate<T: TJSONValue, constructor>(const Name: string): T;
    procedure Delete(const Key: string); virtual;
    procedure Clear; virtual;
    property Count: Integer read GetCount;
    property JSON: TJSONObject read FJSON write SetJSON;
    function ToJsonString(FreeObject: Boolean = False): string; virtual;
    function ToStringPairs: TArray<TPair<string, string>>;
    function ToStream: TStringStream;
  end;

  {$IF RTLVersion < 35.0}
  TURLClientHelper = class helper for TURLClient
  public
    const
      DefaultConnectionTimeout = 60000;
      DefaultSendTimeout = 60000;
      DefaultResponseTimeout = 60000;
  end;
  {$ENDIF}

  TError = class
  private
    FMessage: string;
    FType: string;
    FParam: string;
    FCode: Int64;
  public
    property Message: string read FMessage write FMessage;
    property &Type: string read FType write FType;
    property Param: string read FParam write FParam;
    property Code: Int64 read FCode write FCode;
  end;

  TErrorResponse = class
  private
    FError: TError;
  public
    property Error: TError read FError write FError;
    destructor Destroy; override;
  end;

  ExceptionAPI = class(Exception);

  ExceptionAPIRequest = class(ExceptionAPI)
  private
    FCode: Int64;
    FParam: string;
    FType: string;
  public
    property &Type: string read FType write FType;
    property Code: Int64 read FCode write FCode;
    property Param: string read FParam write FParam;
    constructor Create(const Text, &Type: string; const Param: string = ''; Code: Int64 = -1); reintroduce;
  end;

  /// <summary>
  /// An InvalidRequestError indicates that your request was malformed or
  // missing some required parameters, such as a token or an input.
  // This could be due to a typo, a formatting error, or a logic error in your code.
  /// </summary>
  ExceptionInvalidRequestError = class(ExceptionAPIRequest);

  /// <summary>
  /// A `RateLimitError` indicates that you have hit your assigned rate limit.
  /// This means that you have sent too many tokens or requests in a given period of time,
  /// and our services have temporarily blocked you from sending more.
  /// </summary>
  ExceptionRateLimitError = class(ExceptionAPIRequest);

  /// <summary>
  /// An `AuthenticationError` indicates that your API key or token was invalid,
  /// expired, or revoked. This could be due to a typo, a formatting error, or a security breach.
  /// </summary>
  ExceptionAuthenticationError = class(ExceptionAPIRequest);

  /// <summary>
  /// This error message indicates that your account is not part of an organization
  /// </summary>
  ExceptionPermissionError = class(ExceptionAPIRequest);

  /// <summary>
  /// This error message indicates that our servers are experiencing high
  /// traffic and are unable to process your request at the moment
  /// </summary>
  ExceptionTryAgain = class(ExceptionAPIRequest);

  ExceptionInvalidResponse = class(ExceptionAPIRequest);

  {$WARNINGS OFF}
  TCustomAPI = class
  private
    FToken: string;
    FBaseUrl: string;

    FCustomHeaders: TNetHeaders;
    FProxySettings: TProxySettings;
    FConnectionTimeout: Integer;
    FSendTimeout: Integer;
    FResponseTimeout: Integer;

    procedure SetToken(const Value: string);
    procedure SetBaseUrl(const Value: string);
    procedure ParseAndRaiseError(Error: TError; Code: Int64);
    procedure ParseError(const Code: Int64; const ResponseText: string);
    procedure SetCustomHeaders(const Value: TNetHeaders);
    procedure SetProxySettings(const Value: TProxySettings);
    procedure SetConnectionTimeout(const Value: Integer);
    procedure SetResponseTimeout(const Value: Integer);
    procedure SetSendTimeout(const Value: Integer);
  protected
    function GetHeaders: TNetHeaders; virtual;
    function GetClient: THTTPClient; virtual;
    function GetRequestURL(const Path: string): string;
    function Get(const Path: string; Response: TStream): Integer; overload;
    function Delete(const Path: string; Response: TStream): Integer; overload;
    function Post(const Path: string; Response: TStream): Integer; overload;
    function Post(const Path: string; Body: TJSONObject; Response: TStream; OnReceiveData: TReceiveDataCallback = nil): Integer; overload;
    function Post(const Path: string; Body: TMultipartFormData; Response: TStream): Integer; overload;
    function ParseResponse<T: class, constructor>(const Code: Int64; const ResponseText: string): T;
    procedure CheckAPI;
  public
    function Get<TResult: class, constructor>(const Path: string): TResult; overload;
    function Get<TResult: class, constructor; TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    procedure GetFile(const Path: string; Response: TStream); overload;
    function Delete<TResult: class, constructor>(const Path: string): TResult; overload;
    function Post<TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>; Response: TStream; Event: TReceiveDataCallback = nil): Boolean; overload;
    function Post<TResult: class, constructor; TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    function Post<TResult: class, constructor>(const Path: string): TResult; overload;
    function PostForm<TResult: class, constructor; TParams: TMultipartFormData, constructor>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
  public
    constructor Create; overload;
    constructor Create(const AToken: string); overload;
    destructor Destroy; override;
    property Token: string read FToken write SetToken;
    property BaseUrl: string read FBaseUrl write SetBaseUrl;
    property ProxySettings: TProxySettings read FProxySettings write SetProxySettings;
    /// <summary> Property to set/get the ConnectionTimeout. Value is in milliseconds.
    ///  -1 - Infinite timeout. 0 - platform specific timeout. Supported by Windows, Linux, Android platforms. </summary>
    property ConnectionTimeout: Integer read FConnectionTimeout write SetConnectionTimeout;
    /// <summary> Property to set/get the SendTimeout. Value is in milliseconds.
    ///  -1 - Infinite timeout. 0 - platform specific timeout. Supported by Windows, macOS platforms. </summary>
    property SendTimeout: Integer read FSendTimeout write SetSendTimeout;
    /// <summary> Property to set/get the ResponseTimeout. Value is in milliseconds.
    ///  -1 - Infinite timeout. 0 - platform specific timeout. Supported by all platforms. </summary>
    property ResponseTimeout: Integer read FResponseTimeout write SetResponseTimeout;
    property CustomHeaders: TNetHeaders read FCustomHeaders write SetCustomHeaders;
  end;
  {$WARNINGS ON}

  TAPIRoute = class
  private
    FAPI: TCustomAPI;
    procedure SetAPI(const Value: TCustomAPI);
  public
    property API: TCustomAPI read FAPI write SetAPI;
    constructor CreateRoute(AAPI: TCustomAPI);
  end;

const
  DATE_FORMAT = 'YYYY-MM-DD';
  TIME_FORMAT = 'HH:NN:SS';
  DATE_TIME_FORMAT = DATE_FORMAT + ' ' + TIME_FORMAT;

implementation

uses
  REST.Json, System.NetConsts, System.DateUtils;

constructor TCustomAPI.Create;
begin
  inherited;
  // Defaults
  FConnectionTimeout := TURLClient.DefaultConnectionTimeout;
  FSendTimeout := TURLClient.DefaultSendTimeout;
  FResponseTimeout := TURLClient.DefaultResponseTimeout;
  FToken := '';
  FBaseUrl := '';
end;

constructor TCustomAPI.Create(const AToken: string);
begin
  Create;
  Token := AToken;
end;

destructor TCustomAPI.Destroy;
begin
  inherited;
end;

function TCustomAPI.Post(const Path: string; Body: TJSONObject; Response: TStream; OnReceiveData: TReceiveDataCallback): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    var Headers := GetHeaders + [TNetHeader.Create('Content-Type', 'application/json')];
    var Stream := TStringStream.Create;
    Client.ReceiveDataCallBack := OnReceiveData;
    try
      Stream.WriteString(Body.ToJSON);
      Stream.Position := 0;
      Result := Client.Post(GetRequestURL(Path), Stream, Response, Headers).StatusCode;
    finally
      Client.OnReceiveData := nil;
      Stream.Free;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Get(const Path: string; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Get(GetRequestURL(Path), Response, GetHeaders).StatusCode;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Post(const Path: string; Body: TMultipartFormData; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Post(GetRequestURL(Path), Body, Response, GetHeaders).StatusCode;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Post(const Path: string; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Post(GetRequestURL(Path), TStream(nil), Response, GetHeaders).StatusCode;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Post<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Result := ParseResponse<TResult>(Post(Path, Params.JSON, Response), Response.DataString);
  finally
    Params.Free;
    Response.Free;
  end;
end;

function TCustomAPI.Post<TParams>(const Path: string; ParamProc: TProc<TParams>; Response: TStream; Event: TReceiveDataCallback): Boolean;
begin
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    var Code := Post(Path, Params.JSON, Response, Event);
    case Code of
      200..299:
        Result := True;
    else
      Result := False;
      var Strings := TStringStream.Create;
      try
        Response.Position := 0;
        Strings.LoadFromStream(Response);
        ParseError(Code, Strings.DataString);
      finally
        Strings.Free;
      end;
    end;
  finally
    Params.Free;
  end;
end;

function TCustomAPI.Post<TResult>(const Path: string): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Result := ParseResponse<TResult>(Post(Path, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.Delete(const Path: string; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Delete(GetRequestURL(Path), Response, GetHeaders).StatusCode;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Delete<TResult>(const Path: string): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Result := ParseResponse<TResult>(Delete(Path, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.PostForm<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Result := ParseResponse<TResult>(Post(Path, Params, Response), Response.DataString);
  finally
    Params.Free;
    Response.Free;
  end;
end;

function TCustomAPI.Get<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    var Pairs: TArray<string> := [];
    for var Pair in Params.ToStringPairs do
      Pairs := Pairs + [Pair.Key + '=' + Pair.Value];
    var QPath := Path;
    if Length(Pairs) > 0 then
      QPath := QPath + '?' + string.Join('&', Pairs);
    Result := ParseResponse<TResult>(Get(QPath, Response), Response.DataString);
  finally
    Params.Free;
    Response.Free;
  end;
end;

function TCustomAPI.Get<TResult>(const Path: string): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Result := ParseResponse<TResult>(Get(Path, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.GetClient: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.ProxySettings := FProxySettings;
  Result.ConnectionTimeout := FConnectionTimeout;
  Result.ResponseTimeout := FResponseTimeout;
  {$IF RTLVersion >= 35.0}
  Result.SendTimeout := FSendTimeout;
  {$ENDIF}
  Result.AcceptCharSet := 'utf-8';
end;

procedure TCustomAPI.GetFile(const Path: string; Response: TStream);
begin
  CheckAPI;
  var Client := GetClient;
  try
    var Code := Client.Get(GetRequestURL(Path), Response, GetHeaders).StatusCode;
    case Code of
      200..299:
        ; {success}
    else
      var Strings := TStringStream.Create;
      try
        Response.Position := 0;
        Strings.LoadFromStream(Response);
        ParseError(Code, Strings.DataString);
      finally
        Strings.Free;
      end;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.GetHeaders: TNetHeaders;
begin
  Result := [TNetHeader.Create('Authorization', 'Bearer ' + FToken)] + FCustomHeaders;
end;

function TCustomAPI.GetRequestURL(const Path: string): string;
begin
  Result := FBaseURL + '/' + Path;
end;

procedure TCustomAPI.CheckAPI;
begin
  if FToken.IsEmpty then
    raise ExceptionAPI.Create('Token is empty!');
  if FBaseUrl.IsEmpty then
    raise ExceptionAPI.Create('Base url is empty!');
end;

procedure TCustomAPI.ParseAndRaiseError(Error: TError; Code: Int64);
begin
  case Code of
    429:
      raise ExceptionRateLimitError.Create(Error.Message, Error.&Type, Error.Param, Error.Code);
    400, 404, 415:
      raise ExceptionInvalidRequestError.Create(Error.Message, Error.&Type, Error.Param, Error.Code);
    401:
      raise ExceptionAuthenticationError.Create(Error.Message, Error.&Type, Error.Param, Error.Code);
    403:
      raise ExceptionPermissionError.Create(Error.Message, Error.&Type, Error.Param, Error.Code);
    409:
      raise ExceptionTryAgain.Create(Error.Message, Error.&Type, Error.Param, Error.Code);
  else
    raise ExceptionAPIRequest.Create(Error.Message, Error.&Type, Error.Param, Error.Code);
  end;
end;

procedure TCustomAPI.ParseError(const Code: Int64; const ResponseText: string);
begin
  var Error: TErrorResponse := nil;
  try
    try
      Error := TJson.JsonToObject<TErrorResponse>(ResponseText);
    except
      Error := nil;
    end;
    if Assigned(Error) and Assigned(Error.Error) then
      ParseAndRaiseError(Error.Error, Code)
    else
      raise ExceptionAPIRequest.Create('Unknown error. Code: ' + Code.ToString, '', '', Code);
  finally
    Error.Free;
  end;
end;

function TCustomAPI.ParseResponse<T>(const Code: Int64; const ResponseText: string): T;
begin
  Result := nil;
  case Code of
    200..299:
      try
        Result := TJson.JsonToObject<T>(ResponseText);
      except
        Result := nil;
      end;
  else
    ParseError(Code, ResponseText);
  end;
  if not Assigned(Result) then
    raise ExceptionInvalidResponse.Create('Empty or invalid response', '', '', Code);
end;

procedure TCustomAPI.SetBaseUrl(const Value: string);
begin
  FBaseUrl := Value;
end;

procedure TCustomAPI.SetConnectionTimeout(const Value: Integer);
begin
  FConnectionTimeout := Value;
end;

procedure TCustomAPI.SetCustomHeaders(const Value: TNetHeaders);
begin
  FCustomHeaders := Value;
end;

procedure TCustomAPI.SetProxySettings(const Value: TProxySettings);
begin
  FProxySettings := Value;
end;

procedure TCustomAPI.SetResponseTimeout(const Value: Integer);
begin
  FResponseTimeout := Value;
end;

procedure TCustomAPI.SetSendTimeout(const Value: Integer);
begin
  FSendTimeout := Value;
end;

procedure TCustomAPI.SetToken(const Value: string);
begin
  FToken := Value;
end;

{ ExceptionAPIRequest }

constructor ExceptionAPIRequest.Create(const Text, &Type, Param: string; Code: Int64);
begin
  inherited Create(Text);
  Self.&Type := &Type;
  Self.Code := Code;
  Self.Param := Param;
end;

{ TAPIRoute }

constructor TAPIRoute.CreateRoute(AAPI: TCustomAPI);
begin
  inherited Create;
  FAPI := AAPI;
end;

procedure TAPIRoute.SetAPI(const Value: TCustomAPI);
begin
  FAPI := Value;
end;

{ TJSONInterceptorStringToString }

constructor TJSONInterceptorStringToString.Create;
begin
  ConverterType := ctString;
  ReverterType := rtString;
end;

{ Fetch }

type
  Fetch<T> = class
    type
      TFetchProc = reference to procedure(const Element: T);
  public
    class procedure All(const Items: TArray<T>; Proc: TFetchProc);
  end;

{ Fetch<T> }

class procedure Fetch<T>.All(const Items: TArray<T>; Proc: TFetchProc);
begin
  for var Item in Items do
    Proc(Item);
end;

{ TJSONParam }

function TJSONParam.Add(const Key, Value: string): TJSONParam;
begin
  Delete(Key);
  FJSON.AddPair(Key, Value);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: TJSONValue): TJSONParam;
begin
  Delete(Key);
  FJSON.AddPair(Key, Value);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: TJSONParam): TJSONParam;
begin
  Add(Key, TJSONValue(Value.JSON.Clone));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: TDateTime; Format: string): TJSONParam;
begin
  if Format.IsEmpty then
    Format := DATE_TIME_FORMAT;
  Add(Key, FormatDateTime(Format, System.DateUtils.TTimeZone.local.ToUniversalTime(Value)));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: Boolean): TJSONParam;
begin
  Add(Key, TJSONBool.Create(Value));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: Integer): TJSONParam;
begin
  Add(Key, TJSONNumber.Create(Value));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: Extended): TJSONParam;
begin
  Add(Key, TJSONNumber.Create(Value));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<TJSONValue>): TJSONParam;
var
  JArr: TJSONArray;
begin
  JArr := TJSONArray.Create;
  Fetch<TJSONValue>.All(Value, JArr.AddElement);
  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<TJSONParam>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
  try
    JArr.AddElement(Item.JSON);
    Item.JSON := nil;
  finally
    Item.Free;
  end;

  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<Extended>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
    JArr.Add(Item);

  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<Integer>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
    JArr.Add(Item);

  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<string>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
    JArr.Add(Item);

  Add(Key, JArr);
  Result := Self;
end;

procedure TJSONParam.Clear;
begin
  FJSON.Free;
  FJSON := TJSONObject.Create;
end;

constructor TJSONParam.Create;
begin
  FJSON := TJSONObject.Create;
end;

procedure TJSONParam.Delete(const Key: string);
begin
  var Item := FJSON.RemovePair(Key);
  if Assigned(Item) then
    Item.Free;
end;

destructor TJSONParam.Destroy;
begin
  if Assigned(FJSON) then
    FJSON.Free;
  inherited;
end;

function TJSONParam.GetCount: Integer;
begin
  Result := FJSON.Count;
end;

function TJSONParam.GetOrCreate<T>(const Name: string): T;
begin
  if not FJSON.TryGetValue<T>(Name, Result) then
  begin
    Result := T.Create;
    FJSON.AddPair(Name, Result);
  end;
end;

function TJSONParam.GetOrCreateObject(const Name: string): TJSONObject;
begin
  Result := GetOrCreate<TJSONObject>(Name);
end;

procedure TJSONParam.SetJSON(const Value: TJSONObject);
begin
  FJSON := Value;
end;

function TJSONParam.ToJsonString(FreeObject: Boolean): string;
begin
  Result := FJSON.ToJSON;
  if FreeObject then
    Free;
end;

function TJSONParam.ToStream: TStringStream;
begin
  Result := TStringStream.Create;
  try
    Result.WriteString(ToJsonString);
    Result.Position := 0;
  except
    Result.Free;
    raise;
  end;
end;

function TJSONParam.ToStringPairs: TArray<TPair<string, string>>;
begin
  for var Pair in FJSON do
    Result := Result + [TPair<string, string>.Create(Pair.JsonString.Value, Pair.JsonValue.AsType<string>)];
end;

{ TErrorResponse }

destructor TErrorResponse.Destroy;
begin
  if Assigned(FError) then
    FError.Free;
  inherited;
end;

end.

