unit Dragonhunter.Item.Underground;

interface

type
  TUndergroundItems = class(TObject)
  private
    FItems: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromResources;
    property Items: string read FItems;
  end;

var
  UndergroundItems: TUndergroundItems;

implementation

uses
  System.SysUtils,
  System.JSON,
  Dragonhunter.Resources,
  Dragonhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Error;

{ TUndergroundItems }

constructor TUndergroundItems.Create;
begin
  FItems := '';
end;

destructor TUndergroundItems.Destroy;
begin

  inherited;
end;

procedure TUndergroundItems.LoadFromResources;
var
  LUndergroundItems: TJSONArray;
  LJSONData: TJSONData;
  I: Integer;
begin
  try
    LJSONData := TJSONData.Create;
    try
      LUndergroundItems := LJSONData.LoadFromFile('items.underground.json');
      try
        for I := 0 to LUndergroundItems.Count - 1 do
          FItems := FItems + LUndergroundItems.Items[I].Value + ',';
      finally
        FreeAndNil(LUndergroundItems);
      end;
    finally
      FreeAndNil(LJSONData);
    end;
  except
    on E: Exception do
      Error.Add('UndergroundItems.LoadFromResources', E.Message);
  end;
end;

initialization

UndergroundItems := TUndergroundItems.Create;
UndergroundItems.LoadFromResources;

finalization

FreeAndNil(UndergroundItems);

end.
