# 
# Copyright (C) 2025 Intel Corporation. 
# 
# SPDX-License-Identifier: Apache-2.0 
#

import cv2
import tkinter as tk
from tkinter import ttk, messagebox
from PIL import Image, ImageTk
import requests
import threading
import time

COLORS = {
    "background": "#0a0a0a",
    "panel": "#292a2d",
    "text": "#ffffff",
    "accent": "#0070f3",
    "secondary": "#404040",
    "border": "#2a2a2a",
    "success": "#22c55e",
    "warning": "#f59e0b"
}

class ModernTheme:
    @staticmethod
    def configure_styles():
        style = ttk.Style()
        style.theme_use('clam')
        
        # Base styles
        style.configure('.', 
            background=COLORS["background"],
            foreground=COLORS["text"],
            font=('monospace', 10),
            borderwidth=0,
            relief='flat'
        )
        
        # Panel styling
        style.configure('Panel.TFrame', 
            background=COLORS["panel"],
            borderwidth=1,
            bordercolor=COLORS["border"]
        )
        
        # Button styling
        style.configure('TButton',
            background=COLORS["accent"],
            foreground=COLORS["text"],
            padding=8,
            borderradius=4
        )
        style.map('TButton',
            background=[('active', '#0061c9'), ('disabled', COLORS["secondary"])],
            foreground=[('disabled', COLORS["secondary"])]
        )
        
        # Listbox styling
        style.configure('Modern.TListbox',
            background=COLORS["panel"],
            foreground=COLORS["text"],
            selectbackground=COLORS["accent"],
            selectforeground=COLORS["text"],
            borderwidth=0,
            relief='flat',
            font=('Segoe UI', 10),
            padding=8
        )
        
        # Label styling
        style.configure('Header.TLabel',
            font=('Segoe UI', 20, 'bold'),
            foreground=COLORS["text"],
            padding=8
        )
        style.configure('Detail.TLabel',
            font=('Segoe UI', 10),
            foreground=COLORS["text"],
            background=COLORS["panel"]
        )
        
        # Status indicators
        style.configure('Status.TLabel',
            font=('Segoe UI', 10),
            padding=4,
            borderwidth=1,
            bordercolor=COLORS["border"]
        )

