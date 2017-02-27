program Demo;

uses
  Windows,
  SysUtils,
  Forms,
  uMain in 'uMain.pas' {fMain},
  VirtualDesktopAPI in '..\Source\VirtualDesktopAPI.pas',
  VirtualDesktopManager in '..\Source\VirtualDesktopManager.pas';

{$R *.res}
const
  CRASH_MESSAGE = 'I''m so sorry! Something happened with desktops manager!'#10#13'Last error:'#32'%s'#10#13'The program will be closed.';

begin
  if DesktopManager.Enabled then
  begin
    Application.Initialize;
    Application.Title := 'Demo';
  Application.CreateForm(TfMain, fMain);
    Application.Run;
  end
  else
    MessageBox(0, PChar(Format(CRASH_MESSAGE, [SysErrorMessage(DesktopManager.LastError)])), 'Oops...', MB_ICONEXCLAMATION);
end.

