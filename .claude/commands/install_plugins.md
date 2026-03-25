# Install Plugins

Install the required Claude Code plugins for the Advanced Training project.

## Step 1: Check installed plugins

```bash
claude plugin list 2>&1
```

## Step 2: Install missing plugins

Only install plugins that are **not** already present in the output (any scope counts). For each missing plugin, run with `--scope project`:

```bash
claude plugin install --scope project superpowers@claude-plugins-official 2>&1 || echo "superpowers plugin: may already be installed or requires interactive install"
```

```bash
claude plugin install --scope project skill-creator@claude-plugins-official 2>&1 || echo "skill-creator plugin: may already be installed or requires interactive install"
```

```bash
claude plugin install --scope project code-simplifier@claude-plugins-official 2>&1 || echo "code-simplifier plugin: may already be installed or requires interactive install"
```

If all plugins are already installed, skip this step and report them as "Already present" in the summary.

## Step 3: Show fallback instructions

If the `claude` CLI command is not available or the plugin install fails, tell the user to run interactively:

- `/plugin install --scope project superpowers@claude-plugins-official`
- `/plugin install --scope project skill-creator@claude-plugins-official`
- `/plugin install --scope project code-simplifier@claude-plugins-official`
- Then `/reload-plugins` to activate

## Output Format

```
== Plugin Summary ==
Already present: [list]
Newly installed: [list]
Failed: [list, if any]

== Manual Steps Required ==
- [any steps the user needs to do manually]
```
