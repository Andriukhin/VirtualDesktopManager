// Created by Alexey Andriukhin (dr. F.I.N.) http://www.delphisources.ru/forum/member.php?u=9721
// Tested on Win10 x32 (build 14393), Delphi7

unit uMain;

interface

uses
  // CodeGear
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls, Menus, ImgList,
  
  // VirtualDesktopManager
  VirtualDesktopManager;

type
  TListBox = class(StdCtrls.TListBox)
  public
    procedure CNDrawItem(var Message: TWMDrawItem); message CN_DRAWITEM;
  end;

  TfMain = class(TForm)
    lbDesktops: TListBox;
    Label1: TLabel;
    pmDesktops: TPopupMenu;
    miCreate: TMenuItem;
    miSwitch: TMenuItem;
    miRemoveAndFallbaskTo: TMenuItem;
    miMove: TMenuItem;
    miMoveAndSwitch: TMenuItem;
    miCreateAndSwitch: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    ilDesktops: TImageList;
    cbFollow: TCheckBox;
    lbLog: TListBox;
    Label2: TLabel;
    miRemove: TMenuItem;
    N4: TMenuItem;
    miViews: TMenuItem;
    Label3: TLabel;
    lLegend: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbDesktopsDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure lbDesktopsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure miCreateClick(Sender: TObject);
    procedure miCreateAndSwitchClick(Sender: TObject);
    procedure miSwitchClick(Sender: TObject);
    procedure miRemoveAndFallbaskToClick(Sender: TObject);
    procedure miRemoveClick(Sender: TObject);
    procedure miMoveClick(Sender: TObject);
    procedure miMoveAndSwitchClick(Sender: TObject);
    procedure miViewsFlashClick(Sender: TObject);
    procedure miViewsSwitchClick(Sender: TObject);
    procedure miViewsPinUnpinClick(Sender: TObject);
    procedure miViewsPinUnpinAppClick(Sender: TObject);
    procedure miViewsMoveToClick(Sender: TObject);
    procedure lbDesktopsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  private
    DesktopImg: TBitmap;
    DesktopIdxAtPos: Integer;
    procedure UpdateDesktopList;
    procedure AddToLog(Msg: AnsiString);
  public
    procedure DesktopCreated(Sender: TObject; Desktop: TVirtualDesktop);
    procedure DesktopDestroyBegin(Sender: TObject; Desktop, DesktopFallback: TVirtualDesktop);
    procedure DesktopDestroyFailed(Sender: TObject; Desktop, DesktopFallback: TVirtualDesktop);
    procedure DesktopDestroyed(Sender: TObject; Desktop, DesktopFallback: TVirtualDesktop);
    procedure CurrentDesktopChanged(Sender: TObject; OldDesktop, NewDesktop: TVirtualDesktop);
    procedure ErrorEvent(Sender: TObject; ErrorCode: HRESULT);
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}
{$R DesktopImg.res}

{ TListBox }

procedure TListBox.CNDrawItem(var Message: TWMDrawItem);
var
  State: TOwnerDrawState;
begin
  with Message.DrawItemStruct^ do
  begin
    State := TOwnerDrawState(LongRec(itemState).Lo);
    Self.Canvas.Handle := hDC;
    Self.Canvas.Font := Self.Font;
    Self.Canvas.Brush := Self.Brush;
    if (Integer(itemID) >= 0) and (odSelected in State) then
    begin
      Self.Canvas.Brush.Color := clHighlight;
      Self.Canvas.Font.Color := clHighlightText
    end;
    Self.Canvas.Brush.Style := bsSolid;
    if Integer(itemID) >= 0 then
      Self.DrawItem(itemID, rcItem, State)
    else
      Self.Canvas.FillRect(rcItem);
    Self.Canvas.Handle := 0;
  end;
end;

{ TForm1 }

procedure TfMain.CurrentDesktopChanged(Sender: TObject; OldDesktop, NewDesktop: TVirtualDesktop);
begin
  if cbFollow.Checked then
    DesktopManager.MoveWindowToDesktop(Application.Handle, NewDesktop);
  lbDesktops.Repaint;
  AddToLog(Format('Current changed: %s - %s', [OldDesktop.IdAsString, NewDesktop.IdAsString]));
