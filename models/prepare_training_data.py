import pytesseract
import os

os.makedirs("data/processed", exist_ok=True)
with open("data/train.csv", "w") as f:
    f.write("text,annotation\n")  # Header
    for i in range(500):
        text = pytesseract.image_to_string(f"data/label_{i}.png")
        with open(f"data/label_{i}.txt", "r") as txt_f:
            annotation = txt_f.read()
        with open(f"data/processed/label_{i}_text.txt", "w") as out_f:
            out_f.write(text)
        f.write(f"{text},{annotation}\n")
print("Training data prepared in data/train.csv and data/processed/")