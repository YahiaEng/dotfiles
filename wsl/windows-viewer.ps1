param(
    [Parameter(Mandatory)] [ValidateSet('show', 'hide', 'toggle', 'close', 'shortcuts', 'displays', 'layout', 'choose', 'arrange', 'drag-handoff')] [string] $Action,
    [Parameter(Mandatory)] [string] $ViewerPath,
    [Parameter(Mandatory)] [string] $Distro,
    [Parameter(Mandatory)] [string] $Launcher,
    [string] $Profile = 'both'
)

$ErrorActionPreference = 'Stop'

if ($Action -eq 'shortcuts') {
    $shell = New-Object -ComObject WScript.Shell
    $programs = [Environment]::GetFolderPath('Programs')
    $entries = [ordered]@{
        'Arch Linux (Hyprland)' = '--toggle'
        'Arch Linux - Display settings' = '--display-settings'
        'Arch Linux - Both displays' = 'both'
        'Arch Linux - Primary display' = 'primary'
        'Arch Linux - External display' = 'external'
    }
    $distroArgument = if ($Distro -match '\s') { "`"$Distro`"" } else { $Distro }
    $launcherArgument = if ($Launcher -match '\s') { "`"$Launcher`"" } else { $Launcher }
    foreach ($name in $entries.Keys) {
        $link = $shell.CreateShortcut((Join-Path $programs "$name.lnk"))
        $link.TargetPath = Join-Path $env:SystemRoot 'System32\wsl.exe'
        $link.Arguments = "-d $distroArgument --cd ~ --exec $launcherArgument $($entries[$name])".TrimEnd()
        $link.WindowStyle = 7
        if ($entries[$name] -eq '--toggle' -and !$link.Hotkey) {
            $link.Hotkey = 'Ctrl+Alt+H'
        }
        $link.Save()
    }
    return
}

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class ArchViewerWindows {
    private static readonly IntPtr Topmost = new IntPtr(-1);
    private delegate bool Callback(IntPtr window, IntPtr data);
    [StructLayout(LayoutKind.Sequential)]
    private struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    private struct Point { public int X, Y; }
    [DllImport("user32.dll")] private static extern bool EnumWindows(Callback callback, IntPtr data);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr window, StringBuilder text, int capacity);
    [DllImport("user32.dll")] private static extern bool IsIconic(IntPtr window);
    [DllImport("user32.dll")] private static extern bool ShowWindowAsync(IntPtr window, int command);
    [DllImport("user32.dll")] private static extern bool GetWindowRect(IntPtr window, out Rect bounds);
    [DllImport("user32.dll")] private static extern bool SetWindowPos(IntPtr window, IntPtr after, int x, int y, int width, int height, uint flags);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll")] private static extern bool GetPhysicalCursorPos(out Point point);
    [DllImport("user32.dll")] private static extern IntPtr WindowFromPoint(Point point);
    [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr window, uint msg, IntPtr w, IntPtr l);

    public static IntPtr[] ForProcess(int processId, string title) {
        var windows = new List<IntPtr>();
        EnumWindows((window, data) => {
            uint pid;
            GetWindowThreadProcessId(window, out pid);
            if (pid == processId && IsWindowVisible(window)) {
                var text = new StringBuilder(256);
                GetWindowText(window, text, text.Capacity);
                if (String.IsNullOrEmpty(title) ? text.Length > 0 : text.ToString() == title)
                    windows.Add(window);
            }
            return true;
        }, IntPtr.Zero);
        return windows.ToArray();
    }

    public static void Restore(IntPtr window) {
        if (IsIconic(window))
            ShowWindowAsync(window, 9);
    }

    public static void Minimize(IntPtr window) {
        ShowWindowAsync(window, 6);
    }

    public static void Raise(IntPtr window) {
        const uint NoSize = 0x0001, NoMove = 0x0002, NoActivate = 0x0010, AsyncWindowPos = 0x4000;
        SetWindowPos(window, Topmost, 0, 0, 0, 0, NoSize | NoMove | NoActivate | AsyncWindowPos);
    }

    public static int Left(IntPtr window) {
        Rect bounds;
        GetWindowRect(window, out bounds);
        return bounds.Left;
    }

    public static bool Fills(IntPtr window, int x, int y, int width, int height) {
        Rect bounds;
        return GetWindowRect(window, out bounds) && bounds.Left == x && bounds.Top == y
            && bounds.Right == x + width && bounds.Bottom == y + height;
    }

    public static bool Place(IntPtr window, int x, int y, int width, int height) {
        const uint NoActivate = 0x0010, ShowWindow = 0x0040, AsyncWindowPos = 0x4000;
        return SetWindowPos(window, Topmost, x, y, width, height, NoActivate | ShowWindow | AsyncWindowPos);
    }

    public static void FinishCrossDisplayDrags(System.Diagnostics.Process viewer, IntPtr[] windows) {
        SetThreadDpiAwarenessContext(new IntPtr(-4));
        IntPtr origin = IntPtr.Zero;
        bool held = GetAsyncKeyState(1) < 0;
        while (!viewer.WaitForExit(12)) {
            bool pressed = GetAsyncKeyState(1) < 0;
            if (pressed == held)
                continue;
            held = pressed;
            Point point;
            IntPtr window = GetPhysicalCursorPos(out point) ? WindowFromPoint(point) : IntPtr.Zero;
            if (pressed) {
                origin = Array.IndexOf(windows, window) >= 0 ? window : IntPtr.Zero;
            } else {
                // SDL can drop an up event delivered to a different window.
                // Release on the original window outside the RDP desktop
                // so the guest retains the pointer's destination position.
                if (origin != IntPtr.Zero && window != origin)
                    PostMessage(origin, 0x0202, IntPtr.Zero, new IntPtr(unchecked((int)0x80008000)));
                origin = IntPtr.Zero;
            }
        }
    }
}
'@

