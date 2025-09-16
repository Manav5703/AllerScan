from PIL import Image, ImageDraw, ImageFont
import os
import random

# Define Canadian allergens and synonyms based on Health Canada standards
allergens = {
    "dairy": ["milk", "casein", "whey", "lactose"],
    "peanuts": ["peanut", "arachis"],
    "gluten": ["wheat", "barley", "rye"],
    "soy": ["soybean", "soya"],
    "tree_nuts": ["almond", "cashew"],
    "sesame": ["sesame", "tahini"],
    "eggs": ["egg", "albumen"],
    "fish": ["cod", "salmon"],
    "shellfish": ["shrimp", "crab"],
    "mustard": ["mustard", "sinapis"],
    "sulphites": ["sulphur dioxide", "sulfite"]
}

# Generate mock label image
def create_label_image(label_id, ingredients):
    img = Image.new("RGB", (400, 200), color="white")
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype("arial.ttf", 16)  # Adjust path or use ImageFont.load_default() if font missing
    draw.text((10, 10), f"Ingredients: {', '.join(ingredients)}", fill="black", font=font)
    img.save(f"data/label_{label_id}.png")

    # Save annotation with corrected allergen detection
    with open(f"data/label_{label_id}.txt", "w") as f:
        # Convert ingredients list to lowercase for matching
        ingredients_lower = [ing.lower() for ing in ingredients]
        detected = [allergen for allergen, terms in allergens.items() if any(term in ingredients_lower for term in terms)]
        f.write(f"Contains: {', '.join(detected)}" if detected else "Contains: None")

# Create 500 labels
os.makedirs("data", exist_ok=True)
sample_ingredients = [
    "wheat flour", "sugar", "milk powder", "peanut oil", "soybean oil", "almond extract",
    "sesame seeds", "egg white", "cod oil", "shrimp extract", "mustard powder",
    "sulphur dioxide", "salt", "water", "corn syrup"
]
for i in range(500):
    ingredients = random.sample(sample_ingredients, random.randint(3, 6))
    create_label_image(i, ingredients)

print("Generated 500 synthetic labels in data/")