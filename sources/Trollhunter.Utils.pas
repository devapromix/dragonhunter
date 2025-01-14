﻿unit Trollhunter.Utils;

interface

uses
  Windows,
  Graphics,
  SysUtils,
  Types;

const
  BaseTileSize = 32;
  MapSide = 134;

var
  TileSize: Byte = 32;
  FontSize: Byte = 12;

type
  TExplodeResult = array of string;

type
  TCursorMode = (cmNone, cmLook, cmShoot, cmSearch);

var
  CursorMode: TCursorMode = cmNone;

var
  Path: string = '';

var
  IsGame: Boolean = False;
  ParamTest: Boolean = False;
  ParamWindow: Boolean = False;
  ParamMove: Boolean = False;
  ParamLight: Boolean = False;
  ParamDebug: Boolean = False;

function IsRealMapCell(X, Y: Integer): Boolean;
function IsValidCell(X, Y: Integer): Boolean;
function Clamp(Value, AMin, AMax: Integer): Integer;
function ClampCycle(Value, AMin, AMax: Integer): Integer;
function GetFileDate(TheFileName: string): string;
procedure Gamma(Bitmap: Graphics.TBitmap; L: Double);
function AddMultiLineText(aText: string; Canv: TCanvas; aRect: TRect): Integer;
procedure ScaleBmp(var ABitmap: Graphics.TBitmap; CX, CY: Integer);
function LastPos(const SubStr, Source: string;
  const IgnoreCase: Boolean = True): Integer;
function StrRight(S: string; I: Integer): string;
function StrLeft(S: string; I: Integer): string;
function Explode(const Separator: Char; Source: string)
  : TExplodeResult; overload;
function Explode(const Count: Integer; Source: string): TExplodeResult;
  overload;
function BarWidth(CX, MX, GS: Integer): Integer;
function Percent(N, P: Integer): Integer;
function MakeDir(const DirName: string): Boolean;
function Rand(A, B: Integer): Integer;
function LineDist(x1, y1, x2, y2: Integer): Boolean;
function GetDist(x1, y1, x2, y2: single): word;
function Max(A, B: Integer): Integer;
function Min(A, B: Integer): Integer;
procedure OpenChest(const F: Boolean);
function InRange(X, A, B: Integer): Boolean;
function DelFile(const AName: string): Boolean;
function ToStr(Value: Boolean): string;
function ToInt(Value: Boolean): Integer;
function ToBoo(Value: string): Boolean;
procedure TransKeys(var Key: word);
function GetParams: TPoint;
function GetParamFontSize: Integer;
function RemoveBack(C: Char; S: string): string;
function ExplodeString(const AString: string): TArray<string>;
function GetStrValue(Key, S: string): string;
function GetStrKey(Key, S: string): string;
function TrueOrFalse(const AValue: Boolean): string;
function ColorToInt(const AColor: string): Integer;
function AppendToString(const AString: string;
  const ANewString: string): string;

implementation

uses
  Math,
  Forms,
  StrUtils,
  Classes,
  Dragonhunter.Item,
  Trollhunter.Lang,
  Trollhunter.Map.Tiles,
  Dragonhunter.Map,
  Trollhunter.Log,
  Trollhunter.Creatures,
  Dragonhunter.AStar,
  Trollhunter.Error,
  Dragonhunter.Color;

var
  LExplodeResult: TExplodeResult;
  LGameVersion: string = '';

function IsRealMapCell(X, Y: Integer): Boolean;
begin
  Result := (X > 0) and (Y > 0) and (X < MapSide - 1) and (Y < MapSide - 1);
end;

