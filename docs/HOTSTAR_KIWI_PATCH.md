# Hotstar Kiwi DRM Reverse Engineering & Patching Guide

## Overview
On Amazon Fire TV devices, Hotstar (and several other streaming apps sourced from the Amazon Appstore) incorporates the proprietary **Amazon Kiwi DRM SDK**. 

If the user deregisters or does not log into an Amazon account, Hotstar fails on startup with a blocking modal dialog:
> *"Not Logged In: You must be logged in to run this application. Please log in through the Settings menu."*

Pressing OK executes `System.exit(0)`, terminating the app.

---

## Risk Warning: Account Suspension & App Integrity

Modifying application bytecode (smali) carries inherent risks:
- **Detection Vectors:** Streaming providers regularly deploy client-side telemetry, checksum validation, and Play Integrity / attestation checks. While the Kiwi DRM patch solely alters Amazon Appstore licensing hooks (`com.amazon.android.Kiwi`), backend security routines can potentially detect modified dex files or signature mismatches.
- **Potential Consequences:** Streaming session termination, playback errors (e.g., error codes 401/403 or "Device not supported"), or permanent account suspension for violating the provider's Terms of Service.
- **Recommendations:**
  - Understand the risk before patching.
  - Test with a secondary or non-critical account.
  - Do not redistribute patched APKs publicly.

---

## Technical Analysis of Kiwi DRM

### 1. The Kiwi Lifecycle
When Hotstar launches:
1. `ComponentActivity.onCreate()` invokes:
   ```java
   Kiwi.onCreate(this, true);
   ```
2. Kiwi initiates a workflow chain to verify the Amazon account status.
3. Kiwi communicates with `com.amazon.venezia.command.CommandService` via IPC:
   ```
   Command: get_license
   ```
4. Venezia's `CheckLoginAction` queries `MAPAccountManager.getAccounts()`.
5. If no Amazon account is configured, Venezia returns `NotLoggedInDecisionResult`.
6. Kiwi's `PromptManagerImpl` constructs a system `AlertDialog` with the error text and invokes `ShutdownPrompt.b()`, calling `System.exit(0)`.

---

## Bytecode Patching (Smali Modifications)

The Kiwi SDK in Hotstar is located inside `classes14.dex`.

### Patch 1: Neutralize Launch Workflow (`Kiwi.smali`)
In `com/amazon/android/Kiwi.smali`:
Force the workflow to return `DrmFreeApplicationLaunchTaskWorkflow` (`com.amazon.android.b`):
```smali
.method public static getLaunchWorkflow(Lcom/amazon/android/framework/task/Task;Ljava/lang/String;)Lcom/amazon/android/framework/task/workflow/Workflow;
    .registers 3
    new-instance v0, Lcom/amazon/android/b;
    invoke-direct {v0, p0, p1}, Lcom/amazon/android/b;-><init>(Lcom/amazon/android/framework/task/Task;Ljava/lang/String;)V
    return-object v0
.end method
```

### Patch 2: Strip License Enforcement Workflow (`com/amazon/android/c.smali`)
Remove `LicenseEnforcementTaskWorkflow` (`com.amazon.android.licensing.e`) from the task pipeline.

### Patch 3: Neutralize Prompt Manager (`PromptManagerImpl.smali`)
In `com/amazon/android/framework/prompt/PromptManagerImpl.smali`:
Change `present(Lcom/amazon/android/framework/prompt/Prompt;)V` to return immediately:
```smali
.method public present(Lcom/amazon/android/framework/prompt/Prompt;)V
    .registers 2
    return-void
.end method
```
This ensures that even if an error is triggered, no UI dialog can ever be presented to the user.

### Patch 4: Disable Process Termination (`ShutdownPrompt.smali`)
In `com/amazon/android/framework/prompt/ShutdownPrompt.smali`:
In method `b()V`, comment out or delete the `java/lang/System.exit(I)` invocation:
```smali
# invoke-static {v0}, Ljava/lang/System;->exit(I)V
return-void
```

---

## Recompilation & Timestamp Alignment

After assembling the patched DEX:
1. Re-pack `classes14.dex` into `/data/app/in.startv.hotstar-.../base.apk`.
2. Compile ahead-of-time (AOT) using `dex2oat`:
   ```bash
   cmd package compile -m speed -f in.startv.hotstar
   ```
3. Update the file modification timestamp (`touch -d`) on `base.apk` to match the `ft` (file timestamp) hex value in `/data/system/packages.xml`. This prevents Android's `PackageManagerService` from invalidating the package cache or triggering re-verification.

---

## Result
- Hotstar launches without requiring an Amazon login.
- MediaTek hardware acceleration (`OMX.MTK.VIDEO.DECODER.AVC/HEVC`) is preserved.
- Widevine L1 hardware DRM and 4K UHD streaming remain intact.
