@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  AI Agent Core migration (Windows)
REM
REM  Run from the host project root (one level above ai-agent-core\)
REM  when an older version of AI Agent Core has been replaced or
REM  upgraded.
REM
REM  Default mode is DRY RUN. Pass --apply to execute.
REM
REM  Backups (when --apply): ai-agent-core\generated\migration-backup-<UTC>\
REM ============================================================

REM ------------------------------------------------------------
REM  Resolve paths
REM ------------------------------------------------------------

set SCRIPT_DIR=%~dp0
set CORE_ROOT=%SCRIPT_DIR%..
set TARGET_DIR=%cd%
set SCAFFOLD_DIR=%SCRIPT_DIR%scaffold

set GENERATED_DIR=%CORE_ROOT%\generated
set TASKS_DIR=%GENERATED_DIR%\tasks
set INPUTS_DIR=%GENERATED_DIR%\inputs
set CORE_JSON=%CORE_ROOT%\ai-agent-core.json

REM Build a UTC-ish timestamp for the backup directory.
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddTHHmmssZ -AsUTC"') do set TIMESTAMP=%%i
if "%TIMESTAMP%"=="" set TIMESTAMP=%RANDOM%
set BACKUP_DIR=%GENERATED_DIR%\migration-backup-%TIMESTAMP%

REM Read ai-agent-core version (used when refreshing entrypoint stamp).
set VERSION=unknown
for /f "tokens=2 delims=:," %%a in ('findstr /i "\"version\"" "%CORE_JSON%" 2^>nul') do (
    set VERSION=%%~a
    goto :version_done
)
:version_done
set VERSION=%VERSION:"=%
set VERSION=%VERSION: =%

REM ------------------------------------------------------------
REM  Args
REM ------------------------------------------------------------

set DRY_RUN=1
set VERBOSE=0
set REFRESH_ENTRYPOINTS=1

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--apply" (
  set DRY_RUN=0
  shift
  goto parse_args
)
if /i "%~1"=="--keep-entrypoints" (
  set REFRESH_ENTRYPOINTS=0
  shift
  goto parse_args
)
if /i "%~1"=="--verbose" (
  set VERBOSE=1
  shift
  goto parse_args
)
if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage
echo Unknown argument: %~1
goto usage

:usage
echo Usage: %~nx0 [--apply] [--keep-entrypoints] [--verbose] [--help]
echo.
echo   (default)               Dry run - print the plan, change nothing.
echo   --apply                 Execute the plan.
echo   --keep-entrypoints      Do NOT refresh AGENTS.md / CLAUDE.md from
echo                           the current scaffold; report drift only.
echo   --verbose               Extra detail in output.
echo   --help                  This message.
echo.
echo Run from the host project root (the directory containing ai-agent-core\).
echo.
echo Backups (when --apply): ai-agent-core\generated\migration-backup-^<UTC^>\
exit /b 2

:args_done

set CHANGES=0
set ADVISORIES=0
set BACKUP_CREATED=0

echo AI Agent Core migration
echo   ai-agent-core: %CORE_ROOT%
echo   host root:  %TARGET_DIR%
if "%DRY_RUN%"=="1" (
  echo   mode:       DRY RUN  ^(re-run with --apply to execute^)
) else (
  echo   mode:       APPLY
)

REM ------------------------------------------------------------
REM  Step 1 - legacy host\tasks\
REM ------------------------------------------------------------

if exist "%TARGET_DIR%\tasks\" (
  echo.
  echo [Step 1] Legacy host\tasks\ detected
  call :handle_legacy_task_file todo.md
  call :handle_legacy_task_file lessons.md
  call :backup_remaining_dir "%TARGET_DIR%\tasks" "tasks"
  call :remove_dir "%TARGET_DIR%\tasks"
)

REM ------------------------------------------------------------
REM  Step 2 - legacy host\agent-works\
REM ------------------------------------------------------------

if exist "%TARGET_DIR%\agent-works\" (
  echo.
  echo [Step 2] Legacy host\agent-works\ detected
  call :copy_dir_if_nonempty "%TARGET_DIR%\agent-works" "%TASKS_DIR%\legacy-agent-works"
  call :remove_dir "%TARGET_DIR%\agent-works"
)

REM ------------------------------------------------------------
REM  Step 3 - legacy host\agent-spec\
REM ------------------------------------------------------------