function IsValidCell(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (Y >= 0) and (X <= MapSide - 1) and (Y <= MapSide - 1);
end;

function Clamp(Value, AMin, AMax: Integer): Integer;
begin
  Result := Value;
  if Result < AMin then
    Result := AMin;
  if Result > AMax then
    Result := AMax;
end;

function ClampCycle(Value, AMin, AMax: Integer): Integer;
begin
  Result := Value;
  if (Result < AMin) then
    Result := AMax;
  if (Result > AMax) then
    Result := AMin;
end;

function GetFileDate(TheFileName: string): string;
var
  LHandle: Integer;
begin
  LHandle := FileOpen(TheFileName, 0);
  Result := DateTimeToStr(FileDateToDateTime(FileGetDate(LHandle)));
  FileClose(LHandle);
end;

function RemoveBack(C: Char; S: string): string;
begin
  Result := S;
  if (Trim(Result) = '') then
    Exit('');
  if Result[Length(Result)] = C then
    Delete(Result, Length(Result), 1);
end;

function ExplodeString(const AString: string): TArray<string>;
begin
  Result := AString.Split([',']);
end;

procedure Gamma(Bitmap: Graphics.TBitmap; L: Double);

  function Power(Base, Exponent: Extended): Extended;
  begin
    Result := Exp(Exponent * Ln(Base));
  end;

type
  TRGB = record
    B, G, R: Byte;
  end;

  pRGB = ^TRGB;

var
  Dest: pRGB;
  X, Y: word;
  GT: array [0 .. 255] of Byte;

begin
  Bitmap.PixelFormat := pf24Bit;
  GT[0] := 0;
  if L = 0 then
    L := 0.01;
  for X := 1 to 255 do
    GT[X] := Round(255 * Power(X / 255, 1 / L));
  for Y := 0 to Bitmap.Height - 1 do
  begin
    Dest := Bitmap.ScanLine[Y];
    for X := 0 to Bitmap.Width - 1 do
    begin
      with Dest^ do
      begin
        R := GT[R];
        G := GT[G];
        B := GT[B];
      end;
      Inc(Dest);
    end;
  end;
end;

function ToStr(Value: Boolean): string;
begin
  if Value then
    Result := '1'
  else
    Result := '0';
end;

function ToInt(Value: Boolean): Integer;
begin
  if Value then
    Result := 1
  else
    Result := 0;
end;

function ToBoo(Value: string): Boolean;
begin
  Result := (Value = '1');
end;

function AddMultiLineText(aText: string; Canv: TCanvas; aRect: TRect): Integer;
var
  I, C, LRes: word;
  SL: TStringList;
  S: string;
  TH: Integer;

  procedure AddRow(AStr: string);
  begin
    Canv.TextOut(aRect.Left, LRes * TH + aRect.Top, AStr);
  end;

  function Addline(AStr, aword: string): Boolean;
  begin
    Result := Canv.TextWidth(AStr + aword) >= aRect.Right;
    if Result then
    begin
      AddRow(AStr);
      Inc(LRes)
    end;
  end;

  procedure WordDivider;
  begin
    SL := TStringList.Create;
    StringReplace(aText, '  ', ' ', [rfReplaceAll]); // kill all double-space
    SL.Delimiter := ' ';
    SL.DelimitedText := aText; // divide all Text into words
  end;

begin
  WordDivider;
  LRes := 0;
  S := '';
  TH := Canv.TextHeight('1') - 10;
  C := SL.Count - 1;
  for I := 0 to C do
  begin
    if Addline(S, SL[I]) then // if string fits then inscribe it
      S := ''; // and Clear it //
    S := S + SL[I] + ' '; // and Add a word
    if (I = C) and (S <> '') then // if needed Add last string
    begin
      AddRow(S);
      Inc(LRes);
    end;
  end;
  Result := LRes;
  FreeAndNil(SL);
end;

procedure ScaleBmp(var ABitmap: Graphics.TBitmap; CX, CY: Integer);
var
  B: Graphics.TBitmap;
begin
  B := Graphics.TBitmap.Create;
  try
    B.Width := CX;
    B.Height := CY;
    B.Canvas.StretchDraw(Rect(0, 0, CX, CY), ABitmap);
    ABitmap.Assign(B);
  finally
    FreeAndNil(B);
  end;
end;

function LastPos(const SubStr, Source: string;
  const IgnoreCase: Boolean): Integer;
var
  Found, Len, Pos: Integer;
begin
  Pos := Length(Source);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if IgnoreCase then
    begin
      if (LowerCase(Copy(Source, Pos, Len)) = LowerCase(SubStr)) then
        Found := Pos;
      Dec(Pos);
    end
    else
    begin
      if Copy(Source, Pos, Len) = SubStr then
        Found := Pos;
      Dec(Pos);
    end;
  end;
  Result := Found;
end;

function Explode(const Count: Integer; Source: string): TExplodeResult;
var
  A: Integer;
  S, P: string;
begin
  S := Source;
  SetLength(Result, 0);
  while (Length(S) > Count) do
  begin
    SetLength(Result, Length(Result) + 1);
    P := Copy(S, 1, Count);
    A := LastPos(#32, P);
    P := Copy(S, 1, A);
    Result[High(Result)] := P;
    Delete(S, 1, A);
  end;
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := S;
end;

function Explode(const Separator: Char; Source: string): TExplodeResult;
var
  I: Integer;
  S: string;
begin
  Result := nil;
  S := Source;
  SetLength(Result, 0);
  I := 0;
  while Pos(Separator, S) > 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[I] := Copy(S, 1, Pos(Separator, S) - 1);
    Inc(I);
    S := Copy(S, Pos(Separator, S) + Length(Separator), Length(S));
  end;
  SetLength(Result, Length(Result) + 1);
  Result[I] := Copy(S, 1, Length(S));
end;

function BarWidth(CX, MX, GS: Integer): Integer;
var
  I: Integer;
begin
  if (CX = MX) and (CX = 0) then
  begin
    Result := 0;
    Exit;
  end;
  if (MX <= 0) then
    MX := 1;
  I := (CX * GS) div MX;
  if I <= 0 then
    I := 0;
  if (CX >= MX) then
    I := GS;
  Result := I;
end;

function Percent(N, P: Integer): Integer;
begin
  if (P = 0) then
    Result := N
  else
    Result := N * P div 100
end;

function MakeDir(const DirName: string): Boolean;
begin
  Result := False;
  if not DirectoryExists(Path + DirName) then
  begin
    MkDir(Path + DirName);
    Result := True;
  end;
end;

function Rand(A, B: Integer): Integer;
begin
  Result := Round(Random(B - A + 1) + A);
end;

function GetDist(x1, y1, x2, y2: single): word;
begin
  Result := Round(sqrt(sqr(x2 - x1) + sqr(y2 - y1)));
end;

function LineDist(x1, y1, x2, y2: Integer): Boolean;
var
  I, L, AX, AY: Integer;
  LR: Real;
begin
  Result := False;
  L := Math.Max(Abs(x1 - x2), Abs(y1 - y2));
  for I := 1 to L - 1 do
  begin
    LR := I / L;
    AX := x1 + Round((x2 - x1) * LR);
    AY := y1 + Round((y2 - y1) * LR);
    if not Creatures.Character.FreeCell(AX, AY) then
      Exit;
  end;
  Result := True;
  {
    procedure FlyItem(X, Y, K: Integer);
    var
    I, L, AX, AY, TX, TY, V, RX, RY: Integer;
    LR: Real;
    begin
    TX := PC.X; TY := PC.Y;
    L := Math.Max(Abs(PC.X - X), Abs(PC.Y - Y));
    if (L > 10) then Exit;
    for I := 1 to L - 1 do
    begin
    LR := I / L;
    AX := PC.X + Round((X - PC.X) * LR);
    AY := PC.Y + Round((Y - PC.Y) * LR);
    if (Cave.Dungeon[PC.Z].Cell[AX][AY].Terrain = 1) then Break;
    RX := AX - TX; RY := AY - TY;
    begin
    if ((RX > 0) and (RY > 0)) or ((RX < 0) and (RY < 0)) then V := 2;
    if ((RX > 0) and (RY < 0)) or ((RX < 0) and (RY > 0)) then V := 1;
    if (RY = 0) then V := 0;
    if (RX = 0) then V := 3;
    end;
    Cave.Dungeon[PC.Z].Cell[AX][AY].Fire := K + V;
    Cave.Dungeon[PC.Z].Cell[TX][TY].Fire := 0;
    Draw();
    Application.ProcessMessages;
    Sleep(1);
    TX := AX; TY := AY;
    end;
    Cave.Dungeon[PC.Z].Cell[AX][AY].Fire := 0;
    Draw();
    end;
  }

end;

function Max(A, B: Integer): Integer;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

function Min(A, B: Integer): Integer;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;

function InRange(X, A, B: Integer): Boolean;
begin
  Result := (X >= A) and (X <= B);
end;

function StrRight(S: string; I: Integer): string;
var
  L: Integer;
begin
  L := Length(S);
  Result := Copy(S, L - I + 1, L);
end;

function FileVersion(AFileName: string): string;
var
  szName: array [0 .. 255] of Char;
  P: Pointer;
  Value: Pointer;
  Len: UINT;
  GetTranslationString: string;
  FFileName: PChar;
  FValid: Boolean;
  FSize: DWORD;
  FHandle: DWORD;
  FBuffer: PChar;
begin
  Result := '';
  FBuffer := #0;
  FFileName := StrPCopy(StrAlloc(Length(AFileName) + 1), AFileName);
  FValid := False;
  FSize := GetFileVersionInfoSize(FFileName, FHandle);
  try
    if FSize > 0 then
      try
        GetMem(FBuffer, FSize);
        FValid := GetFileVersionInfo(FFileName, FHandle, FSize, FBuffer);
      except
        FValid := False;
      end;
    if (FValid = True) then
      VerQueryValue(FBuffer, '\VarFileInfo\Translation', P, Len)
    else
      P := nil;
    if P <> nil then
      GetTranslationString :=
        IntToHex(MakeLong(HiWord(Longint(P^)), LoWord(Longint(P^))), 8);
    if FValid then
    begin
      StrPCopy(szName, '\StringFileInfo\' + GetTranslationString +
        '\FileVersion');
      if VerQueryValue(FBuffer, szName, Value, Len) then
        Result := StrPas(PChar(Value));
    end;
  finally
    try
      if FBuffer <> nil then
        FreeMem(FBuffer, FSize);
    except
    end;
    try
      StrDispose(FFileName);
    except
    end;
  end;
end;

function StrLeft(S: string; I: Integer): string;
begin
  Result := Copy(S, 1, I);
end;

function DelFile(const AName: string): Boolean;
begin
  Result := False;
  try
    Result := DeleteFile(Path + 'save\' + AName + '.sav');
  except
    on E: Exception do
      Error.Add('Utils.DelFile', E.Message);
  end;
end;

procedure TransKeys(var Key: word);
begin
  if (Key = 100) then
    Key := 37;
  if (Key = 104) then
    Key := 38;
  if (Key = 102) then
    Key := 39;
  if (Key = 98) then
    Key := 40;
end;

function GetParamFontSize: Integer;
var
  S: string;
  I: Integer;
begin
  Result := 11;
  if (ParamCount > 0) then
    for I := 1 to ParamCount do
    begin
      S := Trim(ParamStr(I));
      case S[2] of
        // Font size
        's':
          begin
            Delete(S, 1, 2);
            Result := StrToIntDef(S, Result);
          end;
      end;
    end;
end;

function GetParams: TPoint;
var
  S: string;
  I: Integer;
  L: TStringList;
begin
  Result.X := Screen.Width;
  Result.Y := Screen.Height;
  if (ParamCount > 0) then
    for I := 1 to ParamCount do
    begin
      S := Trim(ParamStr(I));
      case S[2] of
        // Debug
        'd':
          ParamDebug := True;
        // Test
        't':
          ParamTest := True;
        // Move
        'm':
          ParamMove := True;
        // Window
        'w':
          ParamWindow := True;
        // Light
        'l':
          ParamLight := True;
        // Res
        'r':
          begin
            Delete(S, 1, 2);
            L := TStringList.Create;
            try
              L.Delimiter := 'x';
              L.DelimitedText := S;
              Result.X := StrToIntDef(L[0], Result.X);
              Result.Y := StrToIntDef(L[1], Result.Y);
            finally
              L.Free;
            end;
          end;

      end;
    end;
end;

procedure OpenChest(const F: Boolean);
var
  I, J: Byte;
begin
  J := 0;
  case Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X].Tile of
    tlClosedBarrel:
      begin
        Log.Add(Language.GetLang(55));
        Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X].Tile :=
          tlOpenBarrel;
        J := 2;
      end;
    tlClosedWoodChest, tlLockedWoodChest:
      begin
        Log.Add(Language.GetLang(45));
        Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X].Tile :=
          tlOpenWoodChest;
        J := 3;
      end;
    tlLockedBestChest:
      begin
        Log.Add(Language.GetLang(45));
        Map.Cell[Creatures.Character.Pos.Y][Creatures.Character.Pos.X].Tile :=
          tlOpenBestChest;
        J := 5;
      end;
  end;
  for I := 0 to J do
  begin
    Dragonhunter.Item.Items.Add(Creatures.Character.Pos.X,
      Creatures.Character.Pos.Y, Map.GetRandItemID);
    if not F or (Rand(1, 2) = 1) then
      Break;
  end;
