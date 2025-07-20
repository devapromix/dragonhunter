unit Dragonhunter.Item.Default;

interface

type
  TDefaultItems = class(TObject)
  private
    FItems: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromResources;
    property Items: string read FItems;
  end;

var
  DefaultItems: TDefaultItems;

implementation

uses
  System.SysUtils,
  System.JSON,
  Dragonhunter.Resources,
  Dragonhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Error;

{ TDefaultItems }

constructor TDefaultItems.Create;
begin
  FItems := '';
end;

destructor TDefaultItems.Destroy;
begin

  inherited;
end;

procedure TDefaultItems.LoadFromResources;
var
  LDefaultItems: TJSONArray;
  LJSONData: TJSONData;
  I: Integer;
begin
  try
    LJSONData := TJSONData.Create;
    try
      LDefaultItems := LJSONData.LoadFromFile('items.default.json');
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
      Error.Add('DefaultItems.LoadFromResources', E.Message);
  end;
end;

initialization

DefaultItems := TDefaultItems.Create;
DefaultItems.LoadFromResources;

finalization

FreeAndNil(DefaultItems);

end.
