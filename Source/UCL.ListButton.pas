﻿unit UCL.ListButton;
interface
uses
  Classes, SysUtils, Types, Messages, Controls, ExtCtrls, ImgList, Graphics, Windows,
  UCL.Classes, UCL.ThemeManager, UCL.Colors, UCL.Graphics, UCL.Utils;
type
  TUListStyle = (lsRightDetail, lsBottomDetail, lsVertical);
  TUSelectMode = (smNone, smSelect, smToggle);
  TUListButton = class(TPanel, IUControl)
    private
      var BackColor, TextColor, DetailColor: TColor;
      var ImgRect, TextRect, DetailRect: TRect;
      FIconFont: TFont;
      FCustomBackColor: TUStateColorSet;
      
      FButtonState: TUControlState;
      FListStyle: TUListStyle;
      FImageKind: TUImageKind;
      FImages: TCustomImageList;
      FImageIndex: Integer;
      FFontIcon: string;
      
      FImageSpace: Integer;
      FSpacing: Integer;
      FDetail: string;
      FTransparent: Boolean;
      FSelectMode: TUSelectMode;
      FSelected: Boolean;
      //  Internal
      procedure UpdateColors;
      procedure UpdateRects;
      //  Setters
      procedure SetButtonState(const Value: TUControlState);
      procedure SetListStyle(const Value: TUListStyle);
      procedure SetImageKind(const Value: TUImageKind);
      procedure SetImages(const Value: TCustomImageList);
      procedure SetImageIndex(const Value: Integer);
      procedure SetFontIcon(const Value: string);
      procedure SetImageSpace(const Value: Integer);
      procedure SetSpacing(const Value: Integer);
      procedure SetDetail(const Value: string);
      procedure SetTransparent(const Value: Boolean);
      procedure SetSelectMode(const Value: TUSelectMode);
      procedure SetSelected(const Value: Boolean);
      //  Getters
      function GetSelected: Boolean;
      //  Child events
      procedure CustomBackColor_OnChange(Sender: TObject);
      
      //  Messages
      procedure WM_LButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
      procedure WM_LButtonUp(var Msg: TWMLButtonUp); message WM_LBUTTONUP;
      procedure CM_MouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
      procedure CM_MouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
      procedure CM_EnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
      procedure CM_TextChanged(var Msg: TMessage); message CM_TEXTCHANGED;
    protected
      procedure Paint; override;
      procedure Resize; override;
      procedure CreateWindowHandle(const Params: TCreateParams); override;
      procedure ChangeScale(M, D: Integer{$IF CompilerVersion > 29}; isDpiChange: Boolean{$ENDIF}); override;
    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;
      procedure Loaded; override;
      //  Interface
      function IsContainer: Boolean;
      procedure UpdateTheme(const UpdateChildren: Boolean);
    published
      property IconFont: TFont read FIconFont write FIconFont;
      property CustomBackColor: TUStateColorSet read FCustomBackColor write FCustomBackColor;
      property ButtonState: TUControlState read FButtonState write SetButtonState default csNone;
      property ListStyle: TUListStyle read FListStyle write SetListStyle default lsRightDetail;
      property ImageKind: TUImageKind read FImageKind write SetImageKind default ikFontIcon;
      property Images: TCustomImageList read FImages write SetImages;
      property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
      property FontIcon: string read FFontIcon write SetFontIcon nodefault;
      property ImageSpace: Integer read FImageSpace write SetImageSpace default 40;
      property Spacing: Integer read FSpacing write SetSpacing default 10;
      
      property Detail: string read FDetail write SetDetail nodefault;
      property Transparent: Boolean read FTransparent write SetTransparent default false;
      property SelectMode: TUSelectMode read FSelectMode write SetSelectMode default smNone;
      property Selected: Boolean read GetSelected write SetSelected default false;
      //  Modify default props
      property BevelOuter default bvNone;
      property ParentBackground default false;
      property TabStop default true;
      property FullRepaint default false;
  end;
implementation
uses
  UCL.FontIcons;
{ TUListButton }
//  INTERFACE
function TUListButton.IsContainer: Boolean;
begin
  Result := false;
