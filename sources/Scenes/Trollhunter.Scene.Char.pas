unit Trollhunter.Scene.Char;

interface

uses
  Classes,
  Graphics,
  Trollhunter.Scene,
  Trollhunter.Scenes,
  Trollhunter.Scene.BaseGame;

type
  TSceneChar = class(TSceneBaseGame)
  private
    Y: Integer;
    function Space(C: Byte): string;
    procedure Add; overload;
    procedure Add(S, P: string); overload;
    procedure Add(B: Graphics.TBitmap; S, P: string); overload;
    procedure Add(S: string; P: Integer); overload;
    procedure Add(B: Graphics.TBitmap; S: string; P: Integer); overload;
    // procedure Calendar;
    procedure RenderSkills;
  public
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneChar: TSceneChar;

implementation

uses
  SysUtils,
  Trollhunter.Error,
  Trollhunter.Graph,
  Dragonhunter.Utils,
  Trollhunter.Scene.Game,
  Trollhunter.Creatures,
  Dragonhunter.Scene.Inv,
  Dragonhunter.Item,
  Dragonhunter.Color,
  Trollhunter.Lang,
  Dragonhunter.Map,
  Trollhunter.Skill,
  Dragonhunter.Map.Pattern;

{ TSceneChar }

procedure TSceneChar.Add(S, P: string);
begin
  with Graph.Surface.Canvas do
  begin
    if (S <> '') then
      TextOut(Graph.CharWidth * 3, Y * Graph.CharHeight, S + ':');
    TextOut(Graph.CharWidth * 20, Y * Graph.CharHeight, P);
    Inc(Y);
  end;
end;

procedure TSceneChar.Add(S: string; P: Integer);
begin
  Add(S, IntToStr(P));
end;

procedure TSceneChar.Add;
begin
  Add('', '');
end;

procedure TSceneChar.Add(B: Graphics.TBitmap; S: string; P: Integer);
begin
  with Graph.Surface.Canvas do
    Draw(Graph.CharWidth, Y * Graph.CharHeight, B);
  Add(S, P);
end;

procedure TSceneChar.Add(B: Graphics.TBitmap; S, P: string);
begin
  with Graph.Surface.Canvas do
    Draw(Graph.CharWidth, Y * Graph.CharHeight, B);
  Add(S, P);
end;

{ procedure TSceneChar.Calendar;
  begin
  with Creatures.PC do
  with Graph.Surface.Canvas do
  begin
  Text.DrawOut(60, 10, 'Day: ' + IntToStr(Day));
  Text.DrawOut(60, 11, 'Week: ' + IntToStr(Week));
  Text.DrawOut(60, 12, 'Month: ' + IntToStr(Month));
  Text.DrawOut(60, 13, 'Year: ' + IntToStr(Year));
  end;
  end; }

constructor TSceneChar.Create;
begin
  inherited Create(8);
end;

destructor TSceneChar.Destroy;
begin

  inherited;
end;

procedure TSceneChar.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  case Key of
    32:
      Scenes.Scene := SceneInv;
  end;
end;

procedure TSceneChar.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneChar.Render;
var
  S: string;
