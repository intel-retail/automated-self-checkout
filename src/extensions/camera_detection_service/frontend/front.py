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
import queue
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

COLORS = {
    "background": "#0a0a0a",
    "panel": "#33353a",
    "text": "#ffffff",
    "accent": "#1a73e8",
    "secondary": "#5a5a5a",
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
        logger.info("Starting Camera Monitor Application")
        self.window = tk.Tk()
        self.window.title("Camera Monitor")
        self.window.geometry("1366x768")
        self.window.configure(bg=COLORS["background"])
        
        # Add these new instance variables
        self.preview_running = False
        self.preview_thread = None
        self.frame_queue = None
        
        ModernTheme.configure_styles()
        self._create_layout()
        self._initialize_system()
        self.window.protocol("WM_DELETE_WINDOW", self.on_close)  # Add proper cleanup
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
        self.cam_listbox.bind('<Button-1>', self.on_camera_click)

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
        self.frame_queue = queue.Queue(maxsize=2)  # Pre-initialize queue
        self.preview_running = False
        self.preview_thread = None
        
        # Start with a clean preview canvas
        self.preview_canvas.delete("all")
        
        # Initialize status and load cameras
        self.update_status()
        self.load_cameras()

    def api_request(self, method, endpoint, data=None):
        try:
            response = requests.request(method, f"{self.api_base}{endpoint}", json=data)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API Error: Failed to connect to API: {str(e)}")
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
            logger.info("User initiated camera scan")
            self.refresh_btn.config(state=tk.DISABLED)
            scan_result = self.api_request("POST", "/scan")
            if scan_result:
                logger.info(f"Scan completed: {scan_result['message']}")
                self.window.after(0, lambda: messagebox.showinfo(
                    "Initialization", 
                    "First-time initialization may take a few moments while cameras are being detected. Please wait..."
                ))
                self.window.after(0, lambda: messagebox.showinfo("Scan Complete", scan_result["message"]))
                self.window.after(0, self.load_cameras)

            self.window.after(0, lambda: self.refresh_btn.config(state=tk.NORMAL))
        
        threading.Thread(target=perform_scan).start()

    def load_cameras(self):
        def fetch_cameras():
            response = self.api_request("GET", "/cameras")
            if response and "cameras" in response:
                self.window.after(0, lambda: self._update_camera_list(response["cameras"]))
                # Automatically select first camera after list is updated
                self.window.after(100, self.select_first_camera)

        threading.Thread(target=fetch_cameras, daemon=True).start()

    def select_first_camera(self):
        """Automatically select and load the first camera in the list."""
        if self.cam_listbox.size() > 0:
            self.cam_listbox.selection_clear(0, tk.END)
            self.cam_listbox.selection_set(0)
            clicked_item = self.cam_listbox.get(0)
            camera_id = clicked_item.split(" - ")[0]
            
            # Stop any existing preview
            self.stop_preview()
            
            # Update current camera and start preview
            self.current_cam = camera_id
            self.show_camera_details(camera_id)
            self.window.after(100, lambda: self.start_preview(camera_id))

    def _update_camera_list(self, cameras):
        """Efficiently update the camera listbox only if it has changed."""
        try:
            # Handle both list and dictionary response formats
            if isinstance(cameras, dict):
                new_camera_list = [f"{cam['id']} - {cam['type'].capitalize()}" for cam in cameras.values()]
            else:
                new_camera_list = [f"{cam['id']} - {cam['type'].capitalize()}" for cam in cameras]
            
            # Only update if the list has changed
            current_items = self.cam_listbox.get(0, tk.END)
            if list(current_items) == new_camera_list:
                return  # No need to update UI

            logger.info(f"Updating camera list with {len(new_camera_list)} cameras")
            self.cam_listbox.delete(0, tk.END)
            for cam in new_camera_list:
                self.cam_listbox.insert(tk.END, cam)
        except Exception as e:
            logger.error(f"Error updating camera list: {str(e)}")
            messagebox.showerror("Error", "Failed to update camera list")

    def on_camera_click(self, event):
        """Handle camera selection via click"""
        clicked_index = self.cam_listbox.nearest(event.y)
        if clicked_index < 0:
            return
            
        self.cam_listbox.selection_clear(0, tk.END)
        self.cam_listbox.selection_set(clicked_index)
        
        clicked_item = self.cam_listbox.get(clicked_index)
        camera_id = clicked_item.split(" - ")[0]
        logger.info(f"Camera {camera_id} selected")
        
        logger.info(f"Switching to camera: {camera_id}")
        
        # Stop the current preview and ensure cleanup
        self.stop_preview()
        time.sleep(0.1)  # Small delay to ensure cleanup is complete
        
        # Update current camera after cleanup
        self.current_cam = camera_id
        
        # Show details and start new preview
        self.show_camera_details(camera_id)
        self.window.after(200, lambda: self.start_preview(camera_id))

    def show_camera_details(self, camera_id):
        def fetch_details():
            response = self.api_request("GET", f"/cameras/{camera_id}")
            if response:
                self.window.after(0, self._display_details, response)
        
        threading.Thread(target=fetch_details).start()

    def _display_details(self, details):
        for widget in self.details_container.winfo_children():
            widget.destroy()
        
        print("details\n", details, flush=True)

        # Extract camera details safely
        camera_info = details.get("camera", {})  # Fetch the 'camera' dictionary

        grid_frame = ttk.Frame(self.details_container)
        grid_frame.pack(fill=tk.X)

        # Ensure all entries extract data from camera_info, NOT details
        entries = [
            ("Name", camera_info.get("name", "N/A")),
            ("Resolution", camera_info.get("resolution", "N/A")),
            ("FPS", camera_info.get("fps", "N/A")),
            ("Connection", camera_info.get("connection", "N/A")),
            ("Status", camera_info.get("status", "N/A").capitalize())
        ]

        # print(camera_info.get("status", "N/A").capitalize(), flush=True)

        for idx, (label, value) in enumerate(entries):
            row = ttk.Frame(grid_frame)
            row.grid(row=idx, column=0, sticky='ew', pady=4)

            ttk.Label(row, text=label, width=14, style='Detail.TLabel').pack(side=tk.LEFT, padx=8)
            ttk.Label(row, text=value, style='Detail.TLabel',
                        foreground=COLORS["success"] if value != "N/A" else COLORS["warning"]
                    ).pack(side=tk.LEFT)


            if idx < len(entries) - 1:
                ttk.Separator(grid_frame, orient='horizontal').grid(row=idx + 1, column=0, sticky='ew', pady=(8, 4))  # Move separator down


    def start_preview(self, camera_id):
        if camera_id != self.current_cam:
            logger.warning(f"Stale camera preview request for {camera_id}, current is {self.current_cam}")
            return  # Prevent stale camera preview
            
        try:
            # Ensure previous preview is fully stopped
            if self.preview_thread and self.preview_thread.is_alive():
                logger.warning("Previous preview thread still active, waiting for cleanup")
                self.stop_preview()
                time.sleep(0.2)  # Wait for cleanup
                
            logger.info(f"Starting preview for camera {camera_id}")
            # Get camera details
            details = self.api_request("GET", f"/cameras/{camera_id}")
            camera_data = details.get("camera", {})

            if not camera_data or "index" not in camera_data:
                raise Exception("Camera index not available")

            logger.info(f"Initializing capture for camera index {camera_data['index']}")
            # Initialize new capture
            self.cap = cv2.VideoCapture(int(camera_data["index"]))
            
            if not self.cap.isOpened():
                raise Exception(f"Failed to access camera {camera_id}")
            
            # Optimize camera settings
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Minimize frame buffer
            self.cap.set(cv2.CAP_PROP_FPS, 30)  # Set target FPS
            
            # Clear existing queue
            while not self.frame_queue.empty():
                try:
                    self.frame_queue.get_nowait()
                except:
                    break
            
            # Start preview thread
            print(f"Starting preview thread for camera {camera_id}", flush=True)
            self.preview_running = True
            self.preview_thread = threading.Thread(target=self._capture_frames, daemon=True)
            self.preview_thread.start()
            self.update_preview()

        except Exception as e:
            logger.error(f"Error starting preview for camera {camera_id}: {str(e)}")
            messagebox.showerror("Camera Error", str(e))
            self.current_cam = None
            self.stop_preview()

    def _capture_frames(self):
        """Capture frames in a separate thread"""
        while self.preview_running and self.cap and self.cap.isOpened():
            try:
                ret, frame = self.cap.read()
                if not ret:
                    time.sleep(0.01)
                    continue
                    
                if self.frame_queue.full():
                    try:
                        self.frame_queue.get_nowait()
                    except:
                        pass
                        
                self.frame_queue.put_nowait(frame)
                time.sleep(0.016)  # ~60 FPS
                
            except Exception as e:
                logger.error(f"Frame capture error: {str(e)}")
                time.sleep(0.01)

    def update_preview(self):
        if not self.preview_running:
            return

        try:
            frame = self.frame_queue.get_nowait()
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
            
            self.preview_canvas.delete("all")
            self.preview_canvas.create_rectangle(
                x-border_size, y-border_size,
                x+new_width+border_size, y+new_height+border_size,
                outline=COLORS["accent"], width=2
            )
            self.preview_image = ImageTk.PhotoImage(image=img)
            self.preview_canvas.create_image(x, y, anchor=tk.NW, image=self.preview_image)
        except queue.Empty:
            pass
        
        self.window.after(30, self.update_preview)

    def stop_preview(self):
        """Stops the current camera preview."""
        logger.info("Stopping current preview")
        
        try:
            # Set flag first to stop frame capture loop
            self.preview_running = False
            
            # Clear the frame queue first to prevent blocking
            if self.frame_queue:
                while not self.frame_queue.empty():
                    try:
                        self.frame_queue.get_nowait()
                    except queue.Empty:
                        break
            
            # Wait for preview thread to finish with timeout
            if self.preview_thread and self.preview_thread.is_alive():
                try:
                    self.preview_thread.join(timeout=0.5)
                except Exception as e:
                    logger.error(f"Error joining preview thread: {str(e)}")
                finally:
                    self.preview_thread = None
            
            # Release camera last, after thread is stopped
            if self.cap:
                try:
                    self.cap.release()
                except Exception as e:
                    logger.error(f"Error releasing camera: {str(e)}")
                finally:
                    self.cap = None
            
            # Clear the canvas in the main thread
            self.window.after(0, lambda: self.preview_canvas.delete("all"))
            
        except Exception as e:
            logger.error(f"Error during preview cleanup: {str(e)}")
        finally:
            logger.info("Preview stopped successfully")

    def on_close(self):
        """Cleanup when closing the application"""
        logger.info("Application closing")
        self.stop_preview()
        self.window.destroy()

if __name__ == "__main__":
    app = CameraApp()