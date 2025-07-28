import tkinter as tk
from tkinter import messagebox, scrolledtext
import re
class RecursiveBuilderApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Recursive Builder – Smart Daily Cash Flow")

        self.flow_queue = []
        self.current_flow = {}
        self.entries = []

        # UI Layout
        self.prompt_label = tk.Label(root, text="📝 Describe your daily fixed cash flows (multiple allowed):")
        self.prompt_label.pack(pady=(10, 0))

        self.prompt_entry = tk.Entry(root, width=70)
        self.prompt_entry.pack(pady=5)

        self.process_button = tk.Button(root, text="▶️ Process Prompt", command=self.process_prompt)
        self.process_button.pack(pady=5)

        self.followup_label = tk.Label(root, text="", font=('Arial', 10, 'bold'))
        self.followup_label.pack(pady=(10, 0))

        self.followup_entry = tk.Entry(root, width=40)
        self.followup_entry.pack()
        self.followup_entry.bind("<Return>", self.handle_followup)

        self.output_area = scrolledtext.ScrolledText(root, width=75, height=12, wrap=tk.WORD, state=tk.DISABLED)
        self.output_area.pack(pady=(10, 10))
    def process_prompt(self):
        text = self.prompt_entry.get().strip()
        if not text:
            return
        parts = re.split(r'\s+and\s+|,\s*', text)
        for part in parts:
            flow = self.parse_text_flow(part)
            self.flow_queue.append(flow)
        self.prompt_entry.delete(0, tk.END)
        self.process_next_flow()
    def parse_text_flow(self, prompt: str) -> dict:
        flow = {
            "type": None,
            "amount": None,
            "source": None,
            "category": None,
            "frequency": "daily",
            "time": None,
            "raw": prompt
        }

        prompt = prompt.lower()

        if "receive" in prompt or "get" in prompt:
            flow["type"] = "income"
        elif "spend" in prompt or "pay" in prompt:
            flow["type"] = "expense"

        amt = re.search(r"₹?(\d+)", prompt)
        if amt:
            flow["amount"] = int(amt.group(1))

        if flow["type"] == "income":
            src = re.search(r"from ([a-zA-Z\s]+)", prompt)
            if src:
                flow["source"] = src.group(1).strip()
        elif flow["type"] == "expense":
            cat = re.search(r"on ([a-zA-Z\s]+)", prompt)
            if cat:
                flow["category"] = cat.group(1).strip()

        time = re.search(r"(morning|afternoon|evening|night|\d{1,2}(?:am|pm)?)", prompt)
        if time:
            flow["time"] = time.group(1)

        return flow

    def process_next_flow(self):
        if self.flow_queue:
            self.current_flow = self.flow_queue.pop(0)
            self.ask_next_question()
        else:
            messagebox.showinfo("Done", "✅ All flows processed!")

    def ask_next_question(self):
        if self.current_flow["amount"] is None:
            self.followup_label.config(text=f"💰 How much is the amount? (For: {self.current_flow['raw']})")
        elif self.current_flow["type"] == "income" and not self.current_flow["source"]:
            self.followup_label.config(text=f"📥 What is the source of income?")
        elif self.current_flow["type"] == "expense" and not self.current_flow["category"]:
            self.followup_label.config(text=f"💸 What is the category of expense?")
        elif self.current_flow["time"] is None:
            self.followup_label.config(text="⏰ What time of the day? (e.g., morning, 9am)")
        else:
            self.save_current_flow()

    def handle_followup(self, event=None):
        answer = self.followup_entry.get().strip()
        self.followup_entry.delete(0, tk.END)

        if self.current_flow["amount"] is None:
            try:
                self.current_flow["amount"] = int(answer)
            except ValueError:
                messagebox.showerror("Invalid", "Please enter a valid number.")
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
        if flow["type"] == "income":
            summary = f"✅ Income: ₹{flow['amount']} from {flow['source']} every {flow['frequency']} at {flow['time']}.\n"
        else:
            summary = f"✅ Expense: ₹{flow['amount']} on {flow['category']} every {flow['frequency']} at {flow['time']}.\n"
        self.output_area.insert(tk.END, summary)
        self.output_area.config(state=tk.DISABLED)


# Run the app
if __name__ == "__main__":
    root = tk.Tk()
    app = RecursiveBuilderApp(root)
    root.geometry("700x500")
    root.mainloop()
 