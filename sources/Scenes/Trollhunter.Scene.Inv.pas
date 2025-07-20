unit Trollhunter.Scene.Inv;

interface

uses
  Classes,
  Graphics,
  Trollhunter.Scene,
  Trollhunter.Scenes,
  Trollhunter.Inv,
  Dragonhunter.Item,
  Trollhunter.Creatures,
  Trollhunter.Scene.BaseGame;

type
  TSceneInv = class(TSceneBaseGame)
  private
    CursorPos: Integer;
    Icon: Graphics.TBitmap;
  public
    ItemUseID: string;
    Hero, Item: Graphics.TBitmap;
    procedure RedrawPCIcon;
    procedure RenderUseIcon;
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneInv: TSceneInv;

implementation

uses
  Windows,
  Types,
  SysUtils,
  Trollhunter.Error,
  Trollhunter.Graph,
  Dragonhunter.Color,
  Trollhunter.Game,
  Dragonhunter.Utils,
  Trollhunter.Log,
  Trollhunter.Lang,
  Trollhunter.Scene.Game,
  Dragonhunter.Scene.Item,
  Trollhunter.Scene.Char,
  Trollhunter.Scene.Items,
  Trollhunter.Item.Pattern;

{ TSceneInv }

constructor TSceneInv.Create;
begin
  inherited Create(25);
  Icon := Graphics.TBitmap.Create;
  Hero := Graphics.TBitmap.Create;
  Hero.Transparent := True;
  Item := Graphics.TBitmap.Create;
  Item.Transparent := True;
  CursorPos := 1;
end;

destructor TSceneInv.Destroy;
begin
  Icon.Free;
  Hero.Free;
  Item.Free;
  inherited;
end;

procedure TSceneInv.KeyDown(var Key: Word; Shift: TShiftState);
var
  I, C: Integer;
  K: Word;
