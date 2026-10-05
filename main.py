import os
import urllib.parse
import subprocess
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import requests

app = Flask(__name__)
CORS(app)

IMAGE_PATH = "/data/data/com.termux/files/home/output.jpg"
VIDEO_PATH = "/data/data/com.termux/files/home/output.mp4"

def generate_image(prompt):
    """Pollinations.ai နဲ့ AI ပုံ ဖန်တီးခြင်း"""
    try:
        encoded_prompt = urllib.parse.quote(prompt)
        API_URL = f"https://image.pollinations.ai/prompt/{encoded_prompt}?width=1280&height=720&nologo=true&seed={os.urandom(4).hex()}"
        
        print(f"    📡 Calling Pollinations.ai...")
        response = requests.get(API_URL, timeout=90)
        
        if response.status_code == 200 and len(response.content) > 1000:
            with open(IMAGE_PATH, "wb") as f:
                f.write(response.content)
            return True, None
        else:
            return False, f"Status {response.status_code}"
            
    except Exception as e:
        return False, str(e)[:150]

def image_to_video(animation, duration):
    """ပုံကို Animation အမျိုးအစားအလိုက် Video ပြောင်းခြင်း"""
    try:
        frames = int(duration * 25)  # 25 fps
        
        # 🌟 Animation အမျိုးအစား ရွေးချယ်ခြင်း
        if animation == "zoom_in":
            vf = f"scale=1280:720,zoompan=z='min(zoom+0.0015,1.5)':d={frames}:s=1280x720"
        elif animation == "zoom_out":
            vf = f"scale=1280:720,zoompan=z='if(lte(zoom,1.0),1.5,max(1.001,zoom-0.0015))':d={frames}:s=1280x720"
        elif animation == "pan_right":
            vf = f"scale=1600:720,crop=1280:720:x='min(320,(t*40))':y=0"
        elif animation == "pan_left":
            vf = f"scale=1600:720,crop=1280:720:x='max(0,320-(t*40))':y=0"
        elif animation == "rotate":
            vf = f"scale=1280:720,rotate='0.02*t':c=none"
        else:  # Default: zoom_in
            vf = f"scale=1280:720,zoompan=z='min(zoom+0.0015,1.5)':d={frames}:s=1280x720"
        
        cmd = [
            "ffmpeg", "-y",
            "-loop", "1",
            "-i", IMAGE_PATH,
            "-vf", vf,
            "-c:v", "libx264",
            "-t", str(duration),
            "-pix_fmt", "yuv420p",
            "-r", "25",
            VIDEO_PATH
        ]
        
        print(f"    🎬 Animation: {animation}, Duration: {duration}s")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        
        if result.returncode == 0 and os.path.exists(VIDEO_PATH):
            return True, None
        else:
            return False, f"ffmpeg error: {result.stderr[:200]}"
            
    except Exception as e:
        return False, str(e)[:150]

@app.route('/generate_video', methods=['POST'])
def generate_video():
    data = request.json
    prompt = data.get('prompt', '')
    animation = data.get('animation', 'zoom_in')
    duration = int(data.get('duration', 5))
    
    # Duration ကို ၃ ကနေ ၁၅ စက္ကန့်အတွင်း ကန့်သတ်ခြင်း
    if duration < 3:
        duration = 3
    if duration > 15:
        duration = 15
    
    print(f"\n{'='*50}")
    print(f"📝 Prompt: {prompt}")
    print(f"🎬 Animation: {animation}")
    print(f"⏱️  Duration: {duration}s")
    print(f"{'='*50}")

    # Step 1: AI နဲ့ ပုံ ဖန်တီးခြင်း
    print("\n[Step 1/2] 🎨 Generating image with AI...")
    success, error = generate_image(prompt)
    
    if not success:
        print(f"❌ Image generation failed: {error}")
        return jsonify({
            "status": "error",
            "message": f"AI ပုံ ဖန်တီးမရပါ: {error}"
        }), 500
    
    print("✅ Image generated successfully!")
    
    # Step 2: ပုံကို Video အဖြစ် ပြောင်းခြင်း
    print("\n[Step 2/2] 🎬 Converting image to video...")
    success, error = image_to_video(animation, duration)
    
    if not success:
        print(f"❌ Video conversion failed: {error}")
        return jsonify({
            "status": "error",
            "message": f"Video ပြောင်းမရပါ: {error}"
        }), 500
    
    print("✅ Video created successfully!")
    print(f"{'='*50}\n")
    
    return jsonify({
        "status": "success",
        "video_url": "http://127.0.0.1:8000/video/output.mp4",
        "animation": animation,
        "duration": duration
    })

@app.route('/video/output.mp4')
def get_video():
    if os.path.exists(VIDEO_PATH):
        return send_file(VIDEO_PATH, mimetype='video/mp4')
    return jsonify({"status": "error", "message": "Video not found"}), 404

if __name__ == '__main__':
    print("✅ Server ready!")
    print("🎨 Pollinations.ai (Free AI)")
    print("🎬 Animations: zoom_in, zoom_out, pan_left, pan_right, rotate")
    print("⏱️  Duration: 3-15 seconds")
    
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    
    app.run(host='0.0.0.0', port=8000)
