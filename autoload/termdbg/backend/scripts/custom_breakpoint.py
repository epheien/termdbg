import lldb
import os

def breakpoint_with_full_path(debugger, command, result, internal_dict):
    target = debugger.GetSelectedTarget()
    if not target:
        result.PutCString("No target found.")
        return

    # Execute the original breakpoint command
    debugger.HandleCommand(f"__builtin_b {command}")

    num_breakpoints = target.GetNumBreakpoints()
    if num_breakpoints == 0:
        result.PutCString("No breakpoint created.")
        return

    # Get the last created breakpoint
    breakpoint = target.GetBreakpointAtIndex(num_breakpoints - 1)
    if not breakpoint:
        result.PutCString("No breakpoint created.")
        return

    bpid = breakpoint.GetID()
    for location in breakpoint:
        address = location.GetAddress()
        line_entry = address.GetLineEntry()
        file_spec = line_entry.GetFileSpec()
        if file_spec:
            full_path = file_spec.GetDirectory() + "/" + file_spec.GetFilename()
            full_path = os.path.abspath(full_path)
            result.PutCString(f"Breakpoint {bpid} set at {full_path}:{line_entry.GetLine()}")

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command alias __builtin_b b')
    debugger.HandleCommand('command script add -f custom_breakpoint.breakpoint_with_full_path b')
    print('The "b" command has been installed, use "b" to set breakpoints with full file paths.')
