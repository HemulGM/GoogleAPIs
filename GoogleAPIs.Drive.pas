unit GoogleAPIs.Drive;

interface

uses
  System.Classes, System.SysUtils, Rest.Json, Rest.Json.Types, HGM.FastClientAPI,
  System.Generics.Collections, System.Generics.Defaults, System.Net.Mime,
  System.JSON;

type
  TUploadFileParams = class(TFastMultipartFormData);

  TDriveFile = class
  private
    [JsonNameAttribute('kind')]
    FKind: string;
    [JsonNameAttribute('id')]
    FId: string;
    [JsonNameAttribute('name')]
    FName: string;
    [JsonNameAttribute('mimeType')]
    FMimeType: string;
    [JsonNameAttribute('thumbnailLink')]
    FThumbnailLink: string;
  public
    property Kind: string read FKind write FKind;
    property ThumbnailLink: string read FThumbnailLink write FThumbnailLink;
    property Id: string read FId write FId;
    property Name: string read FName write FName;
    property MimeType: string read FMimeType write FMimeType;
  end;

  TFileList = class
  private
    [JsonNameAttribute('kind')]
    FKind: string;
    [JsonNameAttribute('nextPageToken')]
    FNextPageToken: string;
    [JsonNameAttribute('incompleteSearch')]
    FIncompleteSearch: Boolean;
  public
    property Kind: string read FKind write FKind;
    property NextPageToken: string read FNextPageToken write FNextPageToken;
    property IncompleteSearch: Boolean read FIncompleteSearch write FIncompleteSearch;
  end;

  TFileList<T: TDriveFile> = class(TFileList)
  private
    [JsonNameAttribute('files')]
    FFiles: TArray<T>;
  public
    property Files: TArray<T> read FFiles write FFiles;
    destructor Destroy; override;
  end;

  TUpdateFileMetaParam = class(TJSONParam)
    function AppProperties(const Value: TArray<TPair<string, string>>): TUpdateFileMetaParam;
    function Properties(const Value: TArray<TPair<string, string>>): TUpdateFileMetaParam;
    function ContentHints(const Key: string; Value: TJSONObject): TUpdateFileMetaParam;
  end;

  TFileListDefault = TFileList<TDriveFile>;

  TGoogleDriveRoute = class(TAPIRoute)
    const
      AppDataFolder = 'appDataFolder';
      AppProperties = 'appProperties';
  public
    function Files<T: TFileList, constructor>(const Query: string = ''; const Fields: TArray<string> = []): T;
    function FilesInFolder<T: TFileList, constructor>(const ParentId: string; const Query: string = ''; const Fields: TArray<string> = []): T;
    function CreateFolder(const ParentId: string; const Name: string): TDriveFile;
    function UploadFile(const FolderId: string; const FileName, FilePath: string): TDriveFile;
    function UpdateFileMeta(const FileId: string; Params: TProc<TUpdateFileMetaParam>): TDriveFile;
    function DownloadFile(const FileId: string; Response: TStream): Integer;
    function GetFileLink(const FileId: string): string;
  end;

implementation

uses
  System.NetEncoding, System.StrUtils, System.IOUtils;

{ TFileList<T> }

destructor TFileList<T>.Destroy;
begin
  for var Item in FFiles do
    Item.Free;
  inherited;
end;

{ TGoogleDriveRoute }

function TGoogleDriveRoute.CreateFolder(const ParentId: string; const Name: string): TDriveFile;
begin
  Result := API.Post<TDriveFile, TJSONParam>('drive/v3/files',
    procedure(Params: TJSONParam)
    begin
      Params.Add('name', Name);
      Params.Add('parents', TJSONArray.Create(TJSONString.Create(ParentId)));
      Params.Add('mimeType', 'application/vnd.google-apps.folder');
    end);
end;

function TGoogleDriveRoute.Files<T>(const Query: string; const Fields: TArray<string>): T;
begin
  Result := API.Get<T, TJSONParam>('drive/v3/files',
    procedure(Params: TJSONParam)
    begin
      if not Query.IsEmpty then
        Params.Add('q', TNetEncoding.URL.EncodeQuery(Query));
      if Length(Fields) > 0 then
        Params.Add('fields', 'files(' + TNetEncoding.URL.EncodeQuery(string.Join(',', Fields)) + ')');
    end);
end;

function TGoogleDriveRoute.FilesInFolder<T>(const ParentId: string; const Query: string; const Fields: TArray<string>): T;
begin
  Result := Files<T>('"' + ParentId + '" in parents' + IfThen(not Query.IsEmpty, ' and (' + Query + ')'), Fields);
end;

function TGoogleDriveRoute.GetFileLink(const FileId: string): string;
begin
  Result := API.BaseUrl + '/drive/v3/files/' + FileId + '?alt=media';
end;

function TGoogleDriveRoute.DownloadFile(const FileId: string; Response: TStream): Integer;
begin
  try
    Result := API.GetFile('drive/v3/files/' + FileId + '?alt=media', Response);
  except
    Response.Size := 0;
    raise;
  end;
end;

function TGoogleDriveRoute.UpdateFileMeta(const FileId: string; Params: TProc<TUpdateFileMetaParam>): TDriveFile;
begin
  Result := API.Patch<TDriveFile, TUpdateFileMetaParam>('drive/v3/files/' + FileId + '?fields=contentHints,properties,appProperties', Params);
end;

function TGoogleDriveRoute.UploadFile(const FolderId, FileName, FilePath: string): TDriveFile;
begin
  Result := API.PostForm<TDriveFile, TUploadFileParams>('upload/drive/v3/files?uploadType=multipart',
    procedure(Params: TUploadFileParams)
    begin
      var JSON := TJSONObject.Create;
      try
        JSON.AddPair('name', FileName);
        JSON.AddPair('parents', TJSONArray.Create(TJSONString.Create(FolderId)));
        Params.AddField('', JSON.ToJSON, 'application/json; charset=UTF-8');
      finally
        JSON.Free;
      end;
      Params.AddFile('', FilePath);
    end);
end;

{ TUpdateFileMetaParam }

function TUpdateFileMetaParam.AppProperties(const Value: TArray<TPair<string, string>>): TUpdateFileMetaParam;
begin
  var Values := TJSONParam.Create;
  for var Item in Value do
    Values.Add(Item.Key, Item.Value);
  Result := TUpdateFileMetaParam(Add('appProperties', Values));
end;

function TUpdateFileMetaParam.ContentHints(const Key: string; Value: TJSONObject): TUpdateFileMetaParam;
begin
  GetOrCreateObject('contentHints').AddPair(Key, Value);
  Result := Self;
end;

function TUpdateFileMetaParam.Properties(const Value: TArray<TPair<string, string>>): TUpdateFileMetaParam;
begin
  var Values := TJSONParam.Create;
  for var Item in Value do
    Values.Add(Item.Key, Item.Value);
  Result := TUpdateFileMetaParam(Add('properties', Values));
end;

end.

