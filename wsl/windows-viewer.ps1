param(
    [Parameter(Mandatory)] [ValidateSet('show', 'hide', 'toggle', 'close', 'shortcuts', 'displays', 'layout', 'choose', 'arrange', 'watch', 'drag-handoff')] [string] $Action,
    [Parameter(Mandatory)] [string] $ViewerPath,
    [Parameter(Mandatory)] [string] $Distro,
    [Parameter(Mandatory)] [string] $Launcher,
    [string] $Profile = 'auto',
    [string] $Layout,
    [string] $Handles
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
    private delegate bool MonitorCallback(IntPtr monitor, IntPtr dc, IntPtr bounds, IntPtr data);
    [StructLayout(LayoutKind.Sequential)]
    private struct Rect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    private struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct MonitorInfo {
        public int Size;
        public Rect Bounds, WorkArea;
        public int Flags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct DisplayDevice {
        public int Size;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string Name;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string Description;
        public int Flags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string Id;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string Key;
    }
    public class Display {
        public string Name { get; set; }
        public string Id { get; set; }
        public bool Primary { get; set; }
        public int X { get; set; }
        public int Y { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int ScalePercent { get; set; }
        public double PanelDpi { get; set; }
    }
    [DllImport("user32.dll")] private static extern bool EnumWindows(Callback callback, IntPtr data);
    [DllImport("user32.dll")] private static extern bool EnumDisplayMonitors(IntPtr dc, IntPtr clip, MonitorCallback callback, IntPtr data);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern bool GetMonitorInfo(IntPtr monitor, ref MonitorInfo info);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern bool EnumDisplayDevices(string adapter, int index, ref DisplayDevice device, int flags);
    [DllImport("shcore.dll")] private static extern int GetScaleFactorForMonitor(IntPtr monitor, out int scale);
    [DllImport("shcore.dll")] private static extern int GetDpiForMonitor(IntPtr monitor, int type, out uint x, out uint y);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr window, StringBuilder text, int capacity);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr window);
    [DllImport("user32.dll")] private static extern bool IsZoomed(IntPtr window);
    [DllImport("user32.dll")] private static extern bool ShowWindowAsync(IntPtr window, int command);
    [DllImport("user32.dll")] private static extern bool GetWindowRect(IntPtr window, out Rect bounds);
    [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr window, out Rect bounds);
    [DllImport("user32.dll")] private static extern bool ClientToScreen(IntPtr window, ref Point point);
    [DllImport("user32.dll")] private static extern bool SetWindowPos(IntPtr window, IntPtr after, int x, int y, int width, int height, uint flags);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll")] private static extern bool GetPhysicalCursorPos(out Point point);
    [DllImport("user32.dll")] private static extern IntPtr WindowFromPoint(Point point);
    [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr window, uint msg, IntPtr w, IntPtr l);

    private static string MonitorId(string adapter) {
        var device = new DisplayDevice { Size = Marshal.SizeOf(typeof(DisplayDevice)) };
        const int GetDeviceInterfaceName = 1, Active = 1;
        for (int i = 0; EnumDisplayDevices(adapter, i, ref device, GetDeviceInterfaceName); i++) {
            if ((device.Flags & Active) != 0 && !String.IsNullOrEmpty(device.Id)) {
                using (var sha = System.Security.Cryptography.SHA256.Create())
                    return BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(device.Id.ToUpperInvariant()))).Replace("-", "");
            }
        }
        return "-";
    }

    public static Display[] Displays() {
        var displays = new List<Display>();
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (monitor, dc, bounds, data) => {
            var info = new MonitorInfo { Size = Marshal.SizeOf(typeof(MonitorInfo)) };
            if (GetMonitorInfo(monitor, ref info) && info.DeviceName.StartsWith(@"\\.\DISPLAY")) {
                int scale;
                uint dpiX, dpiY;
                // MDT_RAW_DPI reports panel density without the Windows scale applied.
                double panelDpi = GetDpiForMonitor(monitor, 2, out dpiX, out dpiY) == 0
                    ? Math.Sqrt((double)dpiX * dpiY) : 0;
                displays.Add(new Display {
                    Name = info.DeviceName.Substring(4), Id = MonitorId(info.DeviceName), Primary = (info.Flags & 1) != 0,
                    X = info.Bounds.Left, Y = info.Bounds.Top,
                    Width = info.Bounds.Right - info.Bounds.Left, Height = info.Bounds.Bottom - info.Bounds.Top,
                    ScalePercent = GetScaleFactorForMonitor(monitor, out scale) == 0 ? scale : 0,
                    PanelDpi = panelDpi
                });
            }
            return true;
        }, IntPtr.Zero);
        return displays.ToArray();
    }

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
        Rect client;
        var origin = new Point();
        return !IsZoomed(window) && GetClientRect(window, out client) && ClientToScreen(window, ref origin)
            && origin.X == x && origin.Y == y && client.Right == width && client.Bottom == height;
    }

    public static bool Place(IntPtr window, int x, int y, int width, int height) {
        if (IsZoomed(window))
            return ShowWindowAsync(window, 9);
        Rect outer, client;
        var origin = new Point();
        if (!GetWindowRect(window, out outer) || !GetClientRect(window, out client) || !ClientToScreen(window, ref origin))
            return false;
        const uint NoZOrder = 0x0004, NoActivate = 0x0010, AsyncWindowPos = 0x4000;
        return SetWindowPos(window, IntPtr.Zero, x + outer.Left - origin.X, y + outer.Top - origin.Y,
            width + outer.Right - outer.Left - client.Right, height + outer.Bottom - outer.Top - client.Bottom,
            NoZOrder | NoActivate | AsyncWindowPos);
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

function Get-Displays {
    [ArchViewerWindows]::Displays() | Sort-Object @{ Expression = 'Primary'; Descending = $true }, Name
}

function Select-Displays($Screens, [switch] $Fallback) {
    $selected = @(switch -Regex ($Profile) {
        '^auto(,DISPLAY\d+)?$' {
            $preferredMain = ($Profile -split ',')[1]
            $Screens | Where-Object Name -EQ $preferredMain
            $Screens | Where-Object Name -NE $preferredMain
        }
        '^primary$' { $Screens | Where-Object Primary }
        '^external$' {
            $external = @($Screens | Where-Object { !$_.Primary })
            if ($external.Count -ne 1) { throw 'Select a connected external display by its DISPLAY name.' }
            $external
        }
        default {
            foreach ($display in (($Profile -replace '^manual,', '') -split ',' | Select-Object -Unique)) {
                $Screens | Where-Object Name -EQ $display
            }
        }
    })
    if (!$selected.Count -and ($Fallback -or $Profile.StartsWith('manual,'))) {
        $selected = @($Screens | Select-Object -First 1)
    }
    $selected | Select-Object -First 4
}

function Format-Layout($Screens) {
    foreach ($screen in $Screens) {
        '{0} {1} {2} {3} {4} {5} {6} {7}' -f $screen.Name, $screen.X, $screen.Y, $screen.Width, $screen.Height,
            $screen.ScalePercent, [int] $screen.PanelDpi, $screen.Id
    }
}

if ($Action -in 'displays', 'layout', 'choose') {
    [void] [ArchViewerWindows]::SetThreadDpiAwarenessContext([IntPtr](-4))
    $screens = @(Get-Displays)
    if ($Action -eq 'displays') {
        foreach ($screen in $screens) {
            $label = if ($screen.Primary) { ' primary' } else { '' }
            '{0}{1} {2}x{3} at {4},{5} ({6}% Windows scale, {7} PPI)' -f $screen.Name, $label,
                $screen.Width, $screen.Height, $screen.X, $screen.Y, $screen.ScalePercent, [int] $screen.PanelDpi
        }
        return
    }
    if ($Action -eq 'choose') {
        Add-Type -AssemblyName System.Windows.Forms
        $form = New-Object Windows.Forms.Form -Property @{
            Text = 'Arch Linux displays'
            ClientSize = New-Object Drawing.Size 440, (180 + 32 * $screens.Count)
            FormBorderStyle = 'FixedDialog'
            StartPosition = 'CenterScreen'
            MaximizeBox = $false
            MinimizeBox = $false
            TopMost = $true
            AutoScaleMode = 'Dpi'
        }
        $automatic = $Profile.StartsWith('auto')
        $preferred = @($Profile.Split(',') | Select-Object -Skip 1)
        $follow = New-Object Windows.Forms.CheckBox -Property @{
            Text = 'Automatically use connected displays'; Checked = $automatic
            AutoSize = $true; Left = 20; Top = 18
        }
        $form.Controls.Add($follow)
        $windowsMain = New-Object Windows.Forms.Label -Property @{ Text = 'Windows main display'; Tag = 'auto' }
        $boxes = @(for ($i = 0; $i -lt $screens.Count; $i++) {
            $screen = $screens[$i]
            $tag = $screen.Name
            $label = 'Display {0}  ({1} × {2})' -f $tag.Substring(7), $screen.Width, $screen.Height
            if ($screen.Primary) { $label += '  —  Windows main display' }
            $box = New-Object Windows.Forms.CheckBox -Property @{
                Text = $label; Tag = $tag; Checked = ($tag -in $preferred -or ($automatic -and $i -lt 4))
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
            if ($follow.Checked) { [void] $main.Items.Add($windowsMain) }
            foreach ($box in $boxes) {
                $box.Enabled = !$follow.Checked
                if ($follow.Checked -or $box.Checked) {
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
            $apply.Enabled = $follow.Checked -or ($main.Items.Count -ge 1 -and $main.Items.Count -le 4)
        }
        $follow.add_CheckedChanged($refreshMain)
        foreach ($box in $boxes) { $box.add_CheckedChanged($refreshMain) }
        $identify.add_Click({
            $identify.Enabled = $false
            $labels = @(for ($i = 0; $i -lt $screens.Count; $i++) {
                $bounds = $screens[$i]
                $badge = New-Object Windows.Forms.Form -Property @{
                    Text = 'Display identification'; FormBorderStyle = 'None'; TopMost = $true
                    ShowInTaskbar = $false; Size = New-Object Drawing.Size 112, 88
                    StartPosition = 'Manual'
                    Location = New-Object Drawing.Point ($bounds.X + 32), ($bounds.Y + 32)
                }
                $badge.Controls.Add((New-Object Windows.Forms.Label -Property @{
                    Text = $bounds.Name.Substring(7); Dock = 'Fill'; TextAlign = 'MiddleCenter'
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
            $mainDisplay = $main.SelectedItem.Tag
            if ($follow.Checked) {
                if ($mainDisplay -eq 'auto') { 'auto' } else { "auto,$mainDisplay" }
            } else {
                $ordered = @('manual', $mainDisplay)
                $ordered += @($boxes | Where-Object { $_.Checked -and $_.Tag -ne $mainDisplay } | ForEach-Object Tag)
                $ordered -join ','
            }
        }
        $form.Dispose()
        return
    }
    $selected = @(Select-Displays $screens)
    if (!$selected.Count) { throw "No connected display matches $Profile." }
    Format-Layout $selected
    return
}

$name = [IO.Path]::GetFileNameWithoutExtension($ViewerPath)
$viewerTitle = 'Arch Linux (Hyprland)'
function Get-ViewerProcesses {
    Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.Path -ieq $ViewerPath }
}

function Fit-ViewerWindows($Windows, $Displays) {
    $placed = $true
    for ($i = 0; $i -lt $Displays.Count; $i++) {
        $window = $Windows[$i]
        $display = $Displays[$i]
        if ([ArchViewerWindows]::IsIconic($window)) { continue }
        if (![ArchViewerWindows]::Fills($window, $display.X, $display.Y, $display.Width, $display.Height)) {
            $placed = $false
            if (![ArchViewerWindows]::Place($window, $display.X, $display.Y, $display.Width, $display.Height)) {
                throw "Could not place the viewer on $($display.Name)."
            }
        }
    }
    return $placed
}

if ($Action -in 'arrange', 'watch') {
    [void] [ArchViewerWindows]::SetThreadDpiAwarenessContext([IntPtr](-4))
    $displays = @(foreach ($row in ($Layout -split ';')) {
        $displayName, $x, $y, $width, $height = ($row -split ' ')[0..4]
        [ArchViewerWindows+Display] @{ Name = $displayName; X = $x; Y = $y; Width = $width; Height = $height }
    })
    if ($Handles) {
        $windows = @($Handles -split ',' | ForEach-Object { [IntPtr]([long] $_) })
        $process = Get-ViewerProcesses | Where-Object {
            $current = [ArchViewerWindows]::ForProcess($_.Id, $viewerTitle)
            @($windows | Where-Object { $_ -notin $current }).Count -eq 0
        } | Select-Object -First 1
        if (!$process) { exit 3 }
    } else {
        # The initial SDL windows are staged left to right in output order.
        # Keep those handles once placed, since Windows can arrange them in any direction.
        $deadline = [DateTime]::UtcNow.AddSeconds(45)
        do {
            $process = Get-ViewerProcesses | Select-Object -First 1
            $windows = @()
            if ($process) {
                $windows = @([ArchViewerWindows]::ForProcess($process.Id, $viewerTitle) |
                    Sort-Object { [ArchViewerWindows]::Left($_) })
            }
            if ($windows.Count -eq $displays.Count) { break }
            Start-Sleep -Milliseconds 200
        } while ([DateTime]::UtcNow -lt $deadline)
    }
    if ($windows.Count -ne $displays.Count) {
        throw 'Weaselway did not create the expected viewer windows.'
    }

    if ($Action -eq 'watch') {
        $pending = ''
        $wasVisible = $true
        while (!$process.WaitForExit(750)) {
            $visible = [bool] ($windows | Where-Object { ![ArchViewerWindows]::IsIconic($_) })
            $next = @(Format-Layout (Select-Displays (Get-Displays) -Fallback))
            $snapshot = $next -join ';'
            if ($snapshot -eq $Layout) {
                $pending = ''
                $wasVisible = $visible
                if ($visible) { $null = Fit-ViewerWindows $windows $displays }
            } elseif ($snapshot -and $snapshot -eq $pending -and ($visible -or $wasVisible)) {
                # Windows may minimize a window on the display it removed.
                $next
                return
            } else {
                # Docking and rotation send several intermediate layouts.
                $pending = $snapshot
            }
        }
        return
    }

    # The viewer may still apply its initial size or a DPI change after
    # making the windows visible. Wait for the placement to settle.
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    $stable = 0
    do {
        $stable = if (Fit-ViewerWindows $windows $displays) { $stable + 1 } else { 0 }
        if ($stable -lt 3) { Start-Sleep -Milliseconds 250 }
    } while ($stable -lt 3 -and [DateTime]::UtcNow -lt $deadline)
    if ($stable -lt 3) {
        throw 'The Weaselway windows did not settle on the selected displays.'
    }
    if (!$Handles) {
        foreach ($window in $windows) {
            [ArchViewerWindows]::Raise($window)
        }
        [void] [ArchViewerWindows]::SetForegroundWindow($windows[0])
    }
    $windows -join ','
    return
}

$processes = @(Get-ViewerProcesses)
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
