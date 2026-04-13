import time
import os
import subprocess
import anthropic
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class SaveHandler(FileSystemEventHandler):
    def __init__(self, workspace):
        self.workspace = workspace
        self.client = anthropic.Anthropic()
        self.last_run = {}

    def on_modified(self, event):
        if event.is_directory:
            return
        if not event.src_path.endswith('.sv'):
            return

        now = time.time()
        if now - self.last_run.get(event.src_path, 0) < 1.5:
            return
        self.last_run[event.src_path] = now

        self.run(event.src_path)

    def run(self, filepath):
        filename = os.path.basename(filepath)
        rel_path = os.path.relpath(filepath, self.workspace)

        print(f"\n{'='*60}")
        print(f"💾 Saved: {rel_path}")
        print(f"{'='*60}")

        # Step 1: Run Verilator lint
        lint_output = self.lint(filepath)
        print(lint_output)

        # Step 2: Read the file
        with open(filepath) as f:
            code = f.read()

        # Step 3: Ask Claude for fix suggestions
        print(f"\n🤖 Asking Claude for fix suggestions...\n")
        response = self.client.messages.create(
            model="claude-opus-4-5",
            max_tokens=1500,
            messages=[{
                "role": "user",
                "content": f"""You are a SystemVerilog expert.

Here is the lint report for {filename}:
{lint_output}

Here is the full code:
{code}

For each issue in the lint report:
1. Explain WHY it is a bug in simple terms
2. Show the EXACT line that is wrong
3. Show the FIXED version of that line
4. Rate fix priority: 🔴 CRITICAL / 🟡 WARNING / 🔵 INFO

Keep it concise and practical."""
            }]
        )

        print("💡 FIX SUGGESTIONS")
        print("-" * 60)
        print(response.content[0].text)
        print("=" * 60)

    def lint(self, filepath):
        try:
            result = subprocess.run(
                ["python3", "tools/sv_lint_report.py", filepath],
                capture_output=True,
                text=True,
                cwd=self.workspace
            )
            output = result.stdout + result.stderr
            return output.strip() if output.strip() else "✅ No lint issues found"
        except Exception as e:
            return f"Lint error: {e}"


if __name__ == "__main__":
    workspace = "/Users/lymtics/Documents/SV-Playground"

    observer = Observer()
    handler = SaveHandler(workspace)
    observer.schedule(handler, workspace, recursive=True)
    observer.start()

    print(f"👀 Watching all .sv files in: {workspace}")
    print(f"   Cmd+S on any .sv → lint + fix suggestions")
    print(f"   Ctrl+C to stop\n")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\n🛑 Watcher stopped")

    observer.join()