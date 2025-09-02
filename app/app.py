from collections import Counter
from flask import Flask, render_template, request

app = Flask(__name__)

def count_words(text):
    # normalize
    tokens = [t.strip(".,!?;:\"'()[]{}").lower() for t in text.split()]
    tokens = [t for t in tokens if t]
    total = len(tokens)
    freq = Counter(tokens).most_common(10)
    return total, freq

@app.route("/", methods=["GET", "POST"])
def index():
    result = None
    text = ""
    if request.method == "POST":
        text = request.form.get("text", "")
        total, top10 = count_words(text)
        result = {"total": total, "top10": top10}
    return render_template("index.html", result=result, text=text)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
