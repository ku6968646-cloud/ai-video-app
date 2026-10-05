from flask import Flask, request, jsonify
from flask_cors import CORS
import requests

app = Flask(__name__)
CORS(app)  # Flutter App ကနေ လှမ်းခေါ်လို့ရအောင် ခွင့်ပြုခြင်း

@app.route('/generate_video', methods=['POST'])
def generate_video():
    data = request.json
    prompt = data.get('prompt', '')
    resolution = data.get('resolution', '720p')
    duration = data.get('duration', 5)

    print(f"Received Prompt: {prompt}")

    # ⚠️ ဒီနေရာမှာ ဗီဒီယိုထုတ်တဲ့ Code အစစ် ထည့်ရပါမယ်။
    # လောလောဆယ် App နဲ့ Server ချိတ်ဆက်မှု အောင်မြင်မအောင် စမ်းသပ်ဖို့
    # နမူနာ ဗီဒီယို Link တစ်ခုကို ပြန်ပို့ပေးထားပါတယ်။
    mock_video_url = "https://www.w3schools.com/html/mov_bbb.mp4"

    return jsonify({
        "status": "success",
        "video_url": mock_video_url,
        "message": "Server connected successfully!"
    })

if __name__ == '__main__':
    # 0.0.0.0 က ဖုန်းတွင်း Network ကနေ လှမ်းခေါ်လို့ရအောင် လုပ်ပေးပါတယ်
    app.run(host='0.0.0.0', port=8000)
