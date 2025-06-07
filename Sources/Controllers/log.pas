unit log;

{$mode objfpc}{$H+}

interface



uses
  Classes, SysUtils;

  procedure writelog(logtype,section, message: string);

implementation

procedure writelog(logtype, section, message: string);
var
  f: TextFile;
  sLogFile: string;
  sAppPath:string;
  LogDir, version:string;
begin
 try
    {print software version}
    version:='v1.3';
    sAppPath := ExtractFilePath(ParamStr(0));

{$IFDEF UNIX}
   {if debug param is present, then writeln to stdout}
    if (ParamStr(2) = '-d') or (ParamStr(2) = '-debug') then
    begin
      writeln(message);
    end;
{$ENDIF}

  {$IFDEF UNIX}
 LogDir := sAppPath + 'log/';
 {$ENDIF}
 {$IFDEF WINDOWS}
 LogDir := sAppPath + 'log\';
 {$ENDIF}

    if not DirectoryExists(LogDir) then
      ForceDirectories(LogDir);

 {$IFDEF UNIX}
 sLogFile := LogDir + 'debug.log';
 {$ENDIF}
 {$IFDEF WINDOWS}
 sLogFile := LogDir + 'debug.log';
 {$ENDIF}

    AssignFile(f, sLogFile);
    if FileExists(sLogFile) then
      Append(f)
    else
      ReWrite(f);
    WriteLn(f, version + #9 + formatdatetime('yyyy_mm_dd_hh_nn_ss', now) + #9 + logtype + #9 + section + #9 + message);
    //write message to file log
    if (logtype='error') or (logtype='crit') then
    begin
      DumpExceptionBackTrace(f);    //DumpExceptionBackTrace if error
    end;
    CloseFile(f);

  except
    on E: Exception do
    begin
       WriteLn(formatdatetime('yyyy_mm_dd_hh_nn_ss', now) + #9 + message);
    end;
  end;
end;

end.