end;
procedure TUListButton.UpdateTheme(const UpdateChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;
  //  Do not update children
end;
//  INTERNAL
procedure TUListButton.UpdateColors;
var 
  TM: TUThemeManager;
  _BackColor: TUStateColorSet;
  AccentColor: TColor;
  IsSelected: Boolean;
  IsDark: Boolean;
begin
  //  Prepairing
  TM := SelectThemeManager(Self);
  IsDark := (TM <> nil) and (TM.Theme = utDark);
  AccentColor := SelectAccentColor(TM, $D77800);
  _BackColor := SelectColorSet(TM, CustomBackColor, LISTBUTTON_BACK);
  //  Disabled
  if not Enabled then
    begin
      if Transparent and (ButtonState = csNone) then
        begin
          ParentColor := true;
          BackColor := Color;
        end
      else if IsDark then
        BackColor := $333333
      else
        BackColor := $CCCCCC;
      TextColor := $666666;
      DetailColor := $808080;
    end
  //  Enabled
  else
    begin
      IsSelected := Selected;
      //  Selected
      if IsSelected then
        BackColor := ColorChangeLightness(AccentColor, _BackColor.GetColor(TM, ButtonState, IsSelected))
      //  Transparent
      else if Transparent and (ButtonState = csNone) then
        begin
          ParentColor := true;
          BackColor := Color;
        end
      //  Not selected
      else
        BackColor := _BackColor.GetColor(TM, ButtonState, IsSelected);
      //  Update text color from background
      TextColor := GetTextColorFromBackground(BackColor);
      if not IsSelected then
        DetailColor := $808080    //  Detail on grayed color
      else
        DetailColor := $D0D0D0;   //  Detail on background color
    end;
end;
procedure TUListButton.UpdateRects;
begin
  case ListStyle of
    lsRightDetail:
      begin
        ImgRect := Rect(0, 0, ImageSpace, Height);
        TextRect := Rect(ImageSpace, 0, Width - Spacing, Height);
        DetailRect := Rect(ImageSpace, 0, Width - Spacing, Height)
      end;
    lsBottomDetail:
      begin
        ImgRect := Rect(0, 0, ImageSpace, Height);
        TextRect := Rect(ImageSpace, 0, Width - Spacing, Height div 2);
        DetailRect := Rect(ImageSpace, Height div 2, Width - Spacing, Height);
      end;
    lsVertical:
      begin
        ImgRect := Rect(0, 0, Width, ImageSpace);
        TextRect := Rect(0, ImageSpace, Width, Height - Spacing);
        DetailRect := Rect(0, ImageSpace, Width, Height - Spacing);
      end;
  end;
end;
//  SETTERS
procedure TUListButton.SetButtonState(const Value: TUControlState);
begin
  if Value <> FButtonState then
    begin
      FButtonState := Value;
      UpdateColors;
      Invalidate;
    end;
end;
procedure TUListButton.SetListStyle(const Value: TUListStyle);
begin
  if Value <> FListStyle then
    begin
      FListStyle := Value;
      UpdateRects;
      Invalidate;
    end;
end;
procedure TUListButton.SetImageKind(const Value: TUImageKind);
begin
  if Value <> FImageKind then
    begin
      FImageKind := Value;
      Invalidate;
    end;
end;
procedure TUListButton.SetImages(const Value: TCustomImageList);
begin
  if Value <> FImages then
    begin
      FImages := Value;
      Invalidate;
    end;
end;
procedure TUListButton.SetImageIndex(const Value: Integer);
begin
  if Value <> FImageIndex then
    begin
      FImageIndex := Value;
      Invalidate;
    end;
end;
procedure TUListButton.SetFontIcon(const Value: string);
begin
  if Value <> FFontIcon then
    begin
      FFontIcon := Value;
      Invalidate;
    end;
end;
procedure TUListButton.SetImageSpace(const Value: Integer);
begin
  if Value <> FImageSpace then
    begin
      FImageSpace := Value;
      UpdateRects;
      Invalidate;
    end;
end;
procedure TUListButton.SetSpacing(const Value: Integer);
begin
  if Value <> FSpacing then
    begin
      FSpacing := Value;
      UpdateRects;
      Invalidate;
    end;
end;
procedure TUListButton.SetDetail(const Value: string);
begin
  if Value <> FDetail then
    begin
      FDetail := Value;
      UpdateRects;
      Invalidate;
    end;
end;
procedure TUListButton.SetTransparent(const Value: Boolean);
begin
  if Value <> FTransparent then
    begin
      FTransparent := Value;
      UpdateColors;
      Invalidate;
    end;
end;
procedure TUListButton.SetSelectMode(const Value: TUSelectMode);
begin
  if Value <> FSelectMode then
    begin
      FSelectMode := Value;
      UpdateColors;
      Invalidate;
    end;
end;
procedure TUListButton.SetSelected(const Value: Boolean);
var
  i: Integer;
  Item: TUListButton;
begin
  if Value <> FSelected then
    begin
      FSelected := Value;
      if Value and (FSelectMode = smSelect) then
        begin
          for i := 0 to Parent.ControlCount - 1 do
            if Parent.Controls[i] is TUListButton then
              begin
                Item := Parent.Controls[i] as TUListButton;
                if Item <> Self then
                  Item.Selected := false;
              end;
        end;
      UpdateColors;
      Invalidate;
    end;
end;
//  GETTERS
function TUListButton.GetSelected: Boolean;
begin
  case SelectMode of
    smNone:
      Result := false;
    smSelect:
      Result := FSelected;
    smToggle:
      Result := FSelected;
    else
      Result := false;
  end;
end;
//  CHILD EVENTS
procedure TUListButton.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;
//  MAIN CLASS
constructor TUListButton.Create(aOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle - [csDoubleClicks];
  FButtonState := csNone;
  FImageKind := ikFontIcon;
  FImageIndex := -1;
  FFontIcon := UF_BACK;
  FListStyle := lsRightDetail;
  FImageSpace := 40;
  FSpacing := 10;
  FDetail := 'Detail';
  FTransparent := false;
  FSelectMode := smNone;
  FSelected := false;
  FIconFont := TFont.Create;
  IconFont.Name := 'Segoe MDL2 Assets';
  IconFont.Size := 12;
  FCustomBackColor := TUStateColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(LISTBUTTON_BACK);
  //  Modify default props
  BevelOuter := bvNone;
  ParentBackground := false;
  TabStop := true;
  FullRepaint := false;
end;
destructor TUListButton.Destroy;
begin
  FIconFont.Free;
  FCustomBackColor.Free;
  inherited;
end;
procedure TUListButton.Loaded;
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;
//  CUSTOM METHODS
procedure TUListButton.Paint;
var 
  ImgX, ImgY: Integer;
  IsSeparator: boolean;
begin
  //  Do not inherited
  //  Paint background
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.FillRect(Rect(0, 0, Width, Height));
  Canvas.Brush.Style := bsClear;
  //  Draw image
  if ImageKind = ikFontIcon then
    begin
      //  Set up icon font
      Canvas.Font.Assign(IconFont);
      Canvas.Font.Color := TextColor;
      //  Draw font icon
      DrawTextRect(Canvas, taCenter, taVerticalCenter, ImgRect, FontIcon, false);
    end
  else if (Images <> nil) and (ImageIndex >= 0) then
    begin
      GetCenterPos(Images.Width, Images.Height, ImgRect, ImgX, ImgY);
      Images.Draw(Canvas, ImgX, ImgY, ImageIndex, Enabled);
    end;
  //  Draw text
  IsSeparator := false;
  if Caption = '-' then
    IsSeparator := true;
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := TextColor;
  if NOT IsSeparator then
  case ListStyle of
    lsRightDetail, lsBottomDetail:
      DrawTextRect(Canvas, taLeftJustify, taVerticalCenter, TextRect, Caption, false);
    lsVertical:
      DrawTextRect(Canvas, taCenter, taAlignTop, TextRect, Caption, false);
  end;
  if IsSeparator then
    with Canvas do begin
      Pen.Width := 0;
      Pen.Color := DetailColor;

      MoveTo(15, Height div 2);
      LineTo(Width - 15, Height div 2);
    end;
  //  Detail
  Canvas.Font.Color := DetailColor;
  case ListStyle of
    lsRightDetail:
      DrawTextRect(Canvas, taRightJustify, taVerticalCenter, DetailRect, Detail, false);
    lsBottomDetail:
      DrawTextRect(Canvas, taLeftJustify, taAlignTop, DetailRect, Detail, false);
    lsVertical:
      DrawTextRect(Canvas, taCenter, taAlignBottom, DetailRect, Detail, false);
  end;
end;
procedure TUListButton.Resize;
begin
  inherited;
  UpdateRects;
end;
procedure TUListButton.CreateWindowHandle(const Params: TCreateParams);
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;
procedure TUListButton.ChangeScale(M, D: Integer{$IF CompilerVersion > 29}; isDpiChange: Boolean{$ENDIF});
begin
  inherited;
  FImageSpace := MulDiv(ImageSpace, M, D);
  FSpacing := MulDiv(Spacing, M, D);
  IconFont.Height := MulDiv(IconFont.Height, M, D);
  UpdateRects;
end;
//  MESSAGES
procedure TUListButton.WM_LButtonDown(var Msg: TWMLButtonDown);
begin
  if not Enabled then exit;
  ButtonState := csPress;
  inherited;
end;
procedure TUListButton.WM_LButtonUp(var Msg: TWMLButtonUp);
var
  MousePoint: TPoint;
begin
  if not Enabled then exit;
  MousePoint := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, MousePoint) then
    begin
      //  Select actions
      case SelectMode of
        smNone:
          Selected := false;
        smSelect:
          Selected := true;
        smToggle:
          Selected := not Selected;
      end;
    end;
  ButtonState := csHover;
  inherited;
end;
procedure TUListButton.CM_MouseEnter(var Msg: TMessage);
begin
  if not Enabled then exit;
  ButtonState := csHover;
  inherited;
end;
procedure TUListButton.CM_MouseLeave(var Msg: TMessage);
begin
  if not Enabled then exit;
  ButtonState := csNone;
  inherited;
end;
procedure TUListButton.CM_EnabledChanged(var Msg: TMessage);
begin
  UpdateColors;
  Invalidate;
  inherited;
end;
procedure TUListButton.CM_TextChanged(var Msg: TMessage);
begin
  UpdateRects;
  Invalidate;
  inherited;  
end;
end.
