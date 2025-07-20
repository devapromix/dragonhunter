unit Dragonhunter.Scene.LevelUp;

interface

uses
  Classes,
  Trollhunter.Scene,
  Trollhunter.Scene.BaseGame;

type
  TSceneLevelUp = class(TSceneBaseGame)
  private
    FCount: Integer;
    FHeight: Integer;
    FCursorPos: Integer;
    FSelCursorPos: Integer;
    procedure AtrItem(I: Integer; S: string);
  public
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneLevelUp: TSceneLevelUp;

implementation

uses
  Graphics,
  SysUtils,
  System.StrUtils,
  Trollhunter.Graph,
  Trollhunter.Creatures,
  Trollhunter.Scenes,
  Trollhunter.Scene.Game,
  Dragonhunter.Color,
  Trollhunter.Error,
  Trollhunter.Log,
  Trollhunter.Lang,
  Dragonhunter.Utils,
  Dragonhunter.Terminal,
  Dragonhunter.Frame;

{ TSceneLevelUp }

constructor TSceneLevelUp.Create;
begin
  inherited Create(4);
  FCursorPos := 0;
  FCount := 5;
end;

procedure TSceneLevelUp.AtrItem(I: Integer; S: string);
var
  LStr: string;
begin
  LStr := IfThen(Creatures.Character.PossibleImproveAttribute, '+ 1');
  try
    with Graph.Surface.Canvas do
    begin
      case I of
        0:
          S := S + #32 + IntToStr(Creatures.Character.Prop.Strength);
        1:
          S := S + #32 + IntToStr(Creatures.Character.Prop.Dexterity);
        2:
          S := S + #32 + IntToStr(Creatures.Character.Prop.Intelligence);
        3:
          S := S + #32 + IntToStr(Creatures.Character.Prop.Perception);
        4:
          S := S + #32 + IntToStr(Creatures.Character.Prop.Speed);
      end;
      if (FCursorPos = FSelCursorPos) then
      begin
        Terminal.BoldFont;
        Terminal.TextColor(cAcColor);
        Terminal.MenuLine(Terminal.Width div 2 - 27, Terminal.Height div 2 - 1 +
          FSelCursorPos, 54);
      end
      else
      begin
        Terminal.NormalFont;
        Terminal.TextColor(cBgColor);
      end;
      TextOut((Graph.Width div 2) - (TextWidth(S) div 2),
        (FSelCursorPos * Graph.CharHeight) + FHeight + Graph.CharHeight, S);
      Font.Color := cLtBlue;
      if (FSelCursorPos = FCursorPos) then
        TextOut((Graph.Width div 2) - (TextWidth(S) div 2) +
          ((Length(S) + 1) * Graph.CharWidth),
          (FSelCursorPos * Graph.CharHeight) + FHeight +
          Graph.CharHeight, LStr);
      Inc(FSelCursorPos);
    end;
  except
    on E: Exception do
      Error.Add('SceneLevelUp.AtrItem', E.Message);
  end;
end;

destructor TSceneLevelUp.Destroy;
begin

  inherited;
end;

procedure TSceneLevelUp.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  try
    case Key of
      38, 40:
        begin
          FCursorPos := FCursorPos + (Key - 39);
          FCursorPos := ClampCycle(FCursorPos, 0, FCount - 1);
          Render;
        end;
      13:
        with Creatures.Character do
          if PossibleImproveAttribute then
          begin
            case FCursorPos of
              0:
                if PossibleImproveAttribute then
                begin
                  if UseAtrPoint then
                    AddStrength;
                end;
              1:
                if PossibleImproveAttribute then
                begin
                  if UseAtrPoint then
                    AddDexterity;
                end;
              2:
                if PossibleImproveAttribute then
                begin
                  if UseAtrPoint then
                    AddIntelligence;
                end;
              3:
                if PossibleImproveAttribute then
                begin
                  if UseAtrPoint then
                    AddPerception;
                end;
              4:
                if PossibleImproveAttribute then
                begin
                  if UseAtrPoint then
                    AddSpeed;
                end;
            end;
            Calc;
            Log.Apply;
            Scenes.Scene := SceneGame;
          end;
    end;
  except
    on E: Exception do
      Error.Add('SceneLevelUp.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneLevelUp.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneLevelUp.Render;
var
  LIndex: Integer;
begin
  inherited;
  try
    FSelCursorPos := 0;
    FHeight := (Graph.Height div 2) - (FCount * Graph.CharHeight div 2);
    with Graph.Surface.Canvas do
    begin
      for LIndex := 0 to FCount - 1 do
        AtrItem(LIndex, Language.GetLang(LIndex + 15));
      FHeight := FHeight div Graph.CharHeight;
      Font.Style := [];
      Font.Color := cBgColor;
      if Creatures.Character.PossibleImproveAttribute then
      begin
        Graph.Text.TextCenter(FHeight - 3, Language.GetLang(60));
        Graph.Text.TextCenter(FHeight - 2, Language.GetLang(62));
        Graph.Text.TextCenter(FHeight - 1, Language.GetLang(63));
      end;
      Font.Style := [];
    end;
    Terminal.TextColor(cAcColor);
    Frame.Draw((Terminal.Width div 2) - 30, Terminal.Height div 2 - 7, 60, 13);
    Terminal.Render;
  except
    on E: Exception do
      Error.Add('SceneLevelUp.Render', E.Message);
  end;
end;

initialization

SceneLevelUp := TSceneLevelUp.Create;

finalization

SceneLevelUp.Free;

end.