if ($Action -in 'displays', 'layout', 'choose', 'arrange') {
    [void] [ArchViewerWindows]::SetThreadDpiAwarenessContext([IntPtr](-4))
    Add-Type -AssemblyName System.Windows.Forms
    $screens = @([Windows.Forms.Screen]::AllScreens | Sort-Object @{ Expression = 'Primary'; Descending = $true }, DeviceName)
    if ($Action -eq 'displays') {
        foreach ($screen in $screens) {
            $label = if ($screen.Primary) { ' primary' } else { '' }
            '{0}{1} {2}x{3} at {4},{5}' -f $screen.DeviceName.Split('\')[-1], $label,
                $screen.Bounds.Width, $screen.Bounds.Height, $screen.Bounds.X, $screen.Bounds.Y
        }
        return
    }
    if ($Action -eq 'choose') {
        $form = New-Object Windows.Forms.Form -Property @{
            Text = 'Arch Linux displays'
            ClientSize = New-Object Drawing.Size 440, (174 + 32 * $screens.Count)
            FormBorderStyle = 'FixedDialog'
            StartPosition = 'CenterScreen'
            MaximizeBox = $false
            MinimizeBox = $false
            TopMost = $true
            AutoScaleMode = 'Dpi'
        }
        $form.Controls.Add((New-Object Windows.Forms.Label -Property @{
            Text = 'Show Arch on'; AutoSize = $true; Left = 20; Top = 18
        }))
        $displayNames = @($screens | ForEach-Object { $_.DeviceName.Split('\')[-1] })
        $preferred = if ($Profile -eq 'both') { $displayNames } else { $Profile.Split(',') }
        $boxes = @(for ($i = 0; $i -lt $screens.Count; $i++) {
            $screen = $screens[$i]
            $tag = $displayNames[$i]
            $label = 'Display {0}  ({1} × {2})' -f $tag.Substring(7), $screen.Bounds.Width, $screen.Bounds.Height
            if ($screen.Primary) { $label += '  —  Windows main display' }
            $box = New-Object Windows.Forms.CheckBox -Property @{
                Text = $label; Tag = $tag; Checked = ($tag -in $preferred)
                AutoSize = $true; Left = 20; Top = (48 + 32 * $i)
            }
            $form.Controls.Add($box)
            $box
        })
        $row = 58 + 32 * $screens.Count
        $form.Controls.Add((New-Object Windows.Forms.Label -Property @{
            Text = 'Linux main display'; AutoSize = $true; Left = 20; Top = ($row + 3)
        }))
        $main = New-Object Windows.Forms.ComboBox -Property @{
            DropDownStyle = 'DropDownList'; Left = 164; Top = $row; Width = 254
        }
        $form.Controls.Add($main)
        $apply = New-Object Windows.Forms.Button -Property @{
            Text = 'Apply'; Left = 248; Top = ($row + 55); Width = 80; DialogResult = 'OK'
        }
        $cancel = New-Object Windows.Forms.Button -Property @{
            Text = 'Cancel'; Left = 338; Top = ($row + 55); Width = 80; DialogResult = 'Cancel'
        }
        $identify = New-Object Windows.Forms.Button -Property @{
            Text = 'Identify displays'; Left = 20; Top = ($row + 55); Width = 128
        }
        $form.Controls.AddRange(@($identify, $apply, $cancel))
        $form.AcceptButton = $apply
        $form.CancelButton = $cancel
        $refreshMain = {
            $previous = if ($main.SelectedItem) { $main.SelectedItem.Tag } else { $preferred[0] }
            $main.Items.Clear()
            foreach ($box in $boxes) {
                if ($box.Checked) {
                    [void] $main.Items.Add($box)
                }
            }
            $main.DisplayMember = 'Text'
            if ($main.Items.Count) {
                $main.SelectedIndex = 0
                foreach ($item in $main.Items) {
                    if ($item.Tag -eq $previous) { $main.SelectedItem = $item }
                }
            }
            $apply.Enabled = $main.Items.Count -ge 1 -and $main.Items.Count -le 4
        }
        foreach ($box in $boxes) { $box.add_CheckedChanged($refreshMain) }
        $identify.add_Click({
            $identify.Enabled = $false
            $labels = @(for ($i = 0; $i -lt $screens.Count; $i++) {
                $bounds = $screens[$i].Bounds
                $badge = New-Object Windows.Forms.Form -Property @{
                    Text = 'Display identification'; FormBorderStyle = 'None'; TopMost = $true
                    ShowInTaskbar = $false; Size = New-Object Drawing.Size 112, 88
                    StartPosition = 'Manual'
                    Location = New-Object Drawing.Point ($bounds.X + 32), ($bounds.Y + 32)
                }
                $badge.Controls.Add((New-Object Windows.Forms.Label -Property @{
                    Text = $displayNames[$i].Substring(7); Dock = 'Fill'; TextAlign = 'MiddleCenter'
                    Font = New-Object Drawing.Font 'Segoe UI', 32
                }))
                $badge.Show($form)
                $badge
            })
            $timer = New-Object Windows.Forms.Timer -Property @{ Interval = 1800 }
            $timer.add_Tick({
                $timer.Stop()
                foreach ($badge in $labels) { $badge.Dispose() }
                $identify.Enabled = $true
                $form.Activate()
                $timer.Dispose()
            }.GetNewClosure())
            $timer.Start()
        })
        & $refreshMain
        if ($form.ShowDialog() -eq 'OK') {
            $ordered = @($main.SelectedItem.Tag)
            $ordered += @($boxes | Where-Object { $_.Checked -and $_.Tag -ne $ordered[0] } | ForEach-Object Tag)
            $ordered -join ','
        }
        $form.Dispose()
        return
    }
    $screens = @(switch -Regex ($Profile) {
        '^both,DISPLAY\d+$' {
            $preferredMain = $Profile.Split(',')[1]
            $ordered = @($screens | Where-Object { $_.DeviceName.Split('\')[-1] -eq $preferredMain })
            $ordered += @($screens | Where-Object { $_.DeviceName.Split('\')[-1] -ne $preferredMain })
            $ordered | Select-Object -First 4
        }
        '^both$' { $screens | Select-Object -First 4 }
        '^primary$' { $screens | Where-Object Primary }
        '^external$' {
            $external = @($screens | Where-Object { !$_.Primary })
            if ($external.Count -ne 1) { throw 'Select a connected external display by its DISPLAY name.' }
            $external
        }
        default {
            foreach ($display in ($Profile.Split(',') | Select-Object -Unique)) {
                $screens | Where-Object { $_.DeviceName.Split('\')[-1] -ieq $display }
            }
        }
    })
    if (!$screens.Count) {
        throw "No connected display matches $Profile."
    }
    if ($Action -eq 'layout') {
        $left = ($screens | ForEach-Object { $_.Bounds.X } | Measure-Object -Minimum).Minimum
        $top = ($screens | ForEach-Object { $_.Bounds.Y } | Measure-Object -Minimum).Minimum
        foreach ($screen in $screens) {
            '{0} {1} {2} {3} {4}' -f $screen.DeviceName.Split('\')[-1], ($screen.Bounds.X - $left),
                ($screen.Bounds.Y - $top), $screen.Bounds.Width, $screen.Bounds.Height
        }
        return
    }
}

$name = [IO.Path]::GetFileNameWithoutExtension($ViewerPath)
$viewerTitle = 'Arch Linux (Hyprland)'
if ($Action -eq 'arrange') {
    # ww-start-viewer checks the WSL shared memory before starting FreeRDP.
    # Cold interop startup can take longer than the window placement itself.
    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    do {
        $process = Get-Process -Name $name -ErrorAction SilentlyContinue |
            Where-Object { $_.Path -ieq $ViewerPath } | Select-Object -First 1
        $windows = @()
        if ($process) {
            $windows = @([ArchViewerWindows]::ForProcess($process.Id, $viewerTitle) |
                Sort-Object { [ArchViewerWindows]::Left($_) })
        }
        if ($windows.Count -eq $screens.Count) { break }
        Start-Sleep -Milliseconds 200
    } while ([DateTime]::UtcNow -lt $deadline)

    if ($windows.Count -ne $screens.Count) {
        throw 'Weaselway did not create the expected viewer windows.'
    }
    # The viewer may still apply its initial size or a DPI change after
    # making the windows visible. Wait for the placement to settle.
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    $stable = 0
    do {
        $placed = $true
        for ($i = 0; $i -lt $screens.Count; $i++) {
            $bounds = $screens[$i].Bounds
            if (![ArchViewerWindows]::Fills($windows[$i], $bounds.X, $bounds.Y, $bounds.Width, $bounds.Height)) {
                $placed = $false
                if (![ArchViewerWindows]::Place($windows[$i], $bounds.X, $bounds.Y, $bounds.Width, $bounds.Height)) {
                    throw "Could not place the viewer on $($screens[$i].DeviceName)."
                }
            }
        }
        $stable = if ($placed) { $stable + 1 } else { 0 }
        if ($stable -lt 3) { Start-Sleep -Milliseconds 250 }
    } while ($stable -lt 3 -and [DateTime]::UtcNow -lt $deadline)
    if ($stable -lt 3) {
        throw 'The Weaselway windows did not settle on the selected displays.'
    }
    foreach ($window in $windows) {
        [ArchViewerWindows]::Raise($window)
    }
    [void] [ArchViewerWindows]::SetForegroundWindow($windows[0])
    return
}

$processes = @(Get-Process -Name $name -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -ieq $ViewerPath })
if (!$processes.Count) {
    exit 3
}

foreach ($process in $processes) {
    if ($Action -eq 'drag-handoff') {
        $windows = @([ArchViewerWindows]::ForProcess($process.Id, $viewerTitle))
        if ($windows.Count -gt 1) {
            [ArchViewerWindows]::FinishCrossDisplayDrags($process, $windows)
        }
        continue
    }
    if ($Action -eq 'close') {
        if (!$process.HasExited -and (!$process.CloseMainWindow() -or !$process.WaitForExit(8000))) {
            throw 'The Weaselway viewer did not close.'
        }
    } else {
        $windows = [ArchViewerWindows]::ForProcess($process.Id, $null)
        if (!$windows.Count) { exit 3 }
        if ($Action -eq 'hide' -or ($Action -eq 'toggle' -and [ArchViewerWindows]::GetForegroundWindow() -in $windows)) {
            foreach ($window in $windows) {
                [ArchViewerWindows]::Minimize($window)
            }
            continue
        }
        foreach ($window in $windows) {
            [ArchViewerWindows]::Restore($window)
        }
        foreach ($window in $windows) {
            [ArchViewerWindows]::Raise($window)
        }
        [void] [ArchViewerWindows]::SetForegroundWindow($windows[0])
    }
}
