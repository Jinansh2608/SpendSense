import tkinter as tk
from tkinter import messagebox, scrolledtext
import re
import datetime


class RecursiveBuilderApp:
    def __init__(self, root):
        self.root = root
        self.root.title("📊 Recursive Builder – Smart Daily Cash Flow Tracker")
        self.flow_queue = []
        self.current_flow = {}
        self.entries = []

        # === UI Layout ===
        tk.Label(root, text="📝 Enter your daily fixed cash flow prompts (multiple allowed):").pack(pady=(10, 0))

        self.prompt_entry = tk.Entry(root, width=80)
        self.prompt_entry.pack(pady=5)

        tk.Button(root, text="▶️ Process Prompt", command=self.process_prompt).pack(pady=5)

        self.followup_label = tk.Label(root, text="", font=('Arial', 10, 'bold'))
        self.followup_label.pack(pady=(10, 0))

        self.followup_entry = tk.Entry(root, width=50)
        self.followup_entry.pack()
        self.followup_entry.bind("<Return>", self.handle_followup)

        self.output_area = scrolledtext.ScrolledText(root, width=85, height=15, wrap=tk.WORD, state=tk.DISABLED)
        self.output_area.pack(pady=(10, 10))

    def process_prompt(self):
        raw_input = self.prompt_entry.get().strip()
        if not raw_input:
            messagebox.showwarning("Input Required", "Please enter a prompt first.")
            return
        parts = re.split(r'\s+and\s+|,\s*', raw_input)
        for part in parts:
            flow = self.parse_text_flow(part)
            self.flow_queue.append(flow)

        self.prompt_entry.delete(0, tk.END)
        self.process_next_flow()

    def parse_text_flow(self, prompt: str) -> dict:
        prompt = prompt.lower()
        flow = {
            "type": None,
            "amount": None,
            "source": None,
            "category": None,
            "frequency": "daily",
            "time": None,
            "raw": prompt
        }

        if any(kw in prompt for kw in ["receive", "get", "credit", "income"]):
            flow["type"] = "income"
        elif any(kw in prompt for kw in ["spend", "pay", "deduct", "expense"]):
            flow["type"] = "expense"

        amt = re.search(r"₹?(\d+)", prompt)
        if amt:
            flow["amount"] = int(amt.group(1))

        if flow["type"] == "income":
            src = re.search(r"(?:from|by)\s+([a-zA-Z\s]+)", prompt)
            if src:
                flow["source"] = src.group(1).strip()
        elif flow["type"] == "expense":
            cat = re.search(r"(?:on|for)\s+([a-zA-Z\s]+)", prompt)
            if cat:
                flow["category"] = cat.group(1).strip()

        time = re.search(r"(morning|afternoon|evening|night|\d{1,2}(?:[:.]?\d{2})?\s*(?:am|pm)?)", prompt)
        if time:
            flow["time"] = time.group(1).strip()

        return flow

    def process_next_flow(self):
        if self.flow_queue:
            self.current_flow = self.flow_queue.pop(0)
            self.ask_next_question()
        else:
            messagebox.showinfo("Complete", "✅ All cash flows processed!")

    def ask_next_question(self):
        if self.current_flow["amount"] is None:
            self.followup_label.config(text=f"💰 How much is the amount? (e.g. ₹500)")
        elif self.current_flow["type"] == "income" and not self.current_flow["source"]:
            self.followup_label.config(text="📥 Who is the income from?")
        elif self.current_flow["type"] == "expense" and not self.current_flow["category"]:
            self.followup_label.config(text="💸 What is this expense for?")
        elif self.current_flow["time"] is None:
            self.followup_label.config(text="⏰ When does this occur? (e.g. 9am, morning)")
        else:
            self.save_current_flow()

    def handle_followup(self, event=None):
        answer = self.followup_entry.get().strip()
        self.followup_entry.delete(0, tk.END)

        if not answer:
            messagebox.showerror("Empty", "Please provide a response.")
            return

        if self.current_flow["amount"] is None:
            try:
                self.current_flow["amount"] = int(re.sub(r"[^\d]", "", answer))
            except ValueError:
                messagebox.showerror("Invalid Amount", "Please enter a valid numeric amount.")
                return
        elif self.current_flow["type"] == "income" and not self.current_flow["source"]:
            self.current_flow["source"] = answer
        elif self.current_flow["type"] == "expense" and not self.current_flow["category"]:
            self.current_flow["category"] = answer
        elif self.current_flow["time"] is None:
            self.current_flow["time"] = answer

        self.ask_next_question()

    def save_current_flow(self):
        self.entries.append(self.current_flow.copy())
        self.display_entry(self.current_flow)
        self.current_flow = {}
        self.followup_label.config(text="")
        self.process_next_flow()

    def display_entry(self, flow):
        self.output_area.config(state=tk.NORMAL)
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        if flow["type"] == "income":
            summary = f"[{timestamp}] ✅ Income: ₹{flow['amount']} from '{flow['source']}' every {flow['frequency']} at {flow['time']}.\n"
        else:
            summary = f"[{timestamp}] ✅ Expense: ₹{flow['amount']} on '{flow['category']}' every {flow['frequency']} at {flow['time']}.\n"
        self.output_area.insert(tk.END, summary)
        self.output_area.config(state=tk.DISABLED)


# Run the app
if __name__ == "__main__":
    root = tk.Tk()
    app = RecursiveBuilderApp(root)
    root.geometry("800x550")
    root.mainloop()
