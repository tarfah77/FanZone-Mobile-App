import qrcode
from PIL import Image, ImageDraw, ImageFont
import os


folder_path = "barcodes"
os.makedirs(folder_path, exist_ok=True)


try:
    font = ImageFont.truetype("arial.ttf", size=18)
except:
    font = ImageFont.load_default()


for i in range(1, 11):
    seat_number = f"A{i}"
    data = f"http://menu?seat={seat_number}"

    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white").convert("RGB")
    draw = ImageDraw.Draw(img)

    bbox = font.getbbox(seat_number)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    img_width, img_height = img.size
    position = ((img_width - text_width) // 2, img_height - text_height - 10)



    img.save(os.path.join(folder_path, f"{seat_number}.png"))

print("✅ تم إنشاء الباركودات في مجلد barcodes.")