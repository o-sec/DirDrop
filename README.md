# Hide malware in folder names
hide Base64-encoded PowerShell commands inside nested folder names.

### Description:
This research explores a novel technique for covert payload delivery by embedding Base64-encoded PowerShell commands inside nested folder names. Rather than using traditional script or executable files, the payload is split into segments and stored as directory names. A shortcut (.lnk) at the final directory level dynamically reconstructs and executes the payload via PowerShell’s encoded command feature.

### How this Technique Works:

The technique works as follows:

1. **Payload Encoding**
A PowerShell command is encoded using UTF-16LE and Base64, as required by PowerShell's -EncodedCommand option.

2. **Folder Chaining**
The Base64-encoded payload is split into small chunks (e.g., 5–10 characters). Each chunk becomes the name of a nested folder. For example:
```
C:\Base\VwBy\AGkAdABl\AC0ASABvAHMAdAAg
```

3. **Shortcut Creation**
In the final directory, a Windows shortcut (.lnk file) is created. This shortcut contains a one-liner PowerShell command that:

- Extracts the full path of the current directory. 
- Strips the base path and joins the folder names into the original Base64 string.

- Executes the reconstructed payload using: `powershell.exe -EncodedCommand [ReconstructedString]`

4. **Execution**
When the `.lnk` file is executed, the payload runs without ever being stored as a `.ps1` or visible code file.



### Limitation:
While this technique is stealthy and creative, it comes with several limitations:

**Path Length Limit:** Windows has a maximum path length (commonly 260 characters), which limits the size of the payload that can be encoded using nested folders unless long path support is enabled.

**Base64 Size Overhead:** Encoding a command in Base64 (especially using UTF-16LE for PowerShell) significantly increases its size, reducing the amount of logic that can fit within the path length limit.

**Shortcut Trust Prompts:** Depending on the system configuration and execution context, clicking a .lnk file may prompt the user for confirmation, reducing stealth.

### proof-of-concept:

i included a powershell script `poc.ps1` to automate the task of creating malicious directory structure.

**usage:**
```
.\poc.ps1 -b <BaseDir> -c  <ClearTextCommand>
.\poc.ps1 -b <BaseDir> -cf <ClearTextFile.ps1>
.\poc.ps1 -b <BaseDir> -e  <Base64Command>
.\poc.ps1 -b <BaseDir> -ef <Base64File.txt>

```

**example:**
`.\poc.ps1 -b SecretDocs -c notepad.exe`

<img src='https://raw.githubusercontent.com/o-sec/DirDrop/main/screenshot.png' />

### Disclaimer:
for educational purposes only. The creator does not condone or support any illegal or unethical use of this tool. Users are responsible for ensuring that their use complies with all applicable laws and regulations.