begin
  inherited;
  try
    case Key of
      38, 40:
        begin
          C := Creatures.Character.Inv.Count;
          if (C > 0) then
          begin
            CursorPos := CursorPos + (Key - 39);
            CursorPos := ClampCycle(CursorPos, 1, C);
            Render;
          end;
        end;
      8:
        begin
          C := Items.CellItemsCount(Creatures.Character.Pos.X, Creatures.Character.Pos.Y);
          if (C > 0) then
            Scenes.Scene := SceneItems;
        end;
      32:
        Scenes.Scene := SceneChar;
      13:
        begin
          C := Creatures.Character.Inv.Count;
          if (C > 0) then
          begin
            K := (ord('A') + CursorPos) - 1;
            KeyDown(K, Shift);
          end;
        end;
      27, 123:
        begin
          CursorMode := cmNone;
          Log.Apply;
          Game.Save;
          ItemUseID := '';
          Creatures.Character.Redraw;
          Graph.Messagebar.Clear;
          Scenes.Render;
          Exit;
        end;
      ord('A') .. ord('Z'):
        begin
          I := (Key - (ord('A'))) + 1;
          if (I <= Creatures.Character.Inv.Count) then
          begin
            if (ItemUseID <> '') then
            begin
              Items.Use(ItemUseID,
                ItemPatterns.Patterns[SceneItem.KeyIDToInvItemID(I)].ID, I);
              ItemUseID := '';
              Log.Apply;
              Game.Save;
              Creatures.Character.Redraw;
              Scenes.Render;
              Exit;
            end;
            SceneItem.CursorPos := 0;
            SceneItem.ItemIndex := I;
            Scenes.Scene := SceneItem;
          end;
        end;
    end;
  except
    on E: Exception do
      Error.Add('SceneInv.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneInv.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneInv.RedrawPCIcon;
begin
  try
    Creatures.Character.Redraw;
    Hero.Assign(Creatures.Character.Image);
    ScaleBmp(Hero, 64, 64);
    Hero.Transparent := True;
  except
    on E: Exception do
      Error.Add('SceneInv.RedrawPCIcon', E.Message);
  end;
end;

procedure TSceneInv.RenderUseIcon;
var
  ID, R: string;

  procedure DrawIcon(G: string; Y: Integer);
  var
    I: Integer;
    Tileset: Graphics.TBitmap;
  begin
    Tileset := Graphics.TBitmap.Create;
    try
      I := Items.ItemIndex(G);
      if (ItemPatterns.Patterns[I].Sprite = '') then
        Tileset.Handle := Windows.LoadBitmap(hInstance, PChar(G))
      else
        Tileset.Handle := Windows.LoadBitmap(hInstance,
          PChar(ItemPatterns.Patterns[I].Sprite));
      Graph.BitmapFromTileset(Item, Tileset, 0);
      Items.Colors(Item, I);
      ScaleBmp(Item, 64, 64);
      Item.Transparent := True;
      Graph.Surface.Canvas.Draw(Graph.Surface.Width - 72, Y, Item);
    finally
      Tileset.Free;
    end;
  end;

begin
  DrawIcon(ItemUseID, 96);
  ID := ItemPatterns.Patterns[Items.ItemIndex(CursorPos)].ID;
  DrawIcon(ID, 176);
  R := Items.Craft(ItemUseID, ID);
  if (R <> '') then
    DrawIcon(R, 255);
end;

procedure TSceneInv.Render;
var
  S: string;
  I, ID, C, Y, W: Integer;
  Tileset: Graphics.TBitmap;
begin
  inherited;
  Tileset := Graphics.TBitmap.Create;
  try
    Y := 2;
    with Graph.Surface.Canvas do
    begin
      C := Creatures.Character.Inv.Count;
      for I := 1 to C do
      begin
        CursorPos := ClampCycle(CursorPos, 1, C);
        ID := Items.ItemIndex(I);
        S := Chr(I + 96) + '.';
        Font.Color := clSilver;
        if (CursorPos = I) then
        begin
          Font.Style := [fsBold];
          W := ((Graph.Width div Graph.CharWidth) - 10);
          Graph.RenderMenuLine(Y, 0, True, W, cDkGray);
        end
        else
        begin
          Font.Style := [];
        end;
        Graph.Text.DrawOut(1, Y, S);

        if (ItemPatterns.Patterns[ID].Sprite = '') then
          Tileset.Handle := Windows.LoadBitmap(hInstance,
            PChar(Creatures.Character.Inv.GetIdent(I)))
        else
          Tileset.Handle := Windows.LoadBitmap(hInstance,
            PChar(ItemPatterns.Patterns[ID].Sprite));
        Graph.BitmapFromTileset(Icon, Tileset, 0);
        Items.Colors(Icon, ID);
        ScaleBmp(Icon, Graph.CharHeight, Graph.CharHeight);
        Icon.Transparent := True;
        Draw(Graph.CharWidth * 3, Y * Graph.CharHeight, Icon);

        Items.SetColor(ID);
        if Creatures.Character.Inv.GetDoll(I) then
        begin
          Font.Color := cRdYellow;
          Font.Style := [fsBold];
        end
        else if (Font.Style <> [fsBold]) then
          Font.Style := [];
        if ((ItemPatterns.Patterns[ID].MaxTough > 0) and
          (Creatures.Character.Inv.GetTough(I) <= 0)) then
          Font.Color := cRed;
        Graph.Text.DrawText(5, Y,
          Trim(Language.GetItemLang(ItemPatterns.Patterns[ID].ID) +
          Items.GetItemProp(Creatures.Character.Inv.GetCount(I),
          Creatures.Character.Inv.GetTough(I), I, ID) + Items.GetWeight(ID) +
          Items.GetDollText(I, ID)));
        Inc(Y);
      end;
      Items.RenderPCInvStat(Y);
      if (C = 1) then
        Graph.Text.BarOut('enter, a', Language.GetLang(24), False)
      else if (C > 1) then
        Graph.Text.BarOut('enter, a-' + Chr(96 + C),
          Language.GetLang(24), False);
      Graph.Text.BarOut('space', Language.GetLang(8), False);
      if (Items.CellItemsCount(Creatures.Character.Pos.X, Creatures.Character.Pos.Y) > 0) then
        Graph.Text.BarOut('backspace', Language.GetLang(111), False);
      Draw(Graph.Surface.Width - 72, Graph.CharHeight, Hero);
      if (ItemUseID <> '') then
        RenderUseIcon;
    end;
    Graph.Render;
    Tileset.Free;
  except
    on E: Exception do
      Error.Add('SceneInv.Render', E.Message);
  end;
end;

initialization

SceneInv := TSceneInv.Create;

finalization

SceneInv.Free;

end.
