# ============================================================================
#  WindowsOPTGame - FlushMem.ps1
#  Zero-dependency RAM, Standby List, Working Set and System File Cache Purger
# ============================================================================
[CmdletBinding()]
param()

$code = @'
using System;
using System.Runtime.InteropServices;

public class Win32MemoryPurger {
    [DllImport("ntdll.dll")]
    public static extern uint RtlAdjustPrivilege(int privilege, bool bEnablePrivilege, bool bCurrentThread, out bool bEnabled);

    [DllImport("ntdll.dll")]
    public static extern uint NtSetSystemInformation(int infoClass, IntPtr infoPtr, uint infoLen);

    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetSystemFileCacheSize(IntPtr minimumFileCacheSize, IntPtr maximumFileCacheSize, int flags);

    public static void Purge() {
        bool prev;
        // 19 = SeProfileSingleProcessPrivilege (Required for NtSetSystemInformation MemoryList class)
        RtlAdjustPrivilege(19, true, false, out prev);
        // 28 = SeIncreaseQuotaPrivilege
        RtlAdjustPrivilege(28, true, false, out prev);

        // Command 4 = Purge Standby List
        // Command 1 = Flush Modified Page List
        // Command 0 = Empty Working Sets
        int[] commands = new int[] { 0, 1, 4, 5 };
        foreach (int cmd in commands) {
            try {
                IntPtr pCmd = Marshal.AllocHGlobal(sizeof(int));
                Marshal.WriteInt32(pCmd, cmd);
                NtSetSystemInformation(80, pCmd, (uint)sizeof(int));
                Marshal.FreeHGlobal(pCmd);
            } catch {}
        }

        try {
            SetSystemFileCacheSize((IntPtr)(-1), (IntPtr)(-1), 0);
        } catch {}
    }
}
'@

try {
    Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
} catch {}

# 1. Flush Working sets across all processes
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Handle -ne $null } | ForEach-Object {
    try { [void][Win32MemoryPurger]::EmptyWorkingSet($_.Handle) } catch {}
}

# 2. Flush Standby, Modified, and System cache
try {
    [Win32MemoryPurger]::Purge()
} catch {}

# 3. Force garbage collection
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
