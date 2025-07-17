"""
Plot test results for different LLMs' ability to write the required quality of Cypher to
answer the user's questions.
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import ListedColormap

RED = "#8B0000"
GREEN = "#006400"

# Full schema results (no pruning)
json_results_full = {
    "openai/gpt-4.1": "............F.................",
    "google/gemini-2.5-flash": "......FF....F...F.....F.F.F...",
    "google/gemini-2.0-flash": "......F.....F...F.............",
    "mistralai/devstral-medium": "....F.F..F.FF........F..F..F..",
    "openai/gpt-4.1-nano": "....F.FF.FF.FF.FFF...FF.F.FFF.",
}

xml_results_full = {
    "openai/gpt-4.1": "..F.........F........F........",
    "google/gemini-2.5-flash": "...FF.FF.F....F.......F...F.F.",
    "google/gemini-2.0-flash": "......F.....F.F...........F...",
    "mistralai/devstral-medium": "....F.F..F.F.........FF.F.FF..",
    "openai/gpt-4.1-nano": "....F.F.FFFFFFF.FF....F.F...F.",
}

yaml_results_full = {
    "openai/gpt-4.1": "......F.....F...........F..F..",
    "google/gemini-2.5-flash": "....F.FF.F..F.F.......F...FF..",
    "google/gemini-2.0-flash": "......F.....F.................",
    "mistralai/devstral-medium": "....F.F..F.FF........F..F..F..",
    "openai/gpt-4.1-nano": "..F.F.FF.FFFFFF.F...F.F.F.F.F.",
}

# Pruned schema results
json_results_pruned = {
    "openai/gpt-4.1": "..............................",
    "google/gemini-2.5-flash": "..........F...F...............",
    "google/gemini-2.0-flash": "..........F...................",
    "mistralai/devstral-medium": "......................F.......",
    "openai/gpt-4.1-nano": "......FF....F.F.FF...FF.F...F.",
}

xml_results_pruned = {
    "openai/gpt-4.1": "..............................",
    "google/gemini-2.5-flash": "......F.....F...F.........F...",
    "google/gemini-2.0-flash": "............F.................",
    "mistralai/devstral-medium": "...........................F..",
    "openai/gpt-4.1-nano": "....F.FFFFFFF.F.FF...FF.F.F.F.",
}

yaml_results_pruned = {
    "openai/gpt-4.1": "..F...........................",
    "google/gemini-2.5-flash": "............F...F.........F...",
    "google/gemini-2.0-flash": "..............................",
    "mistralai/devstral-medium": "......FF.F............F....F..",
    "openai/gpt-4.1-nano": "..F.F.FF....F.F.FF...FF....F..",
}


def parse_results(results_dict):
    """Convert string results to binary matrix"""
    models = list(results_dict.keys())
    num_tests = len(list(results_dict.values())[0])

    matrix = np.zeros((len(models), num_tests))

    for i, (_, result_str) in enumerate(results_dict.items()):
        for j, char in enumerate(result_str):
            matrix[i, j] = 1 if char == "." else 0  # 1 for pass (.), 0 for fail (F)

    return matrix, models


def get_model_results(model, full_dicts, pruned_dicts):
    """Return 2D arrays for a single model: (2, num_formats, num_questions)"""
    formats = ["JSON", "XML", "YAML"]
    full_results = []
    pruned_results = []
    for d in full_dicts:
        s = d.get(model)
        arr = np.array([1 if c == "." else 0 for c in s])
        full_results.append(arr)
    for d in pruned_dicts:
        s = d.get(model)
        arr = np.array([1 if c == "." else 0 for c in s])
        pruned_results.append(arr)
    return np.array(full_results), np.array(pruned_results), formats


def main():
    models = list(json_results_full.keys())
    full_dicts = [json_results_full, xml_results_full, yaml_results_full]
    pruned_dicts = [json_results_pruned, xml_results_pruned, yaml_results_pruned]
    num_questions = len(list(json_results_full.values())[0])
    formats = ["JSON", "XML", "YAML"]

    fig, axes = plt.subplots(len(models), 2, figsize=(18, 10), sharex=True)
    if len(models) == 1:
        axes = axes[np.newaxis, :]  # ensure 2D

    for i, model in enumerate(models):
        full, pruned, _ = get_model_results(model, full_dicts, pruned_dicts)
        # Each is shape (3, num_questions)
        for j, (data, title) in enumerate(zip([full, pruned], ["Full Schema", "Pruned Schema"])):
            ax = axes[i, j]
            im = ax.imshow(data, cmap=ListedColormap([RED, GREEN]), aspect="auto", vmin=0, vmax=1)
            ax.set_yticks(range(3))
            ax.set_yticklabels(formats, fontsize=14)
            if i == len(models) - 1:
                ax.set_xticks(range(num_questions))
                ax.set_xticklabels([f"Q{k+1}" for k in range(num_questions)], fontsize=10)
                plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
            else:
                ax.set_xticks([])
            ax.set_title(f"{model} - {title}", fontsize=20, pad=6)
            ax.set_xticks(np.arange(-0.5, num_questions, 1), minor=True)
            ax.set_yticks(np.arange(-0.5, 3, 1), minor=True)
            ax.grid(True, which="minor", color="white", linewidth=0.1)

    plt.tight_layout()
    plt.savefig("per_model_results.png", dpi=300, bbox_inches="tight")


if __name__ == "__main__":
    main()
