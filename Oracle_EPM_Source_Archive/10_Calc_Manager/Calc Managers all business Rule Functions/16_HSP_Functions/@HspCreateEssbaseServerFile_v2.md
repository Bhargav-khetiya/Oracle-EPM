# @HspCreateEssbaseServerFile

## Overview

`@HspCreateEssbaseServerFile` is a **Hyperion Planning (HSP) custom function** embedded within Oracle EPM Cloud (PBCS/EPBCS). It is an administrative utility designed to dynamically generate a physical text file (or CSV) directly onto the Essbase server's filesystem, populating it with a specific payload of text. 

### Why Does This Function Exist?

When EPM administrators build dynamic calculation scripts, they often need to extract data, trigger downstream system alerts, or create audit logs. Standard `DATAEXPORT` commands export large blocks of numeric data, but they are rigid and cannot easily export custom text strings or contextual warnings (e.g., "Warning: Cost Center 001 Failed Validation").
`@HspCreateEssbaseServerFile` provides granular filesystem control. An administrator can use string concatenation (`@HspConcat` or `@CalcMgrStringsToString`) to build a highly specific custom message, and then use this function to instantly write that message out to a physical `.txt` file on the server. That file can then be picked up by EPM Automate, an FTP agent, or a downstream ERP system for processing.

*Note: In modern EPM Cloud, access to the underlying OS filesystem is highly restricted for security reasons. This function is largely considered a legacy On-Premise tool. If used in the Cloud, it typically writes to the secure `inbox/outbox` directory, but its usage is generally superseded by robust Job Console logging or REST API payload generation.*

### When to Use It

- **Custom Audit Logging**: Writing detailed, row-by-row validation failures to a custom `.txt` file rather than cluttering the generic Job Console.
- **Trigger Files**: Dropping a blank `trigger.txt` file onto the server to alert a listening shell script that the nightly Essbase calculation has finished.
- **Dynamic Parameter Files**: Writing out dynamic runtime parameters to a file that will be read by a subsequent MaxL script or batch process.

---

## Category

**Planning Extensions / File System Integration / Custom HSP Functions**

---

## Syntax

```essbase
@HspCreateEssbaseServerFile("Directory_Path", "File_Name", "File_Content", Append_Flag)
```

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `"Directory_Path"` | String | ✅ Yes | The absolute or relative path to the target folder on the server (e.g., `"/u01/data/outbox/"`). Must be in quotes. |
| `"File_Name"` | String | ✅ Yes | The name of the file to create, including the extension (e.g., `"Audit_Log_FY25.txt"`). Must be in quotes. |
| `"File_Content"` | String | ✅ Yes | The actual text payload you want written inside the file. Can be a hardcoded string or a dynamic string variable. |
| `Append_Flag` | Numeric | ✅ Yes | Determines how the file is handled if it already exists.<br>`1`: Append (Add the new content to the end of the existing file).<br>`0`: Overwrite (Delete the existing file and create a new one). |

---

## Return Value

**Return Type**: Numeric (Status Code)

Returns an integer indicating the success of the filesystem operation.
- **`1`**: Success. The file was created or appended successfully.
- **`0` or Negative Integer**: Failure. The directory does not exist, the server lacks write permissions, or the Cloud environment has blocked filesystem access.

---

## How It Works (Behind the Scenes)

1. **Trigger**: The Essbase engine encounters the function.
2. **Payload Compilation**: It evaluates the inputs, combining the Directory Path and File Name into a full OS path.
3. **OS Handshake**: It requests File I/O (Input/Output) access from the underlying server operating system (Linux or Windows).
4. **Execution**: 
   - If `Append_Flag` is `0`, it issues a standard overwrite command.
   - If `Append_Flag` is `1`, it opens the file in append mode.
   - It writes the `"File_Content"` string to the stream.
5. **Return**: It closes the file lock and returns a success/fail integer back to the calculation block.

---

## Syntax Variants & Scenarios

### Variant 1: Overwriting an Audit File

```essbase
/* 
   Creates a new file called "Audit.txt" in the outbox. 
   If it exists, it completely overwrites it.
*/
VAR vStatus = @HspCreateEssbaseServerFile("/u01/outbox/", "Audit.txt", "Calculation Started.", 0);
```

---

## Practical Examples

### Example 1: Generating a Dynamic Validation Log

**Scenario**: A script calculates `"Net_Income"`. If `"Net_Income"` drops below `$0`, the business logic considers it a critical failure. The script must write a warning message to a physical text file called `"Failure_Log.txt"`, appending a new line for every Cost Center that fails the check.

```essbase
FIX("FY25", "Working", @LEVEL0("Cost_Centers"))
    
    IF("Net_Income" < 0)
        
        /* 
           1. Extract the active Cost Center name to build the message.
        */
        VAR vCCName = @NAME(@CURRMBR("Cost_Center"));
        
        /* 
           2. Construct the error message. 
           (e.g., "Failure detected in Cost Center: 105")
        */
        VAR vErrorMsg = @CalcMgrStringsToString("Failure detected in Cost Center: ", vCCName);
        
        /* 
           3. Write the error to the server file. 
           We use '1' (Append) so we don't overwrite previous failures 
           logged by other Cost Centers in the loop.
        */
        VAR vFileStatus = @HspCreateEssbaseServerFile("/u01/data/outbox/", "Failure_Log.txt", vErrorMsg, 1);
        
    ENDIF
    
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Overwriting in a Loop | Using `Append_Flag = 0` inside a FIX | If you put this function inside a `FIX` statement that hits 5,000 members, and you use `0` (Overwrite), Essbase will create the file 5,000 times, overwriting it every single time. When the script finishes, the file will only contain the very last member's data. If you are logging multiple items, you MUST use `1` (Append) |
| Missing Newline Characters | `Append_Flag = 1` creates a giant text block | The function does not automatically add carriage returns or line breaks (`\n`) to the end of your string. If you append 5 errors, they will look like `"Error 1Error 2Error 3"`. You must manually inject a newline character into your string payload before writing it if you want readable rows |
| Cloud Permissions | Function returns 0 in EPBCS | In modern SaaS Oracle Cloud, you do not have root access to `/u01/` paths. If you try to write to a random Linux directory, the Cloud firewall will block it. You must write strictly to the approved EPM Automate `inbox/outbox` directories, and even then, some environments disable this function entirely. Test it thoroughly in DEV first |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@CalcMgrLogMemberStrings`](../15_CalcMgr_Utility/@CalcMgrLogMemberStrings.md) | The modern Cloud alternative. Instead of creating physical files on the server, it writes the text directly to the EPM Job Console log, which is vastly safer and more compliant for SaaS environments |
| [`@HspConcat`](./@HspConcat.md) | Legacy string function used to build the `"File_Content"` string payload before passing it to the file creator |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — HSP Custom Functions](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/hspcreateessbaseserverfile.html)
