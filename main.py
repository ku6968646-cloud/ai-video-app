import os
from dotenv import load_dotenv
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import requests

# .env ဖိုင်ထဲက Token ကို ဖတ်ခြင်း
load_dotenv()
HF_API_TOKEN = os.getenv("HF_API_TOKEN")

app = Flask(__name__)
CORS(app)

# ဗီဒီယိုဖိုင် သိမ်းမည့်နေရာ
VIDEO_PATH = "/data/data/com.termux/files/home/output.mp4"

@app.route('/generate_video', methods=['POST'])
def generate_video():
    # Token မရှိရင် Error ပြခြင်း
    if not HF_API_TOKEN:
        return jsonify({
            "status": "error",
            "message": "Hugging Face Token မထည့်ရသေးပါ။ .env ဖိုင်ထဲမှာ ထည့်ပါ။"
        }), 500

    data = request.json
    prompt = data.get('prompt', '')
    
    print(f"Received Prompt: {prompt}")

    # Hugging Face API ကို ခေါ်ခြင်း
    API_URL = "https://api-inference.huggingface.co/models/damo-vilab/text-to-video-ms-1.7b"
    headers = {"Authorization": f"Bearer {HF_API_TOKEN}"}
    payload = {"inputs": prompt}

    try:
        print("Generating video... (ခဏစောင့်ပါ)")
        response = requests.post(API_URL, headers=headers, json=payload)
        
        if response.status_code == 200:
            # ဗီဒီယိုဖိုင်ကို သိမ်းဆည်းခြင်း
            with open(VIDEO_PATH, "wb") as f:
                f.write(response.content)
            
            print("Video generated successfully!")
            return jsonify({
                "status": "success",
                "video_url": "http://127.0.0.1:8000/video/output.mp4"
            })
        else:
            print(f"API Error: {response.status_code}")
            return jsonify({
                "status": "error",
                "message": f"API Error: {response.status_code} - {response.text}"
            }), 500
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

# ဗီဒီယိုဖိုင်ကို App ဆီ ပြန်ပို့ပေးတဲ့ လမ်းကြောင်း
@app.route('/video/output.mp4')
def get_video():
    if os.path.exists(VIDEO_PATH):
        return send_file(VIDEO_PATH, mimetype='video/mp4')
    else:
        return jsonify({"status": "error", "message": "Video file not found"}), 404

if __name__ == '__main__':
    if not HF_API_TOKEN:
        print("⚠️ သတိပေးချက်: .env ဖိုင်ထဲမှာ HF_API_TOKEN မထည့်ရသေးပါ။")
    else:
        print("✅ Token loaded successfully!")
    
    app.run(host='0.0.0.0', port=8000)
