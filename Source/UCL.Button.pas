unit UCL.Button;

interface

uses
  Classes, Types, Windows, Messages, Controls, Graphics, ImgList, Forms,
  UCL.Classes, UCL.ThemeManager, UCL.Graphics, UCL.Utils, UCL.Colors;

type
  TUButton = class(TUCustomControl, IUControl)
    private
      var BorderThickness: Integer;
      var BorderColor, BackColor, TextColor: TColor;
      var ImgRect, TextRect: TRect;

      FButtonState: TUControlState;
      FCustomBackColor: TUStateColorSet;
      FCustomBorderColor: TUStateColorSet;

      FAlignment: TAlignment;
      FImages: TCustomImageList;
      FImageIndex: Integer;
      FAllowFocus: Boolean;
      FHighlight: Boolean;
      FIsToggleButton: Boolean;
      FIsToggled: Boolean;
      FTransparent: Boolean;

      //  Internal
      procedure UpdateColors;
      procedure UpdateRects;

      //  Setters
      procedure SetButtonState(const Value: TUControlState);
      procedure SetAlignment(const Value: TAlignment);
      procedure SetImages(const Value: TCustomImageList);
      procedure SetImageIndex(const Value: Integer);
      procedure SetAllowFocus(const Value: Boolean);
      procedure SetHighlight(const Value: Boolean);
      procedure SetIsToggleButton(const Value: Boolean);
      procedure SetIsToggled(const Value: Boolean);
      procedure SetTransparent(const Value: Boolean);

      //  Child events
      procedure CustomBackColor_OnChange(Sender: TObject);
      procedure CustomBorderColor_OnChange(Sender: TObject);

      //  Messages
      procedure WM_SetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
      procedure WM_KillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;

      procedure WM_LButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
      procedure WM_LButtonUp(var Msg: TWMLButtonUp); message WM_LBUTTONUP;

      procedure CM_MouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
      procedure CM_MouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
      procedure CM_EnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
      procedure CM_DialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
      procedure CM_TextChanged(var Msg: TMessage); message CM_TEXTCHANGED;

    protected
      procedure Paint; override;
      procedure Resize; override;
      procedure CreateWindowHandle(const Params: TCreateParams); override;
      procedure ChangeScale(M, D: Integer{$IF CompilerVersion > 29}; isDpiChange: Boolean{$ENDIF}); override;

    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      //  Interface
      function IsContainer: Boolean;
      procedure UpdateTheme(const UpdateChildren: Boolean);

    published
      property ButtonState: TUControlState read FButtonState write SetButtonState default csNone;
      property CustomBackColor: TUStateColorSet read FCustomBackColor write FCustomBackColor;
      property CustomBorderColor: TUStateColorSet read FCustomBorderColor write FCustomBorderColor;

      property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
      property Images: TCustomImageList read FImages write SetImages;
      property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
      property AllowFocus: Boolean read FAllowFocus write SetAllowFocus default true;
      property Highlight: Boolean read FHighlight write SetHighlight default false;
      property IsToggleButton: Boolean read FIsToggleButton write SetIsToggleButton default false;
      property IsToggled: Boolean read FIsToggled write SetIsToggled default false;
      property Transparent: Boolean read FTransparent write SetTransparent default false;

      //  Modify default props
      property Height default 30;
      property Width default 135;
      property TabStop default true;
  end;

implementation

{ TUButton }

//  INTERFACE

function TUButton.IsContainer: Boolean;
begin
  Result := false;
end;