if exist "%TARGET_DIR%\agent-spec\" (
  echo.
  echo [Step 3] Legacy host\agent-spec\ detected ^(replaced by ai-agent-core\^)

  if exist "%TARGET_DIR%\agent-spec\WORK_STATE.md" (
    if exist "%TASKS_DIR%\legacy-work-state.md" (
      call :ensure_backup_dir
      call :plan "preserve %TASKS_DIR%\legacy-work-state.md ^(already exists^); back up legacy WORK_STATE.md"
      if "%DRY_RUN%"=="0" (
        copy /y "%TARGET_DIR%\agent-spec\WORK_STATE.md" "%BACKUP_DIR%\agent-spec-WORK_STATE.md" >nul
        del "%TARGET_DIR%\agent-spec\WORK_STATE.md"
      )
    ) else (
      call :plan "archive WORK_STATE.md to %TASKS_DIR%\legacy-work-state.md"
      if "%DRY_RUN%"=="0" (
        if not exist "%TASKS_DIR%" mkdir "%TASKS_DIR%"
        move /y "%TARGET_DIR%\agent-spec\WORK_STATE.md" "%TASKS_DIR%\legacy-work-state.md" >nul
      )
    )
  )

  call :backup_remaining_dir "%TARGET_DIR%\agent-spec" "agent-spec"
  call :plan "remove %TARGET_DIR%\agent-spec\ ^(AI Agent Core-provided shell^)"
  call :remove_dir "%TARGET_DIR%\agent-spec"
)

REM ------------------------------------------------------------
REM  Step 4 - legacy host\agent-input\
REM ------------------------------------------------------------

if exist "%TARGET_DIR%\agent-input\" (
  echo.
  echo [Step 4] Legacy host\agent-input\ detected
  call :copy_dir_if_nonempty "%TARGET_DIR%\agent-input" "%INPUTS_DIR%"
  call :remove_dir "%TARGET_DIR%\agent-input"
)

REM ------------------------------------------------------------
REM  Step 5 - entrypoints staleness (AGENTS.md / CLAUDE.md)
REM ------------------------------------------------------------

call :check_entrypoint AGENTS.md
call :check_entrypoint CLAUDE.md

REM ------------------------------------------------------------
REM  Step 6 - host .gitignore mentions ai-agent-core\generated\
REM ------------------------------------------------------------

if exist "%TARGET_DIR%\.gitignore" (
  findstr /r /c:"ai-agent-core/generated" /c:"^generated/" "%TARGET_DIR%\.gitignore" >nul 2>nul
  if errorlevel 1 (
    echo.
    echo [Step 6] Host .gitignore does not mention ai-agent-core/generated/
    call :plan "append ai-agent-core/generated/ to .gitignore ^(only if ai-agent-core is vendored^)"
    if "%DRY_RUN%"=="0" (
      echo.>>"%TARGET_DIR%\.gitignore"
      echo # ai-agent-core runtime state ^(vendored install only — submodules manage their own .gitignore^)>>"%TARGET_DIR%\.gitignore"
      echo ai-agent-core/generated/>>"%TARGET_DIR%\.gitignore"
    )
  )
)

REM ------------------------------------------------------------
REM  Summary
REM ------------------------------------------------------------

echo.
if "%CHANGES%"=="0" (
  if not "%ADVISORIES%"=="0" (
    echo No migration actions required. ^(%ADVISORIES% advisory note^(s^) above for manual review.^)
  ) else (
    echo No migration actions required.
  )
  exit /b 0
)

if "%BACKUP_CREATED%"=="1" echo Backups: %BACKUP_DIR%

echo.
if "%DRY_RUN%"=="1" (
  echo Dry run: %CHANGES% action^(s^) planned. Re-run with --apply to perform them.
) else (
  echo Migration complete: %CHANGES% action^(s^) executed.
)
exit /b 0


REM ============================================================
REM  Subroutines
REM ============================================================

:plan
  echo   ^> %~1
  set /a CHANGES=CHANGES+1
  exit /b 0

:advise
  REM Advisory note: shown to the user but does not count as an action.
  echo   ! %~1
  set /a ADVISORIES=ADVISORIES+1
  exit /b 0

:ensure_backup_dir
  if "%DRY_RUN%"=="0" (
    if "%BACKUP_CREATED%"=="0" (
      if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
      set BACKUP_CREATED=1
    )
  )
  exit /b 0

:handle_legacy_task_file
  REM %1 = filename (todo.md / lessons.md)
  set _src=%TARGET_DIR%\tasks\%~1
  set _dst=%TASKS_DIR%\%~1
  if not exist "!_src!" exit /b 0
  if exist "!_dst!" (
    call :ensure_backup_dir
    call :plan "preserve !_dst! ^(already populated^); back up legacy !_src!"
    if "%DRY_RUN%"=="0" (
      copy /y "!_src!" "%BACKUP_DIR%\tasks-%~1" >nul
      del "!_src!"
    )
  ) else (
    call :plan "move !_src! to !_dst!"
    if "%DRY_RUN%"=="0" (
      if not exist "%TASKS_DIR%" mkdir "%TASKS_DIR%"
      move /y "!_src!" "!_dst!" >nul
    )
  )
  exit /b 0

