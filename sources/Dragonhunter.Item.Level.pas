unit Dragonhunter.Item.Level;

interface

type
  TLevelItems = class(TObject)
  private
    FItems: string;
    procedure LoadFromResources(const AItemLevel: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function GetItems(const AItemLevel: Integer): string;
  end;

var
  LevelItems: TLevelItems;

implementation

uses
  System.SysUtils,
  System.JSON,
  Dragonhunter.Resources,
  Trollhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Error;

{ TLevelItems }

constructor TLevelItems.Create;
begin
  FItems := '';
end;

destructor TLevelItems.Destroy;
begin

  inherited;
end;

function TLevelItems.GetItems(const AItemLevel: Integer): string;
begin
  try
    FItems := '';
    LoadFromResources(AItemLevel);
  except
    on E: Exception do
      Error.Add(Format('LevelItems.GetItems(%d)', [AItemLevel]), E.Message);
  end;
end;

procedure TLevelItems.LoadFromResources(const AItemLevel: Integer);
var
  LDefaultItems: TJSONArray;
  LJSONData: TJSONData;
  I: Integer;
begin
  try
    if (AItemLevel <= 0) or (AItemLevel > 15) then
      Exit;
    LJSONData := TJSONData.Create;
    try
      LDefaultItems := LJSONData.LoadFromFile(Format('items.level%d.json',
        [AItemLevel]));
      try
        for I := 0 to LDefaultItems.Count - 1 do
          FItems := FItems + LDefaultItems.Items[I].Value + ',';
      finally
        FreeAndNil(LDefaultItems);
      end;
    finally
      FreeAndNil(LJSONData);
    end;
  except
    on E: Exception do
      Error.Add(Format('LevelItems.LoadFromResources(%d)', [AItemLevel]),
        E.Message);
  end;
end;

initialization

LevelItems := TLevelItems.Create;

finalization

FreeAndNil(LevelItems);

end.
