// This is part of the Obo Component Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
unit mExceptionLogForm;

{$mode objfpc}{$H+}

interface

{$IFDEF CONSOLE}
** this unit should not be compiled in a console application **
{$ENDIF}

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, LCLIntf, ExtCtrls, Clipbrd;

resourcestring
  SWrongEmailMessage = 'Email is non valid.';
  SDoCtrlVTitle = 'Send mail';
  SDoCtrlVMessage = 'Now a new mail message will be created.' + sLineBreak + sLineBreak +'PLEASE CLICK CTRL-V to copy the trace log in the message body before sending it.';

type

  { TExceptionLogForm }
  TExceptionLogForm = class(TForm)
    BtnCancel: TButton;
    BtnHalt: TButton;
    CBSendByMail: TCheckBox;
    EditSendToMailAddresses: TEdit;
    MemoReport: TMemo;
    PanelBottom: TPanel;
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnHaltClick(Sender: TObject);
    procedure CBSendByMailChange(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
  strict private
    FUserWantsToShutDown : boolean;
    FReport : String;
    procedure SendReportByMail;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Init (const aReport: String);

    property UserWantsToShutDown: boolean read FUserWantsToShutDown write FUserWantsToShutDown;
  end;

implementation

{$R *.lfm}

uses
  mExceptionLog, mUtility, mToast;

{ TExceptionLogForm }

procedure TExceptionLogForm.FormShow(Sender: TObject);
begin
  if ExceptionLogConfiguration.SendTraceLogByMail and (ExceptionLogConfiguration.TraceLogMailDestination <> '') then
  begin
    CBSendByMail.Checked:= true;
    EditSendToMailAddresses.Text:= ExceptionLogConfiguration.TraceLogMailDestination;
  end
  else
    CBSendByMail.Checked:= false;
end;

procedure TExceptionLogForm.SendReportByMail;
begin
  Clipboard.AsText:= FReport;
  MessageDlg(SDoCtrlVTitle, SDoCtrlVMessage, mtWarning, [mbOk], 0);
  OpenURL('mailto:' + EditSendToMailAddresses.Text + '?subject=Application trace log&body=Click CTRL-V');
  //OpenURL('mailto:' + EditSendToMailAddresses.Text + '?subject=Application trace log&body=' + StringReplace(FReport, sLineBreak, '%0D%0A', [rfReplaceAll]));
end;

procedure TExceptionLogForm.FormHide(Sender: TObject);
begin
end;

procedure TExceptionLogForm.BtnCancelClick(Sender: TObject);
begin
  FUserWantsToShutDown:= false;
  if CBSendByMail.Checked and  (EditSendToMailAddresses.Text <> '') then
  begin
    if ValidEmail(EditSendToMailAddresses.Text) then
    begin
      SendReportByMail;
      Self.ModalResult:= mrOk;
    end
    else
      TmToast.ShowText(SWrongEmailMessage);
  end
  else
    Self.ModalResult:= mrOk;
end;

procedure TExceptionLogForm.BtnHaltClick(Sender: TObject);
begin
  FUserWantsToShutDown:=true;
  if CBSendByMail.Checked and  (EditSendToMailAddresses.Text <> '') then
  begin
    if ValidEmail(EditSendToMailAddresses.Text) then
    begin
      SendReportByMail;
      Self.ModalResult:= mrOk;
    end
    else
      TmToast.ShowText(SWrongEmailMessage);
  end
  else
    Self.ModalResult:= mrOk;
end;

procedure TExceptionLogForm.CBSendByMailChange(Sender: TObject);
begin
  EditSendToMailAddresses.Enabled:= (Sender as TCheckBox).Checked;
end;

constructor TExceptionLogForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Self.Caption := 'DON''T PANIC';
end;

destructor TExceptionLogForm.Destroy;
begin
  inherited Destroy;
end;

procedure TExceptionLogForm.Init(const aReport: String);
begin
  MemoReport.Text:= aReport;
  FReport:= aReport;
end;

end.

