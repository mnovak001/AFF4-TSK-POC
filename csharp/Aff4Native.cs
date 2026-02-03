using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

internal static class Aff4Native
{
    [DllImport("libaff4tsk.so", CallingConvention = CallingConvention.Cdecl)]
    public static extern SafeTskImgHandle aff4_open_image(
        [MarshalAs(UnmanagedType.LPStr)] string path);

    [DllImport("libaff4tsk.so", CallingConvention = CallingConvention.Cdecl)]
    private static extern void aff4_close_image(IntPtr img);

    internal sealed class SafeTskImgHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        private SafeTskImgHandle() : base(ownsHandle: true) {}

        protected override bool ReleaseHandle()
        {
            aff4_close_image(handle);
            return true;
        }
    }
}
