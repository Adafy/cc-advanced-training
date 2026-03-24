# Claude Code Advanced Training

## Action pack 1

### Step 1. Planning

In plan mode:
Prompt: "Create simple tic-tac-toe game. Create only single html page named tic-tac-toe.html. Write the plan to tic-tac-toe-plan.md file"

### Step 2. Create spec-interview command

Prompt: "/spec-interview current plan. ask only three questions"

Prompt: "Implement the new spec and create a new tic-tac-toe-improved.html file"

### Step 3. Create html validation skill using /skill-creator command
Prompt: "/skill-creator Create local skill that can validate any html based code. It should do code analysis only. Output should be json document which contains list of issues found, nothing else. Set up eval test cases to verify the skill works well. Add `disable-model-invocation: true` frontmatter to prevent this skill to autoload."

## Action pack 2

Tic-tac-toe game using superpowers workflow. Uses `/brainstorming`, `/writing-plans`, `/executing-plans`, and `/code-review` to go from idea to reviewed code.

### Step 1. Brainstorm

Prompt: `/brainstorming Create a tic-tac-toe game with a Rust web server backend and TypeScript frontend UI`

Answer the brainstorming questions to refine the design. Approve the design when ready.

### Step 2. Write Plan

Prompt: `/writing-plans`

The skill will create a detailed implementation plan from the approved design spec.

### Step 3. Execute Plan

Prompt: `/executing-plans`

The skill will execute the plan step by step with review checkpoints.

### Step 4. Code Review

Prompt: `/code-review`

Review the implementation against the original design.