:copy_dir_if_nonempty
  REM %1 = source dir, %2 = destination dir
  set _src=%~1
  set _dst=%~2
  REM count files (recursively) in source
  set _count=0
  for /r "%_src%" %%f in (*) do set /a _count+=1
  if !_count! gtr 0 (
    call :plan "copy %_src%\ to %_dst%\"
    if "%DRY_RUN%"=="0" (
      if not exist "%_dst%" mkdir "%_dst%"
      xcopy "%_src%\*" "%_dst%\" /E /I /H /Y >nul
    )
  )
  exit /b 0

:backup_remaining_dir
  REM %1 = source dir, %2 = label for backup subpath
  set _src=%~1
  set _label=%~2
  set _count=0
  for /r "%_src%" %%f in (*) do set /a _count+=1
  if !_count! gtr 0 (
    call :ensure_backup_dir
    call :plan "back up remaining contents of %_src%\ to %BACKUP_DIR%\%_label%\"
    if "%DRY_RUN%"=="0" (
      if not exist "%BACKUP_DIR%\%_label%" mkdir "%BACKUP_DIR%\%_label%"
      xcopy "%_src%\*" "%BACKUP_DIR%\%_label%\" /E /I /H /Y >nul
    )
  )
  exit /b 0

:remove_dir
  set _path=%~1
  if exist "%_path%\" (
    call :plan "remove %_path%\"
    if "%DRY_RUN%"=="0" rmdir /s /q "%_path%"
  )
  exit /b 0

:check_entrypoint
  REM %1 = filename
  set _file=%~1
  set _src=%TARGET_DIR%\%_file%
  set _scaffold=%SCAFFOLD_DIR%\%_file%
  if not exist "%_scaffold%" exit /b 0

  REM Missing entrypoint -> create from scaffold (with stamp).
  if not exist "%_src%" (
    echo.
    echo [Step 5] %_file% is missing at the host root
    call :plan "create %_file% from scaffold"
    if "%DRY_RUN%"=="0" call :write_entrypoint "%_scaffold%" "%_src%"
    exit /b 0
  )

  REM Look for the generation marker.
  findstr /b /c:"Generated by ai-agent-core" "%_src%" >nul 2>nul
  if errorlevel 1 (
    REM No marker -> user-authored. Report drift only; never replace.
    fc /b "%_src%" "%_scaffold%" >nul 2>nul
    if errorlevel 1 (
      echo.
      echo [Step 5] %_file% has no AI Agent Core marker — assumed user-authored
      call :advise "review %_scaffold% and reconcile %_file% manually if needed"
    ) else (
      if "%VERBOSE%"=="1" echo   . %_file% matches the current scaffold (no marker, no drift)
    )
    exit /b 0
  )

  REM Marker present. Compare body bytes (rough — fc treats footer as
  REM part of the file, so body-equal files still register as different;
  REM we treat that as "needs refresh", which is safe given the backup).
  fc /b "%_src%" "%_scaffold%" >nul 2>nul
  if not errorlevel 1 (
    REM Bytewise identical — body matches AND no footer present.
    if "%VERBOSE%"=="1" echo   . %_file% matches the current scaffold
    exit /b 0
  )

  if "%REFRESH_ENTRYPOINTS%"=="0" (
    echo.
    echo [Step 5] %_file% differs from the current scaffold ^(--keep-entrypoints in effect^)
    echo         scaffold: %_scaffold%
    echo         current:  %_src%
    call :advise "review the new scaffold and update %_file% manually"
    exit /b 0
  )

  echo.
  echo [Step 5] %_file% differs from the current scaffold
  echo         scaffold: %_scaffold%
  echo         current:  %_src%
  call :ensure_backup_dir
  call :plan "back up current %_file% to %BACKUP_DIR%\%_file%"
  call :plan "rewrite %_file% from scaffold ^(stamp v%VERSION%^)"
  call :advise "^(your additions, if any, are recoverable from the backup^)"
  if "%DRY_RUN%"=="0" (
    copy /y "%_src%" "%BACKUP_DIR%\%_file%" >nul
    call :write_entrypoint "%_scaffold%" "%_src%"
  )
  exit /b 0

:write_entrypoint
  REM %1 = scaffold path, %2 = destination path. Replicates bootstrap's
  REM "scaffold + blank + --- + Generated by ai-agent-core vX.Y.Z" footer.
  copy /y "%~1" "%~2" >nul
  echo.>> "%~2"
  echo --- >> "%~2"
  echo Generated by ai-agent-core v%VERSION% >> "%~2"
  exit /b 0
