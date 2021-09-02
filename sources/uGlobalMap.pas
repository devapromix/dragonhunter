﻿unit uGlobalMap;

interface

uses Classes, uCustomMap, uUtils;

type
  TGlobalMap = class(TCustomMap)
  private
    FF: TStringList;
    FMap: array [0 .. MapSide - 1, 0 .. MapSide - 1] of Byte;
    function GetText: string;
    procedure SetText(const Value: string);
    function GetLocalMapLevel(const X, Y: Integer): Integer;
  public
    procedure Gen;
    procedure Clear; override;
    procedure Render; override;
    constructor Create;
    destructor Destroy; override;
    procedure Save;
    procedure Load;
    property Text: string read GetText write SetText;

  end;

implementation

{ TGlobalMap }

uses SysUtils, uError;

const
  MapMinLevel = 0;
  MapMaxLevel = 20;

procedure TGlobalMap.Clear;
var
  X, Y: Integer;
begin
  for Y := 0 to Self.Height - 1 do
    for X := 0 to Self.Width - 1 do
      FMap[X][Y] := 0;
end;

constructor TGlobalMap.Create;
begin
  inherited;
  Self.Clear;
  FF := TStringList.Create;
end;

destructor TGlobalMap.Destroy;
begin
  FF.Free;
  inherited;
end;

procedure TGlobalMap.Gen;
var
  J, X, Y: Integer;
begin
  try
    for J := 1 to MapMaxLevel do
    begin
      repeat
        X := Rand(0, MapSide - 1);
        Y := Rand(0, MapSide - 1);
      until (GetLocalMapLevel(X, Y) = J);
      FMap[X][Y] := J;
    end;
  except
    on E: Exception do
      Error.Add('GlobalMap.Gen', E.Message);
  end;
end;

function TGlobalMap.GetText: string;
begin
  Self.Save;
  Result := FF.Text;
end;

function TGlobalMap.GetLocalMapLevel(const X, Y: Integer): Integer;
const
  V = MapSide div 2;
var
  S, PX, PY: Integer;
begin
  Result := 0;
  PX := ABS(X - V);
  PY := ABS(Y - V);
  S := Max(PX, PY);
  Result := S div 3;
  Result := Clamp(Result, MapMinLevel, MapMaxLevel);
end;

procedure TGlobalMap.Load;
begin

end;

procedure TGlobalMap.Render;
begin

end;

procedure TGlobalMap.Save;
var
  X, Y: Integer;
  S: string;
begin
  FF.Clear;
  for Y := 0 to Self.Height - 1 do
  begin
    S := '';
    for X := 0 to Self.Width - 1 do
      S := S + Chr((Ord('a') - 1) + FMap[X][Y]);
    FF.Append(S);
  end;
end;

procedure TGlobalMap.SetText(const Value: string);
begin

end;

end.