class CameraApp:
    def __init__(self):
        self.window = tk.Tk()
        self.window.title("Camera Monitor")
        self.window.geometry("1366x768")
        self.window.configure(bg=COLORS["background"])
        
        ModernTheme.configure_styles()
        self._create_layout()
        self._initialize_system()
        self.window.mainloop()
        
    def _create_layout(self):
        # Main container
        main_frame = ttk.Frame(self.window)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=26, pady=26)

        # Left panel - Camera list
        left_panel = ttk.Frame(main_frame, width=280, style='Panel.TFrame')
        left_panel.pack(side=tk.LEFT, fill=tk.Y, padx=(0, 16))

        ttk.Label(left_panel, text="Connected Cameras", style='Header.TLabel').pack(pady=12, padx=12, anchor='w')
        
        self.cam_listbox = tk.Listbox(left_panel,
            bg=COLORS["panel"],
            selectbackground=COLORS["accent"],
            selectforeground=COLORS["text"],
            activestyle='none',
            borderwidth=0,
            highlightthickness=0,
            font=('Segoe UI', 17)
        )
        self.cam_listbox.pack(fill=tk.BOTH, expand=True, padx=12, pady=(0, 12))
        self.cam_listbox.bind('<<ListboxSelect>>', self.on_camera_select)

        # Right panel - Preview and details
        right_panel = ttk.Frame(main_frame, style='Panel.TFrame')
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        # Preview section
        preview_frame = ttk.Frame(right_panel)
        preview_frame.pack(fill=tk.BOTH, expand=True, padx=12, pady=12)
        
        ttk.Label(preview_frame, text="Live Preview", style='Header.TLabel').pack(anchor='w')
        self.preview_canvas = tk.Canvas(preview_frame,
            bg=COLORS["background"],
            highlightthickness=0,
            bd=0
        )
        self.preview_canvas.pack(fill=tk.BOTH, expand=True, pady=8)

        # Details section
        details_frame = ttk.Frame(right_panel, style='Panel.TFrame')
        details_frame.pack(fill=tk.X, padx=12, pady=(0, 12))

        self.details_container = ttk.Frame(details_frame)
        self.details_container.pack(fill=tk.X, padx=12, pady=12)

        # Status bar
        status_bar = ttk.Frame(self.window, height=32, style='Panel.TFrame')
        status_bar.pack(fill=tk.X, side=tk.BOTTOM)
        
        self.status_label = ttk.Label(status_bar,
            text="Initializing...",
            style='Status.TLabel'
        )
        self.status_label.pack(side=tk.LEFT, padx=12)
        
        self.refresh_btn = ttk.Button(status_bar,
            text="⟳ Scan Now",
            command=self.trigger_scan,
            style='TButton'
        )
        self.refresh_btn.pack(side=tk.RIGHT, padx=12, pady=4)
    
    def _initialize_system(self):
        self.cap = None
        self.current_cam = None
        self.api_base = "http://127.0.0.1:8080"
        self.update_status()
        self.load_cameras()

    def api_request(self, method, endpoint, data=None):
        try:
            response = requests.request(method, f"{self.api_base}{endpoint}", json=data)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            messagebox.showerror("API Error", f"Failed to connect to API: {str(e)}")
            return None

    def update_status(self):
        def status_check():
            response = self.api_request("GET", "/status")
            if response:
                self.status_label.config(text=f"Status: {response['status'].capitalize()} | Cameras: {response['total_cameras_detected']} | Last scan: {response['last_scan_time']}")
            self.window.after(5000, self.update_status)
        
        threading.Thread(target=status_check).start()

    def trigger_scan(self):
        def perform_scan():
            self.refresh_btn.config(state=tk.DISABLED)
            scan_result = self.api_request("POST", "/scan")
            print("scan result\n",scan_result)
            if scan_result:
                messagebox.showinfo("Scan Complete", scan_result["message"])
                self.load_cameras()
            self.refresh_btn.config(state=tk.NORMAL)
        
        threading.Thread(target=perform_scan).start()

    def load_cameras(self):
        def fetch_cameras():
            response = self.api_request("GET", "/cameras")
            print(response)
            if response:
                # Change from response["cameras"] to response["connected_cameras"]
                self.window.after(0, self._update_camera_list, response["cameras"])
            
        
        threading.Thread(target=fetch_cameras).start()

    def _update_camera_list(self, cameras):
        current_selection = self.cam_listbox.curselection()
        self.cam_listbox.delete(0, tk.END)
        
        for cam in cameras:
            self.cam_listbox.insert(tk.END, f"{cam['id']} - {cam['type'].capitalize()}")
        
        if current_selection:
            try:
                self.cam_listbox.selection_set(current_selection[0])
            except tk.TclError:
                pass

    def on_camera_select(self, event):
        selection = event.widget.curselection()
        if selection:
            camera_id = self.cam_listbox.get(selection).split(" - ")[0]
            if camera_id != self.current_cam:
                self.current_cam = camera_id
                self.show_camera_details(camera_id)
                self.start_preview(camera_id)

    def show_camera_details(self, camera_id):
        def fetch_details():
            response = self.api_request("GET", f"/cameras/{camera_id}")
            if response:
                self.window.after(0, self._display_details, response)
        
        threading.Thread(target=fetch_details).start()

    def _display_details(self, details):
        for widget in self.details_container.winfo_children():
            widget.destroy()

        grid_frame = ttk.Frame(self.details_container)
        grid_frame.pack(fill=tk.X)

        entries = [
            ("Name", details.get("name", "N/A")),
            ("Resolution", details.get("resolution", "N/A")),
            ("FPS", details.get("fps", "N/A")),
            ("Connection", details.get("connection", "N/A")),
            ("Status", details.get("status", "N/A").capitalize())
        ]

        for idx, (label, value) in enumerate(entries):
            row = ttk.Frame(grid_frame)
            row.grid(row=idx, column=0, sticky='ew', pady=4)
            
            ttk.Label(row, text=label, width=14, style='Detail.TLabel').pack(side=tk.LEFT, padx=8)
            ttk.Label(row, text=value, style='Detail.TLabel', 
                     foreground=COLORS["success"] if value == "Active" else COLORS["warning"]).pack(side=tk.LEFT)

            if idx < len(entries)-1:
                ttk.Separator(grid_frame, orient='horizontal').grid(row=idx, column=0, sticky='ew', pady=4)

    def start_preview(self, camera_id):
        if self.cap:
            self.cap.release()
            self.cap = None
            
        try:
            # Get camera details
            details = self.api_request("GET", f"/cameras/{camera_id}")
            camera_data = details.get("camera", {})  # Extract nested camera data

            # Check if "index" exists in the camera data
            if camera_data and "index" in camera_data:
                self.cap = cv2.VideoCapture(int(camera_data["index"]))  # Ensure index is an integer
            else:
                raise Exception("Camera index not available")

            # Verify camera access
            if not self.cap.isOpened():
                raise Exception(f"Failed to access camera {camera_id}")
            self.update_preview()

        except Exception as e:
            messagebox.showerror("Camera Error", str(e))
            self.current_cam = None

    def update_preview(self):
        if self.cap and self.cap.isOpened():
            ret, frame = self.cap.read()
            if ret:
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                img = Image.fromarray(frame)
                
                canvas_width = self.preview_canvas.winfo_width()
                canvas_height = self.preview_canvas.winfo_height()
                
                # Maintain aspect ratio with border
                img_ratio = img.width / img.height
                canvas_ratio = canvas_width / canvas_height
                border_size = 2

                if canvas_ratio > img_ratio:
                    new_height = canvas_height - border_size*2
                    new_width = int(new_height * img_ratio)
                else:
                    new_width = canvas_width - border_size*2
                    new_height = int(new_width / img_ratio)

                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                x = (canvas_width - new_width) // 2
                y = (canvas_height - new_height) // 2
                
                # Create bordered preview
                self.preview_canvas.delete("all")
                self.preview_canvas.create_rectangle(
                    x-border_size, y-border_size,
                    x+new_width+border_size, y+new_height+border_size,
                    outline=COLORS["accent"], width=2
                )
                self.preview_image = ImageTk.PhotoImage(image=img)
                self.preview_canvas.create_image(x, y, anchor=tk.NW, image=self.preview_image)
                
        self.window.after(30, self.update_preview)
    
    def on_close(self):
        if self.cap:
            self.cap.release()
        self.window.destroy()

if __name__ == "__main__":
    app = CameraApp()