procedure TUButton.UpdateTheme(const UpdateChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;

  //  Do not update children
end;

//  INTERNAL

procedure TUButton.UpdateColors;
var
  TM: TUThemeManager;
  IsDark: Boolean;
  AccentColor: TColor;
  _BackColor: TUStateColorSet;
  _BorderColor: TUStateColorSet;
begin
  //  Prepairing
  TM := SelectThemeManager(Self);
  IsDark := (TM <> nil) and (TM.Theme = utDark);
  AccentColor := SelectAccentColor(TM, $D77800);

  //  Disabled
  if not Enabled then
    begin
      if IsDark then
        BackColor := $333333
      else
        BackColor := $CCCCCC;
      BorderColor := BackColor;
      TextColor := $666666;
    end

  //  Others
  else
    begin
      //  Highlight
      if
        ((Highlight) or ((IsToggleButton) and (IsToggled)))
        and (ButtonState in [csNone, csHover])
      then
        begin
          BackColor := AccentColor;
          if (ButtonState = csHover) or (AllowFocus and Focused) then
            BorderColor := BrightenColor(BackColor, -32)
          else
            BorderColor := BackColor;
        end

      //  Transparent
      else if (ButtonState = csNone) and Transparent then
        begin
          ParentColor := true;
          BackColor := Color;
          BorderColor := Color;
        end

      //  Default cases
      else
        begin
          //  Select style
          _BackColor := SelectColorSet(TM, CustomBackColor, BUTTON_BACK);
          _BorderColor := SelectColorSet(TM, CustomBorderColor, BUTTON_BORDER);

          BackColor := _BackColor.GetColor(TM, ButtonState, Focused);
          BorderColor := _BorderColor.GetColor(TM, ButtonState, Focused);
        end;

      TextColor := GetTextColorFromBackground(BackColor);
    end;
end;

procedure TUButton.UpdateRects;
begin
  //  Calc rects
  if (Images <> nil) and (ImageIndex >= 0) then
    begin
      ImgRect := Rect(0, 0, Height, Height);  //  Square left align
      TextRect := Rect(Height, 0, Width, Height);
    end
  else
    TextRect := Rect(0, 0, Width, Height);
end;

//  SETTERS

procedure TUButton.SetButtonState(const Value: TUControlState);
begin
  if Value <> FButtonState then
    begin
      FButtonState := Value;
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.SetAlignment(const Value: TAlignment);
begin
  if Value <> FAlignment then
    begin
      FAlignment := Value;
      UpdateRects;
      Invalidate;
    end;
end;

procedure TUButton.SetImages(const Value: TCustomImageList);
begin
  if Value <> FImages then
    begin
      FImages := Value;
      UpdateRects;
      Invalidate;
    end;
end;

procedure TUButton.SetImageIndex(const Value: Integer);
begin
  if Value <> FImageIndex then
    begin
      FImageIndex := Value;
      UpdateRects;
      Invalidate;
    end;
end;

procedure TUButton.SetAllowFocus(const Value: Boolean);
begin
  if Value <> FAllowFocus then
    begin
      FAllowFocus := Value;
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.SetHighlight(const Value: Boolean);
begin
  if Value <> FHighlight then
    begin
      FHighlight := Value;
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.SetIsToggleButton(const Value: Boolean);
begin
  if Value <> FIsToggleButton then
    begin
      FIsToggleButton := Value;
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.SetIsToggled(const Value: Boolean);
begin
  if Value <> FIsToggled then
    begin
      FIsToggled := Value;
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.SetTransparent(const Value: Boolean);
begin
  if Value <> FTransparent then
    begin
      FTransparent := Value;
      UpdateColors;
      Invalidate;
    end;
end;

//  CHILD EVENTS

procedure TUButton.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

procedure TUButton.CustomBorderColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

//  MAIN CLASS

constructor TUButton.Create(aOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle - [csDoubleClicks];

  BorderThickness := 2;

  FButtonState := csNone;
  FAlignment := taCenter;
  FImageIndex := -1;
  FAllowFocus := true;
  FHighlight := false;
  FIsToggleButton := false;
  FIsToggled := false;
  FTransparent := false;

  FCustomBackColor := TUStateColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(BUTTON_BACK);

  FCustomBorderColor := TUStateColorSet.Create;
  FCustomBorderColor.OnChange := CustomBorderColor_OnChange;
  FCustomBorderColor.Assign(BUTTON_BORDER);

  //  Modify default props
  Height := 30;
  Width := 135;
  TabStop := true;
end;

destructor TUButton.Destroy;
begin
  FCustomBackColor.Free;
  FCustomBorderColor.Free;
  inherited;
end;

//  CUSTOM METHODS

procedure TUButton.Paint;
var
  ImgX, ImgY: Integer;
begin
  inherited;

  // Apply Pen
  Canvas.Pen.Style := psClear;

  //  Paint background
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.RoundRect(0, 0, Width, Height, ROUND_MIN_CONST, ROUND_MIN_CONST);
  //Canvas.FillRect(Rect(0, 0, Width, Height));

  //  Draw border
  DrawBorder(Canvas, Rect(0, 0, Width, Height), BorderColor, BorderThickness);

  //  Paint image
  if (Images <> nil) and (ImageIndex >= 0) then
    begin
      GetCenterPos(Images.Width, Images.Height, ImgRect, ImgX, ImgY);
      Images.Draw(Canvas, ImgX, ImgY, ImageIndex, Enabled);
    end;

  //  Paint text
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := TextColor;
  DrawTextRect(Canvas, Alignment, taVerticalCenter, TextRect, Caption, false);
end;

procedure TUButton.Resize;
begin
  inherited;
  UpdateRects;
end;

procedure TUButton.CreateWindowHandle(const Params: TCreateParams);
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;

procedure TUButton.ChangeScale(M, D: Integer{$IF CompilerVersion > 29}; isDpiChange: Boolean{$ENDIF});
begin
  inherited;
  BorderThickness := MulDiv(BorderThickness, M, D);
  UpdateRects;
end;

//  MESSAGES

procedure TUButton.WM_SetFocus(var Msg: TWMSetFocus);
begin
  if not Enabled then exit;
  if AllowFocus then
    begin
      SetFocus;
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.WM_KillFocus(var Msg: TWMKillFocus);
begin
  if not Enabled then exit;
  if AllowFocus then
    begin
      //
      UpdateColors;
      Invalidate;
    end;
end;

procedure TUButton.WM_LButtonDown(var Msg: TWMLButtonDown);
begin
  if not Enabled then exit;
  if AllowFocus then
    SetFocus;
  ButtonState := csPress;
  inherited;
end;

procedure TUButton.WM_LButtonUp(var Msg: TWMLButtonUp);
var
  MousePoint: TPoint;
begin
  if not Enabled then exit;

  MousePoint := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, MousePoint) then
    begin
      //  Change toggle state
      if IsToggleButton then
        FIsToggled := not FIsToggled;
    end;

  ButtonState := csHover;
  inherited;
end;

procedure TUButton.CM_MouseEnter(var Msg: TMessage);
begin
  if not Enabled then exit;
  ButtonState := csHover;
  inherited;
end;

procedure TUButton.CM_MouseLeave(var Msg: TMessage);
begin
  if not Enabled then exit;
  ButtonState := csNone;
  inherited;
end;

procedure TUButton.CM_EnabledChanged(var Msg: TMessage);
begin
  inherited;
  UpdateColors;
  Invalidate;
end;

procedure TUButton.CM_DialogKey(var Msg: TCMDialogKey);
begin
  if AllowFocus and Focused and (Msg.CharCode = VK_RETURN) then
    begin
      Click;
      Msg.Result := 1;
    end
  else
    inherited;
end;

procedure TUButton.CM_TextChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

end.
