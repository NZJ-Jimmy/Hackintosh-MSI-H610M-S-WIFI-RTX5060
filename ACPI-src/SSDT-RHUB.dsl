// Ignore firmware port descriptions on macOS; USBToolBox supplies the map.
// Firmware declares HS09/HS14 unused even though Linux observes devices there.
DefinitionBlock ("", "SSDT", 2, "LOCAL", "RhubFix", 1)
{
    External (_SB_.PC00.XHCI.RHUB, DeviceObj)
    Scope (\_SB.PC00.XHCI.RHUB)
    {
        Method (_STA, 0, NotSerialized)
        {
            If (_OSI ("Darwin")) { Return (Zero) }
            Return (0x0F)
        }
    }
}
