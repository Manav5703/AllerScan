import tensorflow as tf
import pandas as pd
from sklearn.model_selection import train_test_split
import numpy as np
import re
import csv

# Load data with latin1 encoding and handle quoting
try:
    data = pd.read_csv("data/train.csv", encoding="latin1", quoting=csv.QUOTE_ALL, skipinitialspace=True)
except FileNotFoundError:
    raise FileNotFoundError("Could not find 'data/train.csv'. Ensure the file exists in the correct directory.")
except pd.errors.ParserError as e:
    print(f"CSV parsing error: {e}. Attempting to load with error handling...")
    # Fallback: Read CSV manually to handle malformed rows
    rows = []
    with open("data/train.csv", encoding="latin1") as f:
        reader = csv.reader(f)
        header = next(reader)  # Skip header
        for row in reader:
            # Handle rows with unexpected number of fields
            if len(row) >= 2:  # Expect at least text and annotation
                text = row[0].strip()
                annotation = row[-1].strip() if len(row) > 1 else ""
                rows.append([text, annotation])
            else:
                print(f"Skipping malformed row: {row}")
    data = pd.DataFrame(rows, columns=["text", "annotation"])

# Verify data
if "text" not in data.columns or "annotation" not in data.columns:
    raise ValueError("CSV must contain 'text' and 'annotation' columns.")

# Clean and preprocess data
data = data.dropna(subset=["text", "annotation"])  # Drop rows with missing values
data = data[data["text"].str.strip() != ""]  # Drop rows with empty text
data = data[data["annotation"].str.strip() != ""]  # Drop rows with empty annotations

# Define all possible allergens based on CSV
allergens = ["eggs", "crustacean_shellfish", "wheat", "sulphites", "mustard"]

# Clean text (remove special characters, normalize misspellings)
def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^\w\s,]', '', text)  # Remove special characters
    # Normalize common misspellings
    replacements = {
        "vheat": "wheat", "noutarde": "mustard", "noutarle": "mustard", "seuce": "sauce",
        "saya": "soya", "soy": "soya", "oeuf": "egg", "egy": "egg", "oeut": "egg",
        "crevette": "shrimp", "orevette": "shrimp", "shrinp": "shrimp", "sivep": "sirop",
        "sixep": "sirop", "sirup": "sirop", "naple": "maple", "lait": "milk", "jait": "milk",
        "beurre": "butter", "bewrre": "butter", "peanut": "peanut", "peamut": "peanut",
        "pesnut": "peanut", "peawut": "peanut", "arachide": "peanut", "farine": "flour",
        "farime": "flour", "sésane": "sesame", "stsane": "sesame", "sesame": "sesame",
        "almond": "almond", "alnond": "almond", "amande": "almond", "norue": "morue",
        "morue": "cod", "ood": "cod", "poudve": "poudre", "povder": "powder", "powler": "powder",
        "corm": "corn", "com": "corn", "ourds": "curds", "cunts": "curds", "ounds": "curds",
        "sulphur": "sulfite", "sulites": "sulfite", "sulfites": "sulfite"
    }
    for wrong, correct in replacements.items():
        text = text.replace(wrong, correct)
    return text

data["text"] = data["text"].apply(clean_text)

# Handle "May contain" statements by merging with previous row
data["text"] = data["text"].str.replace(r"may contain.*$", "", regex=True).str.strip()

# Extract features and labels
X = data["text"]
y = data["annotation"].apply(lambda x: [1 if allergen in x.split(",") else 0 for allergen in allergens])

# Tokenize text
X = [text.split() for text in X if text.strip()]
if not X:
    raise ValueError("No valid text data found after preprocessing.")

vocab = set(word for sentence in X for word in sentence)
word_index = {word: i + 1 for i, word in enumerate(vocab)}  # Start indexing from 1
X = [[word_index.get(word, 0) for word in sentence] for sentence in X]

# Pad sequences
max_len = max(len(x) for x in X) if X else 100
X = tf.keras.preprocessing.sequence.pad_sequences(X, maxlen=max_len, padding="post", value=0)

# Convert y to numpy array
y = np.array(y.tolist())

# Model
model = tf.keras.Sequential([
    tf.keras.layers.Embedding(len(vocab) + 1, 16, input_length=max_len),
    tf.keras.layers.GlobalAveragePooling1D(),
    tf.keras.layers.Dense(16, activation="relu"),
    tf.keras.layers.Dense(len(allergens), activation="sigmoid")  # Output size matches number of allergens
])
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])

# Train
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model.fit(X_train, y_train, epochs=10, validation_data=(X_test, y_test), verbose=1)

# Save and convert to TFLite
model.save("models/allergen_model.h5")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open("models/allergen_model.tflite", "wb") as f:
    f.write(tflite_model)
print("Trained model saved as models/allergen_model.tflite")