end;

procedure TfMain.DesktopCreated(Sender: TObject; Desktop: TVirtualDesktop);
begin
  UpdateDesktopList;
  AddToLog(Format('Created: %s', [Desktop.IdAsString]));
end;

procedure TfMain.DesktopDestroyBegin(Sender: TObject; Desktop, DesktopFallback: TVirtualDesktop);
begin
  AddToLog(Format('Destroy begin: %s - %s', [Desktop.IdAsString, DesktopFallback.IdAsString]));
end;

procedure TfMain.DesktopDestroyed(Sender: TObject; Desktop, DesktopFallback: TVirtualDesktop);
begin
  UpdateDesktopList;
  AddToLog(Format('Destroyed: %s - %s', [Desktop.IdAsString, DesktopFallback.IdAsString]));
end;

procedure TfMain.DesktopDestroyFailed(Sender: TObject; Desktop, DesktopFallback: TVirtualDesktop);
begin
  AddToLog(Format('Destroy failed: %s - %s', [Desktop.IdAsString, DesktopFallback.IdAsString]));
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  ClientWidth := lbDesktops.Left * 2 + lbDesktops.Width;
  ClientHeight := lLegend.Top + lLegend.Height + Label1.Top;
  DesktopImg := TBitmap.Create;
  DesktopImg.LoadFromResourceName(HInstance, 'DESKTOP');
  with DesktopManager do
  begin
    OnDesktopCreated := DesktopCreated;
    OnDesktopDestroyBegin := DesktopDestroyBegin;
    OnDesktopDestroyFailed := DesktopDestroyFailed;
    OnDesktopDestroyed := DesktopDestroyed;
    OnCurrentDesktopChanged := CurrentDesktopChanged;
    OnError := ErrorEvent;
  end;
  UpdateDesktopList;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  DesktopImg.Free;
  with miRemoveAndFallbaskTo do
    while Count > 0 do
      Items[0].Free;
  with miViews do
    while Count > 0 do
      Items[0].Free;
end;

procedure TfMain.UpdateDesktopList;
begin
  lbDesktops.Items.BeginUpdate;
  while DesktopManager.Count < lbDesktops.Count do
    lbDesktops.Items.Delete(lbDesktops.Count - 1);
  while DesktopManager.Count > lbDesktops.Count do
    lbDesktops.Items.Add(DesktopManager.Desktops[lbDesktops.count].IdAsString);
  lbDesktops.Items.EndUpdate;
  lbDesktops.Repaint;
end;

procedure TfMain.lbDesktopsDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  offset = 5;
var
  text_value: AnsiString;
  frame_w, frame_h: Integer;
  dst_rect, src_rect: TRect;
begin
  with TListBox(Control).Canvas do
  begin
    FillRect(Rect);
    frame_w := DesktopImg.Width;
    frame_h := DesktopImg.Height div 2;
    dst_rect := Bounds(offset + Rect.Left, Rect.Top + (Rect.Bottom - Rect.Top - frame_h) div 2, frame_w, frame_h);
    src_rect := Bounds(0, 0, frame_w, frame_h);
    if DesktopManager.Desktops[Index].IsCurrent then
      OffsetRect(src_rect, 0, frame_h);
    CopyRect(dst_rect, DesktopImg.Canvas, src_rect);
    text_value := Format('#%d %s', [Index, DesktopManager.Desktops[Index].IdAsString]);
    Brush.Style := bsClear;
    TextOut(offset * 2 + DesktopImg.Width, Rect.Top + (Rect.Bottom - Rect.Top - TextHeight(text_value)) div 2, text_value);
  end;
end;

procedure TfMain.ErrorEvent(Sender: TObject; ErrorCode: HRESULT);
begin
  AddToLog('Error: ' + SysErrorMessage(ErrorCode));
end;

