# Program Execution & Workflow

This directory houses the briefing presentation program. The submission script is automated via Cron, managing job dependencies.

## Execution Workflow Map

The diagram below represents the program end-to-end execution.

```mermaid
graph TD
    %% Crontab submission
    Cron([Monthly Cron Submission]) -->|Invokes| Master[launch_briefing.sh]

    %% Level 1: LSF queue parallel execution streams
    Master -->|bsub| JobA[download_from_web.sh]
    Master -->|bsub| JobB[launch_diagnostic_briefing.sh]
    Master -->|bsub -p -w 'done A && done B'| JobC[assemble_briefing.sh]

    %% LSF Tier 1 (Stream A is childless)
    style JobA fill:#d4ebf2,stroke:#333

    %% LSF Tier 1 (Stream B with its children)
    subgraph Stream_B [LSF Execution Stream B]
        JobB --> ScriptB_1[briefing_diag_plots.sh]
        JobB --> ScriptB_2[python/plot_forecast_anom_prob.py]
    end 

    %% Level 2 & 3: LSF double dependency queue submission and final actions with its children
    subgraph Stream_C [LSF Dependent Stream: assemble_briefing.sh]
        JobC --> SubNCL[ncl/forecast_summary.ncl <br> NCL Script]
        JobC --> SubShell[calc_daily_anom_obs_briefing.sh]
        SubShell --> SubShellNCL[ncl/make_daily_anom_graph.ncl <br> NCL Script]
        
        JobC --> SubPy[python/modify_template_dev.py <br> Python Script]
        %% Template pptx interaction
        Templates[(pptx/)] -.->|Read/Modify| SubPy
            
        %% Final steps executed by JobC after program is complete
        SubPy --> RClone[[rclone drive upload]]
        SubPy --> Mail[[mail complete notification]]
    end 

    %% Utility script (not run by this program - manually executed on login nodes)
    subgraph Utilities [Utilities]
        Formatter[python/create_template_pptx.py <br> PPTX Template Formatter]
        Templates -.->|Formatted by| Formatter
    end 

    %% Interactive links (relative paths)
    click Master "launch_briefing.sh" "View launch_briefing script"
    click JobA "download_from_web.sh" "View download_from_web script"
    click JobB "launch_diagnostic_briefing.sh" "View launch_diagnostic_briefing script"
    click JobC "assemble_briefing.sh" "View assemble_briefing script"
    click Templates "pptx/" "Open templates directory"
    click Formatter "python/create_template_pptx.py" "View PPTX formatter script"

    %% Visual Styling Legend
    style Cron fill:#fcf,stroke:#333
    style Master fill:#f9f,stroke:#333,stroke-width:2px
    style JobB fill:#d4ebf2,stroke:#333
    style JobC fill:#bbf,stroke:#333,stroke-width:2px
    style RClone fill:#ffc4c4,stroke:#333,stroke-width:2px
    style Mail fill:#ffc4c4,stroke:#333,stroke-width:2px
    style Templates fill:#e1e1e1,stroke:#333,stroke-dasharray: 5 5 
    style Formatter fill:#ffe3ad,stroke:#333
```

## Program summary

This program is organized into subdirectories based on script language/templates (`python/`, `ncl/`, `pptx/`). The execution flow is broken into three phases.

### 1. Crontab submission and parallel execution workflow (Tier 1)
*   **`launch_briefing.sh`** — **Crontab submission**. Monthly submission via a `crontab` schedule. Its primary responsibility is to submit the three shell scripts to queue.
*   **`download_from_web.sh` (Job A)** — Handles web downloads and executes simultaneously with Job B.
*   **`launch_diagnostic_briefing.sh` (Job B)** — Runs in parallel with Job A and coordinates information for processing CMCC contribution diagnostics:
    *   **`briefing_diag_plots.sh`** — Handles the variable diagnostic workflow.
    *   **`python/plot_forecast_anom_prob.py`** — Creates the CMCC contribution diagnostic plots.

### 2. Double-dependency (Job A and Job B) execution workflow and final steps (upload, mail - Tier 2)
*   **`assemble_briefing.sh` (Job C)** — Submitted to queue with a dependency on both Job A and Job B: `bsub -p -w 'done(JobA) && done(JobB)'`. It will **only** begin execution once both parallel jobs have completed successfully. It executes the following tasks:
    1.  **`ncl/forecast_summary.ncl`** — Generates the forecast summary image.
    2.  **`calc_daily_anom_obs_briefing.sh`** — Launcher for the **`ncl/make_daily_anom_graph.ncl`** to generate the esacci sst image.
    3.  **`python/modify_template_dev.py`** — Assembles and saves the briefing pptx, replacing image placeholders with the required images created or downloaded earlier in the workflow.
    4.  **`rclone drive upload`** — Pushes the completed briefing pptx presentation to drive.
    5.  **`mail complete notification`** — Mail alert for program completion.

### 3. Briefing pptx templates, and utilities (not run by this program)
*   **`pptx/`** — Houses the briefing presentation templates.
*   **`python/create_template_pptx.py`** — This offline script is used to modify a pptx file saved in Powerpoint/Keynote, converting the images to placeholders. **`python/modify_template_dev.py`** is a dependency.

