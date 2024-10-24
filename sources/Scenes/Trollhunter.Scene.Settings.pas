﻿unit Trollhunter.Scene.Settings;

interface

uses
  Classes,
  System.StrUtils,
  Trollhunter.Scene,
  Trollhunter.Scene.BaseMenu;

type
  TSceneSettings = class(TSceneBaseMenu)
  private
    Count, P, T: Integer;
    CursorPos: Integer;
    procedure SettingsItem(A, B: string);
  public
    procedure Render(); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    constructor Create;
    destructor Destroy; override;
  end;

var
  SceneSettings: TSceneSettings;

implementation

uses
  Graphics,
  SysUtils,
  Trollhunter.Graph,
  Trollhunter.Color,
  Trollhunter.Scenes,
  Trollhunter.MainForm,
  Trollhunter.Scene.Menu,
  Trollhunter.Error,
  Trollhunter.Utils,
  Trollhunter.Lang,
  Trollhunter.Settings,
  Dragonhunter.Terminal;

{ TSceneSettings }

constructor TSceneSettings.Create;
begin
  inherited Create(2);
  Count := 4;
  CursorPos := 0;
end;

destructor TSceneSettings.Destroy;
begin

  inherited;
end;

procedure TSceneSettings.KeyDown(var Key: Word; Shift: TShiftState);
var
  LSettings: TSettings;

  procedure Use(I: Integer);
  begin
    case CursorPos of
      0:
        begin
          Language.ChangeLanguage;
          Render;
        end;
      1:
        begin
          with Graph.Surface.Canvas.Font do
          begin
            Size := Size + I;
            Size := Clamp(Size, 10, 20);
          end;
          Graph.Default;
          Render;
        end;
      2:
        begin
          TileSize := TileSize + (I * 16);
          TileSize := Clamp(TileSize, BaseTileSize, 64);
          Graph.Default;
          Render;
        end;
      3:
        begin
          Fullscreen := not Fullscreen;
          Graph.SetFullscreen(Fullscreen);
          Render;
        end;
    end;
  end;

begin
  inherited;
  try
    case Key of
      27, 123:
        begin
          LSettings := TSettings.Create;
          try
            LSettings.Write('Settings', 'Language',
              Language.CurrentLanguageIndex);
            LSettings.Write('Settings', 'FontSize',
              Graph.Surface.Canvas.Font.Size);
            LSettings.Write('Settings', 'TileSize',
              (TileSize - BaseTileSize) div 16);
            LSettings.Write('Settings', 'Fullscreen',
              IfThen(Fullscreen, 'Yes', 'No'));
          finally
            LSettings.Free;
          end;
        end;
      38, 40:
        begin
          CursorPos := CursorPos + (Key - 39);
          CursorPos := ClampCycle(CursorPos, 0, Count - 1);
          Render;
        end;
      37, 39:
        Use(Key - 38);
    end;
  except
    on E: Exception do
      Error.Add('SceneSettings.KeyDown (#' + IntToStr(Key) + ')', E.Message);
  end;
end;

procedure TSceneSettings.KeyPress(var Key: Char);
begin
  inherited;

end;

procedure TSceneSettings.SettingsItem(A, B: string);
var
  S, L: string;
  I, D: Integer;
begin
  try
    with Graph.Surface.Canvas do
    begin
      L := #32;
      B := '<< ' + B + ' >>';
      D := 30 - Length(A + L + B);
      for I := 0 to D do
        L := L + #32;
      S := A + L + B;
      if (CursorPos = P) then
      begin
        Font.Color := cAcColor;
        Font.Style := [fsBold];
        Graph.RenderMenuLine(P, T, False, 50, cDkGray);
      end
      else
      begin
        Font.Color := cBgColor;
        Font.Style := [];
      end;
      TextOut((Graph.Width div 2) - (TextWidth(S) div 2),
        (P * Graph.CharHeight) + T, S);
      Inc(P);
      Font.Color := cBgColor;
      Font.Style := [];
    end;
  except
    on E: Exception do
      Error.Add('SceneSettings.SettingsItem', E.Message);
  end;
end;

procedure TSceneSettings.Render;
begin
  inherited;
  try
    P := 0;
    with Graph.Surface.Canvas do
    begin
      T := (Graph.Height div 2) - ((Count - 1) * Graph.CharHeight div 2);
      SettingsItem(Language.GetLang(130), Language.LanguageName);
      SettingsItem(Language.GetLang(131), IntToStr(Font.Size));
      SettingsItem(Language.GetLang(132), IntToStr(TileSize));
      SettingsItem(Language.GetLang(133),
        IfThen(Fullscreen, Language.GetLang(13), Language.GetLang(14)));
    end;
    Frame.Draw((Terminal.Width div 2) - 28, (Terminal.Height div 2) - 3, 56, 7);    Graph.Render;
  except
    on E: Exception do
      Error.Add('SceneSettings.Render', E.Message);
  end;
end;

initialization

SceneSettings := TSceneSettings.Create;

finalization

SceneSettings.Free;

end.