begin
  inherited;
  Y := 2;
  try
    with Graph.Surface.Canvas do
    begin
      Font.Color := cRdYellow;
      Add(Language.GetLang(37), Creatures.Character.Name);
      Add(Language.GetLang(180),
        Language.GetLang(Creatures.Character.Race + 182));
      Add(Language.GetLang(30), Creatures.Character.Prop.Level);
      Add(Graph.Bars.EXP, Language.GetLang(31),
        Format('%d/%d', [Creatures.Character.EXP,
        Creatures.Character.MaxExp(Creatures.Character.Prop.Level)]));
      Add();
      Add(Language.GetLang(15), Creatures.Character.Prop.Strength);
      Add(Language.GetLang(16), Creatures.Character.Prop.Dexterity);
      Add(Language.GetLang(17), Creatures.Character.Prop.Intelligence);
      Add(Language.GetLang(18), Creatures.Character.Prop.Perception);
      Add(Language.GetLang(19), Creatures.Character.GetSpeed);
      Add();
      Add(Language.GetLang(19), Creatures.Character.AtrPoint);
      Add();
      Add(Graph.Bars.LIFE, Language.GetLang(22),
        Format('%d/%d', [Creatures.Character.LIFE.Cur,
        Creatures.Character.LIFE.Max]));
      Add(Graph.Bars.MANA, Language.GetLang(23),
        Format('%d/%d', [Creatures.Character.MANA.Cur,
        Creatures.Character.MANA.Max]));
      Add();
      Add(Graph.Bars.DAMAGE, Language.GetLang(32),
        Format('%d-%d', [Creatures.Character.Prop.MinDamage,
        Creatures.Character.Prop.MaxDamage]));
      Add(Graph.Bars.PROTECT, Language.GetLang(33),
        Creatures.Character.Prop.PROTECT);
      Add();
      Add(Language.GetLang(66), Creatures.Character.GetRadius);
      Add(Language.GetLang(35), Creatures.Character.Turns);
      Add(Language.GetLang(36), Creatures.Character.Rating);
      Add();
      // Location
      if ParamDebug then
        S := ' (' + IntToStr(Creatures.Character.Dungeon) + ')'
      else
        S := '';
      Add(Language.GetLang(110),
        Language.GetLang(MapPatterns.GetPattern.Id) + S);
      Add();
      Draw(Graph.Surface.Width - 72, Graph.CharHeight, SceneInv.Hero);
    end;
    Graph.Text.BarOut('space', Language.GetLang(25), False);
    RenderSkills;
    // Calendar();
    Graph.Render;
  except
    on E: Exception do
      Error.Add('SceneChar.Render', E.Message);
  end;
end;

procedure TSceneChar.RenderSkills;
var
  S4, X, Y: Word;
  LSkill: TSkill;
  I: Integer;
begin
  S4 := ((Graph.Surface.Width div 4) div Graph.CharWidth);
  X := 2;
  Y := 6;
  for I := 0 to Skills.SkillList.Count - 1 do
  begin
    LSkill := Skills.SkillList[I];
    Graph.Surface.Canvas.Brush.Color := cDkGray;
    Graph.Text.DrawOut(S4 * X, Y, Space(S4));
    Graph.Surface.Canvas.Font.Color := cRdYellow;
    Graph.Surface.Canvas.Brush.Color := cBlack;
    Graph.Text.DrawOut(S4 * X, Y - 1, Language.GetLang(I + 201));
    Graph.Text.DrawOut(S4 * X + (S4 - (Length(IntToStr(LSkill.Level)))), Y - 1,
      IntToStr(LSkill.Level));
    Graph.Surface.Canvas.Brush.Color := cRdYellow;
    Graph.Text.DrawOut(S4 * X, Y,
      Space(Round(LSkill.EXP * S4 / TSkill.MaxExp)));
    if ParamDebug and (LSkill.EXP > 0) then
    begin
      Graph.Surface.Canvas.Font.Color := cRdGray;
      Graph.Text.DrawOut(S4 * X, Y, IntToStr(LSkill.EXP));
    end;
    Graph.Surface.Canvas.Brush.Color := cBlack;
    // Line
    Graph.Surface.Canvas.Pen.Width := 1;
    Graph.Surface.Canvas.Pen.Color := cBlack;
    Graph.Surface.Canvas.MoveTo(S4 * 3 * Graph.CharWidth - 1,
      Y * Graph.CharHeight);
    Graph.Surface.Canvas.LineTo(S4 * 3 * Graph.CharWidth - 1,
      (Y * Graph.CharHeight) + Graph.CharHeight);
    //
    Inc(X);
    if (X > 3) then
    begin
      Inc(Y, 2);
      X := 2;
    end;
  end;
end;

function TSceneChar.Space(C: Byte): string;
var
  I: Byte;
begin
  Result := '';
  for I := 1 to C do
    Result := Result + #32;
end;

initialization

SceneChar := TSceneChar.Create;

finalization

SceneChar.Free;

end.
