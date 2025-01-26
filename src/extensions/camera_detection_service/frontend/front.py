import cv2
import tkinter as tk
from tkinter import ttk, messagebox
from PIL import Image, ImageTk
import requests
import threading
import time

class CameraApp:
    def __init__(self):
        self.window = tk.Tk()
        self.window.title("Camera Monitor")
        self.window.geometry("1200x800")
        self.api_base = "http://127.0.0.1:8080"
        
        # Configure main layout
        self.main_frame = ttk.Frame(self.window)
        self.main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Control panel
        self.control_frame = ttk.Frame(self.main_frame)
        self.control_frame.pack(fill=tk.X, pady=10)
        
        # Status and controls
        self.status_label = ttk.Label(self.control_frame, text="Status: Connecting...")
        self.status_label.pack(side=tk.LEFT, padx=10)
        
        self.refresh_btn = ttk.Button(self.control_frame, text="Scan Now", command=self.trigger_scan)
        self.refresh_btn.pack(side=tk.RIGHT, padx=10)
        
        # Camera list panel
        self.list_frame = ttk.Frame(self.main_frame, width=300)
        self.list_frame.pack(side=tk.LEFT, fill=tk.Y, padx=10, pady=10)
        
        # Preview panel
        self.preview_frame = ttk.Frame(self.main_frame)
        self.preview_frame.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Camera list components
        ttk.Label(self.list_frame, text="Connected Cameras:", font=('Arial', 12, 'bold')).pack(pady=10)
        self.cam_listbox = tk.Listbox(self.list_frame, width=35, height=20, font=('Arial', 10))
        self.cam_listbox.pack(fill=tk.BOTH, expand=True)
        self.cam_listbox.bind('<<ListboxSelect>>', self.on_camera_select)
        
        # Details panel
        self.details_frame = ttk.Frame(self.preview_frame)
        self.details_frame.pack(fill=tk.X, pady=10)
        
        # Preview components
        ttk.Label(self.preview_frame, text="Live Preview", font=('Arial', 12, 'bold')).pack(pady=10)
        self.preview_canvas = tk.Canvas(self.preview_frame, bg='#2e2e2e')
        self.preview_canvas.pack(fill=tk.BOTH, expand=True)
        
        self.cap = None
        self.current_cam = None
        self.update_status()
        self.load_cameras()
        self.window.protocol("WM_DELETE_WINDOW", self.on_close)
        self.window.mainloop()

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
            if scan_result:
                messagebox.showinfo("Scan Complete", scan_result["message"])
                self.load_cameras()
            self.refresh_btn.config(state=tk.NORMAL)
        
        threading.Thread(target=perform_scan).start()

    def load_cameras(self):
        def fetch_cameras():
            response = self.api_request("GET", "/cameras")
            if response:
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
        for widget in self.details_frame.winfo_children():
            widget.destroy()
        
        entries = [
            ("Name", details.get("name", "N/A")),
            ("Resolution", details.get("resolution", "N/A")),
            ("FPS", details.get("fps", "N/A")),
            ("Connection", details.get("connection", "N/A")),
            ("Status", details.get("status", "N/A").capitalize())
        ]
        
        for label, value in entries:
            frame = ttk.Frame(self.details_frame)
            frame.pack(fill=tk.X, pady=2)
            ttk.Label(frame, text=f"{label}:", width=12, anchor=tk.W).pack(side=tk.LEFT)
            ttk.Label(frame, text=value, anchor=tk.W).pack(side=tk.LEFT, fill=tk.X, expand=True)

    def start_preview(self, camera_id):
        if self.cap:
            self.cap.release()
            self.cap = None
            
        try:
            index = int(camera_id.split("_")[-1])
            self.cap = cv2.VideoCapture(index)
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
                img.thumbnail((self.preview_canvas.winfo_width(), 
                             self.preview_canvas.winfo_height()))
                
                x = (self.preview_canvas.winfo_width() - img.width) // 2
                y = (self.preview_canvas.winfo_height() - img.height) // 2
                
                self.preview_canvas.delete("all")
                self.preview_image = ImageTk.PhotoImage(image=img)
                self.preview_canvas.create_image(x, y, anchor=tk.NW, 
                                                image=self.preview_image)
                
        self.window.after(30, self.update_preview)

    def on_close(self):
        if self.cap:
            self.cap.release()
        self.window.destroy()

if __name__ == "__main__":
    app = CameraApp()