end;

function GetStrKey(Key, S: String): String;
begin
  Result := Copy(S, 1, Pos(Key, S) - 1);
end;

function GetStrValue(Key, S: String): String;
begin
  Result := Copy(S, Pos(Key, S) + 1, Length(S));
end;

function TrueOrFalse(const AValue: Boolean): string;
begin
  Result := IfThen(AValue, 'true', 'false');
end;

function ColorToInt(const AColor: string): Integer;
begin
  if AColor = 'GRAY' then
    Result := Integer(cGray)
  else if AColor = 'RED' then
    Result := Integer(cRed)
  else if AColor = 'GREEN' then
    Result := Integer(cGreen)
  else if AColor = 'BLUE' then
    Result := Integer(cBlue)
  else if AColor = 'YELLOW' then
    Result := Integer(cYellow)
  else if AColor = 'PURPLE' then
    Result := Integer(cYellow)
  else
    Result := Integer(clWhite);
end;

function AppendToString(const AString: string;
  const ANewString: string): string;
begin
  Result := RemoveBack(',', AString);
  if Result = '' then
    Result := ANewString
  else
    Result := Result + ',' + ANewString;
  Result := RemoveBack(',', Result);
end;

initialization

Randomize;
Path := ExtractFilePath(ParamStr(0));
MakeDir('save');
LExplodeResult := Explode('.', FileVersion(ParamStr(0)));
LGameVersion := LExplodeResult[0] + '.' + LExplodeResult[1] + '.' +
  LExplodeResult[2];
if (StrToInt(LExplodeResult[3]) in [1 .. 26]) then
  LGameVersion := LGameVersion + Chr(96 + StrToInt(LExplodeResult[3]))
else if (StrToInt(LExplodeResult[3]) > 0) then
  LGameVersion := LGameVersion + '.' + LExplodeResult[3];

end.
