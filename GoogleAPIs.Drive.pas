unit GoogleAPIs.Drive;

interface

uses
  System.Classes, Rest.Json, Rest.Json.Types, HGM.FastClientAPI, System.Net.Mime;

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
  public
    property Kind: string read FKind write FKind;
    property Id: string read FId write FId;
    property Name: string read FName write FName;
    property MimeType: string read FMimeType write FMimeType;
  end;

  TFileList = class
  private
    [JsonNameAttribute('files')]
    FFiles: TArray<TDriveFile>;
    [JsonNameAttribute('kind')]
    FKind: string;
    [JsonNameAttribute('nextPageToken')]
    FNextPageToken: string;
    [JsonNameAttribute('incompleteSearch')]
    FIncompleteSearch: Boolean;
  public
    property Files: TArray<TDriveFile> read FFiles write FFiles;
    property Kind: string read FKind write FKind;
    property NextPageToken: string read FNextPageToken write FNextPageToken;
    property IncompleteSearch: Boolean read FIncompleteSearch write FIncompleteSearch;
    destructor Destroy; override;
  end;

//appDataFolder

  TGoogleDriveRoute = class(TAPIRoute)
    function Files(const Query: string = ''): TFileList;
    function FilesInFolder(const ParentId: string): TFileList;
    function CreateFolder(const ParentId: string; const Name: string): TDriveFile;
    function UploadFile(const FolderId: string; const FileName, FilePath: string): TDriveFile;
    procedure DownloadFile(const FileId: string; Response: TStream);
    function GetFileLink(const FileId: string): string;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.NetEncoding, System.IOUtils;

{ TFileList }

destructor TFileList.Destroy;
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

function TGoogleDriveRoute.Files(const Query: string): TFileList;
begin
  Result := API.Get<TFileList, TJSONParam>('drive/v3/files',
    procedure(Params: TJSONParam)
    begin
      if not Query.IsEmpty then
        Params.Add('q', TNetEncoding.URL.EncodeQuery(Query));
    end);
end;

function TGoogleDriveRoute.FilesInFolder(const ParentId: string): TFileList;
begin
  Result := Files('"' + ParentId + '" in parents');
end;

function TGoogleDriveRoute.GetFileLink(const FileId: string): string;
begin
  Result := API.BaseUrl + '/drive/v3/files/' + FileId + '?alt=media';
end;

procedure TGoogleDriveRoute.DownloadFile(const FileId: string; Response: TStream);
begin
  try
    API.GetFile('drive/v3/files/' + FileId + '?alt=media', Response);
  except
    Response.Size := 0;
    raise;
  end;
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

end.