procedure TfMain.AddToLog(Msg: AnsiString);
begin
  lbLog.Items.Add(Msg);
  SendMessage(lbLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TfMain.lbDesktopsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  i: Integer;
  can_enabled: Boolean;
  mi: TMenuItem;
  wnd: HWND;
  buff: array[0..127] of Char;
  s: AnsiString;
begin
  //DesktopIdxAtPos :=  lbDesktops.ItemAtPos(MousePos, True);
  lbDesktops.ItemIndex := DesktopIdxAtPos;
  with miRemoveAndFallbaskTo do
    while Count > 0 do
      Items[0].Free;
  with miViews do
    while Count > 0 do
      Items[0].Free;
  if DesktopIdxAtPos > -1 then
    can_enabled := not DesktopManager.Desktops[DesktopIdxAtPos].IsCurrent
  else
    can_enabled := False;
  miSwitch.Enabled := can_enabled and (lbDesktops.Count > 0);
  miRemoveAndFallbaskTo.Enabled := (DesktopIdxAtPos > -1) and (lbDesktops.Count > 1);
  miRemove.Enabled := (DesktopIdxAtPos > -1);
  miMove.Enabled := can_enabled and (lbDesktops.Count > 1);
  miMoveAndSwitch.Enabled := can_enabled and (lbDesktops.Count > 1);

  if miRemoveAndFallbaskTo.Enabled then
    for i := 0 to lbDesktops.Count - 1 do
      if i <> DesktopIdxAtPos then
      begin
        mi := TMenuItem.Create(miRemoveAndFallbaskTo);
        mi.Caption := Format('#%d %s', [i, DesktopManager.Desktops[i].IdAsString]);
        mi.Tag := i;
        mi.OnClick := miRemoveAndFallbaskToClick;
        miRemoveAndFallbaskTo.Add(mi);
      end;
  //
  wnd := GetWindow(Handle, GW_HWNDFIRST);
  while wnd <> 0 do
  begin
    GetWindowText(wnd, buff, SizeOf(buff));
    s := StrPas(buff);
    if (wnd <> Application.Handle)            //
      and DesktopManager.IsWindowHaveView(wnd)//
      and IsWindowVisible(wnd)                //
      and (GetWindow(wnd, GW_OWNER) = 0)      //
      and (s <> '') then
    begin
      GetWindowText(wnd, buff, SizeOf(buff));
      mi := TMenuItem.Create(miViews);
      if Length(s) > 20 then
        mi.Caption := Copy(s, 1, 20) + '...'
      else
        mi.Caption := s;
      miViews.Add(mi);
      //
      mi := TMenuItem.Create(miViews.Items[miViews.Count - 1]);
      mi.Caption := 'Flash';
      mi.Tag := wnd;
      mi.ImageIndex := 5;
      mi.OnClick := miViewsFlashClick;
      miViews.Items[miViews.Count - 1].Add(mi);
      //
      mi := TMenuItem.Create(miViews.Items[miViews.Count - 1]);
      mi.Caption := 'Shitch to window';
      mi.Tag := wnd;
      mi.ImageIndex := 1;
      mi.OnClick := miViewsSwitchClick;
//      mi.Enabled := not DesktopManager.IsWindowOnCurrentDesktop(wnd);
      miViews.Items[miViews.Count - 1].Add(mi);
      //
      mi := TMenuItem.Create(miViews.Items[miViews.Count - 1]);
      if DesktopManager.IsPinnedWindow(wnd) then
      begin
        mi.Caption := 'Unpin window';
        mi.ImageIndex := 7;
      end
      else
      begin
        mi.Caption := 'Pin window';
        mi.ImageIndex := 6;
      end;
      mi.Tag := wnd;
      mi.OnClick := miViewsPinUnpinClick;
      miViews.Items[miViews.Count - 1].Add(mi);
      //
      mi := TMenuItem.Create(miViews.Items[miViews.Count - 1]);
      if DesktopManager.IsPinnedApplication(wnd) then
      begin
        mi.Caption := 'Unpin application';
        mi.ImageIndex := 9;
      end
      else
      begin
        mi.Caption := 'Pin application';
        mi.ImageIndex := 8;
      end;
      mi.Tag := wnd;
      mi.OnClick := miViewsPinUnpinAppClick;
      miViews.Items[miViews.Count - 1].Add(mi);
      //
      if DesktopManager.Count > 1 then
      begin
        mi := TMenuItem.Create(miViews.Items[miViews.Count - 1]);
        mi.Caption := 'Move to desktop';
        mi.ImageIndex := 3;
        mi.Tag := wnd;
        miViews.Items[miViews.Count - 1].Add(mi);
        for i := 0 to lbDesktops.Count - 1 do
          if (i <> DesktopManager.CurrentDesktopIndex) {and (not DesktopManager.IsWindowVisibleAtDesktop(wnd, i))} then
          begin
            mi := TMenuItem.Create(TMenuItem(miViews.Items[miViews.Count - 1]).Items[TMenuItem(miViews.Items[miViews.Count - 1]).Count - 1]);
            mi.Caption := Format('#%d %s', [i, DesktopManager.Desktops[i].IdAsString]);
            mi.Tag := i;
            mi.OnClick := miViewsMoveToClick;
            TMenuItem(miViews.Items[miViews.Count - 1]).Items[TMenuItem(miViews.Items[miViews.Count - 1]).Count - 1].Add(mi);
          end;
        TMenuItem(miViews.Items[miViews.Count - 1]).Items[TMenuItem(miViews.Items[miViews.Count - 1]).Count - 1].Enabled := TMenuItem(miViews.Items[miViews.Count - 1]).Items[TMenuItem(miViews.Items[miViews.Count - 1]).Count - 1].Count > 0;
      end;
    end;
    wnd := GetWindow(wnd, GW_HWNDNEXT);
  end;
  //
  pmDesktops.Popup(lbDesktops.ClientToScreen(MousePos).X, lbDesktops.ClientToScreen(MousePos).Y);
end;

procedure TfMain.miRemoveClick(Sender: TObject);
begin
  DesktopManager.RemoveDesktop(DesktopIdxAtPos);
end;

procedure TfMain.miRemoveAndFallbaskToClick(Sender: TObject);
begin
  DesktopManager.RemoveDesktop(DesktopIdxAtPos, (Sender as TMenuItem).Tag);
end;

procedure TfMain.miCreateClick(Sender: TObject);
begin
  DesktopManager.CreateDesktop;
end;

procedure TfMain.miCreateAndSwitchClick(Sender: TObject);
begin
  DesktopManager.CreateDesktopAndSwitch;
end;

procedure TfMain.miMoveAndSwitchClick(Sender: TObject);
begin
  DesktopManager.MoveWindowToDesktop(Application.Handle, DesktopIdxAtPos);
  DesktopManager.SwitchToDesktop(DesktopIdxAtPos);
end;

procedure TfMain.miMoveClick(Sender: TObject);
begin
  DesktopManager.MoveWindowToDesktop(Application.Handle, DesktopIdxAtPos);
end;

procedure TfMain.miSwitchClick(Sender: TObject);
begin
  DesktopManager.SwitchToDesktop(DesktopIdxAtPos);
end;

procedure TfMain.miViewsFlashClick(Sender: TObject);
begin
  DesktopManager.FlashWindow((Sender as TMenuItem).Tag);
end;

procedure TfMain.miViewsSwitchClick(Sender: TObject);
begin
  DesktopManager.SwithToWindow((Sender as TMenuItem).Tag);
end;

procedure TfMain.miViewsPinUnpinClick(Sender: TObject);
begin
  if DesktopManager.IsPinnedWindow((Sender as TMenuItem).Tag) then
    DesktopManager.UnpinWindow((Sender as TMenuItem).Tag)
  else
    DesktopManager.PinWindow((Sender as TMenuItem).Tag);
end;

procedure TfMain.miViewsPinUnpinAppClick(Sender: TObject);
begin
  if DesktopManager.IsPinnedApplication((Sender as TMenuItem).Tag) then
    DesktopManager.UnpinApplication((Sender as TMenuItem).Tag)
  else
    DesktopManager.PinApplication((Sender as TMenuItem).Tag);
end;

procedure TfMain.miViewsMoveToClick(Sender: TObject);
begin
  DesktopManager.MoveWindowToDesktop((Sender as TMenuItem).Owner.Tag, (Sender as TMenuItem).Tag);
end;

procedure TfMain.lbDesktopsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  DesktopIdxAtPos := lbDesktops.ItemAtPos(Point(X, Y), True);
end;

end.

