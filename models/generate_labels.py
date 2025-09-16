from PIL import Image, ImageDraw, ImageFont
import os
import random

# 11 Priority Allergens from Health Canada [web:0, web:20, web:22]
allergens = {
    "dairy": ["milk", "casein", "whey", "lactose", "lait"],  # Bilingual: lait (French for milk)
    "peanuts": ["peanut", "arachis"],
    "tree_nuts": ["almond", "cashew", "walnut", "amande", "noix"],  # Bilingual: amande, noix
    "sesame": ["sesame", "tahini", "sésame"],
    "eggs": ["egg", "albumen", "oeuf"],
    "fish": ["fish", "cod", "salmon", "poisson", "saumon"],
    "crustacean_shellfish": ["shrimp", "crab", "prawn", "crevette"],
    "soy": ["soy", "soybean", "soya", "soja"],
    "wheat": ["wheat", "gluten", "farine de blé"],  # Bilingual: farine de blé
    "sulphites": ["sulphites", "sulfite", "sulphur dioxide", "sulfites"],
    "mustard": ["mustard", "moutarde"]
}

# Realistic Canadian ingredients from Open Food Facts and Health Canada examples [web:6, web:3, web:2]
# Includes common Canadian items like maple, poutine elements, bilingual terms
sample_ingredients = [
    "wheat flour", "maple syrup", "milk powder", "peanut butter", "soy sauce", "almond milk",
    "sesame oil", "egg", "cod fillet", "shrimp", "mustard", "sulphur dioxide", "salt",
    "poutine gravy", "bacon", "cheese curds", "farine de blé", "sirop d'érable", "lait en poudre",
    "beurre d'arachide", "sauce soya", "lait d'amande", "huile de sésame", "oeuf", "filet de morue",
    "crevette", "moutarde", "sulfites", "corn syrup", "sugar", "water", "baking powder"
]

# Generate mock label image with realistic Canadian style (bilingual, "may contain" warnings)
def create_label_image(label_id, ingredients):
    img = Image.new("RGB", (400, 200), color="white")
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()  # Use default font to avoid errors
    text = f"Ingredients / Ingrédients: {', '.join(ingredients)}"
    draw.text((10, 10), text, fill="black", font=font)
    
    # Add "may contain" warning randomly (20% chance, per Health Canada guidelines [web:23, web:24])
    if random.random() < 0.2:
        warning = random.choice(["May contain peanuts / Peut contenir arachides", "May contain milk / Peut contenir lait"])
        draw.text((10, 50), warning, fill="red", font=font)
    
    img.save(f"data/label_{label_id}.png")

    # Save annotation
    with open(f"data/label_{label_id}.txt", "w") as f:
        ingredients_lower = [ing.lower() for ing in ingredients]
        detected = [allergen for allergen, terms in allergens.items() if any(term in ingredients_lower for term in terms)]
        f.write(f"Contains: {', '.join(detected)}" if detected else "Contains: None")

# Create 500 labels
os.makedirs("data", exist_ok=True)
for i in range(500):
    num_ingredients = random.randint(3, 8)  # More realistic range
    ingredients = random.sample(sample_ingredients, num_ingredients)
    create_label_image(i, ingredients)

print("Generated 500 realistic Canadian food label images and annotations in data/")